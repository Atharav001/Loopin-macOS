# Logtrackin — Native macOS Timesheet & Workspace App

![macOS](https://img.shields.io/badge/Platform-macOS%2014%2B-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-purple.svg)
![Database](https://img.shields.io/badge/Database-SQLite3-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

**Logtrackin** is a production-grade, 100% native macOS timesheet and logbook workspace application built using **SwiftUI + AppKit + SQLite3**. It combines natural language task planning, an interactive Clockify-style 7×24 week calendar grid with drag-to-create/resize/move, a floating non-activating interval logging panel displaying exact time interval ranges (e.g. `6:00 PM – 7:00 PM`), a left vertical sidebar navigation, a 6-theme multi-theme engine (Clockify, TickTick, Material Dark, Standard Light), keyword auto-classification, deep work analytics, Pomodoro sprint tools, and quiet hours scheduling.

---

## Architecture & Technical Principles

1. **100% Native macOS Architecture**:
   - Zero web views, Electron, or Tauri layers.
   - Real system traffic lights with fullSizeContentView and custom window dragging.
   - Hard minimum window size enforced at 980 × 640 pt (default: 1180 × 760 pt).
   - Window pinning toggle (`window.level = .floating` / `.normal`).
   - Native macOS window appearance dynamically matches light/dark themes (`.aqua` / `.darkAqua`).

2. **Left Vertical Sidebar Navigation**:
   - Quick action `+ New Entry` (Cmd+N).
   - Instant switching between Week Calendar, Timesheet Rails, Analytics & Reports, Dictionary & Rules, Focus & Pomodoro, and Settings.
   - Persistent footer with live 1-hour interval countdown, quick logging trigger, and pin-to-top toggle.

3. **6-Theme Multi-Theme Engine**:
   - **Clockify Dark**: Deep midnight slate `#0B0F19` with signature cyan accents.
   - **Clockify Light**: Soft grey canvas `#F4F5F7` with crisp white cards and cyan accents.
   - **TickTick Dark**: Warm slate `#1E2022` with royal blue accents.
   - **TickTick Light**: Modern white `#F6F7F9` with TickTick blue buttons.
   - **Normal Dark (Google/Microsoft)**: Material surfaces `#121212` with Google blue accents.
   - **Standard Light**: Pure white Apple/Google minimal light aesthetic.
   - Full-hierarchy dynamic layer adaptation across cards, panels, pickers, and text.

4. **Clockify-Style 7×24 Week Grid**:
   - Continuous mouse interaction with 15-minute time snapping.
   - Top and bottom resize handles with `NSCursor.resizeUpDown`.
   - Planned (dashed outline) vs. Logged (solid fill) entry visualization.
   - 12-hour (AM/PM) and 24-hour military clock display toggle.

5. **Floating Interval-Logging Panel (`NSPanel`)**:
   - Subclassed `NSPanel` floating over full-screen apps and macOS Spaces.
   - Displays exact computed time intervals (e.g. `6:00 PM – 7:00 PM`).
   - Breathing glow border animation with voice dictation support.
   - Quiet hours evaluation supporting overnight ranges (e.g. 22:00 to 07:00).

6. **Local SQLite Data Layer**:
   - Thread-safe storage in `~/Library/Application Support/Loopin/loopin.sqlite`.
   - On-device privacy with zero required cloud dependencies.

---

## Screens & Features

- **Week Calendar**:
  - 7 day-columns × 24 hours with sticky time gutter and 30-min subdivisions.
  - Drag-to-create, edge resizing, block moving, and click-to-edit sheet.
  - Week navigation with `< Prev Week`, `Today`, `Next Week >`.

- **Timesheet Rails (Today's Overview)**:
  - Natural-language quick-add bar ("coding 2-4pm", "standup 10am to 11am").
  - Live interval countdown banner with quick reschedule buttons.
  - Dual 24-hour horizontal scrolling rails (Planned top, Logged bottom) with live red "now" line.
  - Interactive block list with category badges and edit/delete actions.

- **Analytics & Reports**:
  - KPI cards: Total Tracked, Focus Score %, Productive Time, Distraction Time.
  - Stacked horizontal productivity ratio bar.
  - Category distribution bar chart with hover tooltips.
  - Timeframe selector: Today, This Week, Past 7 Days, This Month.

- **Dictionary (Classification Rules)**:
  - Longest-phrase matching engine for auto-categorization.
  - Rule CRUD: add, edit, search, filter, and delete.
  - Automatic learning when editing any entry's category.

- **Settings & Preferences**:
  - Appearance & Theme switcher with 6 interactive theme preview cards.
  - 12h / 24h clock toggle and Monday/Sunday week start selector.
  - 1-hour interval prompt window settings (15m, 30m, 45m, 60m frequency, float over full-screen apps, acoustic chimes).
  - Pomodoro focus duration and auto-start break timers.
  - Quiet hours start/end scheduling.
  - Instant one-click **Export to JSON** and **Export to CSV** (copied to clipboard).

- **Menu Bar Extra**:
  - Minimal, clean icon-only status item in the macOS menu bar for quick logging and countdown visibility.

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

### Create Native Application Bundle (`Logtrackin.app`)
```bash
./build_app.sh
open Logtrackin.app
```

---

## Cross-Platform Architecture (macOS + Android + Cloud)

### 1. Supabase Cross-Device Sync Engine
- Real-time cloud sync with offline-first SQLite cache.
- Local changes are recorded with `syncStatus` flags and synced in the background with Last-Write-Wins conflict resolution based on `updatedAt`.
- Configurable directly from the Loopin Settings tab.

### 2. Two-Way Google Calendar Integration
- Automatically connects and writes to two dedicated Google Calendars:
  - **Loopin Planned**: Planned timesheet blocks.
  - **Loopin Logged**: Actual recorded work and activities.
- Instantly reflects on standard Google Calendar mobile widgets (lock screen and home screen) without extra apps.

### 3. Android Mobile Client (`/android`)
- **UI**: Jetpack Compose with Dark Glass styling matching the macOS app.
- **Local Storage**: Room Database mirroring the SQLite schema.
- **Hourly Logging Service**: Android foreground service with a non-dismissible notification prompt.
- **Inline Notification Reply**: Type what you did directly in the notification bar via Android `RemoteInput` without opening the app, or tap voice/skip.
- **Local Rule Classifier**: Instant on-device classification into Productive, Neutral, or Wasteful categories (gaming, room scrolling, YouTube watching, binge watching).
