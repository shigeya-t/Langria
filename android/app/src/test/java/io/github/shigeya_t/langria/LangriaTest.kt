package io.github.shigeya_t.langria

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

class LanguageDetectorTest {
  @Test fun scripts() {
    assertEquals("Japanese", LanguageDetector.detect("こんにちは、世界"))
    assertEquals("Simplified Chinese", LanguageDetector.detect("这是一个问题"))
    assertEquals("Traditional Chinese", LanguageDetector.detect("這是一個問題"))
    assertEquals("Korean", LanguageDetector.detect("안녕하세요"))
    assertEquals("Russian", LanguageDetector.detect("Привет, мир"))
    assertEquals("Thai", LanguageDetector.detect("สวัสดี"))
    assertEquals("English", LanguageDetector.detect("Hello, world"))
    assertEquals("Vietnamese", LanguageDetector.detect("Xin chào thế giới"))
    assertNull(LanguageDetector.detect("Bonjour à tous"))
    assertNull(LanguageDetector.detect("1234"))
  }
}

class TranscriptTest {
  @Test fun keepsEarlierUtterances() {
    val transcript = Dictation.Transcript(" ")
    assertEquals("Hello", transcript.add("Hello", ended = false))
    assertEquals("Hello there", transcript.add("Hello there", ended = true))
    assertEquals("Hello there How", transcript.add("How", ended = false))
    assertEquals("Hello there How are you", transcript.add("How are you", ended = true))
  }

  @Test fun joinsJapaneseWithoutSpaces() {
    val transcript = Dictation.Transcript("")
    transcript.add("こんにちは", ended = true)
    assertEquals("こんにちは元気ですか", transcript.add("元気ですか", ended = true))
  }
}

class ParagraphsTest {
  private fun line(text: String, top: Int, left: Int = 10, height: Int = 20, width: Int = 300) = TextRecognizer.Line(text, left, top, left + width, top + height)

  @Test fun joinsLinesIntoParagraphs() {
    val text = TextRecognizer.paragraphs(listOf(
      line("The quick brown fox", 10),
      line("jumps over the dog.", 34),
      line("A new paragraph", 100),
      line("日本語の文章が", 200),
      line("続きます。", 224),
    ))
    assertEquals("The quick brown fox jumps over the dog.\nA new paragraph\n日本語の文章が続きます。", text)
  }

  @Test fun largerTextStartsAParagraph() {
    assertEquals("Title\nBody text", TextRecognizer.paragraphs(listOf(line("Title", 10, height = 40), line("Body text", 54))))
  }
}

/** The shared scripts that the build copies into the app. */
class SharedScriptsTest {
  private val i18n = File("../../extension/lib/i18n.js").readText()

  @Test fun androidMessagesExistInBothLanguages() {
    val keys = Regex("'(android\\.[\\w.]+)':").findAll(i18n).map { it.groupValues[1] }.toList()
    assertTrue(keys.isNotEmpty())
    keys.groupingBy { it }.eachCount().forEach { (key, count) -> assertEquals(key, 2, count) }
  }

  @Test fun exposesMessages() {
    assertTrue(i18n.contains("messages, get language()"))
  }
}
