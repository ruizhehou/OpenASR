import XCTest
@testable import OpenASR

final class TranscriptionSegmentTests: XCTestCase {

    func testTimestampFormatting() {
        let seg = TranscriptionSegment(text: "Hello", startMs: 1000, endMs: 5500)
        // startMs=1000 → 0:01.000, endMs=5500 → 0:05.500
        XCTAssertTrue(seg.srtEntry.contains("-->"))
        XCTAssertTrue(seg.srtEntry.contains("Hello"))
    }

    func testVTTEntryUsesDotsNotCommas() {
        let seg = TranscriptionSegment(text: "Test", startMs: 500, endMs: 2000)
        XCTAssertFalse(seg.vttEntry.contains(","))
        XCTAssertTrue(seg.vttEntry.contains("."))
    }

    func testDuration() {
        let seg = TranscriptionSegment(text: "x", startMs: 1000, endMs: 4000)
        XCTAssertEqual(seg.duration, 3.0, accuracy: 0.001)
    }

    func testFullTextFromRecord() {
        let segments = [
            TranscriptionSegment(text: "Hello", startMs: 0, endMs: 1000),
            TranscriptionSegment(text: "world", startMs: 1000, endMs: 2000),
        ]
        let record = TranscriptionRecord(
            source: .microphone,
            modelUsed: .base,
            language: "en",
            segments: segments,
            duration: 2.0
        )
        XCTAssertEqual(record.fullText, "Hello world")
    }

    func testRecordPreviewTruncates() {
        let longText = String(repeating: "A", count: 200)
        let seg = TranscriptionSegment(text: longText, startMs: 0, endMs: 10000)
        let record = TranscriptionRecord(
            source: .file(fileName: "test.mp3"),
            modelUsed: .tiny,
            language: "en",
            segments: [seg],
            duration: 10.0
        )
        XCTAssertTrue(record.preview.count <= 83) // 80 + "..."
    }

    func testTimeIntervalFormatting() {
        let interval: TimeInterval = 3661.5
        XCTAssertEqual(interval.hhmmss, "1:01:01")
    }

    func testShortTimeIntervalFormatting() {
        let interval: TimeInterval = 75.0
        XCTAssertEqual(interval.hhmmss, "01:15")
    }
}
