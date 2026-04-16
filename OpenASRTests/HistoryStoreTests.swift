import XCTest
@testable import OpenASR

final class HistoryStoreTests: XCTestCase {
    var store: HistoryStore!
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        // Use a temp directory for tests
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        store = HistoryStore.shared
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testSaveAndLoad() throws {
        let record = makeRecord()
        try store.save(record)
        let loaded = try store.loadAll()
        XCTAssertTrue(loaded.contains { $0.id == record.id })
        try store.delete(id: record.id)
    }

    func testDelete() throws {
        let record = makeRecord()
        try store.save(record)
        try store.delete(id: record.id)
        let loaded = try store.loadAll()
        XCTAssertFalse(loaded.contains { $0.id == record.id })
    }

    func testSearch() throws {
        let record = makeRecord(text: "Hello world unique phrase")
        try store.save(record)
        let results = try store.search(query: "unique phrase")
        XCTAssertTrue(results.contains { $0.id == record.id })
        try store.delete(id: record.id)
    }

    func testExportPlainText() throws {
        let record = makeRecord(text: "Test export content")
        let exportURL = tempDir.appendingPathComponent("export.txt")
        try store.export(records: [record], format: .plainText, to: exportURL)
        let content = try String(contentsOf: exportURL, encoding: .utf8)
        XCTAssertTrue(content.contains("Test export content"))
    }

    func testExportSRT() throws {
        let record = makeRecord(text: "SRT test", startMs: 0, endMs: 5000)
        let exportURL = tempDir.appendingPathComponent("export.srt")
        try store.export(records: [record], format: .srt, to: exportURL)
        let content = try String(contentsOf: exportURL, encoding: .utf8)
        XCTAssertTrue(content.contains("-->"))
        XCTAssertTrue(content.contains("SRT test"))
    }

    // MARK: - Helpers

    private func makeRecord(text: String = "Test transcription", startMs: Int = 0, endMs: Int = 3000) -> TranscriptionRecord {
        let segment = TranscriptionSegment(text: text, startMs: startMs, endMs: endMs)
        return TranscriptionRecord(
            source: .microphone,
            modelUsed: .base,
            language: "en",
            segments: [segment],
            duration: 3.0
        )
    }
}
