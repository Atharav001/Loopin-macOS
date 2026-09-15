import SwiftUI

public struct PomodoroView: View {
    @ObservedObject var appState: AppState = .shared
    
    public init() {}
    
    private var totalSeconds: Int {
        (appState.isPomodoroBreak ? appState.pomodoroBreakMinutes : appState.pomodoroDurationMinutes) * 60
    }
    
    private var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return 1.0 - (Double(appState.pomodoroSecondsRemaining) / Double(totalSeconds))
    }
    
    private var formattedTime: String {
        let mins = appState.pomodoroSecondsRemaining / 60
        let secs = appState.pomodoroSecondsRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundColor(Theme.accentLight)
                    Text("Pomodoro Focus Session")
                        .font(Theme.titleSmall)
                        .foregroundColor(Theme.textPrimary)
                }
                
                Spacer()
                
                Text(appState.isPomodoroBreak ? "Break Time" : "Focus Time")
                    .font(Theme.caption)
                    .fontWeight(.bold)
                    .foregroundColor(appState.isPomodoroBreak ? Theme.neutral : Theme.productive)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((appState.isPomodoroBreak ? Theme.neutral : Theme.productive).opacity(0.15))
                    .cornerRadius(6)
            }
            
            HStack(spacing: 32) {
                // Circular Progress Ring
                ZStack {
                    Circle()
                        .stroke(Theme.borderSubtle, lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(max(0.01, progress)))
                        .stroke(
                            appState.isPomodoroBreak ? Theme.neutral : Theme.productive,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                        .animation(.linear(duration: 0.5), value: progress)
                    
                    VStack(spacing: 2) {
                        Text(formattedTime)
                            .font(Theme.titleMedium)
                            .fontWeight(.bold)
                            .foregroundColor(Theme.textPrimary)
                        
                        Text(appState.isPomodoroBreak ? "Break" : "Focus")
                            .font(Theme.caption)
                            .foregroundColor(Theme.textMuted)
                    }
                }
                .padding(.leading, 8)
                
                // Controls & Presets
                VStack(alignment: .leading, spacing: 14) {
                    // Start / Pause / Reset Buttons
                    HStack(spacing: 10) {
                        Button(action: {
                            appState.isPomodoroRunning.toggle()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: appState.isPomodoroRunning ? "pause.fill" : "play.fill")
                                Text(appState.isPomodoroRunning ? "Pause" : "Start Focus")
                            }
                            .font(Theme.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(appState.isPomodoroRunning ? Theme.neutral : Theme.accent)
                            .cornerRadius(8)
                            .shadow(color: Theme.accentGlow, radius: 4)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            appState.isPomodoroRunning = false
                            appState.isPomodoroBreak = false
                            appState.pomodoroSecondsRemaining = appState.pomodoroDurationMinutes * 60
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(Theme.caption)
                            .foregroundColor(Theme.textSecondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(Theme.bgSubtle)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Duration Preset Pickers
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Focus Duration")
                                .font(Theme.caption)
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 4) {
                                ForEach([25, 45, 60], id: \.self) { mins in
                                    let isSel = appState.pomodoroDurationMinutes == mins
                                    Button(action: {
                                        appState.pomodoroDurationMinutes = mins
                                        if !appState.isPomodoroBreak && !appState.isPomodoroRunning {
                                            appState.pomodoroSecondsRemaining = mins * 60
                                        }
                                    }) {
                                        Text("\(mins)m")
                                            .font(Theme.caption)
                                            .foregroundColor(isSel ? .white : Theme.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(isSel ? Theme.accent : Theme.bgSubtle)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Break Duration")
                                .font(Theme.caption)
                                .foregroundColor(Theme.textSecondary)
                            
                            HStack(spacing: 4) {
                                ForEach([5, 10, 15], id: \.self) { mins in
                                    let isSel = appState.pomodoroBreakMinutes == mins
                                    Button(action: {
                                        appState.pomodoroBreakMinutes = mins
                                        if appState.isPomodoroBreak && !appState.isPomodoroRunning {
                                            appState.pomodoroSecondsRemaining = mins * 60
                                        }
                                    }) {
                                        Text("\(mins)m")
                                            .font(Theme.caption)
                                            .foregroundColor(isSel ? .white : Theme.textSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(isSel ? Theme.neutral : Theme.bgSubtle)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 14)
    }
}
