import SwiftUI
import UniformTypeIdentifiers

struct HistoryView: View {
    @StateObject private var vm = HistoryViewModel()
    @State private var showExportPanel = false
    @State private var exportFormat: ExportFormat = .plainText
    @State private var selectedRecord: TranscriptionRecord?

    var body: some View {
        VStack(spacing: 0) {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.filteredRecords.isEmpty {
                emptyState
            } else {
                List(vm.filteredRecords, selection: $selectedRecord) { record in
                    HistoryRowView(record: record)
                        .tag(record)
                        .contextMenu {
                            Button("Copy Text") {
                                ClipboardService.copy(record.fullText)
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                vm.delete(record)
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $vm.searchQuery, prompt: "Search transcriptions...")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    ForEach([ExportFormat.plainText, .srt, .vtt, .json], id: \.fileExtension) { fmt in
                        Button(fmt.displayName) {
                            exportFormat = fmt
                            showExportPanel = true
                        }
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .disabled(vm.filteredRecords.isEmpty)

                Button(role: .destructive) {
                    vm.deleteAll()
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
                .disabled(vm.records.isEmpty)
            }
        }
        .onAppear { vm.load() }
        .fileExporter(
            isPresented: $showExportPanel,
            document: TranscriptionExportDocument(records: vm.filteredRecords, format: exportFormat),
            contentType: exportFormat == .json ? .json : .plainText,
            defaultFilename: "OpenASR-Export.\(exportFormat.fileExtension)"
        ) { _ in }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(vm.searchQuery.isEmpty ? "No transcription history yet" : "No results for \"\(vm.searchQuery)\"")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct HistoryRowView: View {
    let record: TranscriptionRecord

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: record.source.icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(record.source.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(record.createdAt.shortDateTimeString)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Text(record.preview)
                    .font(.body)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(record.modelUsed.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                    Text(record.duration.hhmmss)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// FileDocument wrapper for export
struct TranscriptionExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .json] }

    let records: [TranscriptionRecord]
    let format: ExportFormat

    init(records: [TranscriptionRecord], format: ExportFormat) {
        self.records = records
        self.format = format
    }

    init(configuration: ReadConfiguration) throws {
        records = []
        format = .plainText
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let store = HistoryStore.shared
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(format.fileExtension)
        try store.export(records: records, format: format, to: tempURL)
        let data = try Data(contentsOf: tempURL)
        return FileWrapper(regularFileWithContents: data)
    }
}
