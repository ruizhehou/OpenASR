import SwiftUI

struct MainWindowView: View {
    @StateObject private var transcriptionVM = TranscriptionViewModel()
    @StateObject private var settingsVM = SettingsViewModel()
    @ObservedObject private var modelManager = ModelManager.shared
    @State private var selectedTab: Tab = .transcribe

    enum Tab: String, CaseIterable {
        case transcribe = "Transcribe"
        case history = "History"
        case models = "Models"

        var icon: String {
            switch self {
            case .transcribe: return "waveform"
            case .history: return "clock.arrow.circlepath"
            case .models: return "cpu"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(Tab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selectedTab {
            case .transcribe:
                transcribePane
            case .history:
                HistoryView()
            case .models:
                ModelManagerView(selectedModel: $settingsVM.selectedModel)
            }
        }
        .navigationTitle("OpenASR")
        .frame(minWidth: Constants.UI.mainWindowMinWidth, minHeight: Constants.UI.mainWindowMinHeight)
    }

    private var transcribePane: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                if transcriptionVM.isRecording {
                    Button {
                        Task { await transcriptionVM.stopRecording() }
                    } label: {
                        Label("Stop Recording", systemImage: "stop.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)

                    Text(transcriptionVM.recordingDuration.hhmmss)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        Task { await transcriptionVM.startRecording() }
                    } label: {
                        Label("Start Recording", systemImage: "record.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!modelManager.isDownloaded(settingsVM.selectedModel))
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                }

                Spacer()

                if let record = transcriptionVM.lastRecord {
                    CopyButton(text: record.fullText)
                }

                StatusBadge(status: statusBadgeStatus)
            }
            .padding()

            WaveformView(level: transcriptionVM.audioLevel)
                .padding(.horizontal)

            Divider()

            TranscriptionView(
                segments: transcriptionVM.liveSegments,
                showTimestamps: settingsVM.showTimestamps,
                isLive: transcriptionVM.isRecording
            )

            Divider()

            // File drop
            VStack(spacing: 4) {
                FileDropZoneView { urls in
                    guard let url = urls.first else { return }
                    Task { await transcriptionVM.transcribeFile(url: url) }
                }
                if transcriptionVM.isProcessingFile {
                    ProgressView("Transcribing file...", value: transcriptionVM.fileProgress)
                }
            }
            .padding()
        }
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
    }

    private var statusBadgeStatus: StatusBadge.Status {
        if transcriptionVM.isRecording { return .recording }
        if transcriptionVM.isProcessingFile { return .processing }
        if transcriptionVM.errorMessage != nil { return .error }
        return .idle
    }
}
