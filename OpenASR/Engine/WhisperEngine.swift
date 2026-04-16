import Foundation
import OSLog

enum WhisperEngineError: LocalizedError {
    case modelNotLoaded
    case loadFailed(String)
    case transcriptionFailed

    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "No model is loaded. Please download and select a model first."
        case .loadFailed(let reason):
            return "Failed to load model: \(reason)"
        case .transcriptionFailed:
            return "Transcription failed. The audio may be too short or corrupted."
        }
    }
}

/// Swift actor that serializes all whisper.cpp inference calls.
/// whisper_context is NOT thread-safe; actor isolation enforces serial access.
actor WhisperEngine {
    private var bridge: WhisperBridge?
    private(set) var loadedModel: WhisperModel?

    // MARK: - Model Loading

    func load(model: WhisperModel) async throws {
        let url = await MainActor.run { ModelManager.shared.modelFileURL(for: model) }
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WhisperEngineError.loadFailed("Model file not found at \(url.path). Please download it first.")
        }

        Logger.engine.info("Loading model: \(model.displayName)")

        // Load on a background thread to avoid blocking the actor
        let path = url.path
        let newBridge: WhisperBridge? = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let b = WhisperBridge(modelPath: path) {
                    continuation.resume(returning: b)
                } else {
                    continuation.resume(throwing: WhisperEngineError.loadFailed("WhisperBridge init returned nil"))
                }
            }
        }

        self.bridge = newBridge
        self.loadedModel = model
        Logger.engine.info("Model loaded: \(model.displayName)")
    }

    func unload() {
        bridge = nil
        loadedModel = nil
        Logger.engine.info("Model unloaded")
    }

    var isLoaded: Bool { bridge?.isLoaded ?? false }

    // MARK: - Transcription

    /// Transcribe Float32 PCM samples at 16 kHz mono.
    func transcribe(
        samples: [Float],
        language: String = "auto",
        translate: Bool = false
    ) async throws -> [TranscriptionSegment] {
        guard let bridge = bridge, bridge.isLoaded else {
            throw WhisperEngineError.modelNotLoaded
        }

        guard !samples.isEmpty else { return [] }

        Logger.engine.debug("Transcribing \(samples.count) samples (\(String(format: "%.1f", Double(samples.count) / 16000.0))s)")

        let result: [TranscriptionSegment] = try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let segments = samples.withUnsafeBufferPointer { ptr -> [WhisperSegment]? in
                    guard let base = ptr.baseAddress else { return nil }
                    return bridge.transcribePCMSamples(base, count: samples.count, language: language, translate: translate)
                }

                if let segs = segments {
                    let mapped = segs.map { seg in
                        TranscriptionSegment(
                            text: seg.text,
                            startMs: Int(seg.startMs),
                            endMs: Int(seg.endMs),
                            confidence: seg.confidence
                        )
                    }
                    continuation.resume(returning: mapped)
                } else {
                    continuation.resume(throwing: WhisperEngineError.transcriptionFailed)
                }
            }
        }

        Logger.engine.debug("Transcription done: \(result.count) segments")
        return result
    }
}
