package io.github.shigeya_t.langria

/**
 * A rough guess by script, used only by the swap button; the model itself
 * works out the source language. A port of `detectLanguage` in app.js (and
 * LanguageDetector.swift): keep them in step. Returns a target language name,
 * or null when the script does not point to one language.
 */
object LanguageDetector {
  fun detect(text: String): String? {
    fun count(pattern: String) = Regex(pattern, RegexOption.IGNORE_CASE).findAll(text).count()
    val han = count("[\\u3400-\\u9fff\\uf900-\\ufaff]")
    val kana = count("[\\u3040-\\u30ff]")
    // Latin and Cyrillic are counted by words, the others by characters.
    val scores = listOf(
      "cjk" to han + kana,
      "Korean" to count("[\\uac00-\\ud7af\\u1100-\\u11ff\\u3130-\\u318f]"),
      "Thai" to count("[\\u0e00-\\u0e7f]"),
      "Russian" to count("[\\u0400-\\u04ff]+"),
      "latin" to count("[a-z\\u00c0-\\u00d6\\u00d8-\\u00f6\\u00f8-\\u024f\\u1e00-\\u1eff]+"),
    )
    val best = scores.reduce { best, next -> if (next.second > best.second) next else best }
    if (best.second == 0) return null
    return when (best.first) {
      "cjk" -> if (kana > 0) "Japanese" else chineseScript(text)
      "latin" -> when {
        count("[\\u0111\\u01a1\\u01b0\\u1ea0-\\u1ef9]") > 0 -> "Vietnamese"
        // Accented letters point to another European language, which the script alone cannot tell.
        Regex("[\\u00c0-\\u00d6\\u00d8-\\u00f6\\u00f8-\\u024f]").containsMatchIn(text) -> null
        else -> "English"
      }
      else -> best.first
    }
  }

  private const val SIMPLIFIED = "这们个来说时会对过还没发经现开关问题国学长门东车马书见实间话认让处义从众动头气样后边钱师"
  private const val TRADITIONAL = "這們個來說時會對過還沒發經現開關問題國學長門東車馬書見實間話認讓處義從眾動頭氣樣後邊錢師"

  private fun chineseScript(text: String): String? {
    val simple = text.count { it in SIMPLIFIED }
    val traditional = text.count { it in TRADITIONAL }
    if (simple == traditional) return null
    return if (simple > traditional) "Simplified Chinese" else "Traditional Chinese"
  }
}
