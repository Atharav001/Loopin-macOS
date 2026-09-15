# Loopin — Timesheet & Logbook — PRD v2 (Full Rebuild)

This replaces all prior implementation. The previous build (screenshot-verified) is web-rendered UI dressed up as a macOS window: drawn traffic lights instead of real ones, no real title-bar drag region, fixed-pixel columns that clip at the window edge, and no working interaction — clicking just repositions the whole window. None of that is fixable by patching; it's rebuilt native from Phase 0.

## 0. Hard technical constraints (non-negotiable, this is why the last build failed)

- **100% native AppKit + SwiftUI. No WebView, no Electron, no Tauri, no HTML/CSS anywhere in the UI layer.** Every visual bug in the screenshot (fake traffic lights, whole-window dragging, clipped columns) is a direct symptom of web-rendered UI. A native `NSWindow` gives you real traffic lights, real title-bar dragging, and real Auto Layout/SwiftUI reflow for free — most of the previous bug list disappears just by using the right technology, before a single feature is built.
- **The window background must never be globally draggable.** `NSWindow.isMovableByWindowBackground` (AppKit) / `.windowBackgroundDragBehavior` (SwiftUI `Scene`) must be explicitly `false`/`.disabled`. Dragging is only ever triggered by (a) the real system title bar, standard behavior, no code needed, or (b) an explicit `WindowDragGesture` attached to one named drag-handle view — never to a whole screen's background.
- **Every scrollable/grid area must consume its own drag gestures.** The week calendar's drag-to-create gesture is attached directly to the grid view with `.contentShape(Rectangle())` so the entire grid (including empty space) is hit-testable and captures the drag before it can ever reach the window.
- **No fixed-pixel column widths that can clip.** All multi-column layouts (week view, timesheet rails) live inside a `ScrollView(.horizontal)` with a defined minimum window width; columns compute their width from available space, never hard-coded pixel values that assume a specific window size.
- **Every screen must be genuinely interactive from the first phase it appears in.** No "static mockup" phases — if a button is on screen, it does something, even if that something is just writing to a local array, before the phase is marked done.

## 1. Tech stack
- Swift, SwiftUI for view composition, AppKit interop (`NSViewRepresentable`/`NSPanel` subclass) specifically for: the main window's title bar/traffic-light behavior, the week-grid's mouse-drag handling, and the floating logging panel.
- GRDB (SQLite wrapper) for local storage — direct, typed, no ORM magic that hides bugs.
- No backend, no accounts, no network calls anywhere in this rebuild's phases. That layer returns later, unchanged in concept from the previously agreed plan, once this native shell is solid.

