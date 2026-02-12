# Class Timer Pro

Intelligent Offline-First Timetable & Smart Scheduling Engine

## 1. Executive Summary

Class Timer Pro is an intelligent academic scheduling application that enables students to import, manage, and optimize their class and study timetables using AI-powered parsing and smart scheduling logic.

Unlike traditional reminder apps, Class Timer Pro:
- Imports timetables from Excel, PDFs, screenshots, or camera scans
- Automatically converts them into structured calendar events
- Detects scheduling conflicts
- Suggests rescheduling options
- Adds contextual reminders
- Bridges planning with actual productivity through Focus Mode

This app transforms static timetables into dynamic, optimized academic schedules.

## 2. Core Value Proposition

🎯 **“The One-Tap Sync”**

Students upload their timetable once. The app handles everything else.

**Supported Inputs:**
- Excel (.xlsx)
- CSV
- PDF
- Image (Screenshot)
- Camera capture (Printed timetable)

**Output:**
- Structured class events
- Study session blocks
- Smart reminders
- Google Calendar sync (optional)

This is the “magic moment.”
*Take a photo → Confirm preview → Sync → Done.*

## 3. Problem Statement

Students struggle with:
- Manual timetable entry
- Overlapping schedules
- Poor time planning
- Forgotten study sessions
- Distractions during study time
- Inconsistent reminder systems

**Existing tools:**
- Require manual input
- Lack conflict intelligence
- Don’t connect planning to action
- Are either too complex or too basic

## 4. Target Users
- Secondary school students
- University students
- Polytechnic students
- Students using LMS portals (PDF exports)
- Students receiving printed schedules

## 5. System Architecture Overview

### Hybrid Offline + Smart Cloud Architecture
User Input → Universal Import Engine → Timetable Parser (AI / Rule-Based) → Event Structuring Engine → Conflict Detection Engine → Local Storage (Hive) → Calendar Sync Layer (Optional) → Notification & Study Mode Engine

## 6. Core Features

### 6.1 Universal Import Engine
#### 6.1.1 Excel / CSV Import
- User selects file
- App auto-detects column headers: Course, Day, Start Time, End Time, Venue
- Smart column mapping system
- User preview before confirmation

#### 6.1.2 PDF Import
- Extract structured text
- Parse timetable patterns
- Detect Days, Time ranges, Course names, Locations

#### 6.1.3 Image / Screenshot Import (AI-Powered)
- OCR (Optical Character Recognition)
- Pattern recognition model
- Detect timetable grids
- Extract structured class data
- Convert into event objects

**Flagship feature flow:**
Upload screenshot → App scans → Shows preview → User confirms → Events created instantly.

## 7. Smart Scheduling Engine

### 7.1 Smart Buffer Technology
Instead of static reminders, the system generates contextual alerts.
- **Example:** 10 minutes before study session: *“Do you have your materials ready for Physics?”*
- **Example:** Before class: *“Time to head to Lecture Hall B.”*

### 7.2 Conflict Crusher
The system automatically detects overlapping schedules.
- **Logic:** `If (NewEvent.start < ExistingEvent.end AND NewEvent.end > ExistingEvent.start) → Conflict detected`
- **User receives:** *“You have a lecture during this study block. Reschedule to 7:00 PM?”*
- Auto-suggested alternative times based on availability.

### 7.3 Dynamic Study Mode
When a study session begins, the app prompts: *“Activate Focus Mode for 2 hours?”*
- **Features:** Silences notifications, Suggests blocking social apps, Activates Do Not Disturb, Tracks session completion.

## 8. Calendar Integration

- **Option A: Google Calendar Sync**: Classes → Calendar events, Study sessions → Tasks, Two-way update.
- **Option B: Native Device Calendar**: iOS / Android local calendar integration.

## 9. Data Model

### ClassEvent
- id
- title
- type (class | study)
- dayOfWeek
- startTime
- endTime
- venue
- calendarEventId

### StudySession
- id
- title
- linkedCourse
- startTime
- endTime
- focusModeEnabled
- completed

## 10. Application Structure
```text
lib/
├── main.dart
├── models/
│   ├── class_event.dart
│   ├── study_session.dart
│   └── conflict_model.dart
├── services/
│   ├── local_storage_service.dart
│   ├── import_engine_service.dart
│   ├── ocr_service.dart
│   ├── calendar_sync_service.dart
│   ├── notification_service.dart
│   ├── conflict_service.dart
│   └── focus_mode_service.dart
├── screens/
│   ├── onboarding_screen.dart
│   ├── dashboard_screen.dart
│   ├── import_screen.dart
│   ├── preview_screen.dart
│   └── settings_screen.dart
├── widgets/
│   ├── event_card.dart
│   ├── progress_indicator.dart
│   └── sync_animation.dart
```

## 11. User Experience Flow

1.  **Step 1: Onboarding**: Grant Calendar/Notification/Focus Mode permissions.
2.  **Step 2: Add Timetable**: Upload File, Upload Screenshot, or Take Photo.
3.  **Step 3: Preview & Verify**: App displays structured events; user edits if needed.
4.  **Step 4: The Sync**: Animation: Events visually “fly” into calendar.
5.  **Step 5: Dashboard**: Displays Up Next, Today’s Schedule, Study Streak, and Focus Mode Stats.

## 12. Offline Strategy
- **Local Storage**: Hive
- Works offline, syncs when internet available.

## 13. Security & Privacy
- No data collection or cloud storage (unless user enables Google sync).
- OCR processing preferred on-device.

## 14. Edge Case Handling
- Duplicate import detection
- Invalid OCR parsing
- Calendar permission denial
- Time zone/Daylight saving shifts
- Professor schedule changes

## 15. Version Roadmap

- **Version 1.0**: Manual class creation, Excel import, Countdown timers, Conflict detection.
- **Version 1.5**: PDF parsing, Google Calendar sync, Smart Buffer alerts.
- **Version 2.0**: AI image scan, Focus Mode integration, Auto-reschedule engine.
- **Version 3.0**: AI study optimization, Predictive scheduling, Semester analytics.

## 16. Competitive Advantage
| Feature | Traditional Apps | Class Timer Pro |
| :--- | :--- | :--- |
| Excel Import | Sometimes | **Yes** |
| PDF Import | Rare | **Yes** |
| Screenshot AI | No | **Yes** |
| Conflict Detection | No | **Yes** |
| Smart Rescheduling | No | **Yes** |
| Focus Mode Trigger | No | **Yes** |
| Offline Mode | Rare | **Yes** |

## 17. Monetization Strategy (Future)
- Free core app
- Pro version: AI OCR unlimited, Advanced conflict optimizer, Study analytics.

## 18. Engineering Value (Portfolio Strength)
Demonstrates: File parsing, OCR integration, AI-assisted extraction, Calendar APIs, Background services, Notification systems, Conflict resolution algorithms, Offline-first architecture.

## 19. Final Positioning
Class Timer Pro is not just a reminder app or a calendar wrapper; it is a **smart academic scheduling assistant**.
- Small enough to ship.
- Ambitious enough to scale.
- Structured enough to impress.
