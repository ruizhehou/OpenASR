import Foundation
import Combine
import OSLog

@MainActor
final class TranscriptionViewModel: ObservableObject {
    @Published var liveSegments: [TranscriptionSegment] = []
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var fileProgress: Double = 0
    @Published var isProcessingFile: Bool = false
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?
    @Published var lastRecord: TranscriptionRecord?

    let whisperEngine = WhisperEngine()
    private let audioCapture = AudioCaptureEngine()
    private let fileEngine = FileTranscriptionEngine()
    private let historyStore = HistoryStore.shared
    private let settings = SettingsViewModel()

    private var sampleBuffer: [Float] = []
    private var recordingStartTime: Date?
    private var durationTimer: AnyCancellable?
    private var inferenceTask: Task<Void, Never>?

    // MARK: - Model Loading

    func loadModel(_ model: WhisperModel) async {
        do {
            await AppState.shared.set(transcriptionState: .idle)
            try await whisperEngine.load(model: model)
        } catch {
            errorMessage = error.localizedDescription
            Logger.engine.error("Model load failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Real-Time Recording

    func startRecording() async {
        guard !isRecording else { return }

        // Ensure model is loaded
        guard await whisperEngine.isLoaded else {
            errorMessage = "Please download and select a model before recording."
            return
        }

        // Request microphone permission
        let granted = await audioCapture.requestPermission()
        guard granted else {
            errorMessage = "Microphone access denied. Please grant permission in System Settings."
            return
        }

        do {
            sampleBuffer = []
            liveSegments = []
            recordingStartTime = Date()
            isRecording = true

            // Start duration timer
            durationTimer = Timer.publish(every: 0.1, on: .main, in: .common)
                .autoconnect()
                .sink { [weak self] _ in
                    guard let self, let start = self.recordingStartTime else { return }
                    self.recordingDuration = Date().timeIntervalSince(start)
                }

            // Set up audio callbacks
            audioCapture.onAudioBuffer = { [weak self] samples in
                Task { @MainActor [weak self] in
                    self?.appendSamples(samples)
                }
            }
            audioCapture.onLevelUpdate = { [weak self] level in
                Task { @MainActor [weak self] in
                    self?.audioLevel = level
                }
            }

            try audioCapture.startCapture()
            Logger.audio.info("Recording started")
        } catch {
            isRecording = false
            durationTimer?.cancel()
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() async {
        guard isRecording else { return }

        audioCapture.stopCapture()
        durationTimer?.cancel()
        isRecording = false
        audioLevel = 0
        inferenceTask?.cancel()

        // Final transcription of full buffer
        if !sampleBuffer.isEmpty {
            let samples = sampleBuffer
            let language = settings.language
            let translate = settings.translateToEnglish

            do {
                let segments = try await whisperEngine.transcribe(
                    samples: samples,
                    language: language,
                    translate: translate
                )
                liveSegments = segments

                let record = TranscriptionRecord(
                    source: .microphone,
                    modelUsed: await whisperEngine.loadedModel ?? .base,
                    language: language,
                    segments: segments,
                    duration: recordingDuration
                )
                try historyStore.save(record)
                lastRecord = record

                if settings.autoCopyToClipboard {
                    ClipboardService.copy(record.fullText)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        sampleBuffer = []
        recordingDuration = 0
        Logger.audio.info("Recording stopped")
    }

    // MARK: - File Transcription

    func transcribeFile(url: URL) async {
        guard !isProcessingFile else { return }
        guard await whisperEngine.isLoaded else {
            errorMessage = "Please download and select a model first."
            return
        }

        isProcessingFile = true
        fileProgress = 0
        errorMessage = nil

        let language = settings.language
        let translate = settings.translateToEnglish

        do {
            let record = try await fileEngine.transcribe(
                url: url,
                engine: whisperEngine,
                language: language,
                translate: translate,
                progress: { [weak self] p in
                    Task { @MainActor [weak self] in
                        self?.fileProgress = p
                    }
                }
            )

            try historyStore.save(record)
            lastRecord = record
            liveSegments = record.segments

            if settings.autoCopyToClipboard {
                ClipboardService.copy(record.fullText)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessingFile = false
        fileProgress = 0
    }

    // MARK: - Private

    private func appendSamples(_ newSamples: [Float]) {
        sampleBuffer.append(contentsOf: newSamples)

        // Keep rolling window for live inference
        if sampleBuffer.count > Constants.Audio.samplesPerWindow {
            sampleBuffer.removeFirst(sampleBuffer.count - Constants.Audio.samplesPerWindow)
        }

        // Trigger inference every ~1 second (after accumulating at least 1s of audio)
        guard sampleBuffer.count >= Constants.Audio.samplesPerChunk else { return }
        guard inferenceTask == nil || inferenceTask?.isCancelled == true else { return }

        let samples = sampleBuffer
        let language = settings.language
        let translate = settings.translateToEnglish

        inferenceTask = Task { [weak self] in
            guard let self else { return }
            do {
                let segments = try await self.whisperEngine.transcribe(
                    samples: samples,
                    language: language,
                    translate: translate
                )
                if !Task.isCancelled {
                    self.liveSegments = segments
                }
            } catch {
                // Ignore transient errors during live recording
            }
            self.inferenceTask = nil
        }
    }
}

// Helper to set state from non-isolated context
extension AppState {
    func set(transcriptionState: TranscriptionState) {
        self.transcriptionState = transcriptionState
    }
}
