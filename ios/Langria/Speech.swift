import AVFoundation
import NaturalLanguage
import Speech

/// Voice input for the original pane, with Apple's speech recognition. It
/// runs on the device when the language supports it; otherwise the audio goes
/// to Apple's speech service, as with the keyboard's dictation.
@MainActor
final class Dictation {
  enum Failure: Error {
    case denied
    case unavailable
  }

  private let engine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private(set) var isRecording = false

  /// Starts listening; `onText` gets the transcript so far, `onEnd` is
  /// called once when recognition stops (with the error, if any).
  func start(locale: Locale, onText: @escaping (String) -> Void, onEnd: @escaping (Error?) -> Void) async throws {
    guard await Self.authorize() else { throw Failure.denied }
    guard let recognizer = SFSpeechRecognizer(locale: locale), recognizer.isAvailable else { throw Failure.unavailable }

    // Activating the session can block, so it is kept off the main thread.
    try await Task.detached {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker, .allowBluetoothHFP])
      try session.setActive(true, options: .notifyOthersOnDeactivation)
    }.value

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    request.addsPunctuation = true
    if recognizer.supportsOnDeviceRecognition { request.requiresOnDeviceRecognition = true }
    self.request = request

    let input = engine.inputNode
    input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
      request.append(buffer)
    }
    engine.prepare()
    try engine.start()
    isRecording = true

    task = recognizer.recognitionTask(with: request) { [weak self] result, error in
      let text = result?.bestTranscription.formattedString
      let done = error != nil || result?.isFinal == true
      Task { @MainActor in
        guard let self, self.isRecording else { return }
        if let text { onText(text) }
        if done {
          self.finish()
          // Stopping by hand or a pause with nothing heard also ends with an error; only report real ones.
          onEnd(text == nil && !Self.isSilence(error) ? error : nil)
        }
      }
    }
  }

  /// Stops listening and keeps what was heard.
  func stop() {
    request?.endAudio()
    finish()
  }

  private func finish() {
    guard isRecording else { return }
    isRecording = false
    engine.stop()
    engine.inputNode.removeTap(onBus: 0)
    task?.finish()
    task = nil
    request = nil
    Task.detached { try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation) }
  }

  /// "No speech detected" (kAFAssistantErrorDomain 1110) after a quiet start.
  private static func isSilence(_ error: Error?) -> Bool {
    guard let error = error as NSError? else { return true }
    return error.domain == "kAFAssistantErrorDomain" && error.code == 1110
  }

  private static func authorize() async -> Bool {
    let speech = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0 == .authorized) }
    }
    guard speech else { return false }
    return await AVAudioApplication.requestRecordPermission()
  }
}

/// Reads the translation aloud with the system voices, on the device.
@MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  var onChange: ((Bool) -> Void)?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  var isSpeaking: Bool { synthesizer.isSpeaking }

  /// `language` is a BCP 47 tag, or nil to guess it from the text (for a
  /// target typed in under "Other").
  func speak(_ text: String, language: String?) {
    stop()
    // Play even with the ring / silent switch on, as the user asked for it.
    let utterance = AVSpeechUtterance(string: text)
    let tag = language ?? NLLanguageRecognizer.dominantLanguage(for: text)?.rawValue
    if let tag { utterance.voice = AVSpeechSynthesisVoice(language: tag) }
    Task {
      await Task.detached {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
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
