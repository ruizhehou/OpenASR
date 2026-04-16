import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [TranscriptionRecord] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let store = HistoryStore.shared

    var filteredRecords: [TranscriptionRecord] {
        guard !searchQuery.isEmpty else { return records }
        let q = searchQuery.lowercased()
        return records.filter {
            $0.fullText.lowercased().contains(q) ||
            $0.source.displayName.lowercased().contains(q)
        }
    }

    func load() {
        isLoading = true
        do {
            records = try store.loadAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func delete(_ record: TranscriptionRecord) {
        do {
            try store.delete(id: record.id)
            records.removeAll { $0.id == record.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAll() {
        do {
            try store.deleteAll()
            records.removeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func export(records: [TranscriptionRecord], format: ExportFormat, to url: URL) {
        do {
            try store.export(records: records, format: format, to: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
