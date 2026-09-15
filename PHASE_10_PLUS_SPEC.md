# Loopin — Phase 10+ Architecture & Next Steps Specification

This document details the cross-platform roadmap extending the validated native macOS app (**Phases 0–9**) into a synced multi-device ecosystem (macOS ↔ Supabase ↔ Google Calendar ↔ Android).

---

## 1. Core Data Model & Supabase Backend Sync

### 1.1 Timesheet Schema & Sync Protocol
Both **Planned** and **Logged** timesheets are represented in a unified schema with a `kind` discriminator, allowing direct overlay comparisons (Clockify-style planned-vs-actual):

```sql
-- Supabase / PostgreSQL Schema
CREATE TYPE entry_kind AS ENUM ('planned', 'logged');
CREATE TYPE input_method_type AS ENUM ('typed', 'voice', 'skipped');
CREATE TYPE productivity_type AS ENUM ('productive', 'neutral', 'wasteful');

CREATE TABLE timesheet_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    kind entry_kind NOT NULL,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    raw_text TEXT NOT NULL,
    input_method input_method_type NOT NULL DEFAULT 'typed',
    category TEXT,
    subcategory TEXT,
    productivity productivity_type,
    gcal_event_id TEXT,
    device_id TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Row-Level Security (RLS)
ALTER TABLE timesheet_entries ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access their own entries"
    ON timesheet_entries
    FOR ALL
    USING (auth.uid() = user_id);

CREATE INDEX idx_entries_user_range ON timesheet_entries(user_id, start_at, end_at);
CREATE INDEX idx_entries_updated ON timesheet_entries(user_id, updated_at);
```

### 1.2 Offline-First Sync Engine (macOS & Android)
- **Local SQLite / Room Cache**: Writes are instant to local storage.
- **Sync Worker**: Batches entries where `updated_at > last_sync_timestamp`.
- **Conflict Resolution**: Last-Write-Wins (LWW) based on `updated_at` with client monotonic timestamps.
- **Supabase Realtime**: Listens to `INSERT` / `UPDATE` / `DELETE` on `timesheet_entries` filtering by `user_id=eq.{id}` for instant cross-device reflection.

---

## 2. Google Calendar Two-Way Sync

### 2.1 Dedicated Calendars
To prevent polluting personal schedules, Loopin provisions two dedicated Google Calendars under the user's Google account:
1. **Loopin Planned** (`#A855F7` - Purple)
2. **Loopin Logged** (`#22C55E` - Green / Productivity Color)

### 2.2 Sync Flow
- User adds planned/logged block in Loopin -> saves to local SQLite (0ms) -> syncs to Supabase.
- Background worker pushes event to Google Calendar API -> receives `gcal_event_id` -> attaches to entry.
- When modified from Google Calendar (e.g., via phone widget), delta-sync (`syncToken`) updates Loopin client.

### 2.3 Mobile Widget Integration
Because events are pushed directly to Google Calendars, standard Google Calendar home screen and lock screen widgets on Android and iOS automatically display logged and planned blocks with zero extra setup.

---

## 3. Classification Engine: Waste vs. Productive Hierarchy

### 3.1 Taxonomy Breakdown

| Productivity Level | Primary Category | Subcategories / Segments | Example Matched Keywords |
| :--- | :--- | :--- | :--- |
| **Productive** | **Deep Work** | Coding, Writing, Design, Architecture | `swift`, `code`, `xcode`, `github`, `pr review`, `debug`, `figma` |
| **Productive** | **Engineering** | System Design, Server config, DevOps | `aws`, `docker`, `terminal`, `deploy`, `ci/cd`, `database` |
| **Productive** | **Meeting / Collab** | Standup, Sync, Client Call, 1-on-1 | `meeting`, `standup`, `sync`, `interview`, `client call`, `zoom` |
| **Productive** | **Learning** | Reading Docs, Tutorial, Research | `research`, `reading`, `docs`, `paper`, `studying` |
| **Neutral** | **Admin / Email** | Inbox, Slack, Scheduling | `email`, `mail`, `slack`, `calendar`, `inbox zero` |
| **Neutral** | **Life / Rest** | Meals, Coffee, Commute, Exercise | `lunch`, `breakfast`, `dinner`, `coffee`, `walk`, `gym`, `commute` |
| **Wasteful** | **Social Scrolling** | Room scrolling, Feed scrolling | `scroll`, `scrolling`, `insta`, `instagram`, `reels`, `tiktok`, `twitter`, `x.com`, `reddit` |
| **Wasteful** | **YouTube Watching** | Shorts, Long-form videos | `youtube`, `youtube shorts`, `vlog`, `yt` |
| **Wasteful** | **Binge Watching** | TV Shows, Episodes, Seasons | `netflix`, `series`, `episode`, `season`, `anime`, `binge` |
| **Wasteful** | **Movie Watching** | Feature Films, Streaming | `movie`, `film`, `cinema`, `hotstar`, `prime video` |
| **Wasteful** | **Gaming** | Ranked matches, casual games | `cod`, `call of duty`, `valorant`, `fifa`, `game`, `gaming`, `steam` |

### 3.2 Dynamic Phrase Learning
Whenever an entry is reclassified by the user in the UI, `ClassifierEngine.learnRule()` registers that phrase into `classification_rules` locally and syncs to Supabase. Future occurrences auto-tag with the learned rule.

---

## 4. Android Client Specification

### 4.1 Tech Stack
- **Language**: Kotlin 2.0+
- **UI**: Jetpack Compose with Material 3 (custom dark glass styling matching macOS app)
- **Local DB**: Room Database (mirroring `TimesheetEntry` and `ClassificationRule`)
- **Backend / Auth**: Supabase Kotlin SDK (Postgres, Auth, Realtime)

### 4.2 Foreground Service & Hourly Prompt Notification
- **Foreground Service**: Runs persistent background timer immune to Android Doze mode.
- **Actionable Notification**:
  - `RemoteInput` for quick inline typing directly inside notification shade.
  - Action button: **Voice Input** (launches speech-to-text dialog).
  - Action button: **Skip** (records skipped entry).
- **Home Screen Widgets**: Glanceable Compose AppWidget displaying daily planned vs. logged progress.

---

## 5. Next Milestones & Build Order

1. **Phase 10: Supabase Backend Integration (macOS Client)**
   - Add Supabase Swift SDK (`https://github.com/supabase-community/supabase-swift`).
   - Implement Auth (Email/Password or Apple Sign-In).
   - Implement bi-directional background sync queue with local SQLite.
2. **Phase 11: Google Calendar OAuth & Two-Way Sync Engine**
   - OAuth 2.0 PKCE flow for Google Calendar API.
   - Provision "Loopin Planned" & "Loopin Logged" calendars.
   - Real-time event create/update/delete sync.
3. **Phase 12: Android App Foundation (Jetpack Compose & Room)**
   - Initialize Android project with shared models & Room DB.
   - Implement Foreground Service with RemoteInput notifications.
4. **Phase 13: End-to-End Multi-Device Sync Verification**
   - Verify Mac entry logs show up in Android notifications and Google Calendar widget within 2 seconds.
