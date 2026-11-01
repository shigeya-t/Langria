import Foundation

/// The App Store screenshot mode of debug builds, turned on by
/// store/ios/capture.sh with launch arguments (which UserDefaults reads): no
/// ads or consent prompts, a stand-in API key, and the text and its
/// translation given up front, so the shots need no API key and no typing.
/// Off in release builds, whatever the arguments.
enum Screenshots {
  #if DEBUG
  static let enabled = UserDefaults.standard.bool(forKey: "langria-screenshots")
  #else
  static let enabled = false
  #endif

  private static func value(_ name: String) -> String? { enabled ? UserDefaults.standard.string(forKey: "langria-screenshot-\(name)") : nil }

  /// The text put in the original pane.
  static var source: String? { value("source") }
  /// What every translation returns, instead of calling the API.
  static var translation: String? { value("translation") }
  /// A photo to read text from, as if picked in the photo picker.
  static var image: String? { value("image") }
  /// "settings" opens the settings sheet.
  static var screen: String? { value("screen") }
  /// The watch's settings as base64 JSON, as the iPhone would send them (WatchSettings).
  /// Base64, as a launch argument that looks like a dictionary is not read as a string.
  static var watchSettings: Data? { value("watch-settings").flatMap { Data(base64Encoded: $0) } }

  /// A key for every service, so nothing asks for one.
  static let keys = Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0.rawValue, "screenshot-key") })

  /// Tells the script the screen is ready to take (a translation or the settings): a file in the app's tmp folder.
  static func ready() {
    guard enabled else { return }
    FileManager.default.createFile(atPath: NSTemporaryDirectory() + "langria-ready", contents: nil)
  }
}
