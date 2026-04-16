import AVFoundation
import OSLog

enum AudioCaptureError: LocalizedError {
    case microphonePermissionDenied
    case engineStartFailed(Error)
    case formatConversionFailed

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access was denied. Please grant permission in System Settings > Privacy & Security > Microphone."
        case .engineStartFailed(let error):
            return "Audio engine failed to start: \(error.localizedDescription)"
        case .formatConversionFailed:
            return "Failed to set up audio format conversion."
        }
    }
}

/// Captures microphone audio and delivers 16 kHz mono Float32 PCM chunks.
final class AudioCaptureEngine {
    // Callbacks (called on a background audio thread)
    var onAudioBuffer: (([Float]) -> Void)?
    var onLevelUpdate: ((Float) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var isRunning = false

    // Target format: 16 kHz mono Float32 (what whisper.cpp expects)
    private let targetFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: Constants.Audio.sampleRate,
        channels: 1,
        interleaved: false
    )!

    // MARK: - Public API

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startCapture() throws {
        guard !isRunning else { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        Logger.audio.info("Hardware input format: \(inputFormat.description)")

        // Set up converter from hardware format → 16kHz mono float32
        guard let conv = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw AudioCaptureError.formatConversionFailed
        }
        self.converter = conv

        let bufferSize: AVAudioFrameCount = AVAudioFrameCount(inputFormat.sampleRate * Constants.Audio.chunkDuration)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processTap(buffer: buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRunning = true
            Logger.audio.info("Audio capture started")
        } catch {
            inputNode.removeTap(onBus: 0)
            throw AudioCaptureError.engineStartFailed(error)
        }
    }

    func stopCapture() {
        guard isRunning else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isRunning = false
        Logger.audio.info("Audio capture stopped")
    }

    // MARK: - Private

    private func processTap(buffer: AVAudioPCMBuffer) {
        // Report audio level
        let level = buffer.rmsLevel
        onLevelUpdate?(level)

        // Convert to 16 kHz mono float32
        guard let converter = converter else { return }

        let inputFrameCount = buffer.frameLength
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(inputFrameCount) * ratio) + 1

        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else { return }

        var error: NSError?
        var inputConsumed = false

        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            inputConsumed = true
            outStatus.pointee = .haveData
            return buffer
        }

        if status == .error || error != nil {
            Logger.audio.error("Audio conversion error: \(error?.localizedDescription ?? "unknown")")
            return
        }

        let samples = outputBuffer.float32Samples
        if !samples.isEmpty {
            onAudioBuffer?(samples)
        }
    }
}
