import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Native (Android / iOS / desktop): sqflite already has a working factory.
void configureDatabaseFactory() {}

/// Native databases live on the filesystem.
Future<String> resolveDatabasePath(String fileName) async =>
    p.join(await getDatabasesPath(), fileName);
