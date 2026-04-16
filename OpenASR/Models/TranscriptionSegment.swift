import Foundation

struct TranscriptionSegment: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let text: String
    let startMs: Int
    let endMs: Int
    let confidence: Float

    init(id: UUID = UUID(), text: String, startMs: Int, endMs: Int, confidence: Float = 1.0) {
        self.id = id
        self.text = text
        self.startMs = startMs
        self.endMs = endMs
        self.confidence = confidence
    }

    var startTime: TimeInterval { TimeInterval(startMs) / 1000.0 }
    var endTime: TimeInterval { TimeInterval(endMs) / 1000.0 }
    var duration: TimeInterval { endTime - startTime }

    var formattedTimestamp: String {
        "[\(startTime.srtTimestamp) --> \(endTime.srtTimestamp)]"
    }

    var srtEntry: String {
        "\(startTime.srtTimestamp) --> \(endTime.srtTimestamp)\n\(text.trimmingCharacters(in: .whitespaces))"
    }

    var vttEntry: String {
        let start = startTime.srtTimestamp.replacingOccurrences(of: ",", with: ".")
        let end = endTime.srtTimestamp.replacingOccurrences(of: ",", with: ".")
        return "\(start) --> \(end)\n\(text.trimmingCharacters(in: .whitespaces))"
    }
}
