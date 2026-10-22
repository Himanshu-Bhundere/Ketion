import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/utils/logger.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/widgets/domain/services/widget_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'package:drift/drift.dart';

class WidgetServiceImpl implements WidgetService {
  final AppDatabase _db;

  WidgetServiceImpl(this._db) {
    HomeWidget.setAppGroupId('group.com.example.ketion');
  }

  @override
  Future<Result<void>> updateSimpleWidgetData(String key, dynamic value) async {
    try {
      if (value is String) {
        await HomeWidget.saveWidgetData<String>(key, value);
      } else if (value is int) {
        await HomeWidget.saveWidgetData<int>(key, value);
      } else if (value is bool) {
        await HomeWidget.saveWidgetData<bool>(key, value);
      } else if (value is double) {
        await HomeWidget.saveWidgetData<double>(key, value);
      } else {
        await HomeWidget.saveWidgetData<String>(key, jsonEncode(value));
      }
      return const Success(null);
    } catch (e) {
      appLogger.e('Failed to save widget data for key $key', e);
      return Error(UnknownFailure('Failed to save widget data: $e'));
    }
  }

  @override
  Future<Result<void>> triggerWidgetUpdate() async {
    try {
      await HomeWidget.updateWidget(
        androidName:
            'com.example.ketion.widgets.quick_note.QuickNoteWidgetProvider',
        iOSName: 'QuickNoteWidget',
      );
      await HomeWidget.updateWidget(
        androidName:
            'com.example.ketion.widgets.recent_notes.RecentNotesWidgetProvider',
        iOSName: 'RecentNotesWidget',
      );
      return const Success(null);
    } catch (e) {
      appLogger.e('Failed to trigger widget update', e);
      return Error(UnknownFailure('Failed to trigger widget update: $e'));
    }
  }

  @override
  Future<Result<void>> generateWidgetSnapshot() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final snapshotPath = p.join(docsDir.path, 'widget_snapshot.sqlite');
    final tempSnapshotPath = p.join(docsDir.path, 'widget_snapshot.sqlite.tmp');
    final tempFile = File(tempSnapshotPath);

    try {
      // Get the 10 most recently updated non-deleted pages
      final recentPagesQuery = _db.select(_db.pages)
        ..where((t) => t.deleted.equals(false) & t.isTemplate.equals(false))
        ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
        ..limit(10);
      final recentPages = await recentPagesQuery.get();

      // Clean up any stale temporary file from a prior interrupted attempt
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }

      // Create a fresh SQLite database in the temporary file
      final snapshotDb = sqlite.sqlite3.open(tempSnapshotPath);

      snapshotDb.execute('''
        CREATE TABLE recent_pages (
          id TEXT PRIMARY KEY,
          title TEXT,
          updated_at TEXT
        );
      ''');

      final stmt = snapshotDb.prepare(
        'INSERT INTO recent_pages (id, title, updated_at) VALUES (?, ?, ?)',
      );
      for (final page in recentPages) {
        stmt.execute([
          page.id,
          page.title.trim().isEmpty ? 'Untitled' : page.title.trim(),
          page.updatedAt.toIso8601String(),
        ]);
      }
      stmt.dispose();
      snapshotDb.dispose();

      // Prepare backup of existing snapshot so it can be preserved if publication fails
      final snapshotFile = File(snapshotPath);
      final backupPath = '$snapshotPath.bak';
      final backupFile = File(backupPath);
      if (snapshotFile.existsSync()) {
        try {
          snapshotFile.copySync(backupPath);
        } catch (_) {}
      }

      // Atomically replace the published snapshot file so native widget reads are never concurrent with writes
      try {
        tempFile.renameSync(snapshotPath);
      } catch (_) {
        if (snapshotFile.existsSync()) {
          snapshotFile.deleteSync();
        }
        tempFile.renameSync(snapshotPath);
      }

      // Pass the snapshot path to home_widget and check every Result
      final pathResult =
          await updateSimpleWidgetData('snapshot_db_path', snapshotPath);
      if (pathResult is Error) {
        _restoreBackup(backupFile, snapshotFile);
        return pathResult;
      }

      final updatedResult = await updateSimpleWidgetData(
        'snapshot_updated_at',
        DateTime.now().toIso8601String(),
      );
      if (updatedResult is Error) {
        _restoreBackup(backupFile, snapshotFile);
        return updatedResult;
      }

      if (recentPages.isNotEmpty) {
        final latest = recentPages.first;
        final title =
            latest.title.trim().isEmpty ? 'Untitled' : latest.title.trim();
        final idResult =
            await updateSimpleWidgetData('latest_note_id', latest.id);
        if (idResult is Error) {
          _restoreBackup(backupFile, snapshotFile);
          return idResult;
        }
        final titleResult =
            await updateSimpleWidgetData('latest_note_title', title);
        if (titleResult is Error) {
          _restoreBackup(backupFile, snapshotFile);
          return titleResult;
        }
      } else {
        final idResult = await updateSimpleWidgetData('latest_note_id', '');
        if (idResult is Error) {
          _restoreBackup(backupFile, snapshotFile);
          return idResult;
        }
        final titleResult =
            await updateSimpleWidgetData('latest_note_title', '');
        if (titleResult is Error) {
          _restoreBackup(backupFile, snapshotFile);
          return titleResult;
        }
      }

      // On successful publication of snapshot and metadata, delete temporary backup
      if (backupFile.existsSync()) {
        try {
          backupFile.deleteSync();
        } catch (_) {}
      }

      return const Success(null);
    } catch (e) {
      final backupFile = File('$snapshotPath.bak');
      if (backupFile.existsSync()) {
        try {
          backupFile.copySync(snapshotPath);
          backupFile.deleteSync();
        } catch (_) {}
      }
      // Clean up temporary file on failure, preserving the existing snapshot intact
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }
      appLogger.e('Failed to generate widget snapshot', e);
      return Error(UnknownFailure('Failed to generate widget snapshot: $e'));
    }
  }

  void _restoreBackup(File backupFile, File snapshotFile) {
    if (backupFile.existsSync()) {
      try {
        backupFile.copySync(snapshotFile.path);
        backupFile.deleteSync();
      } catch (_) {}
    }
  }
}

WidgetService getWidgetService(dynamic db) =>
    WidgetServiceImpl(db as AppDatabase);
