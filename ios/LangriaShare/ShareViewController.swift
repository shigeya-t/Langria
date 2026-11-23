import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// "Langria" in the share sheet: translates the shared text in the sheet
/// itself, with the app's API keys and settings (KeyStore, ShareSettings).
/// It does not open the app, which an extension may not do.
final class ShareViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    let model = ShareModel { [weak self] in self?.extensionContext?.completeRequest(returningItems: nil) }
    // The sheet is the extension's own view controller, so preferredColorScheme would not reach it.
    overrideUserInterfaceStyle = model.theme == "dark" ? .dark : model.theme == "light" ? .light : .unspecified
    let host = UIHostingController(rootView: ShareView(model: model))
    addChild(host)
    host.view.frame = view.bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(host.view)
    host.didMove(toParent: self)
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    Task {
      switch await Self.input(in: items) {
      case .text(let text, let clipped):
        await model.start(with: text, clipped: clipped)
      case .page(let url):
        guard let text = await PageReader(in: view).text(at: url) else { model.pageUnreadable(); return }
        let (clipped, cut) = Self.clip(text)
        await model.start(with: clipped, clipped: cut)
      }
    }
  }

  /// The most of a page that is translated when nothing on it is selected.
  static let pageLimit = 5000

  enum Input {
    /// The text, and whether it was cut to `pageLimit`.
    case text(String, Bool)
    /// A page shared only as its address, read by PageReader.
    case page(URL)
  }

  /// What was shared. Text comes first, so text that came with a link is what is translated.
  private static func input(in items: [NSExtensionItem]) async -> Input {
    let providers = items.flatMap { $0.attachments ?? [] }
    // A page from Safari's share button: what Preprocess.js read from it.
    let list = UTType.propertyList.identifier
    for provider in providers where provider.hasItemConformingToTypeIdentifier(list) {
      guard let item = try? await provider.loadItem(forTypeIdentifier: list) as? [String: Any],
            let page = item[NSExtensionJavaScriptPreprocessingResultsKey] as? [String: Any] else { continue }
      let selection = (page["selection"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      if !selection.isEmpty { return .text(selection, false) }
      let (text, clipped) = clip(page["text"] as? String ?? "")
      return .text(text, clipped)
    }
    var text = ""
    let type = UTType.plainText.identifier
    for provider in providers where provider.hasItemConformingToTypeIdentifier(type) {
      if let item = try? await provider.loadItem(forTypeIdentifier: type) as? String, !item.isEmpty { text = item; break }
    }
    // Some apps put the text in the item itself rather than in an attachment.
    if text.isEmpty { text = items.lazy.compactMap { $0.attributedContentText?.string }.first { !$0.isEmpty } ?? "" }
    // Some apps share a link as text; its page is what is wanted.
    if let url = webURL(text.trimmingCharacters(in: .whitespacesAndNewlines)) { return .page(url) }
    if !text.isEmpty { return .text(text, false) }
    let urlType = UTType.url.identifier
    for provider in providers where provider.hasItemConformingToTypeIdentifier(urlType) {
      let item = try? await provider.loadItem(forTypeIdentifier: urlType)
      let url = (item as? URL) ?? (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) } ?? (item as? String).flatMap(webURL)
      if let url = url.flatMap({ webURL($0.absoluteString) }) { return .page(url) }
    }
    return .text("", false)
  }

  /// The string as an http(s) address, when it is one and nothing else.
  static func webURL(_ string: String) -> URL? {
    guard !string.contains(where: \.isWhitespace), let url = URL(string: string),
          ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host?.isEmpty == false else { return nil }
    return url
  }

  /// Cuts a page's text to `pageLimit`, at the end of a paragraph when one is near.
  static func clip(_ text: String) -> (String, Bool) {
    let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard text.count > pageLimit else { return (text, false) }
    let head = String(text.prefix(pageLimit))
    if let end = head.range(of: "\n", options: .backwards), head.distance(from: head.startIndex, to: end.lowerBound) > pageLimit * 4 / 5 {
      return (String(head[..<end.lowerBound]), true)
    }
    return (head, true)
  }
}

@MainActor
final class ShareModel: ObservableObject {
  enum State {
    case loading, noText, unreadable, noKey, locked, translating
    case result(String)
    case failure(TranslationError)
  }

