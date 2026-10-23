package io.github.shigeya_t.langria

import android.graphics.Bitmap
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions
import com.google.mlkit.vision.text.japanese.JapaneseTextRecognizerOptions
import com.google.mlkit.vision.text.korean.KoreanTextRecognizerOptions
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.tasks.await
import kotlin.math.abs
import kotlin.math.max

/**
 * Reads the text in a photo on the device (ML Kit, whose models come with
 * Google Play services), so only the text, not the image, is sent to the AI
 * service. Like TextRecognizer.swift, but ML Kit has a model per script: each
 * reads the photo and the one that reads the most, most surely, wins. The
 * Japanese, Chinese and Korean models read Latin letters too.
 */
object TextRecognizer {
  private val recognizers by lazy {
    listOf(
      TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS),
      TextRecognition.getClient(JapaneseTextRecognizerOptions.Builder().build()),
      TextRecognition.getClient(ChineseTextRecognizerOptions.Builder().build()),
      TextRecognition.getClient(KoreanTextRecognizerOptions.Builder().build()),
    )
  }

  suspend fun recognize(bitmap: Bitmap): String = coroutineScope {
    val image = InputImage.fromBitmap(bitmap, 0)
    val results = recognizers.map { recognizer -> async { runCatching { recognizer.process(image).await() } } }.awaitAll()
    // Fails only when no model could run (a model still downloading, say).
    val texts = results.mapNotNull { it.getOrNull() }
    if (texts.isEmpty()) throw results.first().exceptionOrNull()!!
    val lines = texts.maxBy { text -> text.textBlocks.flatMap { it.lines }.sumOf { (it.confidence * it.text.length).toDouble() } }
      .textBlocks.flatMap { it.lines }
      .mapNotNull { line -> line.boundingBox?.let { Line(line.text.trim(), it.left, it.top, it.right, it.bottom) } }
    paragraphs(lines)
  }

  /** A line of text and its box, in pixels from the top left. */
  data class Line(val text: String, val left: Int, val top: Int, val right: Int, val bottom: Int) {
    val height get() = bottom - top
  }

  /**
   * Lines that sit right under each other with a similar height are joined
   * back into paragraphs, so the model translates sentences rather than line
   * fragments; a larger gap, a change of size or a jump sideways starts a new
   * paragraph. The same rules as TextRecognizer.swift, in pixels from the top.
   */
  fun paragraphs(lines: List<Line>): String {
    val result = StringBuilder()
    var previous: Line? = null
    for (line in lines.filter { it.text.isNotEmpty() }.sortedBy { it.top }) {
      previous?.let { previous ->
        val height = max(previous.height, line.height).toFloat()
        val gap = (line.top - previous.bottom).toFloat()
        val similarSize = abs(previous.height - line.height) < height * 0.35f
        val aligned = abs(previous.left - line.left) < height * 1.5f || line.left >= previous.left && line.right <= previous.right + height
        result.append(if (gap < height * 0.8f && gap > -height * 0.5f && similarSize && aligned) separator(previous.text, line.text) else "\n")
      }
      result.append(line.text)
      previous = line
    }
    return result.toString()
  }

  // Words in scripts written with spaces are joined with one; CJK and Thai
  // text runs on.
  private fun separator(first: String, second: String): String {
    if (first.isEmpty() || second.isEmpty()) return " "
    fun tight(code: Int) = code in 0x3000..0x9FFF || code in 0xF900..0xFAFF || code in 0xFF00..0xFFEF || code in 0x0E00..0x0E7F
    return if (tight(first.codePointBefore(first.length)) && tight(second.codePointAt(0))) "" else " "
  }
}
