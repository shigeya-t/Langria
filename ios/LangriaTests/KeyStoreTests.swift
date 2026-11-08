import XCTest
@testable import Langria

final class KeyStoreTests: XCTestCase {
  func testSavesAndLoadsUnlockedKeys() async throws {
    let saved = KeyStore.isLocked
    defer { KeyStore.isLocked = saved }
    try KeyStore.save(["openai": "sk-test", "gemini": ""], locked: false)
    XCTAssertFalse(KeyStore.isLocked)
    let keys = try await KeyStore.load(reason: "test")
    XCTAssertEqual(keys, ["openai": "sk-test"])
    try KeyStore.save([:], locked: false)
    let empty = try await KeyStore.load(reason: "test")
    XCTAssertEqual(empty, [:])
  }
}

@MainActor
final class AppModelTests: XCTestCase {
  // The tests run inside the app, so leave its saved settings as they were.
  private let keys = ["langria-provider", "langria-target", "langria-ui-language", "langria-dictation-language"]
  private var saved: [String: Any] = [:]

  override func setUp() { saved = keys.reduce(into: [:]) { $0[$1] = UserDefaults.standard.object(forKey: $1) } }
  override func tearDown() { keys.forEach { UserDefaults.standard.set(saved[$0], forKey: $0) } }

  func testSwapUsesDetectedLanguage() async throws {
    URLProtocol.registerClass(StubProtocol.self)
    defer { URLProtocol.unregisterClass(StubProtocol.self); StubProtocol.handler = nil }
    StubProtocol.handler = { _, _ in (200, ["output_text": "おはようございます"]) }
    try KeyStore.save(["openai": "sk-test"], locked: false)
    defer { try? KeyStore.save([:], locked: false) }
    let shared = Shared()
    shared.setChoice("en")
    let model = AppModel(shared: shared)
    model.provider = .openai
    model.pickTarget("Japanese")
    await model.unlock(quiet: true)
    // Translated after the usual wait.
    model.source = "Good morning"
    for _ in 0..<50 where model.result == nil { try await Task.sleep(for: .milliseconds(100)) }
    XCTAssertEqual(model.result, "おはようございます")
    model.swap()
    XCTAssertEqual(model.source, "おはようございます")
    XCTAssertEqual(model.target, "English")
    XCTAssertEqual(model.result, "Good morning")
    XCTAssertEqual(model.toast, "Swapped original and translation (target: English)")
  }

  func testReceivesTextWithoutWaiting() async throws {
    URLProtocol.registerClass(StubProtocol.self)
    defer { URLProtocol.unregisterClass(StubProtocol.self); StubProtocol.handler = nil }
    StubProtocol.handler = { _, _ in (200, ["output_text": "こんにちは"]) }
    try KeyStore.save(["openai": "sk-test"], locked: false)
    defer { try? KeyStore.save([:], locked: false) }
    let model = AppModel(shared: Shared())
    model.provider = .openai
    model.pickTarget("Japanese")
    await model.unlock(quiet: true)
    model.receive("Hello")
    XCTAssertEqual(model.source, "Hello")
    // Well within the 700 ms the pane waits after typing.
    for _ in 0..<5 where model.result == nil { try await Task.sleep(for: .milliseconds(100)) }
    XCTAssertEqual(model.result, "こんにちは")
  }

  func testCopiesSettingsForTheShareExtension() {
    UserDefaults.standard.set("anthropic", forKey: "langria-provider")
    UserDefaults.standard.set("Korean", forKey: "langria-target")
    ShareSettings.save()
    let copied = ShareSettings.load()
    XCTAssertEqual(copied["langria-provider"], "anthropic")
    XCTAssertEqual(copied["langria-target"], "Korean")
  }
}
