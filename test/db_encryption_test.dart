import 'dart:io';

import 'package:expense_tracker/data/local/connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('enc_test');
    file = File('${dir.path}/t.sqlite');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  test('SQLite3MultipleCiphers is available', () {
    final db = sqlite3.openInMemory();
    expect(db.select('PRAGMA cipher;'), isNotEmpty);
    db.close();
  });

  test('encrypting a plain file hides its content and needs the key', () {
    final plain = sqlite3.open(file.path);
    plain.execute(
      "CREATE TABLE t(v TEXT); INSERT INTO t VALUES ('secret note');",
    );
    plain.close();

    expect(isPlaintextSqliteFile(file), isTrue);
    expect(
      String.fromCharCodes(file.readAsBytesSync()).contains('secret note'),
      isTrue,
    );

    final encrypting = sqlite3.open(file.path);
    encrypting.execute("PRAGMA rekey = 'abc123';");
    encrypting.close();

    expect(isPlaintextSqliteFile(file), isFalse);
    expect(
      String.fromCharCodes(file.readAsBytesSync()).contains('secret note'),
      isFalse,
    );

    final withKey = sqlite3.open(file.path);
    withKey.execute("PRAGMA key = 'abc123';");
    expect(withKey.select('SELECT v FROM t').single['v'], 'secret note');
    withKey.close();

    final noKey = sqlite3.open(file.path);
    expect(() => noKey.select('SELECT v FROM t'),
        throwsA(isA<SqliteException>()));
    noKey.close();

    final wrongKey = sqlite3.open(file.path);
    wrongKey.execute("PRAGMA key = 'wrong';");
    expect(() => wrongKey.select('SELECT v FROM t'),
        throwsA(isA<SqliteException>()));
    wrongKey.close();
  });
}