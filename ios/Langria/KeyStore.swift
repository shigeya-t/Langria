import Foundation
import LocalAuthentication
import Security

/// Stores the API keys in the keychain as one JSON item, this device only.
/// With the lock on, the item is protected by user presence (Face ID, Touch ID
/// or the passcode), so reading it asks for that, much like the web app's
/// passkey encryption (vault.js). The keys stay in memory until the app goes
/// to the background.
enum KeyStore {
  private static let service = "net.langria.app.api-keys"
  private static let account = "keys"

  enum Failure: Error {
    case noPasscode
    case cancelled
    case keychain(OSStatus)
  }

  /// Whether the stored item needs authentication to read. Kept in
  /// UserDefaults only to draw the UI before reading the keychain.
  static var isLocked: Bool {
    get { UserDefaults.standard.bool(forKey: "langria-lock") }
    set { UserDefaults.standard.set(newValue, forKey: "langria-lock") }
  }

  /// The name shown for the lock: "Face ID", "Touch ID", "Optic ID", or nil for the passcode.
  static var biometryName: String? {
    let context = LAContext()
    _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    switch context.biometryType {
    case .faceID: return "Face ID"
    case .touchID: return "Touch ID"
    case .opticID: return "Optic ID"
    default: return nil
    }
  }

  static var canLock: Bool { LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) }

  /// Reads the keys; with the lock on this shows the Face ID (or passcode) prompt.
  static func load(reason: String) async throws -> [String: String] {
    try await Task.detached {
      var query = baseQuery
      query[kSecReturnData] = true
      query[kSecMatchLimit] = kSecMatchLimitOne
      if isLocked {
        let context = LAContext()
        context.localizedReason = reason
        query[kSecUseAuthenticationContext] = context
      }
      var result: CFTypeRef?
      let status = SecItemCopyMatching(query as CFDictionary, &result)
      switch status {
      case errSecSuccess:
        guard let data = result as? Data else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
      case errSecItemNotFound: return [:]
      case errSecUserCanceled, errSecAuthFailed: throw Failure.cancelled
      default: throw Failure.keychain(status)
      }
    }.value
  }

  /// Replaces the stored keys, protected or not according to `locked`.
  static func save(_ keys: [String: String], locked: Bool) throws {
    SecItemDelete(baseQuery as CFDictionary)
    var item = baseQuery
    item[kSecValueData] = try JSONEncoder().encode(keys.filter { !$0.value.isEmpty })
    if locked {
      guard canLock else { throw Failure.noPasscode }
      var error: Unmanaged<CFError>?
      guard let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, &error) else { throw Failure.noPasscode }
      item[kSecAttrAccessControl] = access
    } else {
      item[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    }
    let status = SecItemAdd(item as CFDictionary, nil)
    if status == errSecParam || status == errSecDecode { throw Failure.noPasscode }
    guard status == errSecSuccess else { throw Failure.keychain(status) }
    isLocked = locked
  }

  private static var baseQuery: [CFString: Any] {
    [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
  }
}
