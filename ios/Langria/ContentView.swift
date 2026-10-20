import PhotosUI
import SwiftUI

struct ContentView: View {
  @EnvironmentObject private var shared: Shared
  @EnvironmentObject private var model: AppModel
  @Environment(\.horizontalSizeClass) private var sizeClass
  @State private var showSettings = false
  @State private var showCamera = false
  @State private var photoItem: PhotosPickerItem?
  @FocusState private var sourceFocused: Bool

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 14) {
          providerPicker
          languageStrip
          if sizeClass == .regular {
            HStack(alignment: .top, spacing: 14) { inputPane; outputPane }
          } else {
            inputPane
            outputPane
          }
          Text(shared.t("ios.ocrNote"))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .padding(16)
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
      }
      .scrollDismissesKeyboard(.interactively)
      .background(Color(.systemGroupedBackground))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          HStack(spacing: 8) {
            Image("Logo").resizable().frame(width: 24, height: 24).clipShape(RoundedRectangle(cornerRadius: 6))
            Text("Langria").font(.headline.weight(.heavy))
          }
          .accessibilityElement(children: .combine)
        }
        if #available(iOS 26, *) {
          ToolbarItem(placement: .topBarTrailing) { settingsButton }.sharedBackgroundVisibility(.hidden)
        } else {
          ToolbarItem(placement: .topBarTrailing) { settingsButton }
        }
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button(shared.t("ios.done")) { sourceFocused = false }
        }
      }
    }
    .sheet(isPresented: $showSettings) { SettingsView() }
    .fullScreenCover(isPresented: $showCamera) {
      CameraPicker { image in Task { await model.read(image) } }.ignoresSafeArea()
    }
    .onChange(of: photoItem) { _, item in
      guard let item else { return }
      photoItem = nil
      Task {
        guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
          model.show(shared.t("ios.imageFailed"))
          return
        }
        await model.read(image)
      }
    }
    .overlay(alignment: .bottom) {
      if let toast = model.toast {
        Text(toast)
          .font(.subheadline.weight(.semibold))
          .padding(.horizontal, 16).padding(.vertical, 10)
          .glassCapsule()
          .padding(.bottom, 24)
          .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .animation(.easeOut(duration: 0.2), value: model.toast)
  }

  private var providerPicker: some View {
    Picker(shared.t("popup.aiService"), selection: $model.provider) {
      ForEach(Provider.allCases) { provider in
        Text("\(provider.orb) \(provider.name)").tag(provider)
      }
    }
    .pickerStyle(.segmented)
  }

  private var languageStrip: some View {
    VStack(spacing: 8) {
      HStack(spacing: 10) {
        HStack(spacing: 6) {
          Circle().fill(Color.accentColor).frame(width: 7, height: 7)
          Text(shared.t("web.autoDetect")).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Button { sourceFocused = false; model.swap() } label: {
          Image(systemName: "arrow.left.arrow.right").font(.footnote.weight(.bold)).frame(width: 22, height: 22)
        }
        .glassButton()
        .buttonBorderShape(.circle)
        .controlSize(.small)
        .disabled(model.result == nil)
        .accessibilityLabel(shared.t("web.swap"))
        Picker(shared.t("web.targetLanguage"), selection: Binding(get: { model.target }, set: { model.pickTarget($0) })) {
          ForEach(shared.targets, id: \.self) { Text(shared.languageLabel($0)).tag($0) }
          Text(shared.t("target.other")).tag(Shared.customTarget)
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .trailing)
      }
      if model.target == Shared.customTarget {
        TextField(shared.t("target.customPlaceholder"), text: $model.customTarget)
          .textFieldStyle(.roundedBorder)
          .autocorrectionDisabled()
          .accessibilityLabel(shared.t("target.customLabel"))
      }
    }
    .font(.subheadline.weight(.semibold))
    .padding(12)
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
  }

  private var inputPane: some View {
    Card {
      HStack(spacing: 8) {
        Text(shared.t("web.original")).font(.subheadline.weight(.bold))
        Picker(shared.t("mode.label"), selection: $model.mode) {
          ForEach(TranslationMode.allCases) { Text(shared.t("mode.\($0.rawValue)")).tag($0) }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .fixedSize()
        Spacer()
        Button(shared.t("web.clear")) { model.clear() }
          .font(.subheadline)
          .disabled(model.source.isEmpty && model.image == nil)
      }
    } content: {
      VStack(alignment: .leading, spacing: 10) {
        if let image = model.image {
          ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(maxHeight: 160)
              .clipShape(RoundedRectangle(cornerRadius: 10))
              .overlay {
                if model.recognizing { ProgressView().padding(10).background(.thinMaterial, in: Circle()) }
              }
            Button { model.removeImage() } label: {
              Image(systemName: "xmark.circle.fill").font(.title3).symbolRenderingMode(.palette).foregroundStyle(.white, .black.opacity(0.6))
            }
            .padding(6)
            .accessibilityLabel(shared.t("ios.removeImage"))
          }
        }
        ZStack(alignment: .topLeading) {
          if model.source.isEmpty {
            Text(shared.t("web.sourcePlaceholder")).foregroundStyle(.tertiary).padding(.top, 8).padding(.leading, 5)
          }
          TextEditor(text: $model.source)
            .focused($sourceFocused)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 150)
        }
      }
    } footer: {
      if model.listening {
        Label(shared.t("ios.listening", ["lang": shared.languageLabel(model.dictationLanguage)]), systemImage: "waveform")
          .foregroundStyle(.red)
          .lineLimit(1)
          .symbolEffect(.variableColor.iterative)
      } else {
        Text(model.characterCount)
      }
      Spacer()
      dictationButton
      if CameraPicker.isAvailable {
        Button { sourceFocused = false; showCamera = true } label: { Image(systemName: "camera") }
          .accessibilityLabel(shared.t("ios.camera"))
      }
      PhotosPicker(selection: $photoItem, matching: .images) { Image(systemName: "photo") }
        .accessibilityLabel(shared.t("ios.photo"))
      CopyButton(label: shared.t("web.copyOriginal")) { model.copy(model.source) }
    }
  }

  private var outputPane: some View {
    Card {
      HStack {
        Text(shared.t("web.translation")).font(.subheadline.weight(.bold))
        Spacer()
        Text(model.currentModel)
          .font(.caption.monospaced())
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .accessibilityLabel("\(shared.t("web.modelOf", ["name": model.provider.name])): \(model.currentModel)")
      }
    } content: {
      translation
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(.top, 8)
        .padding(.horizontal, 5)
    } footer: {
      Text(shared.t(model.statusKey))
      Spacer()
      Button { model.toggleSpeaking() } label: {
        Image(systemName: model.speaking ? "stop.circle" : "speaker.wave.2")
      }
      .disabled(model.result == nil && !model.speaking)
      .accessibilityLabel(shared.t(model.speaking ? "ios.stopSpeaking" : "ios.speak"))
      CopyButton(label: shared.t("web.copyTranslation")) { model.copy(model.result) }
        .disabled(model.result == nil)
    }
  }

  /// Tap to start or stop; touch and hold to pick the language spoken.
  private var dictationButton: some View {
    Menu {
      Picker(shared.t("ios.dictationLanguage"), selection: $model.dictationLanguage) {
        ForEach(shared.targets, id: \.self) { Text(shared.languageLabel($0)).tag($0) }
      }
    } label: {
      Image(systemName: model.listening ? "mic.fill" : "mic")
        .foregroundStyle(model.listening ? Color.red : Color.accentColor)
    } primaryAction: {
      sourceFocused = false
      Task { await model.toggleDictation() }
    }
    .accessibilityLabel(shared.t(model.listening ? "ios.stopDictation" : "ios.dictate"))
    .accessibilityHint(shared.t("ios.dictateHint"))
  }

  // A small plain icon rather than the toolbar's glass button, so it does not draw the eye.
  private var settingsButton: some View {
    Button { showSettings = true } label: {
      Image(systemName: "gearshape")
        .font(.system(size: 15, weight: .regular))
        .foregroundStyle(.secondary)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(shared.t("web.openSettings"))
  }

  @ViewBuilder private var translation: some View {
    switch model.pane {
    case .empty:
      VStack(spacing: 8) {
        Text("✦").font(.title).foregroundStyle(.tertiary)
        Text(shared.t("web.empty")).foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, minHeight: 140)
    case .translating:
      ProgressView().frame(maxWidth: .infinity, minHeight: 140)
    case .result(let text):
      Text(text).textSelection(.enabled)
    case .noKey:
      VStack(alignment: .leading, spacing: 12) {
        Text(shared.t("web.noKey"))
        Button(shared.t("web.openSettings")) { showSettings = true }.buttonStyle(.bordered)
      }
    case .noTarget:
      Text(shared.t("web.enterTarget"))
    case .locked:
      VStack(alignment: .leading, spacing: 12) {
        Text(shared.t("web.locked"))
        Button { Task { await model.unlock() } } label: {
          Label(shared.t("ios.unlockButton", ["method": model.lockMethod]), systemImage: KeyStore.biometryName == "Touch ID" ? "touchid" : "faceid")
        }
        .buttonStyle(.borderedProminent)
        .disabled(model.unlocking)
        if !model.unlockError.isEmpty {
          Text(model.unlockError).font(.footnote).foregroundStyle(.red)
        }
      }
    case .failure(let error, let provider, let modelName):
      Text(model.message(for: error, provider: provider, model: modelName))
        .foregroundStyle(.red)
        .textSelection(.enabled)
    }
  }
}

/// A rounded pane with a title row and a footer row, like the web app's panes.
private struct Card<Header: View, Content: View, Footer: View>: View {
  @ViewBuilder let header: Header
  @ViewBuilder let content: Content
  @ViewBuilder let footer: Footer

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header.padding(.horizontal, 14).frame(minHeight: 44)
      Divider()
      content.padding(.horizontal, 9).padding(.vertical, 6)
      Divider()
      HStack(spacing: 18) { footer }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .frame(minHeight: 44)
    }
    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
  }
}

private struct CopyButton: View {
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) { Image(systemName: "doc.on.doc") }
      .accessibilityLabel(label)
  }
}

// Liquid Glass on iOS 26 and later; the closest earlier look otherwise. The
// panes stay opaque, as they hold text to read.
private extension View {
  @ViewBuilder func glassButton() -> some View {
    if #available(iOS 26, *) { buttonStyle(.glass) } else { buttonStyle(.bordered) }
  }

  @ViewBuilder func glassCapsule() -> some View {
    if #available(iOS 26, *) { glassEffect(.regular, in: .capsule) } else { background(.thickMaterial, in: Capsule()) }
  }
}
