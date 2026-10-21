import AVFAudio
import NaturalLanguage
import Security
import SwiftUI
import WatchConnectivity

/// The watch app's state. Settings, keys and UI text come from the iPhone
/// (`WatchSettings`); only the target picked on the watch is its own, until
/// the target is changed on the iPhone again.
@MainActor
final class WatchModel: NSObject, ObservableObject, WCSessionDelegate {
  enum Pane {
    case empty, translating
    case result(String)
    case failure(String)
  }

  private let defaults = UserDefaults.standard

  @Published private(set) var settings: WatchSettings?
  @Published private(set) var keys: [String: String] = [:]
  @Published var source = "" { didSet { if source != oldValue { translate() } } }
  @Published private(set) var pane: Pane = .empty
  @Published private(set) var speaking = false
  /// The target picked on the watch, or nil to use the iPhone's.
  @Published private(set) var picked: String?

  private var latestRequest = 0
  private let speaker = Speaker()

  override init() {
    super.init()
    settings = defaults.data(forKey: "langria-watch-settings").flatMap { try? JSONDecoder().decode(WatchSettings.self, from: $0) }
    picked = defaults.string(forKey: "langria-target")
    speaker.onChange = { [weak self] in self?.speaking = $0 }
    keys = WatchKeys.load()
    guard WCSession.isSupported() else { return }
    WCSession.default.delegate = self
    WCSession.default.activate()
  }

  var ready: Bool { settings?.enabled == true }
  var provider: Provider { Provider(rawValue: settings?.provider ?? "") ?? .openai }
  var model: String { settings?.models[provider.rawValue].flatMap { $0.isEmpty ? nil : $0 } ?? provider.defaultModel }
  var target: String { picked ?? settings?.target ?? "English" }

  /// The iPhone's targets, plus a language typed in under "Other" there.
  var targets: [String] {
    guard let settings else { return [] }
    return settings.targets.contains(settings.target) || settings.target.isEmpty ? settings.targets : settings.targets + [settings.target]
  }

  func label(_ target: String) -> String { settings?.labels[target] ?? target }

  func t(_ key: String, _ params: [String: String] = [:]) -> String {
    let text = settings?.messages[key] ?? key
    return params.reduce(text) { $0.replacingOccurrences(of: "{\($1.key)}", with: $1.value) }
  }

  func pick(_ next: String) {
    picked = next
    defaults.set(next, forKey: "langria-target")
    translate()
  }

  // MARK: Translating

  func translate() {
    latestRequest += 1
    let request = latestRequest
    speaker.stop()
    let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { pane = .empty; return }
    let provider = provider, model = model, language = target
    guard let key = keys[provider.rawValue], !key.isEmpty else { pane = .failure(t("watch.noKey", ["name": provider.name])); return }
    guard !language.isEmpty else { pane = .failure(t("watch.noTarget")); return }
    let mode = TranslationMode(rawValue: settings?.mode ?? "") ?? .faithful
    pane = .translating
    Task {
      do {
        let result = try await Translator(provider: provider, model: model, key: key, language: language, mode: mode).translate(text)
        guard request == latestRequest else { return }
        let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw TranslationError.empty }
        pane = .result(trimmed)
      } catch is CancellationError {
      } catch {
        guard request == latestRequest else { return }
        let failure = error as? TranslationError ?? .unexpected(error.localizedDescription)
        pane = .failure(failure.message(provider: provider, model: model, t: t))
      }
    }
  }

  func toggleSpeaking() {
    if speaking { speaker.stop(); return }
    guard case .result(let text) = pane else { return }
    speaker.speak(text, language: settings?.locales[target])
  }

  // MARK: Settings from the iPhone

  private func apply(_ context: [String: Any]) {
    guard let data = context["settings"] as? Data, var next = try? JSONDecoder().decode(WatchSettings.self, from: data) else { return }
    if !next.enabled {
      WatchKeys.save([:])
      keys = [:]
    } else if let sent = next.keys {
      WatchKeys.save(sent)
      keys = sent
    }
    // Picking a target on the iPhone again takes over from the watch's pick.
    if let settings, settings.target != next.target {
      picked = nil
      defaults.removeObject(forKey: "langria-target")
    }
    next.keys = nil
    settings = next
    defaults.set(try? JSONEncoder().encode(next), forKey: "langria-watch-settings")
    if case .failure = pane { translate() }
  }

  nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    let context = session.receivedApplicationContext
    Task { @MainActor in self.apply(context) }
  }

  nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
    Task { @MainActor in self.apply(applicationContext) }
  }
}

/// The watch's copy of the API keys, one JSON item in its keychain, this
/// device only. The watch's passcode protects it; there is no lock of its own.
private enum WatchKeys {
  private static let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: "io.github.shigeya-t.Langria.api-keys", kSecAttrAccount: "keys"]

  static func load() -> [String: String] {
    var request = query
    request[kSecReturnData] = true
    var result: CFTypeRef?
    guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return [:] }
    return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
  }

  static func save(_ keys: [String: String]) {
    SecItemDelete(query as CFDictionary)
    guard !keys.isEmpty, let data = try? JSONEncoder().encode(keys) else { return }
    var item = query
    item[kSecValueData] = data
    item[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
    SecItemAdd(item as CFDictionary, nil)
  }
}

/// Reads the translation aloud with the system voices, on the watch.
@MainActor
private final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  var onChange: ((Bool) -> Void)?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  /// `language` is a BCP 47 tag, or nil to guess it from the text.
  func speak(_ text: String, language: String?) {
    stop()
    let utterance = AVSpeechUtterance(string: text)
    if let tag = language ?? NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue { utterance.voice = AVSpeechSynthesisVoice(language: tag) }
    // The default ambient category is silent while the watch is in silent
    // mode; playback plays through the speaker, as the user asked for it.
    Task {
      await Task.detached {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, policy: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
      }.value
      synthesizer.speak(utterance)
    }
    onChange?(true)
  }

  func stop() {
    if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate) }
  }

  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { ended() }
  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { ended() }

  private nonisolated func ended() {
    Task { @MainActor in
      guard !self.synthesizer.isSpeaking else { return }
      Task.detached { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
      self.onChange?(false)
    }
  }
}
