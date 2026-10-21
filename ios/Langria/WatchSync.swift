import Combine
import WatchConnectivity

/// Sends the settings to the watch app and, while "Use on Apple Watch" is on,
/// the API keys, which the watch keeps in its own keychain. Only the latest
/// application context is delivered, so each update carries everything.
@MainActor
final class WatchSync: NSObject, ObservableObject, WCSessionDelegate {
  /// Whether an Apple Watch is paired, to show the setting only then.
  @Published private(set) var paired = false
  /// Whether the watch app is on the watch. An app cannot install it; the
  /// user does that in the Watch app unless automatic app install is on.
  @Published private(set) var installed = false
  @Published var enabled = UserDefaults.standard.bool(forKey: "langria-watch") {
    didSet { UserDefaults.standard.set(enabled, forKey: "langria-watch"); send() }
  }

  private let model: AppModel
  private let shared: Shared
  /// A hash of what was sent last, so the keys are not kept here after the
  /// app locks them again.
  private var last: Int?
  private var observers = Set<AnyCancellable>()

  init(model: AppModel, shared: Shared) {
    self.model = model
    self.shared = shared
    super.init()
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
    // The settings change in many places; send what is current once they settle.
    model.objectWillChange.merge(with: shared.objectWillChange)
      .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
      .sink { [weak self] in self?.send() }
      .store(in: &observers)
  }

  private var settings: WatchSettings {
    // While locked the keys are left out, and the watch keeps the ones it has.
    let keys = model.keys.map { $0.filter { !$0.value.isEmpty } }
    return WatchSettings(
      enabled: enabled,
      keys: enabled ? keys : nil,
      provider: model.provider.rawValue,
      models: Dictionary(uniqueKeysWithValues: Provider.allCases.map { ($0.rawValue, model.model(for: $0)) }),
      mode: model.mode.rawValue,
      target: model.targetLanguage,
      targets: shared.targets,
      labels: Dictionary(uniqueKeysWithValues: shared.targets.map { ($0, shared.languageLabel($0)) }),
      locales: shared.locales,
      messages: Dictionary(uniqueKeysWithValues: WatchSettings.messageKeys.map { ($0, shared.t($0)) }),
      language: shared.language
    )
  }

  func send() {
    guard WCSession.isSupported() else { return }
    let session = WCSession.default
    paired = session.activationState == .activated && session.isPaired
    installed = paired && session.isWatchAppInstalled
    guard installed else { return }
    let next = settings
    guard next.hashValue != last, let data = try? JSONEncoder().encode(next) else { return }
    do {
      try session.updateApplicationContext(["settings": data])
      last = next.hashValue
    } catch {
      // Sent again with the next change, or when the watch app is installed.
    }
  }

  nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    Task { @MainActor in self.send() }
  }

  nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
    Task { @MainActor in self.last = nil; self.send() }
  }

  nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

  // Switching to another watch deactivates the session; activate it for the new one.
  nonisolated func sessionDidDeactivate(_ session: WCSession) {
    session.activate()
  }
}
