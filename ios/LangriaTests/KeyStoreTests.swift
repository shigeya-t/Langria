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
    model.source = "Good morning"
    model.translateNow()
    for _ in 0..<50 where model.result == nil { try await Task.sleep(for: .milliseconds(100)) }
    XCTAssertEqual(model.result, "おはようございます")
    model.swap()
    XCTAssertEqual(model.source, "おはようございます")
    XCTAssertEqual(model.target, "English")
    XCTAssertEqual(model.result, "Good morning")
    XCTAssertEqual(model.toast, "Swapped original and translation (target: English)")
  }
}
