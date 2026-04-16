import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.openasr.app"

    static let engine = Logger(subsystem: subsystem, category: "Engine")
    static let audio = Logger(subsystem: subsystem, category: "Audio")
    static let modelManager = Logger(subsystem: subsystem, category: "ModelManager")
    static let history = Logger(subsystem: subsystem, category: "History")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let bridge = Logger(subsystem: subsystem, category: "Bridge")
}
