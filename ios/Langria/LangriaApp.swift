import SwiftUI

@main
struct LangriaApp: App {
  @StateObject private var shared: Shared
  @StateObject private var model: AppModel
  @AppStorage("langria-theme") private var theme = ""
  @Environment(\.scenePhase) private var scenePhase

  init() {
    let shared = Shared()
    _shared = StateObject(wrappedValue: shared)
    _model = StateObject(wrappedValue: AppModel(shared: shared))
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(shared)
        .environmentObject(model)
        .environment(\.locale, Locale(identifier: shared.language))
        .preferredColorScheme(theme == "light" ? .light : theme == "dark" ? .dark : nil)
    }
    .onChange(of: scenePhase) { _, phase in
      if phase == .background { model.didEnterBackground() }
    }
  }
}
