import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/features/widgets/data/services/widget_service_native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;

  MockPathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return tempDir.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late Directory tempDir;
  late List<MethodCall> methodCalls;
  late WidgetServiceImpl widgetService;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('widget_service_test');
    PathProviderPlatform.instance = MockPathProviderPlatform(tempDir);

    methodCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (call) async {
      methodCalls.add(call);
      return true;
    });

    widgetService = WidgetServiceImpl(database);
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('WidgetServiceImpl Atomic Snapshot Replacement', () {
    test('generateWidgetSnapshot generates sqlite database and atomically replaces it', () async {
      // Insert test pages
      final now = DateTime.now();
      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: 'page-1',
              title: const Value('First Page'),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: 'page-2',
              title: const Value('Second Page'),
              createdAt: now,
              updatedAt: now.add(const Duration(seconds: 1)),
            ),
          );

      final result = await widgetService.generateWidgetSnapshot();
      expect(result, isA<Success<void>>());

      final snapshotPath = p.join(tempDir.path, 'widget_snapshot.sqlite');
      final tempSnapshotPath = p.join(tempDir.path, 'widget_snapshot.sqlite.tmp');

      expect(
        File(tempSnapshotPath).existsSync(),
        isFalse,
        reason: 'Temp file must be cleanly renamed/removed',
      );

      // Verify contents of the generated snapshot database
      final snapshotDb = sqlite.sqlite3.open(snapshotPath);
      final rows = snapshotDb.select('SELECT id, title FROM recent_pages ORDER BY updated_at DESC');
      expect(rows.length, 2);
      expect(rows[0]['id'], 'page-2');
      expect(rows[0]['title'], 'Second Page');
      expect(rows[1]['id'], 'page-1');
      expect(rows[1]['title'], 'First Page');
      snapshotDb.dispose();
    });

    test('generateWidgetSnapshot handles empty database safely', () async {
      final result = await widgetService.generateWidgetSnapshot();
      expect(result, isA<Success<void>>());

      final snapshotPath = p.join(tempDir.path, 'widget_snapshot.sqlite');
      expect(File(snapshotPath).existsSync(), isTrue);

      final snapshotDb = sqlite.sqlite3.open(snapshotPath);
      final rows = snapshotDb.select('SELECT id, title FROM recent_pages');
      expect(rows.length, 0);
      snapshotDb.dispose();

      // Check that latest_note_id was cleared
      final idCall = methodCalls.lastWhere(
        (c) => c.method == 'saveWidgetData' && c.arguments['id'] == 'latest_note_id',
      );
      expect(idCall.arguments['data'], '');
    });

    test('triggerWidgetUpdate updates only QuickNote and RecentNotes widgets', () async {
      methodCalls.clear();
      final result = await widgetService.triggerWidgetUpdate();
      expect(result, isA<Success<void>>());

      final updateCalls = methodCalls.where((c) => c.method == 'updateWidget').toList();
      expect(updateCalls.length, 2);

      final androidNames = updateCalls.map((c) => c.arguments['android']).toList();
      expect(
        androidNames,
        contains('com.example.ketion.widgets.quick_note.QuickNoteWidgetProvider'),
      );
      expect(
        androidNames,
        contains('com.example.ketion.widgets.recent_notes.RecentNotesWidgetProvider'),
      );
      expect(
        androidNames.any((name) => name.toString().contains('SyncStatus')),
        isFalse,
        reason: 'SyncStatus widget must not be updated',
      );
    });
  });
}
