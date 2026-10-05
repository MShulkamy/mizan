import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web: SQLite runs on sqlite3.wasm and the database is persisted in IndexedDB.
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}

/// The web factory treats the value as the IndexedDB database key.
Future<String> resolveDatabasePath(String fileName) async => fileName;
