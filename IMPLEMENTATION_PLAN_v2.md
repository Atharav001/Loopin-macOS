# Loopin — Native macOS Rebuild — Implementation Plan v2

Read PRD_v2.md first — every phase below implements a specific section of it. Each phase lists: goal, exact technical steps, the specific bug from the old build it prevents, and a testable exit check. Do not proceed to the next phase until the exit check passes on a real running build — not a preview, not a screenshot.

---

## Phase 0 — Window shell (prove the drag bug is dead before building anything else)

**Goal:** a completely empty app that is just a correctly behaving native window. No features. This phase exists specifically to isolate and kill the window-dragging bug before any UI is layered on top of it.

**Technical steps:**
1. New macOS SwiftUI App target. In the `App` struct's `Scene`:
   ```swift
   Window("Loopin", id: "main") {
     ContentView()
   }
   .windowBackgroundDragBehavior(.disabled)   // macOS 15+; see step 2 for the AppKit fallback
   .defaultSize(width: 1180, height: 760)
   ```
2. For the `NSWindow` itself (grab it via an `NSViewRepresentable` background helper or `NSApp.windows.first` in `.onAppear`), explicitly set:
   ```swift
   window.isMovableByWindowBackground = false
   window.titlebarAppearsTransparent = true
   window.titleVisibility = .visible
   window.styleMask.insert(.fullSizeContentView)
   window.minSize = NSSize(width: 980, height: 640)
   ```
3. `ContentView` at this phase is just a full-bleed dark `Rectangle()` with the text "Loopin" centered — nothing else.

**Prevents:** the whole-window-drags-on-any-click bug from the screenshot (root cause: background was globally draggable, likely combined with no real title bar at all).

**Exit check:** run the app. Confirm: (a) dragging the real title bar moves the window normally, (b) clicking and dragging anywhere in the dark content area does **nothing** to the window position, (c) resizing from a corner works and refuses to go below 980×640, (d) the traffic lights are real system controls (hover shows the standard close/min/zoom icons, not static drawn circles).

---

## Phase 1 — Local data layer
**Goal:** `TimesheetEntry` and `ClassificationRule` tables exist and are readable/writable, with zero UI yet.

**Technical steps:**
1. Add GRDB via Swift Package Manager.
2. Define the schema exactly as PRD_v2 §6.1 (carried from the prior PRD):
   ```swift
   struct TimesheetEntry: Codable, FetchableRecord, PersistableRecord {
     var id: String
     var kind: String        // "planned" | "logged"
     var startAt: Date
     var endAt: Date
     var rawText: String
     var inputMethod: String // "typed" | "voice" | "skipped"
     var category: String?
     var subcategory: String?
     var productivity: String? // "productive" | "neutral" | "wasteful"
     var updatedAt: Date
   }
   ```
3. A `DatabaseManager` singleton opens the DB file in Application Support, runs a migration creating both tables, exposes `insert`, `update`, `fetchForDay(_ date: Date)`, `fetchForWeek(_ weekStart: Date)`.
4. Write 3–4 unit tests: insert an entry, fetch it back, update it, confirm `fetchForDay` returns only same-day rows.

**Exit check:** unit tests pass. No UI exists yet — this is intentional, confirms the data layer is correct in isolation before it's ever rendered.

---

## Phase 2 — Navigation shell + Rails screen (read-only first)
**Goal:** the 5-tab navigation works, and the Rails screen renders real data from Phase 1 (seed a few test rows manually) — no interactivity yet beyond tab switching.

**Technical steps:**
1. `enum Tab { case rails, week, analytics, dictionary, focusPrompts }`, `@State private var selectedTab: Tab = .rails` in `ContentView`.
2. Tab bar: plain `HStack` of `Button(action: { selectedTab = .rails }) { Text("Rails") }` etc., each with a `.background(selectedTab == .rails ? accentColor : clear)` — a normal SwiftUI view, deliberately not a custom drag-capable container.
3. Rails screen: query `DatabaseManager.fetchForDay(Date())`, render the two rail rows as a `Canvas` where each entry is a filled rectangle at `x = hourOffset(entry.startAt) * hourWidth`, width `= duration * hourWidth`, inside `ScrollView(.horizontal) { }` — confirms the no-fixed-width rule from PRD_v2 §0 from the very first rendered screen.
4. Legend and empty-state text render conditionally on `entries.isEmpty`.

**Prevents:** the "static image, nothing switches" complaint — tab switching here is a real `@State` change driving a real `switch` in the body, and the rails are drawn from a real query, not a placeholder asset.

**Exit check:** switching tabs shows different (even if mostly blank) screens instantly. Seeding a test entry via a debug button visibly appears on the rail at the correct horizontal position, and resizing the window narrower/wider does not clip anything — the scroll view engages instead.

