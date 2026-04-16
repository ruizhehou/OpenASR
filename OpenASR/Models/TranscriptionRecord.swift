import Foundation

enum RecordSource: Codable, Equatable {
    case microphone
    case file(fileName: String)

    var displayName: String {
        switch self {
        case .microphone: return "Microphone"
        case .file(let name): return name
        }
    }

    var icon: String {
        switch self {
        case .microphone: return "mic.fill"
        case .file: return "doc.fill"
        }
    }
}

struct TranscriptionRecord: Identifiable, Codable, Hashable {
    static func == (lhs: TranscriptionRecord, rhs: TranscriptionRecord) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    let id: UUID
    let createdAt: Date
    let source: RecordSource
    let modelUsed: WhisperModel
    let language: String
    var segments: [TranscriptionSegment]
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        source: RecordSource,
        modelUsed: WhisperModel,
        language: String,
        segments: [TranscriptionSegment],
        duration: TimeInterval
    ) {
        self.id = id
        self.createdAt = createdAt
        self.source = source
        self.modelUsed = modelUsed
        self.language = language
        self.segments = segments
        self.duration = duration
    }

    var fullText: String {
        segments.map { $0.text.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var preview: String {
        let text = fullText
        if text.count <= 80 { return text }
        return String(text.prefix(80)) + "..."
    }
}
