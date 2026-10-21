import AVFAudio
import NaturalLanguage

/// Reads the translation aloud with the system voices, on the device. Used
/// by the iPhone app and the watch app.
@MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  /// The utterance being read. `isSpeaking` can still be true when reading
  /// is reported finished, or never become true, so the end is told by the
  /// utterance instead.
  private var current: AVSpeechUtterance?
  var onChange: ((Bool) -> Void)?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  /// `language` is a BCP 47 tag, or nil to guess it from the text (for a
  /// target typed in under "Other"). Returns false, without reading, when the
  /// device has no voice for the language.
  @discardableResult
  func speak(_ text: String, language: String?) -> Bool {
    stop()
    let utterance = AVSpeechUtterance(string: text)
    if let tag = language ?? NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue {
      guard let voice = AVSpeechSynthesisVoice(language: tag) else { return false }
      utterance.voice = voice
    }
    current = utterance
    // Play even in silent mode (the ring / silent switch on iPhone), as the
    // user asked for it; the default ambient category would be muted.
    Task {
      await Task.detached {
        let session = AVAudioSession.sharedInstance()
        #if os(watchOS)
        try? session.setCategory(.playback, mode: .spokenAudio, policy: .default)
        #else
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        #endif
        try? session.setActive(true)
      }.value
      // Stopped while the session was being set up.
      guard current === utterance else { return }
      synthesizer.speak(utterance)
    }
    onChange?(true)
    return true
  }

  func stop() {
    guard let utterance = current else { return }
    synthesizer.stopSpeaking(at: .immediate)
    ended(utterance)
  }

  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { Task { @MainActor in self.ended(utterance) } }
  nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { Task { @MainActor in self.ended(utterance) } }

  /// Only the utterance being read ends it; a stopped earlier one may report late.
  private func ended(_ utterance: AVSpeechUtterance) {
    guard current === utterance else { return }
    current = nil
    Task.detached { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
    onChange?(false)
  }
}
