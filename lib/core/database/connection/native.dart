import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

QueryExecutor connect() {
  return LazyDatabase(() async {
    final documentsDir = await getApplicationDocumentsDirectory();

    final Directory dbDirectory;

    if (Platform.isWindows) {
      final supportDir = await getApplicationSupportDirectory();

      dbDirectory = Directory(
        p.join(supportDir.path, 'Ketion'),
      );

      await dbDirectory.create(recursive: true);

      final newDatabase = File(
        p.join(dbDirectory.path, 'ketion.sqlite'),
      );

      final oldDatabase = File(
        p.join(documentsDir.path, 'ketion.sqlite'),
      );

      // Migrate the existing database only if the new location
      // does not already contain one.
      if (!await newDatabase.exists() && await oldDatabase.exists()) {
        await oldDatabase.copy(newDatabase.path);

        // Preserve uncheckpointed SQLite WAL transactions.
        final oldWal = File('${oldDatabase.path}-wal');

        if (await oldWal.exists()) {
          await oldWal.copy('${newDatabase.path}-wal');
        }
      }
    } else {
      dbDirectory = documentsDir;
    }

    final file = File(
      p.join(dbDirectory.path, 'ketion.sqlite'),
    );

    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode = WAL;');
      },
    );
  });
}
