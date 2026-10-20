import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var shared: Shared
  @EnvironmentObject private var model: AppModel
  @EnvironmentObject private var ads: Ads
  @Environment(\.dismiss) private var dismiss
  @AppStorage("langria-theme") private var theme = ""
  @State private var editing: Provider = .openai
  @State private var key = ""
  @State private var modelName = ""
  @State private var showKey = false
  @State private var error = ""
  /// The key and model as stored, to tell whether the fields were changed.
  @State private var savedKey = ""
  @State private var savedModel = ""
  @State private var justSaved = false
  /// Set while asking whether to drop unsaved changes: the provider to switch
  /// to, or nil when closing the settings.
  @State private var leaving: Provider??

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker(shared.t("popup.aiService"), selection: Binding(get: { editing }, set: { next in
            if hasChanges { leaving = .some(next) } else { editing = next }
          })) {
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
          HStack {
            Button(shared.t("settings.save")) { save() }
              .disabled(!hasChanges)
            Spacer()
            if justSaved {
              Label(shared.t("web.savedProvider", ["name": editing.name]), systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .transition(.opacity)
            }
          }
          .animation(.easeOut(duration: 0.2), value: justSaved)
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
          if ads.privacyOptionsRequired {
            Button(shared.t("ios.adPrivacy")) { Task { await ads.showPrivacyOptions() } }
          }
          LabeledContent(shared.t("ios.version"), value: version)
        }
      }
      .navigationTitle(shared.t("settings.title"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(shared.t("ios.done")) { if hasChanges { leaving = .some(nil) } else { dismiss() } }
        }
      }
      // Swiping the sheet down would drop the changes without asking.
      .interactiveDismissDisabled(hasChanges)
      .alert(shared.t("ios.unsavedTitle"), isPresented: Binding(get: { leaving != nil }, set: { if !$0 { leaving = nil } })) {
        Button(shared.t("ios.discard"), role: .destructive) { leave(saving: false) }
        Button(shared.t("settings.save")) { leave(saving: true) }
        Button(shared.t("vault.cancel"), role: .cancel) { leaving = nil }
      } message: {
        Text(shared.t("ios.unsavedMessage", ["name": editing.name]))
      }
      .onChange(of: key) { _, _ in justSaved = false }
      .onChange(of: modelName) { _, _ in justSaved = false }
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
    savedKey = model.keys?[editing.rawValue] ?? ""
    savedModel = model.model(for: editing)
    key = savedKey
    modelName = savedModel
    error = ""
  }

  private var trimmedKey: String { key.trimmingCharacters(in: .whitespacesAndNewlines) }
  // A blank model field means the default model, as when saving.
  private var effectiveModel: String {
    let trimmed = modelName.trimmingCharacters(in: .whitespaces)
    return trimmed.isEmpty ? editing.defaultModel : trimmed
  }

  private var hasChanges: Bool {
    (model.keys != nil && trimmedKey != savedKey) || effectiveModel != savedModel
  }

  /// Saves and stays on the settings, so other services can be set up too.
  @discardableResult
  private func save() -> Bool {
    do {
      try model.save(key: trimmedKey, model: modelName, for: editing)
      fill()
      justSaved = true
      return true
    } catch {
      self.error = model.describe(error)
      return false
    }
  }

  /// Answers the unsaved-changes alert: switches to the chosen service or closes the settings.
  private func leave(saving: Bool) {
    guard let target = leaving else { return }
    leaving = nil
    if saving && !save() { return }
    if let next = target {
      editing = next
      justSaved = false
    } else {
      dismiss()
    }
  }

  private func setLock(_ on: Bool) {
    error = ""
    do { try model.setLock(on) } catch { self.error = model.describe(error) }
  }
}
