import AVFoundation

extension AVAudioPCMBuffer {
    /// Extract interleaved Float32 samples from the buffer
    var float32Samples: [Float] {
        guard let channelData = floatChannelData else { return [] }
        let frameCount = Int(frameLength)
        let channelCount = Int(format.channelCount)

        if channelCount == 1 {
            return Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))
        }

        // Mix down to mono
        var mono = [Float](repeating: 0, count: frameCount)
        let scale = 1.0 / Float(channelCount)
        for ch in 0..<channelCount {
            let ptr = channelData[ch]
            for i in 0..<frameCount {
                mono[i] += ptr[i] * scale
            }
        }
        return mono
    }

    /// RMS level in range [0, 1]
    var rmsLevel: Float {
        guard let channelData = floatChannelData else { return 0 }
        let frameCount = Int(frameLength)
        guard frameCount > 0 else { return 0 }
        var sum: Float = 0
        let ptr = channelData[0]
        for i in 0..<frameCount {
            sum += ptr[i] * ptr[i]
        }
        return sqrt(sum / Float(frameCount))
    }
}
