import SwiftUI
import Combine
import AppKit

// MARK: - FocusTimerMode
public enum FocusTimerMode: String, CaseIterable, Identifiable {
    case pomodoro = "Pomodoro"
    case stopwatch = "Stopwatch"
    case countdown = "Timer"
    
    public var id: String { rawValue }
    public var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .stopwatch: return "stopwatch"
        case .countdown: return "hourglass"
        }
    }
}

// MARK: - FocusTimerView
public struct FocusTimerView: View {
    @Binding var isAlwaysOnTop: Bool
    var onClose: () -> Void
    
    @State private var selectedMode: FocusTimerMode = .pomodoro
    
    // MARK: - Pomodoro State
    @State private var pomodoroFocusMinutes: Int = 25
    @State private var pomodoroBreakMinutes: Int = 5
    @State private var pomodoroSecondsRemaining: Int = 25 * 60
    @State private var isPomodoroRunning: Bool = false
    @State private var isPomodoroInBreak: Bool = false
    @State private var showingDurationEditor: PomodoroPhaseType? = nil
    
    // MARK: - Stopwatch State
    @State private var stopwatchCentiseconds: Int = 0
    @State private var isStopwatchRunning: Bool = false
    @State private var stopwatchLaps: [String] = []
    
    // MARK: - Normal Countdown Timer State
    @State private var timerTotalSeconds: Int = 15 * 60
    @State private var timerSecondsRemaining: Int = 15 * 60
    @State private var isTimerRunning: Bool = false
    @State private var timerLaps: [String] = []
    @State private var isEditingTimerDuration: Bool = false
    
    // MARK: - Real-time Timing State
    @State private var lastTickDate: Date? = nil
    @State private var pomodoroAccumulator: TimeInterval = 0
    @State private var timerAccumulator: TimeInterval = 0
    
    // MARK: - All-Edge Surrounding Breathing Glow Animation State
    @State private var isEdgeGlowActive: Bool = false
    @State private var edgeBreathingPhase: CGFloat = 0.4
    @State private var glowTimerTask: Task<Void, Never>? = nil
    
    // Timer ticking at 20Hz (0.05s) for smooth stopwatch, progress rings, and real-world timestamp deltas
    private let tickTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    public enum PomodoroPhaseType: String, Identifiable {
        case focus = "Focus Duration"
        case breakTime = "Break Duration"
        public var id: String { rawValue }
    }
    
    public init(isAlwaysOnTop: Binding<Bool>, onClose: @escaping () -> Void) {
        self._isAlwaysOnTop = isAlwaysOnTop
        self.onClose = onClose
    }
    
    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let minDim = min(w, h)
            let dialSize = max(100, min(minDim * 0.48, h * 0.45, 210))
            let spacing = max(6, min(12, h * 0.025))
            
