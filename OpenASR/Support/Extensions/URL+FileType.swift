import Foundation
import UniformTypeIdentifiers

extension URL {
    static let supportedAudioExtensions: Set<String> = [
        "mp3", "wav", "m4a", "mp4", "ogg", "flac", "webm", "aac", "aiff", "caf", "opus", "wma"
    ]

    var isAudioFile: Bool {
        Self.supportedAudioExtensions.contains(pathExtension.lowercased())
    }

    var fileSize: Int64? {
        (try? resourceValues(forKeys: [.fileSizeKey]))?.fileSize.map(Int64.init)
    }
}