## 2. Main window specification
- **Default size:** 1180 × 760 pt. **Minimum size:** 980 × 640 pt (below this, the week view's 7 columns cannot render legibly — enforced via `NSWindow.minSize`, not just a suggestion). **Resizable:** yes, both axes, standard green-button zoom to full-height/width.
- **Title bar:** standard system title bar (`.titled` style mask), real traffic lights, title text "Loopin". `titlebarAppearsTransparent = true` with a `fullSizeContentView` so the dark theme extends under the title bar, but the traffic lights and drag behavior remain 100% system-native — this is the detail the previous build got wrong by drawing its own.
- **Dragging:** only via the real title bar (automatic, zero custom code) — `isMovableByWindowBackground` explicitly set `false`.
- **Pin-on-top toggle** (the pin icon in the header): toggles `window.level` between `.normal` and `.floating`. This is a deliberate, explicit user action — the main window is not floating by default, only the interval-logging panel (Section 5) is.

## 3. Navigation shell
- A single row of tab buttons: **Rails** (today's overview), **Week Calendar**, **Analytics & Reports**, **Dictionary**, **Focus & Prompts** (settings). Implemented as a plain `HStack` of `Button`s bound to a `@State selectedTab` enum — no custom tab-bar view that could intercept drag gestures.
- Tab switch must be instant and must actually swap the visible SwiftUI view (`switch selectedTab { }` in the body) — not a static asset toggle.

## 4. Screen specs

### 4.1 Rails (today's overview)
- **Quick-plan input**: single-line text field with a "PLANNED" badge prefix, mic button, submit arrow. On submit, runs the natural-language parser (Section 6.3) and inserts a `planned` `TimesheetEntry`. Must actually create a row in the local database and immediately reflect on the rails below — no placeholder text.
- **Interval Logging Active banner**: shows the countdown to the next prompt, computed live from a running timer (`Timer.publish` or `DispatchSourceTimer`), not a static string. Interval buttons (5m/10m/15m/25m) are real controls that reschedule the timer immediately on tap.
- **Today's Timesheet Rails**: two horizontal rail rows (planned above, logged below) spanning a scrollable 24-hour axis. A vertical red "now" line at the current time, updated every 60s. Rails are drawn with SwiftUI `Canvas` or stacked `Rectangle` views positioned by computed offset (`hour * hourWidth`), inside a `ScrollView(.horizontal)` — this is what prevents the clipping seen in the screenshot; there is no fixed total width assumption.
- **Legend**: Productive / Neutral / Wasteful / Planned / Skipped — static color key, no interaction needed.
- **Today's Blocks Breakdown**: list of today's entries; empty state shown only when the list is genuinely empty, driven by the real query result count, not a hardcoded empty view.

### 4.2 Week Calendar — the Clockify-style grid (highest-risk screen, spec'd in full)
- Layout: 7 day-columns × 24 hour-rows (30-min sub-rows for finer placement), inside `ScrollView([.horizontal, .vertical])`. Each day column has a **minimum width of 140pt**; if the window is wider than 7×140pt + the time-axis gutter, columns grow evenly to fill the space — computed each layout pass, never hard-coded.
- **Click-and-drag to create an entry** (this is the specific Clockify interaction requested):
  1. `mouseDown` inside an empty grid cell records the start Y-position, converted to a time value snapped to the nearest 15 minutes.
  2. `mouseDragged` extends a live translucent selection rectangle from the start point to the current cursor Y, re-snapping the end time to the nearest 15 minutes on every move.
  3. `mouseUp` opens an inline popover anchored to the selection with a title field and category picker; confirming writes a new `TimesheetEntry` (`kind: planned` if dragged on a future date, `kind: logged` if on today/past) spanning exactly the dragged range; canceling discards the selection with no side effects.
  - Implementation note: this needs real `NSView` mouse-event handling (`mouseDown(with:)`, `mouseDragged(with:)`, `mouseUp(with:)`) wrapped via `NSViewRepresentable`, not a SwiftUI `DragGesture` alone — SwiftUI's gesture system doesn't cleanly expose the continuous "extend a rectangle while tracking snapped grid lines" interaction Clockify uses. The wrapped `NSView` reports the resolved time range back to SwiftUI via a closure/binding.
- **Resizing an existing entry**: dragging its top or bottom edge (an 6pt hit-zone) adjusts start/end time with the same 15-minute snapping; dragging its body (not an edge) moves the whole block to a new time.
- **Clicking an existing entry** (no drag) opens the same inline editor prefilled with its current data.
- Planned and logged entries render in the same grid, distinguished by fill style (solid = logged, outlined = planned), matching DESIGN.md's existing rule.

### 4.3 Analytics & Reports
- Daily/weekly totals, category breakdown bar chart, productive-vs-wasteful stacked bar. Pure local aggregation queries against `TimesheetEntry`, computed on tab appearance — no cached/static numbers.

### 4.4 Dictionary
- List of `ClassificationRule` rows (phrase → category → productivity), each editable inline, a "+" row to add a new mapping, swipe/right-click to delete. This screen is the direct UI for the corrections described in the prior PRD's Section 3.3 — must actually persist edits to the local database on change.

### 4.5 Focus & Prompts (settings)
- Interval picker (same options as the Rails banner, single source of truth — changing it here updates the running timer immediately).
- **Quiet hours**: two time pickers, "from" and "to". Stored as local time-of-day values. The interval-prompt scheduler checks `isWithinQuietHours(now)` before firing, handling overnight ranges (e.g. 22:00–07:00) by checking `now >= start || now < end` when `start > end`, and `start <= now < end` otherwise. No prompts fire, no panel opens, during this window — verified by an explicit unit test with a mocked clock at the exact boundary minutes.
- Pomodoro duration settings (carried over from the existing focus-timer feature, unchanged).

## 5. The floating interval-logging panel — exact spec
- Built as an `NSPanel` subclass (not a plain `NSWindow`, not a SwiftUI `.sheet`), configured exactly as follows:
  - `styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView]`
  - `isFloatingPanel = true`, `level = .floating`
  - `becomesKeyOnlyIfNeeded = true` — the panel does not steal focus from whatever app is frontmost merely by appearing, but becomes key the instant the user clicks its text field, so typing works immediately without an extra click.
  - `hidesOnDeactivate = false` — stays visible even if the user switches to a different app, satisfying "requires user interaction" instead of silently vanishing.
  - `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]` — visible over full-screen apps and on every Space, so it can't be missed by being on the "wrong desktop."
  - `isMovableByWindowBackground = true` is acceptable **on this specific panel only** (it's a small, self-contained utility window with no internal scroll/grid competing for the gesture) — this is the one exception to the Section 0 rule, and it's safe specifically because the panel has no draggable content inside it.
- Content: text field (autofocused on appear), mic button (on-device speech-to-text), Skip button. Breathing-glow border while unanswered (DESIGN.md Section 2.1).
- Fires on the configured interval **unless** `isWithinQuietHours(now)` is true (Section 4.5) — checked at the moment of firing, not just at schedule-setup time, so a mid-wait change to quiet hours takes effect immediately.
- Answering (typed/voice) or skipping writes a `logged`/`skipped` entry and dismisses the panel with the ripple-confirm or muted-fade animation respectively (DESIGN.md Section 2.2/3.2).

## 6. Supporting logic
### 6.1 Data model
Unchanged from the prior PRD's `TimesheetEntry`/`ClassificationRule` schema — still correct, was never the problem.

### 6.2 Classification
Unchanged local keyword-dictionary approach — still correct.

### 6.3 Natural-language quick-add parsing
"coding 2-4pm" → parses a relative/explicit time range and title via a small local parser (regex/date-detector based, e.g. `NSDataDetector` for date/time spans) — no network call, no LLM.

## 7. Explicitly out of scope for this rebuild's phases
Backend/accounts, Google Calendar sync, Android client — conceptually unchanged from the previously delivered plan, resumed only after the native macOS shell above is verified solid end-to-end. Rebuilding those isn't necessary; they weren't the source of the problems in the screenshot.

## 8. Definition of "not a mockup" (applies to every phase in the implementation plan)
A phase is only complete when: the window can be freely resized and dragged only by its real title bar with zero drift; every visible control performs its real action against the local database; the week grid can create, resize, and move an entry by mouse drag exactly as spec'd in 4.2; and no column, row, or text is clipped at the rebuild's minimum window size (980×640).
