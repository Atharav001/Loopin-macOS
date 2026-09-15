import AppKit

// MARK: - SoundManager
@MainActor
public final class SoundManager: @unchecked Sendable {
    public static let shared = SoundManager()
    
    public enum SoundType {
        case prompt
        case success
        case pomodoroComplete
        case click
    }
    
    public func play(_ type: SoundType) {
        guard AppState.shared.soundEnabled else { return }
        
        switch type {
        case .prompt:
            NSSound(named: "Ping")?.play()
        case .success:
            NSSound(named: "Glass")?.play()
        case .pomodoroComplete:
            NSSound(named: "Hero")?.play()
        case .click:
            NSSound(named: "Tink")?.play()
        }
    }
}
