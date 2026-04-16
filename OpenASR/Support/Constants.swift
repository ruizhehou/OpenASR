import Foundation

enum Constants {
    enum App {
        static let name = "OpenASR"
        static let bundleIdentifier = "com.openasr.app"
        static let version = "1.0.0"
    }

    enum UserDefaults {
        static let selectedModel = "selectedModel"
        static let transcriptionLanguage = "transcriptionLanguage"
        static let autoCopyToClipboard = "autoCopyToClipboard"
        static let launchAtLogin = "launchAtLogin"
        static let showTimestamps = "showTimestamps"
        static let translateToEnglish = "translateToEnglish"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hotkeyKey = "hotkeyKey"
    }

    enum Paths {
        static var appSupport: URL {
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("OpenASR")
        }
        static var modelsDirectory: URL {
            appSupport.appendingPathComponent("Models")
        }
        static var historyFile: URL {
            appSupport.appendingPathComponent("history.json")
        }
    }

    enum Audio {
        static let sampleRate: Double = 16000
        static let chunkDuration: Double = 1.0  // seconds per chunk
        static let windowDuration: Double = 30.0 // sliding window size
        static let samplesPerChunk: Int = 16000
        static let samplesPerWindow: Int = 480000
    }

    enum Whisper {
        static let baseDownloadURL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/"
    }

    enum UI {
        static let menuBarPopoverWidth: CGFloat = 320
        static let menuBarPopoverHeight: CGFloat = 480
        static let mainWindowMinWidth: CGFloat = 700
        static let mainWindowMinHeight: CGFloat = 500
    }
}
