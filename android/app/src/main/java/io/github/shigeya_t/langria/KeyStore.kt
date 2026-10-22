package io.github.shigeya_t.langria

import android.app.KeyguardManager
import android.content.Context
import android.hardware.biometrics.BiometricManager.Authenticators
import android.hardware.biometrics.BiometricPrompt
import android.os.CancellationSignal
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyPermanentlyInvalidatedException
import android.security.keystore.KeyProperties
import android.util.Base64
import androidx.core.content.edit
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.security.GeneralSecurityException
import java.security.KeyFactory
import java.security.KeyPairGenerator
import java.security.PrivateKey
import java.security.UnrecoverableKeyException
import java.security.spec.MGF1ParameterSpec
import java.security.spec.X509EncodedKeySpec
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.OAEPParameterSpec
import javax.crypto.spec.PSource
import javax.crypto.spec.SecretKeySpec
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import java.security.KeyStore as JavaKeyStore

/**
 * Stores the API keys on this device only, encrypted as one JSON item: with a
 * fresh AES key, itself encrypted with an RSA key pair kept in the Android
 * Keystore. With the lock on, the pair's private key can only be used right
 * after the fingerprint, face or screen lock, so reading the keys asks for
 * that while saving them does not, as with the iOS app's keychain item
 * (KeyStore.swift). The keys stay in memory until the app goes to the
 * background.
 */
object KeyStore {
  private const val FILE = "langria-keys"
  private const val PLAIN_ALIAS = "langria-api-keys"
  private const val LOCKED_ALIAS = "langria-api-keys-locked"
  private const val RSA = "RSA/ECB/OAEPWithSHA-256AndMGF1Padding"
  // The Keystore supports SHA-1 for OAEP's MGF1 on every version.
  private val oaep = OAEPParameterSpec("SHA-256", "MGF1", MGF1ParameterSpec.SHA1, PSource.PSpecified.DEFAULT)

  sealed class Failure : Exception() {
    data object NoScreenLock : Failure()
    data object Cancelled : Failure()
    /** The Keystore lost the key pair (a reset screen lock, for one), so the keys cannot be read. */
    data object KeysLost : Failure()
    data class Keystore(val detail: String) : Failure()
  }

  /** Whether reading the keys needs authentication. Kept in the settings only to draw the UI before reading them. */
  fun isLocked(context: Context) = Settings.prefs(context).getBoolean("langria-lock", false)

  fun canLock(context: Context) = context.getSystemService(KeyguardManager::class.java).isDeviceSecure

  /** Reads the keys; with the lock on this shows the system's prompt, titled `title`, over `context` (an activity). */
  suspend fun load(context: Context, title: String): Map<String, String> {
    val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
    val wrapped = prefs.getString("wrapped", null) ?: return emptyMap()
    val alias = prefs.getString("alias", PLAIN_ALIAS)!!
    val cipher = withContext(Dispatchers.Default) {
      try {
        val key = keystore().getKey(alias, null) as? PrivateKey ?: throw Failure.KeysLost
        Cipher.getInstance(RSA).apply { init(Cipher.DECRYPT_MODE, key, oaep) }
      } catch (error: KeyPermanentlyInvalidatedException) {
        throw Failure.KeysLost
      } catch (error: UnrecoverableKeyException) {
        throw Failure.KeysLost
      } catch (error: GeneralSecurityException) {
        throw Failure.Keystore(error.message ?: error.javaClass.simpleName)
      }
    }
    val unlocked = if (alias == LOCKED_ALIAS) authenticate(context, title, cipher) else cipher
    return withContext(Dispatchers.Default) {
      try {
        val secret = unlocked.doFinal(decode(wrapped))
        val aes = Cipher.getInstance("AES/GCM/NoPadding")
        aes.init(Cipher.DECRYPT_MODE, SecretKeySpec(secret, "AES"), GCMParameterSpec(128, decode(prefs.getString("iv", "")!!)))
        val json = JSONObject(String(aes.doFinal(decode(prefs.getString("data", "")!!))))
        json.keys().asSequence().associateWith { json.getString(it) }
      } catch (error: GeneralSecurityException) {
        throw Failure.KeysLost
      } catch (error: IllegalArgumentException) {
        throw Failure.KeysLost
      }
    }
  }

