import SwiftUI

@main
struct LangriaWatchApp: App {
  @StateObject private var model = WatchModel()

  var body: some Scene {
    WindowGroup {
      WatchView()
        .environmentObject(model)
        .environment(\.locale, Locale(identifier: model.settings?.language ?? Locale.current.identifier))
    }
  }
}

struct WatchView: View {
  @EnvironmentObject private var model: WatchModel

  var body: some View {
    NavigationStack {
      Group {
        if model.ready { translator } else { setup }
      }
      .navigationTitle("Langria")
    }
  }

  private var setup: some View {
    ScrollView {
      VStack(spacing: 10) {
        Image(systemName: "iphone.and.arrow.forward").font(.title2).foregroundStyle(.tint)
        Text("setup").multilineTextAlignment(.center)
      }
      .padding(.top, 8)
    }
    // The setup text follows the watch's language; the iPhone has not said otherwise yet.
    .environment(\.locale, .current)
  }

  private var translator: some View {
    List {
      Section {
        // Opens the system input: dictation, Scribble or the keyboard.
        TextField(model.t("watch.input"), text: $model.source, axis: .vertical)
          .lineLimit(1...6)
        Picker(model.t("watch.translateTo"), selection: Binding(get: { model.target }, set: { model.pick($0) })) {
          ForEach(model.targets, id: \.self) { Text(model.label($0)).tag($0) }
        }
      } footer: {
        // The system input decides the dictation language; the app cannot set it.
        Text(model.t("watch.dictationHint"))
      }
      result
    }
  }

  @ViewBuilder private var result: some View {
    switch model.pane {
    case .empty:
      EmptyView()
    case .translating:
      Section {
        HStack {
          ProgressView().fixedSize()
          Text(model.t("status.translating")).foregroundStyle(.secondary)
        }
      }
    case .result(let text):
      Section {
        Text(text)
        Button(model.t(model.speaking ? "ios.stopSpeaking" : "ios.speak"), systemImage: model.speaking ? "stop.fill" : "speaker.wave.2") {
          model.toggleSpeaking()
        }
        if let notice = model.notice { Text(notice).font(.footnote).foregroundStyle(.secondary) }
      } footer: {
        Text("\(model.provider.name) · \(model.model)")
      }
    case .failure(let message):
      Section {
        Text(message).foregroundStyle(.red).font(.footnote)
      }
    }
  }
}
