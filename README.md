# Loopin — Native macOS Timesheet & Logbook App

![macOS](https://img.shields.io/badge/Platform-macOS%2014%2B-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-purple.svg)
![Database](https://img.shields.io/badge/Database-SQLite3-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

**Loopin** is a production-grade, 100% native macOS timesheet and logbook application built using **SwiftUI + AppKit + SQLite3**. It combines natural language task planning, an interactive Clockify-style 7×24 week grid with drag-to-create/resize/move, a floating non-activating interval logging panel with breathing glow border, keyword auto-classification, deep work analytics, and quiet hours scheduling.

---

## Architecture & Technical Principles

1. **100% Native macOS Architecture**:
   - Zero web views, Electron, or Tauri layers.
   - Real system traffic lights (close, minimize, zoom/full-screen).
   - Real macOS title-bar dragging with `isMovableByWindowBackground = false`.
   - Hard minimum window size enforced at 980 × 640 pt (default: 1180 × 760 pt).
   - Window pinning toggle (`window.level = .floating` / `.normal`).

2. **Clockify-Style 7×24 Week Grid**:
   - Continuous AppKit mouse interaction (`mouseDown`, `mouseDragged`, `mouseUp`) wrapped via `NSViewRepresentable`.
   - 15-minute time snapping on drag-to-create and edge resizing.
   - 6pt top and bottom resize handles with `NSCursor.resizeUpDown`.
   - Planned (dashed outline) vs. Logged (solid fill) entry visualization.
   - Dynamic column expansion across window widths.

3. **Floating Interval-Logging Panel (`NSPanel`)**:
   - Subclassed `NSPanel` with `[.nonactivatingPanel, .titled, .fullSizeContentView]`.
   - Floats over full-screen applications and all macOS Spaces without stealing key focus until clicked.
   - Breathing glow border animation while unanswered.
   - Voice dictation integration with Apple's `Speech` framework.
   - Quiet hours evaluation supporting overnight ranges (e.g. 22:00 to 07:00).

4. **Local SQLite Data Layer**:
   - Thread-safe storage in `~/Library/Application Support/Loopin/loopin.sqlite`.
   - Zero external cloud dependencies — 100% on-device privacy.

---

## Screens & Features

- **Rails (Today's Overview)**:
  - Natural-language quick-add bar ("coding 2-4pm", "standup 10am to 11am").
  - Live interval countdown banner with 5m/10m/15m/25m quick reschedule buttons.
  - Dual 24-hour horizontal scrolling rails (Planned top, Logged bottom) with live red "now" line.
  - Interactive block list with category badges and edit/delete actions.

- **Week Calendar**:
  - 7 day-columns × 24 hours with 30-min subdivisions and sticky time gutter.
  - Drag-to-create, block edge resizing, block moving, and click-to-edit.
  - Week navigation with `< Prev Week`, `Today`, `Next Week >`.

- **Analytics & Reports**:
  - KPI cards: Total Tracked, Focus Score %, Productive Time, Distraction Time.
  - Stacked horizontal productivity ratio bar.
  - Category distribution bar chart with hover tooltips.
  - Timeframe selector: Today, This Week, Past 7 Days, This Month.

- **Dictionary (Classification Rules)**:
  - Longest-phrase matching engine for auto-categorization.
  - Rule CRUD: add, edit, search, filter, and delete.
  - Automatic learning when editing any entry's category.

- **Focus & Prompts (Settings)**:
  - Interval prompt scheduler (5m, 10m, 15m, 25m, custom).
  - Quiet hours configuration with overnight wraparound support.
  - Pomodoro focus timer with visual progress ring, presets, and sound alerts.
  - Data management (seed demo entries, clear database).

- **Menu Bar Extra**:
  - macOS Status Item in the top menu bar for quick logging and Pomodoro control.

---

## Building and Running

### Prerequisites
- macOS 14.0 or newer
- Xcode 15+ / Swift 5.9+

### Build & Run via Terminal
```bash
# Clone the repository
git clone https://github.com/Atharav001/Loopin-macOS.git
cd Loopin-macOS

# Run tests
swift test

# Build and launch
swift run
```

### Create Native Application Bundle (`Loopin.app`)
```bash
./build_app.sh
open Loopin.app
```
