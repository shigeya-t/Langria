import SwiftUI
import UIKit

/// What the translation pane shows. Messages are kept as cases rather than
/// text so that switching the UI language redraws them.
enum Pane {
  case empty, translating, noKey, noTarget, locked
  case result(String)
  case failure(TranslationError, Provider, String)
}

/// The translation screen's state, following app.js: settings in
/// UserDefaults under the web app's localStorage names, a 700 ms pause before
/// translating, and replies to older requests dropped.
@MainActor
final class AppModel: ObservableObject {
  private let defaults = UserDefaults.standard
  let shared: Shared

  @Published var provider: Provider { didSet { defaults.set(provider.rawValue, forKey: "langria-provider"); textChanged() } }
  @Published private(set) var target: String
  @Published var customTarget: String { didSet { defaults.set(customTarget.trimmingCharacters(in: .whitespaces), forKey: "langria-target-custom"); if target == Shared.customTarget { textChanged() } } }
  @Published var mode: TranslationMode { didSet { defaults.set(mode.rawValue, forKey: "langria-mode"); textChanged() } }
  @Published var source = "" { didSet { if source != oldValue { textChanged() } } }
  @Published private(set) var pane: Pane = .empty
  @Published private(set) var statusKey = "status.ready"
  @Published private(set) var image: UIImage?
  @Published private(set) var recognizing = false
  @Published private(set) var unlocking = false
  @Published var unlockError = ""
  @Published var toast: String?
  /// The decrypted keys, or nil while locked.
  @Published private(set) var keys: [String: String]?
  @Published private(set) var locked = KeyStore.isLocked
  /// The target language whose locale voice input listens in.
  @Published var dictationLanguage: String { didSet { defaults.set(dictationLanguage, forKey: "langria-dictation-language") } }
  @Published private(set) var listening = false
  @Published private(set) var speaking = false

  private let dictation = Dictation()
  private let speaker = Speaker()

  private var latestRequest = 0
  /// Set while the text has changed since the result on screen was made.
  private var stale = false
  private var pending: Task<Void, Never>?
  private var unlockPrompted = false
  private var toastTask: Task<Void, Never>?

  init(shared: Shared) {
    self.shared = shared
    provider = Provider(rawValue: defaults.string(forKey: "langria-provider") ?? "") ?? .openai
    mode = TranslationMode(rawValue: defaults.string(forKey: "langria-mode") ?? "") ?? .faithful
    customTarget = defaults.string(forKey: "langria-target-custom") ?? ""
    // Until a target is chosen it follows the UI language.
    let stored = defaults.string(forKey: "langria-target") ?? ""
    target = stored == Shared.customTarget || shared.targets.contains(stored) ? stored : shared.defaultTarget
    // Until one is picked, voice input listens in the device's language when it is in the list.
    let device = Locale.preferredLanguages.first ?? "en"
    let spoken = defaults.string(forKey: "langria-dictation-language") ?? ""
    dictationLanguage = shared.targets.contains(spoken) ? spoken
      : shared.targets.first { Self.matches(shared.locales[$0], device) } ?? shared.targets.first { Self.matches(shared.locales[$0], String(device.prefix(2))) } ?? "English"
    speaker.onChange = { [weak self] in self?.speaking = $0 }
    if !locked { Task { await loadKeys(quiet: true) } }
  }

  /// Stores the target, so it no longer follows the UI language.
  private func setTarget(_ next: String) {
    target = next
    defaults.set(next, forKey: "langria-target")
  }

  /// The target picked in the menu.
  func pickTarget(_ next: String) {
    setTarget(next)
    if next == Shared.customTarget && customTarget.trimmingCharacters(in: .whitespaces).isEmpty { return }
    textChanged()
  }

  /// Called when the UI language changes: a target never picked follows it.
  func uiLanguageChanged() {
    if defaults.string(forKey: "langria-target") == nil { target = shared.defaultTarget }
  }

  func model(for provider: Provider) -> String { defaults.string(forKey: provider.modelKey).flatMap { $0.isEmpty ? nil : $0 } ?? provider.defaultModel }
  var currentModel: String { model(for: provider) }

  /// The language name sent to the model, or "" when "Other" is chosen but left blank.
  var targetLanguage: String { target == Shared.customTarget ? customTarget.trimmingCharacters(in: .whitespaces) : target }

  var characterCount: String {
    shared.t("web.characters", ["count": source.count.formatted(.number.locale(Locale(identifier: shared.language)))])
  }

  // MARK: Translating

