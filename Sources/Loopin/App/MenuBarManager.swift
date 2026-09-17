import SwiftUI
import AppKit

// MARK: - MenuBarManager
@MainActor
public final class MenuBarManager: NSObject, @unchecked Sendable {
    public static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    
    public func setupMenuBar() {
        guard statusItem == nil else { return }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Logtrackin")
            button.imagePosition = .imageOnly
            button.title = ""
        }
        
        let menu = NSMenu()
        
        let logItem = NSMenuItem(title: "Log Activity Now...", action: #selector(triggerLogPrompt), keyEquivalent: "l")
        logItem.target = self
        menu.addItem(logItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let openItem = NSMenuItem(title: "Show Logtrackin Window", action: #selector(showMainWindow), keyEquivalent: "o")
        openItem.target = self
        menu.addItem(openItem)
        
        let focusTimerItem = NSMenuItem(title: "Open Pomodoro Timer", action: #selector(openFocusTimerWindow), keyEquivalent: "t")
        focusTimerItem.target = self
        menu.addItem(focusTimerItem)
        
        let stickyTodoItem = NSMenuItem(title: "Open Quick To-Do List", action: #selector(openStickyTodoWindow), keyEquivalent: "d")
        stickyTodoItem.target = self
        menu.addItem(stickyTodoItem)
        
        let pomodoroItem = NSMenuItem(title: "Toggle Background Focus", action: #selector(togglePomodoro), keyEquivalent: "p")
        pomodoroItem.target = self
        menu.addItem(pomodoroItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let tutorialItem = NSMenuItem(title: "Logtrackin Tutorial & Guide...", action: #selector(openTutorialWindow), keyEquivalent: "")
        tutorialItem.target = self
        menu.addItem(tutorialItem)
        
        let quitItem = NSMenuItem(title: "Quit Logtrackin", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc private func triggerLogPrompt() {
        AppState.shared.showFloatingLoggingPanel = true
    }
    
    @objc private func openFocusTimerWindow() {
        FocusTimerWindowController.shared.show()
    }
    
    @objc private func openStickyTodoWindow() {
        StickyTodoWindowController.shared.show()
    }
    
    @objc private func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title == "Logtrackin" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func togglePomodoro() {
        AppState.shared.isPomodoroRunning.toggle()
    }
    
    @objc private func openTutorialWindow() {
        TutorialWindowController.shared.show()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
