import AVFoundation
import OSLog

enum FileTranscriptionError: LocalizedError {
    case unsupportedFormat
    case noAudioTrack
    case readerFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            return "This file format is not supported. Please use MP3, WAV, M4A, MP4, FLAC, or OGG."
        case .noAudioTrack:
            return "No audio track found in the selected file."
        case .readerFailed(let error):
            return "Failed to read audio file: \(error?.localizedDescription ?? "unknown error")"
        }
    }
}

/// Transcribes audio/video files by extracting PCM audio and chunking for whisper.cpp.
final class FileTranscriptionEngine {

    func transcribe(
        url: URL,
        engine: WhisperEngine,
        language: String,
        translate: Bool,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> TranscriptionRecord {
        guard url.isAudioFile else {
            throw FileTranscriptionError.unsupportedFormat
        }

        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        // Get audio track
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = tracks.first else {
            throw FileTranscriptionError.noAudioTrack
        }

        // Set up reader with 16kHz mono float32 output
        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: Constants.Audio.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 32,
            AVLinearPCMIsFloatKey: true,
            AVLinearPCMIsNonInterleaved: false
        ]

        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        trackOutput.alwaysCopiesSampleData = false
        reader.add(trackOutput)
        reader.startReading()

        // Read all samples
        var allSamples: [Float] = []
        allSamples.reserveCapacity(Int(durationSeconds * Constants.Audio.sampleRate) + 1000)

        while reader.status == .reading {
            guard let sampleBuffer = trackOutput.copyNextSampleBuffer() else { break }
            guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { continue }

            let length = CMBlockBufferGetDataLength(blockBuffer)
            var data = [UInt8](repeating: 0, count: length)
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: &data)

            // Convert bytes to Float32
            let floatCount = length / MemoryLayout<Float>.size
            data.withUnsafeBytes { rawPtr in
                let floatPtr = rawPtr.bindMemory(to: Float.self)
                allSamples.append(contentsOf: floatPtr.prefix(floatCount))
            }
        }

        if reader.status == .failed {
            throw FileTranscriptionError.readerFailed(reader.error)
        }

        Logger.engine.info("Read \(allSamples.count) samples (\(String(format: "%.1f", Double(allSamples.count)/16000.0))s) from \(url.lastPathComponent)")

        // Chunk into 30-second windows and transcribe
        let chunkSize = Constants.Audio.samplesPerWindow
        let totalChunks = max(1, Int(ceil(Double(allSamples.count) / Double(chunkSize))))
        var allSegments: [TranscriptionSegment] = []

        for chunkIndex in 0..<totalChunks {
            let start = chunkIndex * chunkSize
            let end = min(start + chunkSize, allSamples.count)
            let chunk = Array(allSamples[start..<end])

            let chunkOffsetMs = Int(Double(start) / Constants.Audio.sampleRate * 1000.0)

            let segments = try await engine.transcribe(
                samples: chunk,
                language: language,
                translate: translate
            )

            // Adjust timestamps by chunk offset
            let adjusted = segments.map { seg in
                TranscriptionSegment(
                    text: seg.text,
                    startMs: seg.startMs + chunkOffsetMs,
                    endMs: seg.endMs + chunkOffsetMs,
                    confidence: seg.confidence
                )
            }
            allSegments.append(contentsOf: adjusted)

            progress(Double(chunkIndex + 1) / Double(totalChunks))
        }

        let model = await engine.loadedModel ?? .base

        return TranscriptionRecord(
            source: .file(fileName: url.lastPathComponent),
            modelUsed: model,
            language: language,
            segments: allSegments,
            duration: durationSeconds
        )
    }
}
