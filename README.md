# Ketion

Ketion is a modern, offline-first, cross-platform note-taking and knowledge base application built with Flutter, designed for high performance, rich multimedia capture, and seamless cross-platform sharing.

---

## Key Features

### 1. Block-Based Rich Text Editor
* **Modular Block Architecture:** Headings, paragraphs, task lists / checkboxes, numbered and bulleted lists, quotes, dividers, and callouts.
* **Multimedia Blocks:** Inline images, native video playback (`video_player` / `video_player_win`), audio player (`just_audio`), and file attachments.
* **Math & Code:** LaTeX / KaTeX mathematical equations (`flutter_math_fork`) and syntax-highlighted code blocks.
* **Interactive Drag-and-Drop:** Reorder blocks with native desktop and mobile drag gestures.

### 2. Universal Cross-Platform Share Target
* **iOS Share Extension (`KetionShareExtension`):** Native App Extension accepting images, videos/movies (`public.movie`, `public.video`, `com.apple.quicktime-movie`), PDFs, URLs, and plain text directly from Apple Photos, Safari, Instagram, Files, and third-party apps via App Groups (`group.com.example.ketion`).
* **Android Share Target:** Responds to `ACTION_SEND` and `ACTION_SEND_MULTIPLE` for `image/*`, `video/*`, `audio/*`, `application/pdf`, and `text/plain`. Resolves Content URIs and stream data to a staging pipeline.
* **Windows Drag & Drop and CLI:** Supports OLE desktop drop (`desktop_drop`, `super_drag_and_drop`) and command-line file arguments on application launch.
* **Smart Routing:** Shared content automatically attaches to the currently active note or the last opened note without interrupting your workflow.

### 3. Floating Assistive Ball (Quick Capture)
* **Android Floating Bubble:** Background overlay service (`AssistiveBallService`) with draggable assistive ball and floating quick-note dialog (`SYSTEM_ALERT_WINDOW` / foreground service).
* **Windows Floating Overlay:** Custom Win32 topmost window (`assistive_ball_window.cpp`) with DWM modern rounded corners for distraction-free quick capture over any running application.

### 4. Offline-First Storage & Cloud Synchronization
* **Local-First Database:** Powered by Drift (SQLite) with SQLite FTS5 for instant full-text search across all notes, tags, and block content.
* **Google Drive Sync:** Bidirectional background and manual sync via Google Drive API with automatic conflict resolution and offline write queues.

### 5. Native Android Widgets
* **Quick Note Widget:** One-tap entry into a new note from the home screen.
* **Recent Notes Widget:** Scrollable list of recently edited notes with direct deeplinks.
* **Sync Status Widget:** Live indicator of cloud sync and pending local modifications backed by an isolated snapshot database (`widget_snapshot.sqlite`).

### 6. Timezone-Aware Reminders & Full-Screen Alarms
* Exact alarms (`SCHEDULE_EXACT_ALARM`, `USE_FULL_SCREEN_INTENT`) with full-screen ringing UI, audio alerts, snoozing, and device boot auto-rescheduling (`BOOT_COMPLETED`).

### 7. Multi-Format Import & Export
* Export entire notes or workspaces to **PDF** (with customizable typography and layout via `printing`), **Markdown**, and **HTML**.

---

## Tech Stack & Architecture

Ketion follows **Clean Architecture** principles with strict separation into Domain, Data, and Presentation layers:

```
lib/
├── core/                  # Core utilities, theme, router (GoRouter), database bootstrap
│   ├── database/          # Drift SQLite database schema and DAOs
│   ├── router/            # GoRouter configuration and route guards
│   └── theme/             # Material Design 3 tokens and typography
└── features/
    ├── assistive_ball/    # Floating ball UI and platform method channels
    ├── blocks/            # Domain entities and state for content blocks
    ├── collections/       # Folder and notebook management
    ├── editor/            # SuperEditor integration and custom block builders
    ├── import_export/     # PDF, Markdown, and HTML generators
    ├── incoming_share/    # Unified share receiver coordinator and providers
    ├── media/             # Image/audio/video pickers and local cache storage
    ├── pages/             # Page metadata, favorites, archiving, and trash
    ├── reminders/         # Notification scheduler and alarm ringing service
    ├── search/            # Full-Text Search (FTS5) queries
    ├── settings/          # Themes, accent colors, database backup/restore
    ├── sync/              # Google Drive OAuth2 and synchronization engine
    └── tags/              # Multi-colored tagging system
```

* **Framework:** [Flutter](https://flutter.dev) (Dart 3.x)
* **State Management:** [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
* **Local Database:** [Drift](https://drift.simonbinder.eu/) + `sqlite3_flutter_libs`
* **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
* **Editor Core:** [SuperEditor](https://pub.dev/packages/super_editor)
* **Media & Audio:** `just_audio`, `video_player`, `video_player_win`, `image_picker`, `file_picker`
* **Notifications:** `flutter_local_notifications`, `timezone`

---

## Platform Details

| Platform | Minimum Version | Native Capabilities |
| :--- | :--- | :--- |
| **iOS** | iOS 14.0+ | Share Extension (`.appex`), App Groups, Custom Document Types, SceneDelegate file dispatch |
| **Android** | Android 8.0+ (API 26+) | Foreground Service Overlay, Glance AppWidgets, Exact Alarm Receiver, Content Resolver stream ingestion |
| **Windows** | Windows 10+ (x64) | Win32 Assistive Ball Window, DWM rounded corners, OLE Drag & Drop, Inno Setup installer |

---

## Getting Started

### Prerequisites
* Flutter SDK (3.x or higher)
* Android Studio / Xcode / Visual Studio (C++ workload for Windows)
* CocoaPods (for iOS dependencies)

### Setup & Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/example/ketion.git
   cd ketion
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run code generation (Drift, Freezed, JSON):**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## Building and Running

### iOS
```bash
cd ios
pod install
cd ..
flutter run -d ios
```
*Note for Share Extension:* Ensure both `Runner` and `KetionShareExtension` targets share the same Development Team and App Group (`group.com.example.ketion`) in Xcode.

### Android
```bash
flutter run -d android
```
To build a release APK:
```bash
flutter build apk --release
```

### Windows Desktop
```bash
flutter run -d windows
```
To create a Windows Release build:
```bash
flutter build windows --release
```
To package into an installer, compile `packaging/windows/ketion.iss` using Inno Setup.

---

## License

This project is licensed under the MIT License - see the LICENSE file for details.