---

## Phase 3 — Week Calendar grid: render only (no drag yet)
**Goal:** the 7×24 grid renders correctly at any window width, with existing entries shown as blocks. Drag-to-create comes in Phase 4 — kept separate so a rendering bug and a gesture bug are never debugged at the same time.

**Technical steps:**
1. `WeekGridView`: a `ScrollView([.horizontal, .vertical])` containing an `HStack` of 7 `DayColumnView`s, each `.frame(minWidth: 140)`.
2. Each `DayColumnView` is a `ZStack` of: 48 half-hour gridlines (`Divider()` at computed y-offsets), plus one rectangle per `TimesheetEntry` on that day positioned by `y = timeOffset(entry.startAt) * hourHeight`, `height = duration * hourHeight`.
3. Time-axis gutter on the left (fixed 48pt width, outside the horizontal scroll so hour labels stay visible while scrolling days — implemented as a separate non-scrolling `VStack` overlapping the `ScrollView`, or a pinned header/leading column pattern).
4. Current-time red line: a `Rectangle` positioned at today's column, updated by a `Timer` firing every 60s.

**Exit check:** at the minimum window size (980×640), all 7 columns are visible and scrollable, none clipped; at a wider size, columns grow to fill space rather than leaving dead space or clipping. Seeded entries from Phase 1's test data appear as correctly positioned/sized blocks.

---

## Phase 4 — Week Calendar: drag-to-create, resize, move
**Goal:** the actual Clockify-style interaction from PRD_v2 §4.2.

**Technical steps:**
1. Wrap the grid's interaction layer in an `NSViewRepresentable`:
   ```swift
   final class GridInteractionView: NSView {
     var onDragChanged: ((CGPoint, CGPoint) -> Void)?
     var onDragEnded: ((CGPoint, CGPoint) -> Void)?
     private var dragStart: CGPoint?

     override func mouseDown(with event: NSEvent) {
       dragStart = convert(event.locationInWindow, from: nil)
     }
     override func mouseDragged(with event: NSEvent) {
       guard let start = dragStart else { return }
       onDragChanged?(start, convert(event.locationInWindow, from: nil))
     }
     override func mouseUp(with event: NSEvent) {
       guard let start = dragStart else { return }
       onDragEnded?(start, convert(event.locationInWindow, from: nil))
       dragStart = nil
     }
   }
   ```
2. In the SwiftUI wrapper, convert the two `CGPoint`s to snapped `Date` values: `let minutes = round((y / hourHeight) * 60 / 15) * 15` (15-minute snap), map to a `Date` for that column's day.
3. While dragging, overlay a translucent `Rectangle` between the snapped start/current time — this is `@State` driven, updating live on every `onDragChanged` call.
4. On `mouseUp`, if the drag was over empty space: open a `.popover` anchored at the release point with a title `TextField` and a category `Picker`; confirming calls `DatabaseManager.insert(...)` and dismisses; canceling discards.
5. If the drag started on an existing entry's edge (hit-test a 6pt zone at the block's top/bottom before starting a new-entry drag), resize that entry's `startAt`/`endAt` instead of creating a new one. If it started on the entry's body (not an edge), move the whole block by the drag delta.
6. Every write goes through `DatabaseManager.update`, and the view re-queries/re-renders immediately (SwiftUI `@Query`/`@State` refresh) — no separate "save" step the user could forget.

**Prevents:** the "just a static image" complaint specifically — this phase is where the app becomes genuinely operable by mouse, matching the exact Clockify interaction requested.

**Exit check:** clicking and dragging on an empty grid cell shows a live-growing selection rectangle snapped to 15-minute lines; releasing opens the entry popover; confirming shows the new block immediately; dragging an existing block's edge resizes it; dragging its body moves it; none of this ever moves the window itself (re-confirm Phase 0's check still holds now that a drag gesture exists in the content area).

---

## Phase 5 — Floating interval-logging panel + quiet hours
**Goal:** PRD_v2 §5 exactly.

**Technical steps:**
1. Subclass `NSPanel`:
   ```swift
   final class LoggingPanel: NSPanel {
     init(contentView: NSView) {
       super.init(contentRect: NSRect(x: 0, y: 0, width: 360, height: 160),
                   styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
                   backing: .buffered, defer: false)
       isFloatingPanel = true
       level = .floating
       becomesKeyOnlyIfNeeded = true
       hidesOnDeactivate = false
       isMovableByWindowBackground = true
       collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
       self.contentView = contentView
     }
   }
   ```
