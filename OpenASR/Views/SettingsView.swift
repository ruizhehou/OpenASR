import SwiftUI

struct SettingsView: View {
    @StateObject private var vm = SettingsViewModel()
    @ObservedObject private var modelManager = ModelManager.shared

    var body: some View {
        TabView {
            GeneralTab(vm: vm)
                .tabItem { Label("General", systemImage: "gearshape") }

            ModelManagerView(selectedModel: $vm.selectedModel)
                .tabItem { Label("Models", systemImage: "cpu") }

            HotkeysTab(vm: vm)
                .tabItem { Label("Hotkeys", systemImage: "keyboard") }

            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 400)
    }
}

struct GeneralTab: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        Form {
            Section("Transcription") {
                Picker("Language", selection: $vm.language) {
                    ForEach(SettingsViewModel.supportedLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                Toggle("Translate to English", isOn: $vm.translateToEnglish)
                Toggle("Show timestamps", isOn: $vm.showTimestamps)
            }
            Section("Clipboard") {
                Toggle("Auto-copy transcription to clipboard", isOn: $vm.autoCopyToClipboard)
            }
            Section("System") {
                Toggle("Launch at login", isOn: $vm.launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct HotkeysTab: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Record Toggle") {
                HStack {
                    Text("Start / Stop Recording")
                    Spacer()
                    Text("⌘⇧R")
                        .font(.system(.body, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(4)
            }
            Text("Custom hotkey configuration coming in a future update.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("OpenASR")
                .font(.title.bold())
            Text("Version \(Constants.App.version)")
                .foregroundStyle(.secondary)
            Text("Powered by OpenAI Whisper via whisper.cpp")
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            HStack(spacing: 20) {
                Link("GitHub", destination: URL(string: "https://github.com/ggerganov/whisper.cpp")!)
                Link("Whisper Paper", destination: URL(string: "https://arxiv.org/abs/2212.04356")!)
            }
            .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
