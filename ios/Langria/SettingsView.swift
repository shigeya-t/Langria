import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var shared: Shared
  @EnvironmentObject private var model: AppModel
  @Environment(\.dismiss) private var dismiss
  @AppStorage("langria-theme") private var theme = ""
  @State private var editing: Provider = .openai
  @State private var key = ""
  @State private var modelName = ""
  @State private var showKey = false
  @State private var error = ""

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker(shared.t("popup.aiService"), selection: $editing) {
            ForEach(Provider.allCases) { Text($0.name).tag($0) }
          }
          .pickerStyle(.segmented)
          HStack {
            Group {
              if showKey { TextField(placeholder, text: $key) } else { SecureField(placeholder, text: $key) }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .font(.body.monospaced())
            .disabled(model.keys == nil)
            .accessibilityLabel("\(shared.t("settings.apiKey")) \(editing.name)")
            Button(shared.t(showKey ? "settings.hide" : "settings.show")) { showKey.toggle() }
              .buttonStyle(.borderless)
              .disabled(model.keys == nil)
          }
          LabeledContent(shared.t("settings.model")) {
            TextField(editing.defaultModel, text: $modelName)
              .multilineTextAlignment(.trailing)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .font(.body.monospaced())
          }
          Button(shared.t("settings.save")) { save() }
        } header: {
          Text("\(shared.t("settings.apiKey")) · \(editing.name)")
        } footer: {
          Text(shared.t("ios.settingsDescription"))
        }

        Section {
          if model.keys == nil {
            Button { Task { await model.unlock() } } label: {
              Label(shared.t("vault.unlock"), systemImage: "lock.open")
            }
            .disabled(model.unlocking)
          }
          Toggle(shared.t("ios.lockToggle", ["method": model.lockMethod]), isOn: Binding(get: { model.locked }, set: { setLock($0) }))
            .disabled(model.keys == nil)
        } header: {
          Text(shared.t("ios.lockTitle"))
        } footer: {
          VStack(alignment: .leading, spacing: 6) {
            Text(shared.t("ios.lockNote", ["method": model.lockMethod]))
            if !error.isEmpty { Text(error).foregroundStyle(.red) }
            if !model.unlockError.isEmpty { Text(model.unlockError).foregroundStyle(.red) }
          }
        }

        Section {
          Picker(shared.t("ios.displayLanguage"), selection: Binding(get: { shared.choice ?? "" }, set: { shared.setChoice($0.isEmpty ? nil : $0); model.uiLanguageChanged() })) {
            Text(shared.t("ios.system")).tag("")
            Text("English").tag("en")
            Text("日本語").tag("ja")
          }
          Picker(shared.t("ios.appearance"), selection: $theme) {
            Text(shared.t("ios.system")).tag("")
            Text(shared.t("ios.light")).tag("light")
            Text(shared.t("ios.dark")).tag("dark")
          }
        }

        Section {
          Text(shared.t("web.securityNote")).font(.footnote).foregroundStyle(.secondary)
          Link(shared.t("settings.repo"), destination: URL(string: "https://github.com/shigeya-t/Langria")!)
          LabeledContent(shared.t("ios.version"), value: version)
        }
      }
      .navigationTitle(shared.t("settings.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) { Button(shared.t("ios.done")) { dismiss() } }
      }
      .onAppear { editing = model.provider; fill() }
      .onChange(of: editing) { _, _ in fill() }
      .onChange(of: model.keys) { _, _ in fill() }
    }
  }

  private var placeholder: String { shared.t(model.keys == nil ? "settings.lockedPlaceholder" : "settings.keyPlaceholder") }

  private var version: String {
    let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    return shared.commit.isEmpty ? short : "\(short) (\(shared.commit))"
  }

  private func fill() {
    key = model.keys?[editing.rawValue] ?? ""
    modelName = model.model(for: editing)
    error = ""
  }

  private func save() {
    do {
      try model.save(key: key.trimmingCharacters(in: .whitespacesAndNewlines), model: modelName, for: editing)
      dismiss()
    } catch {
      self.error = model.describe(error)
    }
  }

  private func setLock(_ on: Bool) {
    error = ""
    do { try model.setLock(on) } catch { self.error = model.describe(error) }
  }
}