  func textChanged() {
    pending?.cancel()
    latestRequest += 1
    stale = true
    speaker.stop()
    let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
    if text.isEmpty { pane = .empty; statusKey = "status.ready"; return }
    pending = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(700))
      guard !Task.isCancelled else { return }
      await self?.translate(text)
    }
  }

  func translateNow() {
    pending?.cancel()
    let text = source.trimmingCharacters(in: .whitespacesAndNewlines)
    if !text.isEmpty { Task { await translate(text) } }
  }

  private func translate(_ text: String) async {
    latestRequest += 1
    let request = latestRequest
    guard let keys else {
      pane = .locked
      statusKey = "status.locked"
      // Ask once on the first locked translation; after that the pane's button does.
      if !unlockPrompted { unlockPrompted = true; await unlock(quiet: true) }
      return
    }
    let key = keys[provider.rawValue] ?? ""
    guard !key.isEmpty else { pane = .noKey; statusKey = "status.noKey"; return }
    let language = targetLanguage
    guard !language.isEmpty else { pane = .noTarget; statusKey = "status.noTarget"; return }
    let provider = provider, model = currentModel
    pane = .translating
    statusKey = "status.translating"
    do {
      let result = try await Translator(provider: provider, model: model, key: key, language: language, mode: mode).translate(text)
      guard request == latestRequest else { return }
      let trimmed = result.trimmingCharacters(in: .whitespacesAndNewlines)
      if trimmed.isEmpty { throw TranslationError.empty }
      pane = .result(trimmed)
      stale = false
      statusKey = "status.done"
    } catch is CancellationError {
    } catch {
      guard request == latestRequest else { return }
      pane = .failure(error as? TranslationError ?? .unexpected(error.localizedDescription), provider, model)
      statusKey = "status.error"
    }
  }

  var result: String? { if !stale, case .result(let text) = pane { text } else { nil } }

  func message(for error: TranslationError, provider: Provider, model: String) -> String {
    let t = shared.t
    switch error {
    case .api(let status, let detail):
      let summary = status == 401 || status == 403 ? t("error.auth", ["name": provider.name])
        : status == 429 ? t("error.rateLimit", [:])
        : status == 400 || status == 404 ? t("error.model", ["model": model])
        : t("error.http", ["name": provider.name, "status": String(status)])
      return "\(summary)\n\n\(t("error.detail", ["detail": detail.isEmpty ? t("error.noDetail", [:]) : detail]))"
    case .truncated: return t("error.truncated", [:])
    case .empty: return t("error.empty", [:])
    case .network: return t("error.network", ["name": provider.name])
    case .timeout: return t("error.timeout", ["name": provider.name])
    case .blocked(let reason): return t("error.blocked", ["name": provider.name, "reason": reason])
    case .unexpected(let detail): return detail.isEmpty ? t("error.unexpected", [:]) : detail
    }
  }

  func clear() {
    source = ""
    image = nil
  }

  /// Only a finished translation can be swapped; while one is pending the
  /// pane would still hold the previous result.
  func swap() {
    guard let text = result else { return }
    let originalText = source.trimmingCharacters(in: .whitespacesAndNewlines)
    image = nil
    if let original = LanguageDetector.detect(originalText), original != target {
      // The original is already the translation of the new input, so show it
      // as is and make its language the new target.
      setTarget(original)
      source = text
      pending?.cancel()
      latestRequest += 1
      pane = .result(originalText)
      stale = false
      statusKey = "status.done"
      show(shared.t("web.swapped", ["lang": shared.languageLabel(original)]))
    } else {
      source = text
      show(shared.t("web.copiedToSource"))
    }
  }

  func copy(_ text: String?) {
    guard let text, !text.isEmpty else { return }
    UIPasteboard.general.string = text
    show(shared.t("copied"))
  }

  func show(_ message: String) {
    toast = message
    toastTask?.cancel()
    toastTask = Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(1800))
      guard !Task.isCancelled else { return }
      self?.toast = nil
    }
  }

  // MARK: Voice input and reading aloud

  private static func matches(_ locale: String?, _ device: String) -> Bool {
    guard let locale else { return false }
    // "zh-Hant-TW" and "zh-TW" both point to Traditional Chinese.
    let simplify = { (tag: String) in tag.replacingOccurrences(of: "-Hans", with: "").replacingOccurrences(of: "-Hant", with: "") }
    let a = simplify(locale).lowercased(), b = simplify(device).lowercased()
    return a == b || (!b.contains("-") && a.hasPrefix(b + "-"))
  }

  func toggleDictation() async {
    if listening { dictation.stop(); listening = false; return }
    speaker.stop()
    let language = dictationLanguage
    // What is already in the pane stays; speech is added on a new line.
    let base = source.trimmingCharacters(in: .whitespacesAndNewlines)
    do {
      try await dictation.start(locale: Locale(identifier: shared.locales[language] ?? "en-US")) { [weak self] text in
        guard let self else { return }
        self.source = base.isEmpty ? text : "\(base)\n\(text)"
      } onEnd: { [weak self] error in
        guard let self else { return }
        self.listening = false
        if let error { self.show(self.shared.t("ios.speechFailed", ["detail": error.localizedDescription])) }
      }
      listening = true
    } catch Dictation.Failure.denied {
      show(shared.t("ios.speechDenied"))
    } catch Dictation.Failure.unavailable {
      show(shared.t("ios.speechUnavailable", ["lang": shared.languageLabel(language)]))
    } catch {
      dictation.stop()
      show(shared.t("ios.speechFailed", ["detail": error.localizedDescription]))
    }
  }

  /// The status to show once reading text from a photo ends.
  private var restingStatus: String {
    switch pane {
    case .translating: "status.translating"
    case .result: "status.done"
    case .failure: "status.error"
    case .locked: "status.locked"
    case .noKey: "status.noKey"
    case .noTarget: "status.noTarget"
    case .empty: "status.ready"
    }
  }

  func toggleSpeaking() {
    if speaking { speaker.stop(); return }
    guard let text = result else { return }
    speaker.speak(text, language: target == Shared.customTarget ? nil : shared.locales[target])
  }

  // MARK: Reading text from photos

  func read(_ picked: UIImage) async {
    image = picked
    recognizing = true
    statusKey = "ios.reading"
    defer { recognizing = false }
    do {
      let text = try await TextRecognizer.recognize(picked)
      guard image === picked else { return }
      if text.isEmpty {
        show(shared.t("ios.noText"))
        statusKey = restingStatus
        return
      }
      source = text
    } catch {
      show(shared.t("ios.ocrFailed"))
      statusKey = "status.error"
    }
  }

  func removeImage() { image = nil }

  // MARK: Keys

  var lockMethod: String { KeyStore.biometryName ?? shared.t("ios.passcode") }

  func unlock(quiet: Bool = false) async {
    guard !unlocking, keys == nil else { return }
    unlocking = true
    unlockError = ""
    defer { unlocking = false }
    await loadKeys(quiet: quiet)
    if keys != nil {
      if locked { show(shared.t("unlocked")) }
      textChanged()
    }
  }

  private func loadKeys(quiet: Bool) async {
    do {
      keys = try await KeyStore.load(reason: shared.t("ios.unlockReason"))
    } catch KeyStore.Failure.cancelled {
      // A prompt started without a tap may be dismissed; the button is right there.
      if !quiet { unlockError = shared.t("vault.cancelled") }
    } catch {
      unlockError = describe(error)
    }
  }

  /// Locks again when the app goes to the background, if the lock is on.
  func didEnterBackground() {
    if listening { dictation.stop(); listening = false }
    guard locked else { return }
    keys = nil
    unlockPrompted = false
    if case .result = pane {} else if source.isEmpty { pane = .empty } else { pane = .locked; statusKey = "status.locked" }
  }

  func save(key: String, model: String, for provider: Provider) throws {
    if var keys {
      keys[provider.rawValue] = key
      try KeyStore.save(keys, locked: locked)
      self.keys = keys
    }
    let trimmed = model.trimmingCharacters(in: .whitespaces)
    defaults.set(trimmed.isEmpty ? provider.defaultModel : trimmed, forKey: provider.modelKey)
    show(shared.t("web.savedProvider", ["name": provider.name]))
    textChanged()
  }

  func setLock(_ on: Bool) throws {
    guard let keys, on != locked else { return }
    do {
      try KeyStore.save(keys, locked: on)
    } catch {
      // Saving deletes the old item first; put the keys back as they were.
      try? KeyStore.save(keys, locked: locked)
      throw error
    }
    locked = on
  }

  func describe(_ error: Error) -> String {
    switch error {
    case KeyStore.Failure.noPasscode: shared.t("ios.noPasscode")
    case KeyStore.Failure.cancelled: shared.t("vault.cancelled")
    case KeyStore.Failure.keychain(let status): shared.t("ios.keychainError", ["detail": (SecCopyErrorMessageString(status, nil) as String?) ?? String(status)])
    default: error.localizedDescription
    }
  }
}
