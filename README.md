# Ketion

Ketion is a fast, offline-first, cross-platform note-taking application built with Flutter.

## Features
- **Offline First**: All notes are stored locally using a robust SQLite database (via Drift).
- **Google Drive Sync**: Seamlessly synchronize your notes to Google Drive.
- **Native Android Widgets**:
  - **Quick Note**: Instantly launch into a new note from your home screen.
  - **Recent Notes**: View and access your most recently edited notes directly.
  - **Sync Status**: Monitor your current synchronization status at a glance.
- **Cross-Platform**: Designed to work gracefully on mobile platforms.

## Architecture
- **State Management**: Riverpod for clean, reactive state management.
- **Local Storage**: Drift (SQLite) as the single source of truth.
- **Clean Architecture**: Separation of concerns across Domain, Data, and Presentation layers.

## Getting Started

To build the project locally, ensure you have Flutter installed.

```bash
flutter pub get
flutter run
```

## Native Widgets

The Android widgets rely on a read-only snapshot of the database (`widget_snapshot.sqlite`) to remain lightweight and avoid corrupting the main application state while the Flutter engine is paused.
