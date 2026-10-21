import UIKit
import XCTest
@testable import Langria

final class LanguageDetectorTests: XCTestCase {
  func testScripts() {
    XCTAssertEqual(LanguageDetector.detect("今日はいい天気ですね"), "Japanese")
    XCTAssertEqual(LanguageDetector.detect("这个问题我们还没说"), "Simplified Chinese")
    XCTAssertEqual(LanguageDetector.detect("這個問題我們還沒說"), "Traditional Chinese")
    XCTAssertEqual(LanguageDetector.detect("안녕하세요"), "Korean")
    XCTAssertEqual(LanguageDetector.detect("Привет, как дела?"), "Russian")
    XCTAssertEqual(LanguageDetector.detect("Hello there"), "English")
    XCTAssertEqual(LanguageDetector.detect("Xin chào các bạn, tôi là người Việt"), "Vietnamese")
    XCTAssertNil(LanguageDetector.detect("Ça va très bien"))
    XCTAssertNil(LanguageDetector.detect("12345"))
    // A Latin brand name in Chinese text does not make it English.
    XCTAssertEqual(LanguageDetector.detect("我们用 iPhone 来说话"), "Simplified Chinese")
  }
}

@MainActor
final class SharedTests: XCTestCase {
  func testRunsSharedScripts() {
    let saved = UserDefaults.standard.string(forKey: "langria-ui-language")
    defer { UserDefaults.standard.set(saved, forKey: "langria-ui-language") }
    let shared = Shared()
    shared.setChoice("ja")
    XCTAssertEqual(shared.t("web.original"), "原文")
    XCTAssertEqual(shared.languageLabel("Korean"), "韓国語")
    XCTAssertEqual(shared.defaultTarget, "Japanese")
    shared.setChoice("en")
    XCTAssertEqual(shared.t("error.auth", ["name": "Claude"]), "Check your API key. The Claude API key is invalid or lacks permission.")
    XCTAssertEqual(shared.targets.first, "English")
    XCTAssertTrue(shared.targets.contains("Indonesian"))
  }

  /// The watch shows the key itself for a message missing from i18n.js.
  func testWatchMessagesExist() {
    let saved = UserDefaults.standard.string(forKey: "langria-ui-language")
    defer { UserDefaults.standard.set(saved, forKey: "langria-ui-language") }
    let shared = Shared()
    for language in ["en", "ja"] {
      shared.setChoice(language)
      for key in WatchSettings.messageKeys { XCTAssertNotEqual(shared.t(key), key, "\(language): \(key)") }
    }
    shared.setChoice("ja")
    XCTAssertNotEqual(shared.t("watch.input"), "Speak or type")
  }
}

final class TranscriptTests: XCTestCase {
  func testKeepsEarlierUtterances() {
    var transcript = Dictation.Transcript(separator: " ")
    XCTAssertEqual(transcript.add("Hello", ended: false), "Hello")
    XCTAssertEqual(transcript.add("Hello there", ended: true), "Hello there")
    // After a pause the results start over with the new utterance.
    XCTAssertEqual(transcript.add("How", ended: false), "Hello there How")
    XCTAssertEqual(transcript.add("How are you", ended: false), "Hello there How are you")
    // A revision of the same utterance replaces it.
    XCTAssertEqual(transcript.add("How are", ended: false), "Hello there How are")
    // A restart that is not marked as one is still kept.
    XCTAssertEqual(transcript.add("Fine", ended: false), "Hello there How are Fine")
  }

  func testJoinsJapaneseWithoutSpaces() {
    var transcript = Dictation.Transcript(separator: "")
    _ = transcript.add("おはようございます。", ended: true)
    XCTAssertEqual(transcript.add("今日は", ended: false), "おはようございます。今日は")
  }
}

final class TextRecognizerTests: XCTestCase {
  private func render(_ lines: [String], size: CGFloat = 44) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 900), format: format).image { context in
      UIColor.white.setFill()
      context.fill(CGRect(x: 0, y: 0, width: 1200, height: 900))
      var y: CGFloat = 60
      for line in lines {
        if line.isEmpty { y += size * 1.6; continue }
        (line as NSString).draw(at: CGPoint(x: 60, y: y), withAttributes: [.font: UIFont.systemFont(ofSize: size), .foregroundColor: UIColor.black])
        y += size * 1.3
      }
    }
  }

  func testJoinsLinesIntoParagraphs() async throws {
    let text = try await TextRecognizer.recognize(render([
      "Welcome to the city museum. The galleries",
      "are open from 9 a.m. to 5 p.m. every day",
      "except Monday.",
      "",
      "Tickets are sold at the front desk."
    ]))
    let paragraphs = text.components(separatedBy: "\n")
    XCTAssertEqual(paragraphs.count, 2, text)
    XCTAssertTrue(paragraphs[0].hasPrefix("Welcome to the city museum. The galleries are open"), text)
    XCTAssertTrue(paragraphs[1].hasPrefix("Tickets"), text)
  }

  func testReadsJapanese() async throws {
    let text = try await TextRecognizer.recognize(render(["本日は休館日です。", "またのお越しをお待ちしております。"]))
    XCTAssertTrue(text.contains("休館日"), text)
    XCTAssertFalse(text.contains(" "), text)
  }

  func testBlankImage() async throws {
    let text = try await TextRecognizer.recognize(render([]))
    XCTAssertEqual(text, "")
  }
}

@MainActor
final class SpeechLanguageTests: XCTestCase {
  func testLocalesComeFromLanguagesJS() {
    let shared = Shared()
    XCTAssertEqual(shared.locales["Japanese"], "ja-JP")
    XCTAssertEqual(shared.locales["Traditional Chinese"], "zh-TW")
    XCTAssertEqual(Set(shared.locales.keys), Set(shared.targets))
  }
}
