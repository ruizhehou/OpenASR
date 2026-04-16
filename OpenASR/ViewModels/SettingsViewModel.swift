import Foundation
import SwiftUI
import ServiceManagement

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage(Constants.UserDefaults.selectedModel)
    var selectedModelRaw: String = WhisperModel.base.rawValue

    @AppStorage(Constants.UserDefaults.transcriptionLanguage)
    var language: String = "auto"

    @AppStorage(Constants.UserDefaults.autoCopyToClipboard)
    var autoCopyToClipboard: Bool = true

    @AppStorage(Constants.UserDefaults.launchAtLogin)
    var launchAtLogin: Bool = false {
        didSet { applyLaunchAtLoginChange() }
    }

    @AppStorage(Constants.UserDefaults.showTimestamps)
    var showTimestamps: Bool = false

    @AppStorage(Constants.UserDefaults.translateToEnglish)
    var translateToEnglish: Bool = false

    var selectedModel: WhisperModel {
        get { WhisperModel(rawValue: selectedModelRaw) ?? .base }
        set { selectedModelRaw = newValue.rawValue }
    }

    static let supportedLanguages: [(code: String, name: String)] = [
        ("auto", "Auto Detect"),
        ("en", "English"),
        ("zh", "Chinese"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("fr", "French"),
        ("de", "German"),
        ("es", "Spanish"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("ru", "Russian"),
        ("ar", "Arabic"),
        ("hi", "Hindi"),
        ("nl", "Dutch"),
        ("pl", "Polish"),
        ("tr", "Turkish"),
    ]

    private func applyLaunchAtLoginChange() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently fail — launch at login is a convenience feature
            }
        }
    }
}