  let shared: Shared
  let provider: Provider
  let modelName: String
  let mode: TranslationMode
  let customTarget: String
  let theme: String
  let close: () -> Void
  @Published private(set) var source = ""
  /// The source is the start of a longer page.
  @Published private(set) var clipped = false
  @Published private(set) var state: State = .loading
  /// Changed only for this sheet; the app's target stays as it is.
  @Published var target: String { didSet { if target != oldValue { translate() } } }
  @Published private(set) var copied = false
  @Published private(set) var speaking = false
  @Published private(set) var unlocking = false
  @Published private(set) var unlockError = ""
  private var keys: [String: String]?
  private var pending: Task<Void, Never>?
  private let speaker = Speaker()

  init(close: @escaping () -> Void) {
    let settings = ShareSettings.load()
    shared = Shared(stored: settings["langria-ui-language"])
    provider = Provider(rawValue: settings["langria-provider"] ?? "") ?? .openai
    modelName = settings[provider.modelKey].flatMap { $0.isEmpty ? nil : $0 } ?? provider.defaultModel
    mode = TranslationMode(rawValue: settings["langria-mode"] ?? "") ?? .faithful
    customTarget = (settings["langria-target-custom"] ?? "").trimmingCharacters(in: .whitespaces)
    theme = settings["langria-theme"] ?? ""
    self.close = close
    let stored = settings["langria-target"] ?? ""
    target = shared.targets.contains(stored) || (stored == Shared.customTarget && !customTarget.isEmpty) ? stored : shared.defaultTarget
    speaker.onChange = { [weak self] in self?.speaking = $0 }
  }

  /// The targets offered: the language list, plus the one typed under "Other" in the app.
  var targets: [String] { shared.targets + (customTarget.isEmpty ? [] : [Shared.customTarget]) }

  func label(_ target: String) -> String { target == Shared.customTarget ? customTarget : shared.languageLabel(target) }

  var lockMethod: String { KeyStore.biometryName ?? shared.t("ios.passcode") }

  var result: String? { if case .result(let text) = state { text } else { nil } }

  func start(with text: String, clipped: Bool) async {
    source = text.trimmingCharacters(in: .whitespacesAndNewlines)
    self.clipped = clipped
    guard !source.isEmpty else { state = .noText; return }
    await unlock()
  }

  func pageUnreadable() { state = .unreadable }

  /// Reads the keys; with the lock on this shows the Face ID (or passcode) prompt.
  func unlock() async {
    guard !unlocking else { return }
    unlocking = true
    unlockError = ""
    defer { unlocking = false }
    do {
      keys = try await KeyStore.load(reason: shared.t("ios.unlockReason"))
      translate()
    } catch {
      state = .locked
      if case KeyStore.Failure.keychain(let status) = error {
        unlockError = shared.t("ios.keychainError", ["detail": (SecCopyErrorMessageString(status, nil) as String?) ?? String(status)])
      } else if case KeyStore.Failure.cancelled = error {
        unlockError = shared.t("vault.cancelled")
      } else {
        unlockError = error.localizedDescription
      }
    }
  }

  func translate() {
    guard !source.isEmpty else { return }
    guard let keys else { state = .locked; return }
    guard let key = keys[provider.rawValue], !key.isEmpty else { state = .noKey; return }
    speaker.stop()
    pending?.cancel()
    state = .translating
    let typed = Translator(provider: provider, model: modelName, key: key, language: target == Shared.customTarget ? customTarget : target, mode: mode)
    let text = source, custom = target == Shared.customTarget
    pending = Task { [weak self] in
      do {
        // A language typed in under "Other" is settled into one name first (see Translator).
        let translator = custom ? Translator(provider: typed.provider, model: typed.model, key: typed.key, language: await typed.resolvedLanguage(), mode: typed.mode) : typed
        try Task.checkCancellation()
        let result = try await translator.translate(text).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !Task.isCancelled else { return }
        if result.isEmpty { throw TranslationError.empty }
        self?.state = .result(result)
      } catch is CancellationError {
      } catch {
        guard !Task.isCancelled else { return }
        self?.state = .failure(error as? TranslationError ?? .unexpected(error.localizedDescription))
      }
    }
  }

  func message(for error: TranslationError) -> String { error.message(provider: provider, model: modelName, t: shared.t) }

  func copy() {
    guard let result else { return }
    UIPasteboard.general.string = result
    copied = true
    Task { [weak self] in
      try? await Task.sleep(for: .milliseconds(1500))
      self?.copied = false
    }
  }

  func toggleSpeaking() {
    if speaking { speaker.stop(); return }
    guard let result else { return }
    speaker.speak(result, language: target == Shared.customTarget ? nil : shared.locales[target])
  }

  func dismiss() {
    speaker.stop()
    pending?.cancel()
    close()
  }
}
