import SwiftUI
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        Task { @MainActor in
            MenuBarManager.shared.setupMenuBar()
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
            CommandGroup(replacing: .help) {
                Button("Logtrackin Help") {
                    if let url = URL(string: "https://github.com/Atharav001/Logtrackin") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
