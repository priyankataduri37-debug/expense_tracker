import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> _dbKey() async {
  const storage = FlutterSecureStorage();

  var key = await storage.read(key: 'db_key');

  if (key == null) {
    final random = Random.secure();

    key = List.generate(
      32,
          (_) => random.nextInt(256),
    ).map(
          (byte) => byte.toRadixString(16).padLeft(2, '0'),
    ).join();

    await storage.write(
      key: 'db_key',
      value: key,
    );
  }

  return key;
}

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();

    final file = File(
      p.join(dir.path, 'expenses.sqlite'),
    );

    final key = await _dbKey();

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        final cipherResult = rawDb.select(
          'PRAGMA cipher;',
        );

        assert(
        cipherResult.isNotEmpty,
        'SQLite3MultipleCiphers is not enabled. '
            'Check the sqlite3 build hook configuration.',
        );

        rawDb.execute(
          "PRAGMA key = '$key';",
        );

        rawDb.select(
          'SELECT count(*) FROM sqlite_master;',
        );
      },
    );
  });
}