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
    
    // MARK: - Countdown Timer State
    @State private var timerTotalSeconds: Int = 15 * 60
    @State private var timerSecondsRemaining: Int = 15 * 60
    @State private var isTimerRunning: Bool = false
    @State private var timerLaps: [String] = []
    @State private var isEditingTimerDuration: Bool = false
    
    // MARK: - Typing & Direct Input State
    @State private var typedMinutesText: String = ""
    @FocusState private var isFieldFocused: Bool
    
    // MARK: - Real-time Timing State
    @State private var lastTickDate: Date? = nil
    @State private var pomodoroAccumulator: TimeInterval = 0
    @State private var timerAccumulator: TimeInterval = 0
    
    // MARK: - Breathing Glow Animation State
    @State private var isEdgeGlowActive: Bool = false
    @State private var edgeBreathingPhase: CGFloat = 0.4
    @State private var glowTimerTask: Task<Void, Never>? = nil
    
    // 20Hz Tick Timer
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
            
            // Layout dimension calculations to guarantee contents never overflow or clip
            let isCompactW = w < 330
            let isSuperCompactW = w < 275
            let isCompactH = h < 340
            let isTinyH = h < 300
            
            // Sizing budget
            let navBarH: CGFloat = 34
            let modeSelectorH: CGFloat = 34
            let actionsH: CGFloat = isCompactH ? 38 : 46
            let pillsH: CGFloat = isCompactH ? 26 : 30
            let paddingBudget: CGFloat = isTinyH ? 20 : 34
            let availableH = max(60, h - navBarH - modeSelectorH - actionsH - pillsH - paddingBudget)
            let dialSize = max(70, min(w * 0.44, availableH, 185))
            
            ZStack {
                VStack(spacing: 0) {
                    // 1. Sleek Navigation Bar (Anchors the 3 traffic light buttons properly)
                    navigationBar(containerWidth: w, isSuperCompact: isSuperCompactW)
                    
                    // 2. Main Scroll-Free Responsive Body Content
                    VStack(spacing: max(3, min(8, h * 0.02))) {
                        // Mode Selector (Shows only logos/symbols when window is narrow)
                        modeSelector(containerWidth: w, isCompact: isCompactW)
                            .padding(.horizontal, max(8, min(14, w * 0.04)))
                            .padding(.top, max(4, min(8, h * 0.015)))
                        
                        Spacer(minLength: 1)
                        
                        // Active Mode Section
                        Group {
                            switch selectedMode {
                            case .pomodoro:
                                pomodoroSection(dialSize: dialSize, w: w, isCompactW: isCompactW, isCompactH: isCompactH)
                            case .stopwatch:
                                stopwatchSection(dialSize: dialSize, w: w, h: h, isCompactW: isCompactW, isCompactH: isCompactH, isTinyH: isTinyH)
                            case .countdown:
                                countdownTimerSection(dialSize: dialSize, w: w, h: h, isCompactW: isCompactW, isCompactH: isCompactH, isTinyH: isTinyH)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer(minLength: 1)
                    }
                    .padding(.bottom, max(6, min(12, h * 0.02)))
                }
                
                // 3. Surrounding Breathing Glow Overlay on Phase End
                if isEdgeGlowActive {
                    allEdgeBreathingGlowBorder
                        .transition(.opacity)
                }
                
                // 4. Click-and-Type Duration Editor Overlays
                if let phase = showingDurationEditor {
                    durationEditorOverlay(for: phase)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
                
                if isEditingTimerDuration {
                    timerDurationEditorOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .clipped()
        }
        .onReceive(tickTimer) { now in
            handlePreciseTick(at: now)
        }
    }
    
    // MARK: - 1. Window Navigation Bar (Grounded traffic light bar)
    private func navigationBar(containerWidth: CGFloat, isSuperCompact: Bool) -> some View {
        HStack(spacing: 8) {
            // Reserved space for standard macOS traffic lights (close, minimize, zoom)
            Spacer()
                .frame(width: 68)
            
            // Window Title (Centered / Flexible)
            if containerWidth >= 280 {
                Text(containerWidth >= 360 ? "Focus & Pomodoro Timer" : "Focus Timer")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            
            Spacer()
            
            // Always on Top Pin Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isAlwaysOnTop.toggle()
                }
            }) {
                HStack(spacing: 3) {
                    Image(systemName: isAlwaysOnTop ? "pin.fill" : "pin")
                        .font(.system(size: 9, weight: .bold))
                    if !isSuperCompact {
                        Text(isAlwaysOnTop ? "On Top" : "Pin")
                            .font(.system(size: 10, weight: .semibold))
                    }
                }
                .foregroundColor(isAlwaysOnTop ? Theme.accent : Theme.textMuted)
                .padding(.horizontal, isSuperCompact ? 6 : 8)
                .padding(.vertical, 3.5)
                .background(isAlwaysOnTop ? Theme.accent.opacity(0.2) : Color.white.opacity(0.06))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isAlwaysOnTop ? Theme.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help(isAlwaysOnTop ? "Window is Always on Top" : "Pin Window on Top")
        }
        .padding(.horizontal, 10)
        .frame(height: 34)
        .background(
            Color.black.opacity(0.35)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.white.opacity(0.08)),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - 2. Mode Selector (Shows only logos when resized smaller)
    private func modeSelector(containerWidth: CGFloat, isCompact: Bool) -> some View {
        HStack(spacing: 3) {
            ForEach(FocusTimerMode.allCases) { mode in
                let isSelected = selectedMode == mode
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: mode.icon)
                            .font(.system(size: isCompact ? 12 : 10, weight: .semibold))
                        
                        // When window size reduces, hide full text and show only symbols/logos
                        if !isCompact {
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .foregroundColor(isSelected ? .white : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 6 : 5)
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
                .help(mode.rawValue)
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
    
    // MARK: - 3. Pomodoro Section
    private func pomodoroSection(dialSize: CGFloat, w: CGFloat, isCompactW: Bool, isCompactH: Bool) -> some View {
        VStack(spacing: isCompactH ? 6 : 10) {
            let totalSecs = max(1, (isPomodoroInBreak ? pomodoroBreakMinutes : pomodoroFocusMinutes) * 60)
            let progress = 1.0 - (Double(pomodoroSecondsRemaining) / Double(totalSecs))
            let activeColor = isPomodoroInBreak ? Theme.wasteful : Theme.accent
            let strokeW: CGFloat = max(4, dialSize * 0.05)
            
            // Circular Dial with Click-to-Edit digits
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeW)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress))))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [activeColor.opacity(0.5), activeColor, Theme.accentLight]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                // Dial Content (Clickable when paused to type time directly)
                VStack(spacing: isCompactH ? 1 : 3) {
                    if dialSize >= 95 {
                        Text(isPomodoroInBreak ? "BREAK" : "FOCUS")
                            .font(.system(size: max(8, dialSize * 0.075), weight: .bold, design: .monospaced))
                            .foregroundColor(activeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(activeColor.opacity(0.16))
                            .clipShape(Capsule())
                    }
                    
                    Text(formatTime(seconds: pomodoroSecondsRemaining))
                        .font(.system(size: max(16, dialSize * 0.22), weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    if !isPomodoroRunning && dialSize >= 115 {
                        Text("Click to edit")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Theme.textMuted.opacity(0.8))
                    }
                }
                .contentShape(Circle())
                .onTapGesture {
                    if !isPomodoroRunning {
                        openPomodoroEditor(for: isPomodoroInBreak ? .breakTime : .focus)
                    }
                }
            }
            .frame(width: dialSize, height: dialSize)
            .shadow(color: activeColor.opacity(isPomodoroRunning ? 0.35 : 0.05), radius: 8)
            .help(!isPomodoroRunning ? "Click to type and edit time" : "")
            
            // Editable Duration Clickable Pills
            HStack(spacing: isCompactW ? 6 : 10) {
                // Focus Pill
                Button(action: {
                    openPomodoroEditor(for: .focus)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 8))
                        Text(isCompactW ? "\(pomodoroFocusMinutes)m" : "Focus: \(pomodoroFocusMinutes)m")
                            .font(.system(size: isCompactW ? 9 : 10, weight: .bold))
                        Image(systemName: "pencil")
                            .font(.system(size: 7))
                    }
                    .foregroundColor(isPomodoroInBreak ? Theme.textSecondary : Theme.accentLight)
                    .padding(.horizontal, isCompactW ? 6 : 8)
                    .padding(.vertical, 3.5)
                    .background(isPomodoroInBreak ? Color.white.opacity(0.06) : Theme.accent.opacity(0.15))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isPomodoroInBreak ? Color.clear : Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Click to type focus duration")
                
                // Break Pill
                Button(action: {
                    openPomodoroEditor(for: .breakTime)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 8))
                        Text(isCompactW ? "\(pomodoroBreakMinutes)m" : "Break: \(pomodoroBreakMinutes)m")
                            .font(.system(size: isCompactW ? 9 : 10, weight: .bold))
                        Image(systemName: "pencil")
                            .font(.system(size: 7))
                    }
                    .foregroundColor(isPomodoroInBreak ? Theme.wasteful : Theme.textSecondary)
                    .padding(.horizontal, isCompactW ? 6 : 8)
                    .padding(.vertical, 3.5)
                    .background(isPomodoroInBreak ? Theme.wasteful.opacity(0.18) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isPomodoroInBreak ? Theme.wasteful.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help("Click to type break duration")
            }
            
            // Primary Control Actions (Reset, Start/Pause, Skip)
            HStack(spacing: isCompactW ? 8 : 12) {
                // Reset Button
                Button(action: {
                    isPomodoroRunning = false
                    pomodoroAccumulator = 0
                    lastTickDate = nil
                    pomodoroSecondsRemaining = (isPomodoroInBreak ? pomodoroBreakMinutes : pomodoroFocusMinutes) * 60
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: isCompactH ? 10 : 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: isCompactH ? 28 : 32, height: isCompactH ? 28 : 32)
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
                    HStack(spacing: 5) {
                        Image(systemName: isPomodoroRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(isPomodoroRunning ? "Pause" : (isPomodoroInBreak ? "Start Break" : "Start Focus"))
                            .font(.system(size: isCompactW ? 10 : 11, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundColor(.white)
                    .frame(minWidth: isCompactW ? 80 : 110)
                    .padding(.horizontal, 10)
                    .padding(.vertical, isCompactH ? 5.5 : 7)
                    .background(
                        LinearGradient(
                            colors: [activeColor, activeColor.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: activeColor.opacity(0.35), radius: 5, y: 1)
                }
                .buttonStyle(.plain)
                
                // Skip Phase Button
                Button(action: {
                    transitionPomodoroPhase(autoStart: false)
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: isCompactH ? 10 : 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: isCompactH ? 28 : 32, height: isCompactH ? 28 : 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Skip to Next Phase")
            }
        }
    }
    
    // MARK: - 4. Stopwatch Section
    private func stopwatchSection(dialSize: CGFloat, w: CGFloat, h: CGFloat, isCompactW: Bool, isCompactH: Bool, isTinyH: Bool) -> some View {
        VStack(spacing: isCompactH ? 6 : 10) {
            let strokeW: CGFloat = max(4, dialSize * 0.05)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeW)
                    .frame(width: dialSize, height: dialSize)
                
                VStack(spacing: 2) {
                    if dialSize >= 95 {
                        Text("STOPWATCH")
                            .font(.system(size: max(8, dialSize * 0.075), weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.productive)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Theme.productive.opacity(0.16))
                            .clipShape(Capsule())
                    }
                    
                    Text(formatStopwatch(centiseconds: stopwatchCentiseconds))
                        .font(.system(size: max(15, dialSize * 0.18), weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
            }
            .shadow(color: Theme.productive.opacity(isStopwatchRunning ? 0.35 : 0.05), radius: 8)
            
            // Actions: Reset, Lap, Start/Pause
            HStack(spacing: isCompactW ? 8 : 12) {
                Button(action: {
                    isStopwatchRunning = false
                    stopwatchCentiseconds = 0
                    stopwatchLaps.removeAll()
                    lastTickDate = nil
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: isCompactH ? 10 : 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: isCompactH ? 28 : 32, height: isCompactH ? 28 : 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Reset")
                
                // Lap Button
                Button(action: {
                    let lapTime = formatStopwatch(centiseconds: stopwatchCentiseconds)
                    stopwatchLaps.insert(lapTime, at: 0)
                }) {
                    Text("Lap")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, isCompactW ? 8 : 10)
                        .padding(.vertical, isCompactH ? 4.5 : 6)
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
                    .frame(minWidth: isCompactW ? 75 : 95)
                    .padding(.horizontal, 10)
                    .padding(.vertical, isCompactH ? 5.5 : 7)
                    .background(isStopwatchRunning ? Theme.wasteful : Theme.productive)
                    .clipShape(Capsule())
                    .shadow(color: (isStopwatchRunning ? Theme.wasteful : Theme.productive).opacity(0.35), radius: 5)
                }
                .buttonStyle(.plain)
            }
            
            // Laps List (Hidden if height is tiny to prevent any cutting)
            if !stopwatchLaps.isEmpty && !isTinyH && h >= 320 {
                let maxItems = h < 370 ? 1 : 3
                VStack(spacing: 3) {
                    ForEach(Array(stopwatchLaps.prefix(maxItems).enumerated()), id: \.offset) { idx, lap in
                        HStack {
                            Text("Lap \(stopwatchLaps.count - idx)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text(lap)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                .frame(maxHeight: isCompactH ? 28 : 50)
            }
        }
    }
    
    // MARK: - 5. Countdown Timer Section
    private func countdownTimerSection(dialSize: CGFloat, w: CGFloat, h: CGFloat, isCompactW: Bool, isCompactH: Bool, isTinyH: Bool) -> some View {
        VStack(spacing: isCompactH ? 6 : 10) {
            let progress = timerTotalSeconds > 0 ? (1.0 - (Double(timerSecondsRemaining) / Double(timerTotalSeconds))) : 0.0
            let strokeW: CGFloat = max(4, dialSize * 0.05)
            
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: strokeW)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(1.0, max(0.0, progress))))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Theme.planned.opacity(0.5), Theme.planned, Theme.accentLight]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)
                
                VStack(spacing: isCompactH ? 1 : 2) {
                    if dialSize >= 95 {
                        Text("TIMER")
                            .font(.system(size: max(8, dialSize * 0.075), weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.planned)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1.5)
                            .background(Theme.planned.opacity(0.16))
                            .clipShape(Capsule())
                    }
                    
                    Text(formatTime(seconds: timerSecondsRemaining))
                        .font(.system(size: max(16, dialSize * 0.20), weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    if !isTimerRunning && dialSize >= 115 {
                        Text("Click to edit")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(Theme.textMuted.opacity(0.8))
                    }
                }
                .contentShape(Circle())
                .onTapGesture {
                    if !isTimerRunning {
                        openTimerEditor()
                    }
                }
            }
            .frame(width: dialSize, height: dialSize)
            .shadow(color: Theme.planned.opacity(isTimerRunning ? 0.35 : 0.05), radius: 8)
            .help(!isTimerRunning ? "Click to type timer duration" : "")
            
            // Editable Duration Button (Click to type)
            Button(action: {
                openTimerEditor()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 8))
                    Text(isCompactW ? "\(timerTotalSeconds / 60)m" : "Duration: \(timerTotalSeconds / 60)m")
                        .font(.system(size: isCompactW ? 9 : 10, weight: .bold))
                    Image(systemName: "pencil")
                        .font(.system(size: 7))
                }
                .foregroundColor(Theme.planned)
                .padding(.horizontal, isCompactW ? 6 : 8)
                .padding(.vertical, 3.5)
                .background(Theme.planned.opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Theme.planned.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Click to type countdown duration")
            
            // Actions: Reset, Lap, Start/Pause
            HStack(spacing: isCompactW ? 8 : 12) {
                Button(action: {
                    isTimerRunning = false
                    timerSecondsRemaining = timerTotalSeconds
                    timerLaps.removeAll()
                    timerAccumulator = 0
                    lastTickDate = nil
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: isCompactH ? 10 : 12, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .frame(width: isCompactH ? 28 : 32, height: isCompactH ? 28 : 32)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Reset Timer")
                
                Button(action: {
                    let lapTime = formatTime(seconds: timerSecondsRemaining)
                    timerLaps.insert(lapTime, at: 0)
                }) {
                    Text("Lap")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Theme.textSecondary)
                        .padding(.horizontal, isCompactW ? 8 : 10)
                        .padding(.vertical, isCompactH ? 4.5 : 6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!isTimerRunning)
                .opacity(isTimerRunning ? 1.0 : 0.4)
                
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
                    .frame(minWidth: isCompactW ? 75 : 95)
                    .padding(.horizontal, 10)
                    .padding(.vertical, isCompactH ? 5.5 : 7)
                    .background(Theme.planned)
                    .clipShape(Capsule())
                    .shadow(color: Theme.planned.opacity(0.4), radius: 5)
                }
                .buttonStyle(.plain)
            }
            
            if !timerLaps.isEmpty && !isTinyH && h >= 320 {
                let maxItems = h < 370 ? 1 : 2
                VStack(spacing: 3) {
                    ForEach(Array(timerLaps.prefix(maxItems).enumerated()), id: \.offset) { idx, lap in
                        HStack {
                            Text("Lap \(timerLaps.count - idx)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Theme.textMuted)
                            Spacer()
                            Text(lap)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Theme.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                .frame(maxHeight: isCompactH ? 26 : 40)
            }
        }
    }
    
    // MARK: - 6. All-Edge Surrounding Breathing Glow Animation Overlay
    private var allEdgeBreathingGlowBorder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
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
            
            RoundedRectangle(cornerRadius: 16)
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
                .shadow(color: Theme.accent.opacity(0.85 * edgeBreathingPhase), radius: 20)
                .shadow(color: Theme.productive.opacity(0.75 * edgeBreathingPhase), radius: 32)
            
            RoundedRectangle(cornerRadius: 16)
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
                    lineWidth: 1.5
                )
                .opacity(0.5 + (0.5 * edgeBreathingPhase))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    // MARK: - 7. Duration Editor Overlay (Direct typing + Steppers + Presets)
    private func durationEditorOverlay(for phase: PomodoroPhaseType) -> some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    commitPomodoroDuration(for: phase)
                }
            
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text(phase == .focus ? "Edit Focus Time" : "Edit Break Time")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        commitPomodoroDuration(for: phase)
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
                
                // Direct Type Input Field + Stepper Controls
                HStack(spacing: 12) {
                    // Minus Button
                    Button(action: {
                        let current = Int(typedMinutesText) ?? (phase == .focus ? pomodoroFocusMinutes : pomodoroBreakMinutes)
                        let newM = max(1, current - 1)
                        typedMinutesText = "\(newM)"
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // Direct Typeable Text Box
                    HStack(spacing: 4) {
                        TextField("25", text: $typedMinutesText)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .frame(width: 65)
                            .focused($isFieldFocused)
                            .onSubmit {
                                commitPomodoroDuration(for: phase)
                            }
                            .onChange(of: typedMinutesText) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    typedMinutesText = filtered
                                }
                            }
                        
                        Text("min")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isFieldFocused ? Theme.accent : Color.white.opacity(0.18), lineWidth: 1.5)
                    )
                    
                    // Plus Button
                    Button(action: {
                        let current = Int(typedMinutesText) ?? (phase == .focus ? pomodoroFocusMinutes : pomodoroBreakMinutes)
                        let newM = min(180, current + 1)
                        typedMinutesText = "\(newM)"
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Click box to type minutes directly")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                
                // Presets Quick Chips
                let presets = phase == .focus ? [15, 20, 25, 30, 45, 50, 60] : [3, 5, 10, 15, 20, 30]
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(presets, id: \.self) { mins in
                            let isSel = Int(typedMinutesText) == mins
                            Button(action: {
                                typedMinutesText = "\(mins)"
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
                    commitPomodoroDuration(for: phase)
                }) {
                    Text("Set Time")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(width: 250)
            .background(Theme.bgDeep)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
    }
    
    // MARK: - 8. Timer Duration Editor Overlay (Direct typing + Steppers + Presets)
    private var timerDurationEditorOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    commitTimerDuration()
                }
            
            VStack(spacing: 12) {
                HStack {
                    Text("Edit Timer Duration")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        commitTimerDuration()
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
                
                // Stepper + Text Input Field
                HStack(spacing: 12) {
                    Button(action: {
                        let current = Int(typedMinutesText) ?? (timerTotalSeconds / 60)
                        let newM = max(1, current - 1)
                        typedMinutesText = "\(newM)"
                    }) {
                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    
                    HStack(spacing: 4) {
                        TextField("15", text: $typedMinutesText)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(.plain)
                            .frame(width: 65)
                            .focused($isFieldFocused)
                            .onSubmit {
                                commitTimerDuration()
                            }
                            .onChange(of: typedMinutesText) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    typedMinutesText = filtered
                                }
                            }
                        
                        Text("min")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isFieldFocused ? Theme.planned : Color.white.opacity(0.18), lineWidth: 1.5)
                    )
                    
                    Button(action: {
                        let current = Int(typedMinutesText) ?? (timerTotalSeconds / 60)
                        let newM = min(360, current + 1)
                        typedMinutesText = "\(newM)"
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Theme.textPrimary)
                            .frame(width: 30, height: 30)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                
                Text("Click box to type minutes directly")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                
                // Presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach([5, 10, 15, 20, 25, 30, 45, 60], id: \.self) { p in
                            let isSel = Int(typedMinutesText) == p
                            Button(action: {
                                typedMinutesText = "\(p)"
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
                    commitTimerDuration()
                }) {
                    Text("Set Time")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(Theme.planned)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(width: 250)
            .background(Theme.bgDeep)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.6), radius: 24)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isFieldFocused = true
            }
        }
    }
    
    // MARK: - Editor Helpers
    private func openPomodoroEditor(for phase: PomodoroPhaseType) {
        let current = phase == .focus ? pomodoroFocusMinutes : pomodoroBreakMinutes
        typedMinutesText = "\(current)"
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showingDurationEditor = phase
        }
    }
    
    private func commitPomodoroDuration(for phase: PomodoroPhaseType) {
        let parsed = max(1, min(180, Int(typedMinutesText) ?? (phase == .focus ? pomodoroFocusMinutes : pomodoroBreakMinutes)))
        if phase == .focus {
            pomodoroFocusMinutes = parsed
            if !isPomodoroRunning && !isPomodoroInBreak {
                pomodoroSecondsRemaining = parsed * 60
            }
        } else {
            pomodoroBreakMinutes = parsed
            if !isPomodoroRunning && isPomodoroInBreak {
                pomodoroSecondsRemaining = parsed * 60
            }
        }
        withAnimation(.easeOut(duration: 0.2)) {
            showingDurationEditor = nil
        }
    }
    
    private func openTimerEditor() {
        typedMinutesText = "\(timerTotalSeconds / 60)"
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isEditingTimerDuration = true
        }
    }
    
    private func commitTimerDuration() {
        let parsed = max(1, min(360, Int(typedMinutesText) ?? (timerTotalSeconds / 60)))
        timerTotalSeconds = parsed * 60
        if !isTimerRunning {
            timerSecondsRemaining = timerTotalSeconds
        }
        withAnimation(.easeOut(duration: 0.2)) {
            isEditingTimerDuration = false
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
        
        // 3. Countdown Timer Logic
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
                        // Timer complete
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
        
        withAnimation(.easeInOut(duration: 0.7).repeatCount(5, autoreverses: true)) {
            edgeBreathingPhase = 1.0
        }
        
        glowTimerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_500_000_000)
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
