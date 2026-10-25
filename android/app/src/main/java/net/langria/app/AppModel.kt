package net.langria.app

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageDecoder
import android.net.Uri
import android.os.Build
import android.os.LocaleList
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.content.edit
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.lang.ref.WeakReference
import java.text.NumberFormat
import java.util.Locale

/** What the translation pane shows. Messages are kept as cases rather than text so that switching the UI language redraws them. */
sealed interface Pane {
  data object Empty : Pane
  data object Translating : Pane
  data object NoKey : Pane
  data object NoTarget : Pane
  data object Locked : Pane
  data class Result(val text: String) : Pane
  data class Failure(val error: TranslationError, val provider: Provider, val model: String) : Pane
}

/**
 * The translation screen's state, following app.js and the iOS app's
 * AppModel.swift: settings under the web app's localStorage names, a 700 ms
 * pause before translating, and replies to older requests dropped.
 */
class AppModel(private val context: Context, val shared: Shared, private val scope: CoroutineScope) {
  companion object {
    const val AUTO_DICTATION = "auto"

    private fun matches(locale: String?, device: String): Boolean {
      if (locale == null) return false
      // "zh-Hant-TW" and "zh-TW" both point to Traditional Chinese.
      fun simplify(tag: String) = tag.replace("-Hans", "").replace("-Hant", "").lowercase()
      val a = simplify(locale)
      val b = simplify(device)
      return a == b || (!b.contains("-") && a.startsWith("$b-"))
    }
  }

  private val prefs = Settings.prefs(context)

  var provider by mutableStateOf(Provider.of(prefs.getString("langria-provider", null)) ?: Provider.OPENAI)
    private set
  var target by mutableStateOf("")
    private set
  var customTarget by mutableStateOf(prefs.getString("langria-target-custom", null).orEmpty())
    private set
  var mode by mutableStateOf(TranslationMode.of(prefs.getString("langria-mode", null)) ?: TranslationMode.FAITHFUL)
    private set
  private var sourceState by mutableStateOf("")
  var source: String
    get() = sourceState
    set(value) { if (value != sourceState) { sourceState = value; textChanged() } }
  var pane by mutableStateOf<Pane>(Pane.Empty)
    private set
  var statusKey by mutableStateOf("status.ready")
    private set
  var image by mutableStateOf<Bitmap?>(null)
    private set
  var recognizing by mutableStateOf(false)
    private set
  var unlocking by mutableStateOf(false)
    private set
  var unlockError by mutableStateOf("")
  var toast by mutableStateOf<String?>(null)
    private set
  /** The decrypted keys, or null while locked. */
  var keys by mutableStateOf<Map<String, String>?>(null)
    private set
  var locked by mutableStateOf(KeyStore.isLocked(context))
    private set
  /** The language picked for voice input, a target or AUTO_DICTATION. */
  var dictationChoice by mutableStateOf(AUTO_DICTATION)
    private set
  /** The target in the list that matches the device's language. */
  val deviceLanguage: String
  var listening by mutableStateOf(false)
    private set
  var speaking by mutableStateOf(false)
    private set

  /** The activity in front, for the unlock prompt shown without a tap. */
  var activity: WeakReference<Activity> = WeakReference(null)
  /** Set while another app's screen (the camera, the photo picker) is open for this one, so leaving for it does not lock the keys. */
  var openingOtherScreen = false

  private val dictation = Dictation(context)
  private val speaker = Speaker(context)

  private var latestRequest = 0
  /** Set while the text has changed since the result on screen was made. */
  private var stale = false
  private var pending: Job? = null
  private var unlockPrompted = false
  private var toastJob: Job? = null

  init {
    // Until a target is chosen it follows the UI language.
    val stored = prefs.getString("langria-target", null).orEmpty()
    target = if (stored == Shared.CUSTOM_TARGET || stored in shared.targets) stored else shared.defaultTarget
    val device = LocaleList.getDefault()[0]?.toLanguageTag() ?: "en"
    deviceLanguage = shared.targets.firstOrNull { matches(shared.locales[it], device) }
      ?: shared.targets.firstOrNull { matches(shared.locales[it], device.substringBefore('-')) }
      ?: "English"
    val spoken = prefs.getString("langria-dictation-language", null).orEmpty()
    dictationChoice = if (spoken in shared.targets) spoken else AUTO_DICTATION
    speaker.onChange = { speaking = it }
    if (!locked) scope.launch { loadKeys(quiet = true) }
  }

