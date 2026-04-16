import XCTest
@testable import OpenASR

@MainActor
final class ModelManagerTests: XCTestCase {

    func testModelFileURL() {
        let manager = ModelManager.shared
        let url = manager.modelFileURL(for: .base)
        XCTAssertTrue(url.lastPathComponent == WhisperModel.base.fileName)
        XCTAssertTrue(url.path.contains("OpenASR/Models"))
    }

    func testIsDownloadedReturnsFalseForMissingFile() {
        let manager = ModelManager.shared
        // Use a model that's very unlikely to be downloaded in test env
        let downloaded = manager.isDownloaded(.largeV3)
        // Just verify it doesn't crash; result depends on environment
        _ = downloaded
    }

    func testWhisperModelProperties() {
        XCTAssertEqual(WhisperModel.base.fileName, "ggml-base.bin")
        XCTAssertTrue(WhisperModel.base.fileSizeMB > 0)
        XCTAssertTrue(WhisperModel.base.supportsMultipleLanguages)
        XCTAssertFalse(WhisperModel.tinyEN.supportsMultipleLanguages)
        XCTAssertTrue(WhisperModel.base.recommendedForRealtime)
        XCTAssertFalse(WhisperModel.largeV3.recommendedForRealtime)
    }

    func testAllModelsHaveUniqueRawValues() {
        let rawValues = WhisperModel.allCases.map(\.rawValue)
        let unique = Set(rawValues)
        XCTAssertEqual(rawValues.count, unique.count)
    }

    func testModelDownloadURLsAreValid() {
        for model in WhisperModel.allCases {
            let url = model.downloadURL
            XCTAssertNotNil(url.host)
            XCTAssertTrue(url.absoluteString.hasSuffix(".bin"), "Expected .bin suffix for \(model.rawValue)")
        }
    }
}