  /** Replaces the stored keys, protected or not according to `locked`. */
  suspend fun save(context: Context, keys: Map<String, String>, locked: Boolean) = withContext(Dispatchers.Default) {
    if (locked && !canLock(context)) throw Failure.NoScreenLock
    val alias = if (locked) LOCKED_ALIAS else PLAIN_ALIAS
    try {
      val secret = KeyGenerator.getInstance("AES").apply { init(256) }.generateKey()
      val aes = Cipher.getInstance("AES/GCM/NoPadding").apply { init(Cipher.ENCRYPT_MODE, secret) }
      val data = aes.doFinal(JSONObject(keys.filterValues { it.isNotEmpty() }).toString().toByteArray())
      // Encrypting with the public key needs no authentication; a copy outside
      // the Keystore is used, as the Keystore's own copy may refuse it.
      // A new pair each time the lock is turned on, so an old one that the
      // Keystore has since disabled is not used.
      val store = keystore()
      val prefs = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)
      if (locked && prefs.getString("alias", null) != alias && store.containsAlias(alias)) store.deleteEntry(alias)
      val stored = store.getCertificate(alias)?.publicKey ?: generate(alias, locked)
      val publicKey = KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(stored.encoded))
      val wrapped = Cipher.getInstance(RSA).apply { init(Cipher.ENCRYPT_MODE, publicKey, oaep) }.doFinal(secret.encoded)
      prefs.edit(commit = true) {
        putString("alias", alias)
        putString("wrapped", encode(wrapped))
        putString("iv", encode(aes.iv))
        putString("data", encode(data))
      }
    } catch (error: IllegalStateException) {
      // Thrown for a key that needs authentication when there is no screen lock.
      throw Failure.NoScreenLock
    } catch (error: GeneralSecurityException) {
      throw Failure.Keystore(error.message ?: error.javaClass.simpleName)
    }
    Settings.prefs(context).edit(commit = true) { putBoolean("langria-lock", locked) }
  }

  private fun generate(alias: String, locked: Boolean) = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore").apply {
    val spec = KeyGenParameterSpec.Builder(alias, KeyProperties.PURPOSE_DECRYPT)
      .setKeySize(2048)
      .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA1)
      .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_OAEP)
    if (locked) {
      spec.setUserAuthenticationRequired(true)
        .setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL)
        // Adding a fingerprint should not lose the keys; the screen lock is asked for either way.
        .setInvalidatedByBiometricEnrollment(false)
    }
    initialize(spec.build())
  }.generateKeyPair().public

  private suspend fun authenticate(context: Context, title: String, cipher: Cipher): Cipher = suspendCancellableCoroutine { continuation ->
    val cancel = CancellationSignal()
    continuation.invokeOnCancellation { cancel.cancel() }
    val prompt = BiometricPrompt.Builder(context)
      .setTitle(title)
      .setAllowedAuthenticators(Authenticators.BIOMETRIC_STRONG or Authenticators.DEVICE_CREDENTIAL)
      .build()
    prompt.authenticate(BiometricPrompt.CryptoObject(cipher), cancel, context.mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
      override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
        continuation.resume(result.cryptoObject?.cipher ?: cipher)
      }

      override fun onAuthenticationError(code: Int, message: CharSequence) {
        val cancelled = code in setOf(BiometricPrompt.BIOMETRIC_ERROR_CANCELED, BiometricPrompt.BIOMETRIC_ERROR_USER_CANCELED, BiometricPrompt.BIOMETRIC_ERROR_TIMEOUT, BiometricPrompt.BIOMETRIC_ERROR_LOCKOUT)
        continuation.resumeWithException(if (cancelled) Failure.Cancelled else if (code == BiometricPrompt.BIOMETRIC_ERROR_NO_DEVICE_CREDENTIAL) Failure.NoScreenLock else Failure.Keystore(message.toString()))
      }
    })
  }

  private fun keystore() = JavaKeyStore.getInstance("AndroidKeyStore").apply { load(null) }
  private fun encode(bytes: ByteArray) = Base64.encodeToString(bytes, Base64.NO_WRAP)
  private fun decode(text: String) = Base64.decode(text, Base64.NO_WRAP)
}
