import Foundation

/// A rough guess by script, used only by the swap button; the model itself
/// works out the source language. A port of `detectLanguage` in app.js: keep
/// the two in step. Returns a target language name, or nil when the script
/// does not point to one language.
enum LanguageDetector {
  static func detect(_ text: String) -> String? {
    func count(_ pattern: String) -> Int {
      (try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]))?.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text)) ?? 0
    }
    let han = count("[\\u3400-\\u9fff\\uf900-\\ufaff]"), kana = count("[\\u3040-\\u30ff]")
    // Latin and Cyrillic are counted by words, the others by characters.
    let scores: [(String, Int)] = [
      ("cjk", han + kana),
      ("Korean", count("[\\uac00-\\ud7af\\u1100-\\u11ff\\u3130-\\u318f]")),
      ("Thai", count("[\\u0e00-\\u0e7f]")),
      ("Russian", count("[\\u0400-\\u04ff]+")),
      ("latin", count("[a-z\\u00c0-\\u00d6\\u00d8-\\u00f6\\u00f8-\\u024f\\u1e00-\\u1eff]+"))
    ]
    let best = scores.reduce(scores[0]) { $1.1 > $0.1 ? $1 : $0 }
    guard best.1 > 0 else { return nil }
    switch best.0 {
    case "cjk": return kana > 0 ? "Japanese" : chineseScript(text)
    case "latin":
      if count("[\\u0111\\u01a1\\u01b0\\u1ea0-\\u1ef9]") > 0 { return "Vietnamese" }
      // Accented letters point to another European language, which the script alone cannot tell.
      return text.range(of: "[\\u00c0-\\u00d6\\u00d8-\\u00f6\\u00f8-\\u024f]", options: .regularExpression) != nil ? nil : "English"
    default: return best.0
    }
  }

  private static let simplified = "这们个来说时会对过还没发经现开关问题国学长门东车马书见实间话认让处义从众动头气样后边钱师"
  private static let traditional = "這們個來說時會對過還沒發經現開關問題國學長門東車馬書見實間話認讓處義從眾動頭氣樣後邊錢師"

  private static func chineseScript(_ text: String) -> String? {
    var simple = 0, traditionalCount = 0
    for char in text {
      if simplified.contains(char) { simple += 1 } else if traditional.contains(char) { traditionalCount += 1 }
    }
    if simple == traditionalCount { return nil }
    return simple > traditionalCount ? "Simplified Chinese" : "Traditional Chinese"
  }
}