  fun pickProvider(next: Provider) {
    provider = next
    prefs.edit { putString("langria-provider", next.id) }
    textChanged()
  }

  fun pickMode(next: TranslationMode) {
    mode = next
    prefs.edit { putString("langria-mode", next.id) }
    textChanged()
  }

  fun updateCustomTarget(next: String) {
    customTarget = next
    prefs.edit { putString("langria-target-custom", next.trim()) }
    if (target == Shared.CUSTOM_TARGET) textChanged()
  }

  fun pickDictation(next: String) {
    dictationChoice = next
    prefs.edit { putString("langria-dictation-language", next) }
  }

  /** Stores the target, so it no longer follows the UI language. */
  private fun storeTarget(next: String) {
    target = next
    prefs.edit {
      putString("langria-target", next)
      if (next in shared.targets && next != deviceLanguage) putString("langria-dictation-other", next)
    }
  }

  /**
   * The language voice input listens in. Auto assumes you speak the device's
   * language, unless you are translating into it: then the other person's,
   * the last target that was not the device's language. So the swap button
   * switches it too.
   */
  val dictationLanguage: String get() = if (dictationChoice == AUTO_DICTATION) autoDictationLanguage else dictationChoice

  val autoDictationLanguage: String
    get() {
      if (target != deviceLanguage) return deviceLanguage
      val other = prefs.getString("langria-dictation-other", null).orEmpty()
      return if (other in shared.targets && other != deviceLanguage) other else shared.targets.firstOrNull { it != deviceLanguage } ?: "English"
    }

  /** The target picked in the menu. */
  fun pickTarget(next: String) {
    storeTarget(next)
    if (next == Shared.CUSTOM_TARGET && customTarget.isBlank()) return
    textChanged()
  }

  /** Called when the UI language changes: a target never picked follows it. */
  fun uiLanguageChanged() {
    if (!prefs.contains("langria-target")) target = shared.defaultTarget
  }

  fun model(provider: Provider): String = prefs.getString(provider.modelKey, null)?.takeIf { it.isNotEmpty() } ?: provider.defaultModel
  val currentModel: String get() = model(provider)

  /** The language name sent to the model, or "" when "Other" is chosen but left blank. */
  val targetLanguage: String get() = if (target == Shared.CUSTOM_TARGET) customTarget.trim() else target

  val characterCount: String
    get() = shared.t("web.characters", "count" to NumberFormat.getInstance(Locale.forLanguageTag(shared.language)).format(source.codePointCount(0, source.length)))

  // Translating

  fun textChanged() {
    pending?.cancel()
    latestRequest += 1
    stale = true
    speaker.stop()
    val text = source.trim()
    if (text.isEmpty()) { pane = Pane.Empty; statusKey = "status.ready"; return }
    pending = scope.launch {
      delay(700)
      translate(text)
    }
  }

  fun translateNow() {
    pending?.cancel()
    val text = source.trim()
    if (text.isNotEmpty()) scope.launch { translate(text) }
  }

  private suspend fun translate(text: String) {
    latestRequest += 1
    val request = latestRequest
    val keys = keys
    if (keys == null) {
      pane = Pane.Locked
      statusKey = "status.locked"
      // Ask once on the first locked translation; after that the pane's button does.
      if (!unlockPrompted) { unlockPrompted = true; activity.get()?.let { unlock(it, quiet = true) } }
      return
    }
    val key = keys[provider.id].orEmpty()
    if (key.isEmpty()) { pane = Pane.NoKey; statusKey = "status.noKey"; return }
    val language = targetLanguage
    if (language.isEmpty()) { pane = Pane.NoTarget; statusKey = "status.noTarget"; return }
    val provider = provider
    val model = currentModel
    pane = Pane.Translating
    statusKey = "status.translating"
    try {
      val result = Translator(provider, model, key, language, mode).translate(text).trim()
      if (request != latestRequest) return
      if (result.isEmpty()) throw TranslationError.Empty
      pane = Pane.Result(result)
      stale = false
      statusKey = "status.done"
    } catch (error: CancellationException) {
      throw error
    } catch (error: Exception) {
      if (request != latestRequest) return
      pane = Pane.Failure(error as? TranslationError ?: TranslationError.Unexpected(error.message.orEmpty()), provider, model)
      statusKey = "status.error"
    }
  }

