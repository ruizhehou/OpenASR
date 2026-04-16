import AppKit

struct ClipboardService {
    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    static var currentString: String? {
        NSPasteboard.general.string(forType: .string)
    }
}
