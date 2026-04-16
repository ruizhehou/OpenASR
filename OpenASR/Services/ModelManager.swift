import Foundation
import OSLog
import CryptoKit

@MainActor
final class ModelManager: ObservableObject {
    static let shared = ModelManager()

    @Published var downloadedModels: Set<WhisperModel> = []
    @Published var downloadProgress: [WhisperModel: Double] = [:]
    @Published var downloadError: [WhisperModel: String] = [:]

    private var activeTasks: [WhisperModel: URLSessionDownloadTask] = [:]
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 3600
        session = URLSession(configuration: config)
        createDirectoriesIfNeeded()
        refreshDownloadedModels()
    }

    // MARK: - Paths

    func modelFileURL(for model: WhisperModel) -> URL {
        Constants.Paths.modelsDirectory.appendingPathComponent(model.fileName)
    }

    func isDownloaded(_ model: WhisperModel) -> Bool {
        FileManager.default.fileExists(atPath: modelFileURL(for: model).path)
    }

    func refreshDownloadedModels() {
        downloadedModels = Set(WhisperModel.allCases.filter { isDownloaded($0) })
    }

    // MARK: - Download

    func download(_ model: WhisperModel) async throws {
        guard !isDownloaded(model) else { return }
        guard activeTasks[model] == nil else { return }

        downloadProgress[model] = 0
        downloadError.removeValue(forKey: model)

        Logger.modelManager.info("Downloading model: \(model.displayName) from \(model.downloadURL.absoluteString)")

        let tempURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let task = session.downloadTask(with: model.downloadURL) { [weak self] localURL, response, error in
                Task { @MainActor [weak self] in
                    self?.activeTasks.removeValue(forKey: model)
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let url = localURL {
                        continuation.resume(returning: url)
                    } else {
                        continuation.resume(throwing: URLError(.badServerResponse))
                    }
                }
            }

            // Track progress via observation
            let observation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                Task { @MainActor [weak self] in
                    self?.downloadProgress[model] = progress.fractionCompleted
                }
            }
            _ = observation  // retain

            activeTasks[model] = task
            task.resume()
        }

        // Move to final location
        let destURL = modelFileURL(for: model)
        try? FileManager.default.removeItem(at: destURL)
        try FileManager.default.moveItem(at: tempURL, to: destURL)

        downloadProgress.removeValue(forKey: model)
        downloadedModels.insert(model)
        Logger.modelManager.info("Model downloaded: \(model.displayName)")
    }

    func cancelDownload(_ model: WhisperModel) {
        activeTasks[model]?.cancel()
        activeTasks.removeValue(forKey: model)
        downloadProgress.removeValue(forKey: model)
    }

    func delete(_ model: WhisperModel) throws {
        let url = modelFileURL(for: model)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        downloadedModels.remove(model)
        Logger.modelManager.info("Model deleted: \(model.displayName)")
    }

    // MARK: - Private

    private func createDirectoriesIfNeeded() {
        try? FileManager.default.createDirectory(
            at: Constants.Paths.modelsDirectory,
            withIntermediateDirectories: true
        )
    }
}