  val result: String? get() = (pane as? Pane.Result)?.text?.takeIf { !stale }

  fun message(failure: Pane.Failure) = failure.error.message(failure.provider, failure.model, shared::t)

  fun clear() {
    source = ""
    image = null
  }

  /** Only a finished translation can be swapped; while one is pending the pane would still hold the previous result. */
  fun swap() {
    val text = result ?: return
    val originalText = source.trim()
    image = null
    val original = LanguageDetector.detect(originalText)
    if (original != null && original != target) {
      // The original is already the translation of the new input, so show it
      // as is and make its language the new target.
      storeTarget(original)
      sourceState = text
      pending?.cancel()
      latestRequest += 1
      speaker.stop()
      pane = Pane.Result(originalText)
      stale = false
      statusKey = "status.done"
      show(shared.t("web.swapped", "lang" to shared.languageLabel(original)))
    } else {
      source = text
      show(shared.t("web.copiedToSource"))
    }
  }

  fun copy(text: String?) {
    if (text.isNullOrEmpty()) return
    context.getSystemService(ClipboardManager::class.java).setPrimaryClip(ClipData.newPlainText("Langria", text))
    // Android 13 and later confirm a copy themselves.
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) show(shared.t("copied"))
  }

  fun show(message: String) {
    toast = message
    toastJob?.cancel()
    toastJob = scope.launch {
      delay(1800)
      toast = null
    }
  }

  // Voice input and reading aloud

  /** Starts or stops voice input; the microphone must already be allowed. */
  fun toggleDictation() {
    if (listening) { dictation.stop(); listening = false; return }
    speaker.stop()
    val language = dictationLanguage
    // What is already in the pane stays; speech is added on a new line.
    val base = source.trim()
    try {
      dictation.start(shared.locales[language] ?: "en-US", onText = { text ->
        source = if (base.isEmpty()) text else "$base\n$text"
      }, onEnd = { failure ->
        listening = false
        when (failure) {
          null -> {}
          Dictation.Failure.Unavailable -> show(shared.t("ios.speechUnavailable", "lang" to shared.languageLabel(language)))
          is Dictation.Failure.Stopped -> show(shared.t("ios.speechFailed", "detail" to failure.code.toString()))
        }
      })
      listening = true
    } catch (error: Dictation.Failure.Unavailable) {
      show(shared.t("ios.speechUnavailable", "lang" to shared.languageLabel(language)))
    }
  }

  fun dictationDenied() = show(shared.t("android.speechDenied"))

  /** The status to show once reading text from a photo ends. */
  private val restingStatus: String
    get() = when (pane) {
      Pane.Translating -> "status.translating"
      is Pane.Result -> "status.done"
      is Pane.Failure -> "status.error"
      Pane.Locked -> "status.locked"
      Pane.NoKey -> "status.noKey"
      Pane.NoTarget -> "status.noTarget"
      Pane.Empty -> "status.ready"
    }

  fun toggleSpeaking() {
    if (speaking) { speaker.stop(); speaking = false; return }
    val text = result ?: return
    scope.launch {
      if (!speaker.speak(text, if (target == Shared.CUSTOM_TARGET) null else shared.locales[target])) {
        show(shared.t("ios.speakUnavailable", "lang" to if (target == Shared.CUSTOM_TARGET) targetLanguage else shared.languageLabel(target)))
      }
    }
  }

  // Reading text from photos

  fun read(picked: Bitmap) {
    image = picked
    recognizing = true
    statusKey = "ios.reading"
    scope.launch {
      try {
        val text = TextRecognizer.recognize(picked)
        if (image !== picked) return@launch
        if (text.isEmpty()) {
          show(shared.t("ios.noText"))
          statusKey = restingStatus
          return@launch
        }
        source = text
      } catch (error: CancellationException) {
        throw error
      } catch (error: Exception) {
        show(shared.t("ios.ocrFailed"))
        statusKey = "status.error"
      } finally {
        recognizing = false
      }
    }
  }

  /** Reads a photo from the camera or the photo picker. */
  fun read(uri: Uri) {
    scope.launch {
      val bitmap = withContext(Dispatchers.IO) {
        runCatching {
          ImageDecoder.decodeBitmap(ImageDecoder.createSource(context.contentResolver, uri)) { decoder, info, _ ->
            // ML Kit reads the pixels, which a hardware bitmap does not allow.
            decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
            // A camera photo is far larger than text recognition needs.
            val longest = maxOf(info.size.width, info.size.height)
            if (longest > 2048) decoder.setTargetSampleSize(longest / 2048 + 1)
          }
        }.getOrNull()
      }
      if (bitmap == null) show(shared.t("ios.imageFailed")) else read(bitmap)
    }
  }

  fun removeImage() { image = null }

  // Keys

  val lockMethod: String get() = shared.t("android.lockMethod")

  fun unlock(activity: Activity, quiet: Boolean = false) {
    if (unlocking || keys != null) return
    unlocking = true
    unlockError = ""
    scope.launch {
      try {
        loadKeys(quiet, activity)
        if (keys != null) {
          if (locked) show(shared.t("unlocked"))
          textChanged()
        }
      } finally {
        unlocking = false
      }
    }
  }

  private suspend fun loadKeys(quiet: Boolean, activity: Activity? = null) {
    try {
      keys = KeyStore.load(activity ?: context, shared.t("ios.unlockReason"))
    } catch (error: KeyStore.Failure.Cancelled) {
      // A prompt started without a tap may be dismissed; the button is right there.
      if (!quiet) unlockError = shared.t("vault.cancelled")
    } catch (error: KeyStore.Failure.KeysLost) {
      // Start again with no keys, unlocked, rather than asking for ones that cannot be read.
      KeyStore.save(context, emptyMap(), locked = false)
      locked = false
      keys = emptyMap()
      unlockError = shared.t("android.keysLost")
      show(unlockError)
    } catch (error: Exception) {
      unlockError = describe(error)
    }
  }

  /** Locks again when the app goes to the background, if the lock is on. */
  fun didEnterBackground() {
    if (openingOtherScreen) return
    if (listening) { dictation.stop(); listening = false }
    speaker.stop()
    if (!locked) return
    keys = null
    unlockPrompted = false
    if (pane is Pane.Result) return
    if (source.isEmpty()) pane = Pane.Empty else { pane = Pane.Locked; statusKey = "status.locked" }
  }

  suspend fun save(key: String, model: String, provider: Provider) {
    keys?.let { current ->
      val next = current + (provider.id to key)
      KeyStore.save(context, next, locked)
      keys = next
    }
    val trimmed = model.trim()
    prefs.edit { putString(provider.modelKey, trimmed.ifEmpty { provider.defaultModel }) }
    // The settings, still open, say it was saved.
    textChanged()
  }

  suspend fun setLock(on: Boolean) {
    val keys = keys ?: return
    if (on == locked) return
    try {
      KeyStore.save(context, keys, on)
    } catch (error: Exception) {
      // Put the keys back as they were.
      runCatching { KeyStore.save(context, keys, locked) }
      throw error
    }
    locked = on
  }

  fun describe(error: Throwable): String = when (error) {
    KeyStore.Failure.NoScreenLock -> shared.t("android.noScreenLock")
    KeyStore.Failure.Cancelled -> shared.t("vault.cancelled")
    KeyStore.Failure.KeysLost -> shared.t("android.keysLost")
    is KeyStore.Failure.Keystore -> shared.t("android.keystoreError", "detail" to error.detail)
    else -> error.message ?: error.toString()
  }

  fun close() {
    dictation.stop()
    speaker.shutdown()
  }
}
