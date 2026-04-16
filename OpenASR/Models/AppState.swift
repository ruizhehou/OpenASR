import Foundation
import Combine

enum TranscriptionState: Equatable {
    case idle
    case recording
    case processingFile(progress: Double)
    case error(String)

    var isActive: Bool {
        switch self {
        case .recording, .processingFile: return true
        default: return false
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var transcriptionState: TranscriptionState = .idle
    @Published var currentSegments: [TranscriptionSegment] = []
    @Published var isRecording: Bool = false
    @Published var selectedModel: WhisperModel = .base
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?
    @Published var recordingDuration: TimeInterval = 0

    private init() {}
}
