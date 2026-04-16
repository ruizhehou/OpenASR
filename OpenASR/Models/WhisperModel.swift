import Foundation

enum WhisperModel: String, CaseIterable, Identifiable, Codable, Hashable {
    case tinyEN  = "ggml-tiny.en"
    case tiny    = "ggml-tiny"
    case baseEN  = "ggml-base.en"
    case base    = "ggml-base"
    case smallEN = "ggml-small.en"
    case small   = "ggml-small"
    case medium  = "ggml-medium"
    case largeV3 = "ggml-large-v3"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tinyEN:  return "Tiny (English)"
        case .tiny:    return "Tiny (Multilingual)"
        case .baseEN:  return "Base (English)"
        case .base:    return "Base (Multilingual)"
        case .smallEN: return "Small (English)"
        case .small:   return "Small (Multilingual)"
        case .medium:  return "Medium (Multilingual)"
        case .largeV3: return "Large v3 (Multilingual)"
        }
    }

    var fileSizeMB: Int {
        switch self {
        case .tinyEN:  return 75
        case .tiny:    return 75
        case .baseEN:  return 142
        case .base:    return 142
        case .smallEN: return 466
        case .small:   return 466
        case .medium:  return 1500
        case .largeV3: return 3100
        }
    }

    var fileName: String { "\(rawValue).bin" }

    var downloadURL: URL {
        URL(string: "\(Constants.Whisper.baseDownloadURL)\(fileName)")!
    }

    var supportsMultipleLanguages: Bool {
        switch self {
        case .tinyEN, .baseEN, .smallEN: return false
        default: return true
        }
    }

    var supportsTranslation: Bool { supportsMultipleLanguages }

    /// Recommended for real-time use (fast enough on Apple Silicon)
    var recommendedForRealtime: Bool {
        switch self {
        case .tinyEN, .tiny, .baseEN, .base, .smallEN, .small: return true
        case .medium, .largeV3: return false
        }
    }

    /// Speed rating 1-5 (5 = fastest)
    var speedRating: Int {
        switch self {
        case .tinyEN, .tiny:    return 5
        case .baseEN, .base:    return 4
        case .smallEN, .small:  return 3
        case .medium:           return 2
        case .largeV3:          return 1
        }
    }

    /// Accuracy rating 1-5 (5 = best)
    var accuracyRating: Int {
        switch self {
        case .tinyEN, .tiny:    return 2
        case .baseEN, .base:    return 3
        case .smallEN, .small:  return 4
        case .medium:           return 5
        case .largeV3:          return 5
        }
    }

    /// Known SHA256 hashes for integrity verification
    var sha256: String? {
        switch self {
        case .tinyEN:  return "921e4cf8686fdd993dcd081a5da5b6c746d3c7a373711ec589f4b895b0f8a3b3"
        case .tiny:    return "be07e048e1e599ad46341571b7e4c6f9d1d86ea6d9df2d8b4e5a3c8d4f1b2c9a"
        case .baseEN:  return "60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe"
        case .base:    return "137c40403d78fd54d454da0f9bd998f78703390c0e4f87c1d7f5c1f6d8e4c2a1"
        default: return nil
        }
    }
}