2. A `LoggingScheduler` singleton holds a `Timer` (or `DispatchSourceTimer`) at the configured interval. On fire: call `isWithinQuietHours(Date())`; if true, skip silently and reschedule; if false, instantiate `LoggingPanel`, show it, and start the breathing-glow animation on its border.
3. `isWithinQuietHours(_ date: Date) -> Bool`:
   ```swift
   func isWithinQuietHours(_ date: Date, start: DateComponents, end: DateComponents) -> Bool {
     let cal = Calendar.current
     let nowMinutes = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
     let startMinutes = (start.hour ?? 0) * 60 + (start.minute ?? 0)
     let endMinutes = (end.hour ?? 0) * 60 + (end.minute ?? 0)
     if startMinutes <= endMinutes {
       return nowMinutes >= startMinutes && nowMinutes < endMinutes
     } else { // overnight range, e.g. 22:00–07:00
       return nowMinutes >= startMinutes || nowMinutes < endMinutes
     }
   }
   ```
4. Panel content: `TextField` (autofocus via `.onAppear { window.makeFirstResponder(textField) }`), mic button wired to `SFSpeechRecognizer` (on-device recognition request), Skip button. Any of the three writes a `TimesheetEntry` (`kind: logged`, `inputMethod` set accordingly) and closes the panel with the matching animation from DESIGN.md.

**Exit check:** with the interval set to 1 minute for testing, the panel appears reliably, floats over a full-screen app (verify by full-screening Safari first), does not steal focus until its text field is clicked, and does not appear at all when the current time is set (via system clock, for testing) inside a configured quiet-hours window — verify both the normal and overnight-wraparound cases explicitly.

---

## Phase 6 — Classification (Dictionary tab)
**Goal:** PRD_v2 §4.4/§6.2.

**Technical steps:**
1. `ClassificationRule` CRUD screen: `List` bound directly to a `@State [ClassificationRule]` refreshed from `DatabaseManager` on appear and after every edit.
2. Classifier function: on any new `logged`/`planned` entry's `rawText`, lowercase it, check for substring matches against all rules' `phrase`, pick the longest matching phrase (avoids "youtube" matching before a more specific "youtube shorts" rule), set `category`/`productivity` accordingly; no match → `category = nil` (renders as "Uncategorized" in the UI).
3. Editing an entry's category in any screen (Rails, Week grid popover) writes a new/updated `ClassificationRule` for that exact phrase automatically — this is the "correction persists" behavior from the PRD.

**Exit check:** typing "watched youtube" in the quick-plan or logging panel auto-tags Wasteful/YouTube Watching (after seeding that starter rule); correcting a wrongly-tagged entry once causes the identical phrase to classify correctly on the next entry, verified by creating two entries with the same text in the same session.

---

## Phase 7 — Analytics & Reports
**Goal:** PRD_v2 §4.3.

**Technical steps:** query `TimesheetEntry` for the selected day/week, group by `category`, sum durations; render a simple bar per category using plain SwiftUI `Rectangle` bars sized proportionally (no charting library needed for this simplicity) plus one stacked bar for productive vs. wasteful totals.

**Exit check:** with a week of seeded test data spanning several categories, the breakdown numbers match a manual sum you compute by hand from the seed data.

---

## Phase 8 — Focus & Prompts (settings) — full screen
**Goal:** wire the interval picker and quiet-hours pickers (built in isolation in Phase 5) into a real settings UI, plus carry over the existing Pomodoro duration settings.

**Technical steps:** standard SwiftUI `Form` with a segmented interval picker and two `DatePicker(.hourAndMinute)` fields for quiet hours start/end, all bound to `@AppStorage` or a settings row in the database, read by `LoggingScheduler` on every change (not just at app launch).

**Exit check:** changing the interval here immediately reschedules the next panel fire without restarting the app; changing quiet hours takes effect on the very next scheduled fire, even mid-wait.

---

## Phase 9 — Animation pass
**Goal:** DESIGN.md's breathing glow / ripple confirm / edge-slide nudge, applied to the now-fully-functional screens from Phases 2–8.

**Technical steps:** implement as reusable `ViewModifier`s (`.breathingGlow(active:)`, `.rippleConfirm(trigger:)`) so they're applied identically everywhere rather than hand-rolled per screen; add the `accessibilityReduceMotion` environment check to fall back to static equivalents per DESIGN.md §5.

**Exit check:** completing a logging-panel entry shows the ripple once, not on a loop; the panel's border breathes only while unanswered and stops immediately on submit; enabling Reduce Motion in System Settings removes all looping animation app-wide.

---

## Phase 10 onward
Backend/accounts, Google Calendar two-way sync, and the Android client resume exactly as previously specified (the earlier IMPLEMENTATION_PLAN.md's Phases 21–26, renumbered to follow on from Phase 9 here) — unchanged in concept, since none of that was the source of the problems in the screenshot. Do not begin Phase 10 until Phases 0–9 above pass every exit check on a real running build.
