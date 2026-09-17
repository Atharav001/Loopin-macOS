import SwiftUI
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        setupDockIcon()
        Task { @MainActor in
            MenuBarManager.shared.setupMenuBar()
            NotificationService.shared.requestAuthorization()
        }
    }
    
    @MainActor
    private func setupDockIcon() {
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let iconImg = NSImage(contentsOfFile: iconPath) {
            NSApplication.shared.applicationIconImage = iconImg
            return
        }
        
        let localPaths = ["assets/logo.png", "assets/AppIcon.icns", "../assets/logo.png"]
        for p in localPaths {
            if FileManager.default.fileExists(atPath: p),
               let iconImg = NSImage(contentsOfFile: p) {
                NSApplication.shared.applicationIconImage = iconImg
                return
            }
        }
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
public struct LoopinApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        Window("Logtrackin", id: "main") {
            ContentView()
        }
        .defaultSize(width: 1180, height: 760)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {}
            CommandGroup(after: .appInfo) {
                Button("Preferences...") {
                    // Open preferences/settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandMenu("Focus & Tasks") {
                Button("Open Pomodoro Timer") {
                    FocusTimerWindowController.shared.show()
                }
                .keyboardShortcut("t", modifiers: [.command])
                
                Button("Open Quick To-Do Sticky Note") {
                    StickyTodoWindowController.shared.show()
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Button("Logtrackin Tutorial & Guide") {
                    TutorialWindowController.shared.show()
                }
                .keyboardShortcut("?", modifiers: [.command])
                
                Divider()
                
                Button("GitHub Documentation") {
                    if let url = URL(string: "https://github.com/Atharav001/Logtrackin") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
