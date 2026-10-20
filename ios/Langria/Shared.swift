import Foundation
import JavaScriptCore

/// The UI text (`i18n.js`), the target languages (`languages.js`) and the
/// commit hash (`version.js`) shared with the web app and the extension. They
/// are classic scripts that set globals, so they run as is in JavaScriptCore,
/// and the app keeps a single copy of the messages and language list.
@MainActor
final class Shared: ObservableObject {
  static let customTarget = "other"

  /// The language picked in Settings ("en" / "ja"), or nil to follow the device.
  @Published private(set) var choice: String?
  /// The UI language in use, "en" or "ja".
  @Published private(set) var language = "en"
  let targets: [String]
  let commit: String

  private let context = JSContext()!
  private let i18n: JSValue

  init() {
    // i18n.js falls back to `navigator.language` when no language is picked.
    context.evaluateScript("globalThis.navigator = { language: \(Self.jsString(Locale.preferredLanguages.first ?? "en")) };")
    for name in ["version", "i18n", "languages"] {
      guard let url = Bundle.main.url(forResource: name, withExtension: "js"), let script = try? String(contentsOf: url, encoding: .utf8) else { continue }
      context.evaluateScript(script, withSourceURL: url)
    }
    i18n = context.objectForKeyedSubscript("LangriaI18n")
    targets = context.evaluateScript("Object.keys(LangriaLanguages.targets)").toArray() as? [String] ?? ["English", "Japanese"]
    let hash = context.evaluateScript("globalThis.LANGRIA_COMMIT || ''").toString() ?? ""
    commit = hash == "undefined" ? "" : hash
    setChoice(UserDefaults.standard.string(forKey: "langria-ui-language"))
  }

  func setChoice(_ next: String?) {
    choice = next
    UserDefaults.standard.set(next, forKey: "langria-ui-language")
    language = i18n.invokeMethod("setLanguage", withArguments: [next ?? ""]).toString() ?? "en"
  }

  func t(_ key: String, _ params: [String: String] = [:]) -> String {
    i18n.invokeMethod("t", withArguments: [key, params]).toString() ?? key
  }

  func languageLabel(_ target: String) -> String {
    i18n.invokeMethod("languageLabel", withArguments: [target]).toString() ?? target
  }

  /// The target used until one is picked: Japanese for a Japanese UI, English otherwise.
  var defaultTarget: String { i18n.invokeMethod("defaultTarget", withArguments: []).toString() ?? "English" }

  private static func jsString(_ text: String) -> String {
    let data = try? JSONSerialization.data(withJSONObject: [text])
    return String(data: data ?? Data("[\"en\"]".utf8), encoding: .utf8).map { String($0.dropFirst().dropLast()) } ?? "\"en\""
  }
}
