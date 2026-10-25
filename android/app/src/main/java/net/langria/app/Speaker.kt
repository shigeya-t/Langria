package net.langria.app

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.view.textclassifier.TextClassificationManager
import android.view.textclassifier.TextLanguage
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Locale

/** Reads the translation aloud with the system's text to speech, as Speaker.swift does on iOS. */
class Speaker(private val context: Context) {
  private var engine: TextToSpeech? = null
  private var ready = CompletableDeferred<Boolean>()
  /** The utterance being read, so a stopped earlier one that reports late is ignored. */
  private var current: String? = null
  private var count = 0
  /** Called on the main thread when reading starts or ends. */
  var onChange: ((Boolean) -> Unit)? = null

  private fun engine(): TextToSpeech = engine ?: TextToSpeech(context) { status -> ready.complete(status == TextToSpeech.SUCCESS) }.also { tts ->
    engine = tts
    tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
      override fun onStart(utteranceId: String) {}
      override fun onDone(utteranceId: String) = ended(utteranceId)
      @Deprecated("Deprecated in Java")
      override fun onError(utteranceId: String) = ended(utteranceId)
      override fun onStop(utteranceId: String, interrupted: Boolean) = ended(utteranceId)
    })
  }

  /**
   * `language` is a BCP 47 tag, or null to guess it from the text (for a
   * target typed in under "Other"). Returns false, without reading, when the
   * device has no voice for the language.
   */
  suspend fun speak(text: String, language: String?): Boolean {
    stop()
    val tts = engine()
    if (!ready.await()) return false
    val tag = language ?: detect(text)
    if (tag != null && tts.setLanguage(Locale.forLanguageTag(tag)) < TextToSpeech.LANG_AVAILABLE) return false
    val id = "langria-${++count}"
    current = id
    onChange?.invoke(true)
    tts.speak(text, TextToSpeech.QUEUE_FLUSH, null, id)
    return true
  }

  fun stop() {
    val id = current ?: return
    engine?.stop()
    ended(id)
  }

  fun shutdown() {
    stop()
    engine?.shutdown()
    engine = null
    ready = CompletableDeferred()
  }

  private fun ended(id: String) {
    context.mainExecutor.execute {
      if (current != id) return@execute
      current = null
      onChange?.invoke(false)
    }
  }

  // The system's language detection, run on the device; it may block, so not on the main thread.
  private suspend fun detect(text: String): String? = withContext(Dispatchers.Default) {
    runCatching {
      val classifier = context.getSystemService(TextClassificationManager::class.java).textClassifier
      val result = classifier.detectLanguage(TextLanguage.Request.Builder(text).build())
      result.takeIf { it.localeHypothesisCount > 0 }?.getLocale(0)?.toLanguageTag()
    }.getOrNull()
  }
}
