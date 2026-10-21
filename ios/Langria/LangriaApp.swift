import SwiftUI

@main
struct LangriaApp: App {
  @StateObject private var shared: Shared
  @StateObject private var model: AppModel
  @StateObject private var ads = Ads()
  @StateObject private var watch: WatchSync
  @AppStorage("langria-theme") private var theme = ""
  @Environment(\.scenePhase) private var scenePhase

  init() {
    let shared = Shared()
    let model = AppModel(shared: shared)
    _shared = StateObject(wrappedValue: shared)
    _model = StateObject(wrappedValue: model)
    _watch = StateObject(wrappedValue: WatchSync(model: model, shared: shared))
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(shared)
        .environmentObject(model)
        .environmentObject(ads)
        .environmentObject(watch)
        .environment(\.locale, Locale(identifier: shared.language))
        .preferredColorScheme(theme == "light" ? .light : theme == "dark" ? .dark : nil)
    }
    .onChange(of: scenePhase, initial: true) { _, phase in
      if phase == .background { model.didEnterBackground() }
      if phase == .active { Task { await ads.gatherConsent() } }
    }
  }
}
