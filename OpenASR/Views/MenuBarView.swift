import SwiftUI

struct MenuBarView: View {
    @StateObject private var transcriptionVM = TranscriptionViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @ObservedObject private var modelManager = ModelManager.shared
    @State private var showModelManager = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.accentColor)
                Text("OpenASR")
                    .font(.headline)
                Spacer()
                StatusBadge(status: statusBadgeStatus)
                Button {
                    openSettings()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                Button {
                    openMainWindow()
                } label: {
                    Image(systemName: "arrow.up.right.square")
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Waveform + recording controls
            VStack(spacing: 8) {
                WaveformView(level: transcriptionVM.audioLevel)
                    .padding(.horizontal, 12)

                if transcriptionVM.isRecording {
                    Text(transcriptionVM.recordingDuration.hhmmss)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    if transcriptionVM.isRecording {
                        Button {
                            Task { await transcriptionVM.stopRecording() }
                        } label: {
                            Label("Stop", systemImage: "stop.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.small)
                    } else {
                        Button {
                            Task { await transcriptionVM.startRecording() }
                        } label: {
                            Label("Record", systemImage: "record.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(!modelManager.isDownloaded(settingsVM.selectedModel))
                    }

                    if let record = transcriptionVM.lastRecord {
                        CopyButton(text: record.fullText, label: "Copy")
                            .controlSize(.small)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Live transcript preview
            if !transcriptionVM.liveSegments.isEmpty {
                TranscriptionView(
                    segments: transcriptionVM.liveSegments,
                    showTimestamps: settingsVM.showTimestamps,
                    isLive: transcriptionVM.isRecording
                )
                .frame(height: 100)

                Divider()
            }

            // File drop zone
            FileDropZoneView { urls in
                guard let url = urls.first else { return }
                Task { await transcriptionVM.transcribeFile(url: url) }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if transcriptionVM.isProcessingFile {
                ProgressView(value: transcriptionVM.fileProgress)
                    .padding(.horizontal, 12)
            }

            Divider()

            // Model selector
            HStack {
                Text("Model:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("", selection: $settingsVM.selectedModel) {
                    ForEach(WhisperModel.allCases.filter { modelManager.isDownloaded($0) }) { model in
                        Text(model.displayName).tag(model)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(maxWidth: .infinity)

                if modelManager.downloadedModels.isEmpty {
                    Button("Download Models") {
                        showModelManager = true
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: Constants.UI.menuBarPopoverWidth)
        .alert("Error", isPresented: .constant(transcriptionVM.errorMessage != nil)) {
            Button("OK") { transcriptionVM.errorMessage = nil }
        } message: {
            Text(transcriptionVM.errorMessage ?? "")
        }
        .onAppear {
            if let model = modelManager.downloadedModels.first {
                Task { await transcriptionVM.loadModel(model) }
            }
        }
        .onChange(of: settingsVM.selectedModel) { model in
            Task { await transcriptionVM.loadModel(model) }
        }
        .sheet(isPresented: $showModelManager) {
            ModelManagerView(selectedModel: $settingsVM.selectedModel)
                .frame(width: 480, height: 400)
        }
    }

    private var statusBadgeStatus: StatusBadge.Status {
        if transcriptionVM.isRecording { return .recording }
        if transcriptionVM.isProcessingFile { return .processing }
        if transcriptionVM.errorMessage != nil { return .error }
        return .idle
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func openMainWindow() {
        NotificationCenter.default.post(name: .openMainWindow, object: nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension Notification.Name {
    static let openMainWindow = Notification.Name("OpenASROpenMainWindow")
}
