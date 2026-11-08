import SwiftUI

/// The sheet: the target language, the shared text and its translation.
struct ShareView: View {
  @ObservedObject var model: ShareModel
  private var t: (String, [String: String]) -> String { model.shared.t }

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker(t("web.targetLanguage", [:]), selection: $model.target) {
            ForEach(model.targets, id: \.self) { Text(model.label($0)).tag($0) }
          }
        }
        if !model.source.isEmpty {
          Section(t("web.original", [:])) {
            Text(model.source).textSelection(.enabled).lineLimit(8)
          }
        }
        Section {
          translation
        } header: {
          HStack {
            Text(t("web.translation", [:]))
            Spacer()
            Text(model.modelName).font(.caption.monospaced()).textCase(nil)
          }
        }
      }
      .navigationTitle("Langria")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(t("ios.shareClose", [:])) { model.dismiss() }
        }
      }
    }
    .environment(\.locale, Locale(identifier: model.shared.language))
  }

  @ViewBuilder private var translation: some View {
    switch model.state {
    case .loading, .translating:
      HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 12)
    case .noText:
      Text(t("ios.shareNoText", [:])).foregroundStyle(.secondary)
    case .noKey:
      Text(t("ios.shareNoKey", [:]))
    case .locked:
      VStack(alignment: .leading, spacing: 12) {
        Text(t("web.locked", [:]))
        Button { Task { await model.unlock() } } label: {
          Label(t("ios.unlockButton", ["method": model.lockMethod]), systemImage: KeyStore.biometryName == "Touch ID" ? "touchid" : "faceid")
        }
        .buttonStyle(.borderedProminent)
        .disabled(model.unlocking)
        if !model.unlockError.isEmpty {
          Text(model.unlockError).font(.footnote).foregroundStyle(.red)
        }
      }
      .padding(.vertical, 4)
    case .result(let text):
      Text(text).textSelection(.enabled)
      HStack(spacing: 12) {
        Button { model.copy() } label: {
          Label(t(model.copied ? "copied" : "web.copyTranslation", [:]), systemImage: model.copied ? "checkmark" : "doc.on.doc")
        }
        Spacer()
        Button { model.toggleSpeaking() } label: {
          Image(systemName: model.speaking ? "stop.circle" : "speaker.wave.2")
        }
        .accessibilityLabel(t(model.speaking ? "ios.stopSpeaking" : "ios.speak", [:]))
      }
      .buttonStyle(.borderless)
    case .failure(let error):
      VStack(alignment: .leading, spacing: 12) {
        Text(model.message(for: error)).foregroundStyle(.red).textSelection(.enabled)
        switch error.remedy {
        case .retry:
          Button { model.translate() } label: { Label(t("popup.retry", [:]), systemImage: "arrow.clockwise") }.buttonStyle(.bordered)
        case .settings:
          Text(t("ios.shareFixInApp", [:])).font(.footnote).foregroundStyle(.secondary)
        case .none:
          EmptyView()
        }
      }
      .padding(.vertical, 4)
    }
  }
}