            ZStack {
                VStack(spacing: spacing) {
                    // 1. Header Bar with Window Controls & Always on Top
                    headerBar
                    
                    // 2. Mode Selector Segmented Pill
                    modeSelector
                    
                    Spacer(minLength: 2)
                    
                    // 3. Main Display based on Mode
                    Group {
                        switch selectedMode {
                        case .pomodoro:
                            pomodoroSection(dialSize: dialSize, containerWidth: w)
                        case .stopwatch:
                            stopwatchSection(dialSize: dialSize)
                        case .countdown:
                            countdownTimerSection(dialSize: dialSize)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    Spacer(minLength: 2)
                }
                .padding(.horizontal, max(10, min(16, w * 0.04)))
                .padding(.top, max(8, min(14, h * 0.03)))
                .padding(.bottom, max(8, min(14, h * 0.03)))
                
                // 4. All-Edge Surrounding Breathing Glow Overlay
                if isEdgeGlowActive {
                    allEdgeBreathingGlowBorder
                        .transition(.opacity)
                }
                
                // 5. Click-to-Edit Duration Popover Sheet
                if let phase = showingDurationEditor {
                    durationEditorOverlay(for: phase)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                if isEditingTimerDuration {
                    timerDurationEditorOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .onReceive(tickTimer) { now in
            handlePreciseTick(at: now)
        }
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(spacing: 8) {
            // Close Window Button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Theme.textMuted)
                    .frame(width: 20, height: 20)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            
            Text("Pomodoro & Stopwatch")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            Spacer()
            
            // Always on Top Toggle Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAlwaysOnTop.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 9, weight: .bold))
                    Text(isAlwaysOnTop ? "On Top" : "Pin")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(isAlwaysOnTop ? Theme.accent : Theme.textMuted)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(isAlwaysOnTop ? Theme.accent.opacity(0.2) : Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isAlwaysOnTop ? Theme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help(isAlwaysOnTop ? "Window is Always on Top" : "Keep Window on Top")
        }
    }
    
    // MARK: - Mode Selector
    private var modeSelector: some View {
        HStack(spacing: 4) {
            ForEach(FocusTimerMode.allCases) { mode in
                let isSelected = selectedMode == mode
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 10, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(
                        isSelected ?
                            LinearGradient(
                                colors: [Theme.accent, Theme.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: isSelected ? Theme.accent.opacity(0.35) : .clear, radius: 4, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - 1. Pomodoro Section
    private func pomodoroSection(dialSize: CGFloat, containerWidth: CGFloat) -> some View {
        VStack(spacing: 10) {
            let totalSecs = max(1, (isPomodoroInBreak ? pomodoroBreakMinutes : pomodoroFocusMinutes) * 60)
            let progress = 1.0 - (Double(pomodoroSecondsRemaining) / Double(totalSecs))
            let activeColor = isPomodoroInBreak ? Theme.wasteful : Theme.accent
            
            // Circular Dial with Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 7)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress))))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [activeColor.opacity(0.5), activeColor, Theme.accentLight]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                VStack(spacing: 3) {
                    Text(isPomodoroInBreak ? "BREAK TIME" : "FOCUS SPRINT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(activeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(activeColor.opacity(0.16))
                        .clipShape(Capsule())
                    
                    Text(formatTime(seconds: pomodoroSecondsRemaining))
                        .font(.system(size: max(22, dialSize * 0.22), weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
            .frame(width: dialSize, height: dialSize)
            .shadow(color: activeColor.opacity(isPomodoroRunning ? 0.35 : 0.05), radius: 10)
            
            // Editable Duration Clickable Pills
            HStack(spacing: 10) {
                // Focus Duration Pill (Click to edit)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingDurationEditor = .focus
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 9))
                        Text("Focus: \(pomodoroFocusMinutes)m")
                            .font(.system(size: 10, weight: .bold))
                        Image(systemName: "pencil")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(isPomodoroInBreak ? Theme.textSecondary : Theme.accentLight)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isPomodoroInBreak ? Color.white.opacity(0.06) : Theme.accent.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isPomodoroInBreak ? Color.clear : Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Click to edit focus duration")
                
                // Break Duration Pill (Click to edit)
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showingDurationEditor = .breakTime
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 9))
                        Text("Break: \(pomodoroBreakMinutes)m")
                            .font(.system(size: 10, weight: .bold))
                        Image(systemName: "pencil")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(isPomodoroInBreak ? Theme.wasteful : Theme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isPomodoroInBreak ? Theme.wasteful.opacity(0.18) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isPomodoroInBreak ? Theme.wasteful.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Click to edit break duration")
            }
            
            // Primary Control Actions (Reset, Start/Pause, Skip)
            HStack(spacing: 12) {
                // Reset Button
                Button(action: {
                    isPomodoroRunning = false
                    pomodoroAccumulator = 0
                    lastTickDate = nil
                    pomodoroSecondsRemaining = (isPomodoroInBreak ? pomodoroBreakMinutes : pomodoroFocusMinutes) * 60
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Reset Session")
                
                // Start / Pause Main Button
                Button(action: {
                    lastTickDate = Date()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPomodoroRunning.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(isPomodoroRunning ? "Pause" : (isPomodoroInBreak ? "Start Break" : "Start Focus"))
                            .font(.system(size: 11, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundColor(.white)
                    .frame(minWidth: 110)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [activeColor, activeColor.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: activeColor.opacity(0.4), radius: 6, y: 1)
                }
                .buttonStyle(.plain)
                
                // Skip Phase Button
                Button(action: {
                    transitionPomodoroPhase(autoStart: false)
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Skip to Next Phase")
            }
        }
    }
    
    // MARK: - 2. Stopwatch Section
    private func stopwatchSection(dialSize: CGFloat) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 7)
                    .frame(width: dialSize, height: dialSize)
                
                VStack(spacing: 2) {
                    Text("STOPWATCH")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.productive)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.productive.opacity(0.16))
                        .clipShape(Capsule())
                    
                    Text(formatStopwatch(centiseconds: stopwatchCentiseconds))
                        .font(.system(size: max(20, dialSize * 0.18), weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
            .shadow(color: Theme.productive.opacity(isStopwatchRunning ? 0.35 : 0.05), radius: 10)
            
            // Actions: Reset, Lap (subtle), Start/Pause
            HStack(spacing: 12) {
                Button(action: {
                    isStopwatchRunning = false
                    stopwatchCentiseconds = 0
                    stopwatchLaps.removeAll()
                    lastTickDate = nil
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Reset")
                
                // Lap Button (subtle secondary)
                Button(action: {
                    let lapTime = formatStopwatch(centiseconds: stopwatchCentiseconds)
                    stopwatchLaps.insert(lapTime, at: 0)
                }) {
                    Text("Lap")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!isStopwatchRunning)
                .opacity(isStopwatchRunning ? 1.0 : 0.4)
                
                // Start / Pause
                Button(action: {
                    lastTickDate = Date()
                    isStopwatchRunning.toggle()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isStopwatchRunning ? "pause.fill" : "play.fill")
                        Text(isStopwatchRunning ? "Pause" : "Start")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 95)
                    .padding(.vertical, 7)
                    .background(isStopwatchRunning ? Theme.wasteful : Theme.productive)
                    .clipShape(Capsule())
                    .shadow(color: (isStopwatchRunning ? Theme.wasteful : Theme.productive).opacity(0.35), radius: 6)
                }
                .buttonStyle(.plain)
            }
            
            // Laps List (subtle, non-distracting)
            if !stopwatchLaps.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(Array(stopwatchLaps.prefix(3).enumerated()), id: \.offset) { idx, lap in
                            HStack {
                                Text("Lap \(stopwatchLaps.count - idx)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                                Spacer()
                                Text(lap)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2.5)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .frame(maxHeight: 50)
            }
        }
    }
    
    // MARK: - 3. Normal Countdown Timer Section
    private func countdownTimerSection(dialSize: CGFloat) -> some View {
        VStack(spacing: 10) {
            let progress = timerTotalSeconds > 0 ? (1.0 - (Double(timerSecondsRemaining) / Double(timerTotalSeconds))) : 0.0
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 7)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress))))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Theme.planned.opacity(0.5), Theme.planned, Theme.accentLight]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 7, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                VStack(spacing: 2) {
                    Text("TIMER")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.planned)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.planned.opacity(0.16))
                        .clipShape(Capsule())
                    
                    Text(formatTime(seconds: timerSecondsRemaining))
                        .font(.system(size: max(20, dialSize * 0.20), weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
            .frame(width: dialSize, height: dialSize)
            .shadow(color: Theme.planned.opacity(isTimerRunning ? 0.35 : 0.05), radius: 10)
            
            // Editable Duration / Presets Button
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isEditingTimerDuration = true
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 9))
                    Text("Duration: \(timerTotalSeconds / 60)m")
                        .font(.system(size: 10, weight: .bold))
                    Image(systemName: "pencil")
                        .font(.system(size: 8))
                }
                .foregroundColor(Theme.planned)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.planned.opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.planned.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Click to edit countdown duration")
            
            // Actions: Reset, Lap, Start/Pause
            HStack(spacing: 12) {
                Button(action: {
                    isTimerRunning = false
                    timerSecondsRemaining = timerTotalSeconds
                    timerLaps.removeAll()
                    timerAccumulator = 0
                    lastTickDate = nil
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Reset Timer")
                
                // Lap button (subtle)
                Button(action: {
                    let lapTime = formatTime(seconds: timerSecondsRemaining)
                    timerLaps.insert(lapTime, at: 0)
                }) {
                    Text("Lap")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!isTimerRunning)
                .opacity(isTimerRunning ? 1.0 : 0.4)
                
                // Play / Pause
                Button(action: {
                    lastTickDate = Date()
                    isTimerRunning.toggle()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isTimerRunning ? "pause.fill" : "play.fill")
                        Text(isTimerRunning ? "Pause" : "Start")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 95)
                    .padding(.vertical, 7)
                    .background(Theme.planned)
                    .clipShape(Capsule())
                    .shadow(color: Theme.planned.opacity(0.4), radius: 6)
                }
                .buttonStyle(.plain)
            }
            
            if !timerLaps.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(Array(timerLaps.prefix(2).enumerated()), id: \.offset) { idx, lap in
                            HStack {
                                Text("Lap \(timerLaps.count - idx)")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(Theme.textMuted)
                                Spacer()
                                Text(lap)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(Theme.textSecondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2.5)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .frame(maxHeight: 40)
            }
        }
    }
    
    // MARK: - 4. All-Edge Surrounding Breathing Glow Animation Overlay
    private var allEdgeBreathingGlowBorder: some View {
        ZStack {
            // Subtle ambient backdrop liquid glow
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    RadialGradient(
                        colors: [
                            (isPomodoroInBreak ? Theme.wasteful : Theme.productive).opacity(0.12 * edgeBreathingPhase),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 260
                    )
                )
                .ignoresSafeArea()
            
            // Layer 1: Wide Deep Breathing Outer Glow
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [
                            Theme.accent,
                            Theme.productive,
                            Theme.accentLight,
                            Theme.productive
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3 + (2.5 * edgeBreathingPhase)
                )
                .shadow(color: Theme.accent.opacity(0.85 * edgeBreathingPhase), radius: 22)
                .shadow(color: Theme.productive.opacity(0.75 * edgeBreathingPhase), radius: 36)
                .shadow(color: Theme.accentLight.opacity(0.65 * edgeBreathingPhase), radius: 50)
            
            // Layer 2: Sharp Inner Radiant Border
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .white,
                            Theme.accentLight,
                            Theme.productive,
                            Theme.accent,
                            .white
                        ]),
                        center: .center
                    ),
                    lineWidth: 2
                )
                .opacity(0.5 + (0.5 * edgeBreathingPhase))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    // MARK: - 5. Click-to-Edit Popovers
    private func durationEditorOverlay(for phase: PomodoroPhaseType) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showingDurationEditor = nil
                    }
                }
            
            VStack(spacing: 12) {
                HStack {
                    Text(phase.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showingDurationEditor = nil
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .padding(4)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Stepper Row
                let currentVal = phase == .focus ? pomodoroFocusMinutes : pomodoroBreakMinutes
                HStack(spacing: 16) {
                    Button(action: {
                        if phase == .focus {
                            pomodoroFocusMinutes = max(1, pomodoroFocusMinutes - 1)
                            if !isPomodoroRunning && !isPomodoroInBreak {
                                pomodoroSecondsRemaining = pomodoroFocusMinutes * 60
                            }
                        } else {
                            pomodoroBreakMinutes = max(1, pomodoroBreakMinutes - 1)
                            if !isPomodoroRunning && isPomodoroInBreak {
                                pomodoroSecondsRemaining = pomodoroBreakMinutes * 60
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(currentVal) mins")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .frame(minWidth: 70)
                    
                    Button(action: {
                        if phase == .focus {
                            pomodoroFocusMinutes = min(180, pomodoroFocusMinutes + 1)
                            if !isPomodoroRunning && !isPomodoroInBreak {
                                pomodoroSecondsRemaining = pomodoroFocusMinutes * 60
                            }
                        } else {
                            pomodoroBreakMinutes = min(60, pomodoroBreakMinutes + 1)
                            if !isPomodoroRunning && isPomodoroInBreak {
                                pomodoroSecondsRemaining = pomodoroBreakMinutes * 60
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Preset Quick Chips
                let presets = phase == .focus ? [15, 20, 25, 30, 45, 50, 60] : [3, 5, 10, 15, 20, 30]
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(presets, id: \.self) { mins in
                            let isSel = currentVal == mins
                            Button(action: {
                                if phase == .focus {
                                    pomodoroFocusMinutes = mins
                                    if !isPomodoroRunning && !isPomodoroInBreak {
                                        pomodoroSecondsRemaining = mins * 60
                                    }
                                } else {
                                    pomodoroBreakMinutes = mins
                                    if !isPomodoroRunning && isPomodoroInBreak {
                                        pomodoroSecondsRemaining = mins * 60
                                    }
                                }
                            }) {
                                Text("\(mins)m")
                                    .font(.system(size: 10, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .white : Theme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSel ? Theme.accent : Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Done Button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showingDurationEditor = nil
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(width: 240)
            .background(Theme.bgDeep)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
        }
    }
    
    private var timerDurationEditorOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isEditingTimerDuration = false
                    }
                }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Timer Duration")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isEditingTimerDuration = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Theme.textMuted)
                            .padding(4)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Stepper
                let mins = timerTotalSeconds / 60
                HStack(spacing: 16) {
                    Button(action: {
                        let newMins = max(1, mins - 1)
                        timerTotalSeconds = newMins * 60
                        if !isTimerRunning {
                            timerSecondsRemaining = timerTotalSeconds
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    Text("\(mins) mins")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .frame(minWidth: 70)
                    
                    Button(action: {
                        let newMins = min(360, mins + 1)
                        timerTotalSeconds = newMins * 60
                        if !isTimerRunning {
                            timerSecondsRemaining = timerTotalSeconds
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                // Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach([5, 10, 15, 20, 25, 30, 45, 60], id: \.self) { p in
                            let isSel = mins == p
                            Button(action: {
                                timerTotalSeconds = p * 60
                                if !isTimerRunning {
                                    timerSecondsRemaining = timerTotalSeconds
                                }
                            }) {
                                Text("\(p)m")
                                    .font(.system(size: 10, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .white : Theme.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(isSel ? Theme.planned : Color.white.opacity(0.08))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isEditingTimerDuration = false
                    }
                }) {
                    Text("Done")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Theme.planned)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(width: 240)
            .background(Theme.bgDeep)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 20)
        }
    }
    
    // MARK: - Accurate Timestamp Real-Time Ticking
    private func handlePreciseTick(at now: Date) {
        guard let last = lastTickDate else {
            lastTickDate = now
            return
        }
        let delta = now.timeIntervalSince(last)
        lastTickDate = now
        
        // 1. Pomodoro Logic
        if isPomodoroRunning {
            pomodoroAccumulator += delta
            if pomodoroAccumulator >= 1.0 {
                let secondsToDeduct = Int(pomodoroAccumulator)
                pomodoroAccumulator -= Double(secondsToDeduct)
                
                if pomodoroSecondsRemaining > secondsToDeduct {
                    pomodoroSecondsRemaining -= secondsToDeduct
                } else {
                    pomodoroSecondsRemaining = 0
                    isPomodoroRunning = false
                    pomodoroAccumulator = 0
                    triggerTimeFrameEndAnimation {
                        transitionPomodoroPhase(autoStart: true)
                    }
                }
            }
        }
        
        // 2. Stopwatch Logic
        if isStopwatchRunning {
            stopwatchCentiseconds += Int(round(delta * 100))
        }
        
        // 3. Normal Countdown Timer Logic
        if isTimerRunning {
            timerAccumulator += delta
            if timerAccumulator >= 1.0 {
                let secondsToDeduct = Int(timerAccumulator)
                timerAccumulator -= Double(secondsToDeduct)
                
                if timerSecondsRemaining > secondsToDeduct {
                    timerSecondsRemaining -= secondsToDeduct
                } else {
                    timerSecondsRemaining = 0
                    isTimerRunning = false
                    timerAccumulator = 0
                    triggerTimeFrameEndAnimation {
                        // Timer completed
                    }
                }
            }
        }
    }
    
    private func transitionPomodoroPhase(autoStart: Bool) {
        isPomodoroInBreak.toggle()
        pomodoroSecondsRemaining = (isPomodoroInBreak ? pomodoroBreakMinutes : pomodoroFocusMinutes) * 60
        pomodoroAccumulator = 0
        lastTickDate = Date()
        isPomodoroRunning = autoStart
    }
    
    // MARK: - Breathing Glow Animation Trigger
    private func triggerTimeFrameEndAnimation(onComplete: @escaping () -> Void) {
        NSSound(named: "Glass")?.play()
        
        glowTimerTask?.cancel()
        isEdgeGlowActive = true
        edgeBreathingPhase = 0.2
        
        // Start smooth breathing animation
        withAnimation(.easeInOut(duration: 0.7).repeatCount(5, autoreverses: true)) {
            edgeBreathingPhase = 1.0
        }
        
        glowTimerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000) // 3.5s breathing glow
            withAnimation(.easeOut(duration: 0.5)) {
                isEdgeGlowActive = false
                edgeBreathingPhase = 0.2
            }
            onComplete()
        }
    }
    
    // MARK: - Formatters
    private func formatTime(seconds: Int) -> String {
        let total = max(0, seconds)
        let hours = total / 3600
        let mins = (total % 3600) / 60
        let secs = total % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
    
    private func formatStopwatch(centiseconds: Int) -> String {
        let totalSeconds = centiseconds / 100
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        let cs = centiseconds % 100
        return String(format: "%02d:%02d.%02d", mins, secs, cs)
    }
}
