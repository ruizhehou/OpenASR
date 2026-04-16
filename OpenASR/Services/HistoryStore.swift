import Foundation
import OSLog

enum ExportFormat {
    case plainText
    case srt
    case vtt
    case json

    var fileExtension: String {
        switch self {
        case .plainText: return "txt"
        case .srt: return "srt"
        case .vtt: return "vtt"
        case .json: return "json"
        }
    }

    var displayName: String {
        switch self {
        case .plainText: return "Plain Text (.txt)"
        case .srt: return "SubRip (.srt)"
        case .vtt: return "WebVTT (.vtt)"
        case .json: return "JSON (.json)"
        }
    }
}

final class HistoryStore {
    static let shared = HistoryStore()

    private let storeURL = Constants.Paths.historyFile
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let queue = DispatchQueue(label: "com.openasr.historystore", qos: .utility)

    private init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        createDirectoryIfNeeded()
    }

    // MARK: - CRUD

    func save(_ record: TranscriptionRecord) throws {
        var records = (try? loadAll()) ?? []
        records.insert(record, at: 0)
        try persist(records)
        Logger.history.info("Saved record: \(record.id)")
    }

    func loadAll() throws -> [TranscriptionRecord] {
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return [] }
        let data = try Data(contentsOf: storeURL)
        return try decoder.decode([TranscriptionRecord].self, from: data)
    }

    func delete(id: UUID) throws {
        var records = try loadAll()
        records.removeAll { $0.id == id }
        try persist(records)
    }

    func deleteAll() throws {
        try persist([])
    }

    func search(query: String) throws -> [TranscriptionRecord] {
        let records = try loadAll()
        guard !query.isEmpty else { return records }
        let lowered = query.lowercased()
        return records.filter { $0.fullText.lowercased().contains(lowered) }
    }

    // MARK: - Export

    func export(records: [TranscriptionRecord], format: ExportFormat, to url: URL) throws {
        let content: String
        switch format {
        case .plainText:
            content = exportPlainText(records)
        case .srt:
            content = exportSRT(records)
        case .vtt:
            content = exportVTT(records)
        case .json:
            let data = try encoder.encode(records)
            try data.write(to: url, options: .atomic)
            return
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Private

    private func persist(_ records: [TranscriptionRecord]) throws {
        let data = try encoder.encode(records)
        try data.write(to: storeURL, options: .atomic)
    }

    private func createDirectoryIfNeeded() {
        try? FileManager.default.createDirectory(
            at: Constants.Paths.appSupport,
            withIntermediateDirectories: true
        )
    }

    private func exportPlainText(_ records: [TranscriptionRecord]) -> String {
        records.map { record in
            let header = "[\(record.createdAt.shortDateTimeString)] \(record.source.displayName)"
            let body = record.fullText
            return "\(header)\n\(body)\n"
        }.joined(separator: "\n---\n\n")
    }

    private func exportSRT(_ records: [TranscriptionRecord]) -> String {
        var lines: [String] = []
        var index = 1
        for record in records {
            for seg in record.segments {
                lines.append(String(index))
                lines.append(seg.srtEntry)
                lines.append("")
                index += 1
            }
        }
        return lines.joined(separator: "\n")
    }

    private func exportVTT(_ records: [TranscriptionRecord]) -> String {
        var lines = ["WEBVTT", ""]
        for record in records {
            for seg in record.segments {
                lines.append(seg.vttEntry)
                lines.append("")
            }
        }
        return lines.joined(separator: "\n")
    }
}
