import AppIntents

/// "Translate with Langria": puts text into the original pane and translates
/// it. Shortcuts, the Action button and Siri run it; a shortcut that receives
/// text from the share sheet can hand it on. The app opens, so the key is
/// read (and unlocked) there as usual and the text goes nowhere else.
/// Titles are in Localizable.strings, not i18n.js, because the system reads
/// them from the app bundle without running the app.
struct TranslateIntent: AppIntent {
  static let title: LocalizedStringResource = "Translate with Langria"
  static let description = IntentDescription("Opens Langria with the text in the original pane and translates it.")
  static let openAppWhenRun = true

  @Parameter(title: "Text", inputOptions: String.IntentInputOptions(multiline: true), requestValueDialog: "What would you like to translate?")
  var text: String

  @Dependency private var model: AppModel

  static var parameterSummary: some ParameterSummary { Summary("Translate \(\.$text) with Langria") }

  @MainActor
  func perform() async throws -> some IntentResult {
    model.receive(text)
    return .result()
  }
}

struct LangriaShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: TranslateIntent(),
      phrases: ["Translate with \(.applicationName)", "Translate text with \(.applicationName)"],
      shortTitle: "Translate",
      systemImageName: "character.bubble"
    )
  }
}
