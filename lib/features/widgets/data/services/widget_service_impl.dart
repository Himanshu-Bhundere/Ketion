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

class WidgetServiceImpl implements WidgetService {
  final AppDatabase _db;
  final String _androidAppWidgetProvider = 'KetionWidgetProvider';

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
        androidName: _androidAppWidgetProvider,
        iOSName: 'KetionWidget',
      );
      return const Success(null);
    } catch (e) {
      appLogger.e('Failed to trigger widget update', e);
      return Error(UnknownFailure('Failed to trigger widget update: $e'));
    }
  }

  @override
  Future<Result<void>> generateWidgetSnapshot() async {
    try {
      // Get the 5 most recently updated pages
      final recentPages = await _db.customSelect(
        'SELECT id, title, updated_at FROM pages WHERE is_trashed = 0 ORDER BY updated_at DESC LIMIT 5',
      ).get();

      final docsDir = await getApplicationDocumentsDirectory();
      final snapshotPath = p.join(docsDir.path, 'widget_snapshot.sqlite');
      
      // Delete old snapshot if it exists
      final snapshotFile = File(snapshotPath);
      if (snapshotFile.existsSync()) {
        snapshotFile.deleteSync();
      }

      // Create a fresh SQLite database for the snapshot
      final snapshotDb = sqlite.sqlite3.open(snapshotPath);
      
      snapshotDb.execute('''
        CREATE TABLE recent_pages (
          id TEXT PRIMARY KEY,
          title TEXT,
          updated_at TEXT
        );
      ''');

      final stmt = snapshotDb.prepare('INSERT INTO recent_pages (id, title, updated_at) VALUES (?, ?, ?)');
      for (final row in recentPages) {
        stmt.execute([
          row.read<String>('id'),
          row.read<String>('title'),
          row.read<String>('updated_at'),
        ]);
      }
      stmt.dispose();
      snapshotDb.dispose();

      // Pass the snapshot path to home_widget so the native code knows where to find it
      await updateSimpleWidgetData('snapshot_db_path', snapshotPath);
      
      return const Success(null);
    } catch (e) {
      appLogger.e('Failed to generate widget snapshot', e);
      return Error(UnknownFailure('Failed to generate widget snapshot: $e'));
    }
  }
}
