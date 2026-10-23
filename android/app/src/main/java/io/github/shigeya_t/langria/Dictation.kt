package io.github.shigeya_t.langria

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer

/**
 * Voice input for the original pane, with the system's speech recognition.
 * It runs on the device when the language's model is installed (asked for
 * with EXTRA_PREFER_OFFLINE); otherwise the audio goes to the recognition
 * service, as with the keyboard's voice typing. Android ends recognition at
 * each pause, so it starts again and joins the utterances (Speech.swift does
 * the same for iOS).
 */
class Dictation(private val context: Context) {
  sealed class Failure : Exception() {
    data object Unavailable : Failure()
    data class Stopped(val code: Int) : Failure()
  }

  private var recognizer: SpeechRecognizer? = null
  var isRecording = false
    private set

  /**
   * Starts listening (with the microphone already allowed); `onText` gets
   * the transcript so far, `onEnd` is called once when listening stops (with
   * the failure, if any). Must be called on the main thread.
   */
  fun start(locale: String, onText: (String) -> Unit, onEnd: (Failure?) -> Unit) {
    if (!SpeechRecognizer.isRecognitionAvailable(context)) throw Failure.Unavailable
    val recognizer = SpeechRecognizer.createSpeechRecognizer(context)
    this.recognizer = recognizer
    isRecording = true
    val transcript = Transcript(if (locale.startsWith("ja") || locale.startsWith("zh")) "" else " ")
    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
      .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
      .putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
      .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
      .putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
      .putExtra(RecognizerIntent.EXTRA_ENABLE_FORMATTING, RecognizerIntent.FORMATTING_OPTIMIZE_QUALITY)
    var heard = false

    fun end(failure: Failure?) {
      if (!isRecording) return
      finish()
      onEnd(failure)
    }

    recognizer.setRecognitionListener(object : RecognitionListener {
      override fun onPartialResults(results: Bundle) {
        best(results)?.let { onText(transcript.add(it, ended = false)) }
      }

      override fun onResults(results: Bundle) {
        best(results)?.let { heard = true; onText(transcript.add(it, ended = true)) }
        // A pause ended the utterance: listen for the next one.
        if (isRecording) recognizer.startListening(intent)
      }

      override fun onError(error: Int) {
        when (error) {
          // A pause with nothing (more) heard ends voice input; not an error.
          SpeechRecognizer.ERROR_NO_MATCH, SpeechRecognizer.ERROR_SPEECH_TIMEOUT, SpeechRecognizer.ERROR_CLIENT -> end(null)
          SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED, SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> end(if (heard) null else Failure.Unavailable)
          else -> end(Failure.Stopped(error))
        }
      }

      override fun onReadyForSpeech(params: Bundle?) {}
      override fun onBeginningOfSpeech() {}
      override fun onRmsChanged(rmsdB: Float) {}
      override fun onBufferReceived(buffer: ByteArray?) {}
      override fun onEndOfSpeech() {}
      override fun onEvent(eventType: Int, params: Bundle?) {}
    })
    recognizer.startListening(intent)
  }

  /** Stops listening and keeps what was heard. */
  fun stop() {
    recognizer?.stopListening()
    finish()
  }

  private fun finish() {
    if (!isRecording) return
    isRecording = false
    recognizer?.destroy()
    recognizer = null
  }

  private fun best(results: Bundle) = results.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()?.takeIf { it.isNotBlank() }

  /**
   * Joins the utterances of one session. Each new utterance's results no
   * longer include the earlier ones, so those are kept here. The same as
   * `Dictation.Transcript` in Speech.swift.
   */
  class Transcript(private val separator: String) {
    private var kept = ""
    private var current = ""

    /** Takes the latest result and returns the whole text so far. `ended` marks the last result of an utterance. */
    fun add(text: String, ended: Boolean): String {
      // Not every pause is marked; a result that drops what was heard means a new utterance.
      if (current.isNotEmpty() && text.length < current.length && !current.startsWith(text) && !text.startsWith(current.take(1))) keep(current)
      current = text
      val whole = join(kept, current)
      if (ended) { keep(current); current = "" }
      return whole
    }

    private fun keep(text: String) { kept = join(kept, text) }

    private fun join(a: String, b: String): String {
      val first = a.trim(' ')
      val second = b.trim(' ')
      return if (first.isEmpty()) second else if (second.isEmpty()) first else first + separator + second
    }
  }
}
