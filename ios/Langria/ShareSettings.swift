import Foundation
import Security

/// The settings the share extension needs (service, model, mode, target, UI
/// language, appearance, lock). The app keeps them in UserDefaults and copies
/// them into a keychain item in the access group it shares with the extension
/// (the same group as the API keys), so no App Group is needed and the app's
/// own storage stays as it was. Nothing here is secret.
enum ShareSettings {
  static let names = ["langria-provider", "langria-mode", "langria-target", "langria-target-custom", "langria-ui-language", "langria-theme", "langria-lock"] + Provider.allCases.map(\.modelKey)
  private static let service = "net.langria.app.share-settings"

  /// "TEAMID.bundle-id": the app's own keychain group, which the extension
  /// lists too. Nil when the build is not signed with a team.
  static let accessGroup: String? = {
    let value = Bundle.main.object(forInfoDictionaryKey: "LangriaKeychainGroup") as? String ?? ""
    return value.isEmpty || value.hasPrefix(".") || value.contains("$(") ? nil : value
  }()

  static let isExtension = Bundle.main.bundleURL.pathExtension == "appex"

  private static var saved: [String: String]?
  private static var observer: NSObjectProtocol?

  /// Copies the settings now and whenever UserDefaults changes. Called once by the app.
  static func startCopying() {
    save()
    observer = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { _ in save() }
  }

  static func current(_ defaults: UserDefaults = .standard) -> [String: String] {
    names.reduce(into: [:]) { result, name in
      switch defaults.object(forKey: name) {
      case let text as String: result[name] = text
      case let flag as Bool: result[name] = flag ? "true" : "false"
      default: break
      }
    }
  }

  /// Writes the settings if they changed (the ads SDK writes UserDefaults often too).
  static func save() {
    let settings = current()
    guard settings != saved, let data = try? JSONEncoder().encode(settings) else { return }
    SecItemDelete(query as CFDictionary)
    var item = query
    item[kSecValueData] = data
    item[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    if SecItemAdd(item as CFDictionary, nil) == errSecSuccess { saved = settings }
  }

  static func load() -> [String: String] {
    var request = query
    request[kSecReturnData] = true
    request[kSecMatchLimit] = kSecMatchLimitOne
    var result: CFTypeRef?
    guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return [:] }
    return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
  }

  private static var query: [CFString: Any] {
    var query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: "settings"]
    if let accessGroup { query[kSecAttrAccessGroup] = accessGroup }
    return query
  }
}
