import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var hotkeyService: HotkeyService?
    private var mainWindowObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupPopover()
        setupHotkey()
        setupMainWindowObserver()

        NSApp.setActivationPolicy(.regular)
        openMainWindow()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "OpenASR")
            button.image?.isTemplate = true
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(
            width: Constants.UI.menuBarPopoverWidth,
            height: Constants.UI.menuBarPopoverHeight
        )
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarView())
        self.popover = popover
    }

    // MARK: - Main Window

    private func setupMainWindowObserver() {
        mainWindowObserver = NotificationCenter.default.addObserver(
            forName: .openMainWindow,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.openMainWindow()
        }
    }

    func openMainWindow() {
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0,
                                width: Constants.UI.mainWindowMinWidth,
                                height: Constants.UI.mainWindowMinHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "OpenASR"
        window.center()
        window.contentViewController = NSHostingController(rootView: MainWindowView())
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: Constants.UI.mainWindowMinWidth,
                                height: Constants.UI.mainWindowMinHeight)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.mainWindow = window
    }

    // MARK: - Hotkey

    private func setupHotkey() {
        let service = HotkeyService()
        service.onHotkeyPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.togglePopover()
            }
        }
        service.register()
        self.hotkeyService = service
    }
}
