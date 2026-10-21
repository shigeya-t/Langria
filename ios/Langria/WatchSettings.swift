import Foundation

/// What the iPhone app sends to the watch app (WatchSync.swift), as JSON in
/// the WatchConnectivity application context. The watch has no
/// JavaScriptCore to run i18n.js and languages.js, so the UI text and the
/// language labels it needs come along in the UI language picked on the iPhone.
struct WatchSettings: Codable, Hashable {
  /// "Use on Apple Watch"; when off, the watch deletes its copy of the keys.
  var enabled: Bool
  /// The API keys, or nil to keep the ones the watch has (while the iPhone is locked).
  var keys: [String: String]?
  var provider: String
  /// Model per provider, by `Provider.rawValue`.
  var models: [String: String]
  var mode: String
  /// The language name given to the model, with "Other" already resolved.
  var target: String
  var targets: [String]
  var labels: [String: String]
  var locales: [String: String]
  var messages: [String: String]
  var language: String

  /// The message keys the watch uses.
  static let messageKeys = [
    "watch.input", "watch.translateTo", "watch.noKey", "watch.noTarget", "status.translating", "ios.speak", "ios.stopSpeaking", "ios.speakUnavailable",
    "error.detail", "error.noDetail", "error.auth", "error.rateLimit", "error.model", "error.http",
    "error.truncated", "error.empty", "error.network", "error.timeout", "error.blocked", "error.unexpected"
  ]
}
