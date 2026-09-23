import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema for Mizan.
///
/// The database is created lazily on first launch and seeded with a starter
/// set of categories. Demo transactions are added separately so a user can
/// wipe them without losing their category setup.
class AppDatabase {
  AppDatabase._();

  static const String _fileName = 'mizan.db';
  static const int _version = 1;

  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), _fileName);
    _db = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
    return _db!;
  }

  /// Used by tests to inject an in-memory database.
  static set override(Database db) => _db = db;

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        name_en  TEXT NOT NULL,
        name_ar  TEXT NOT NULL,
        icon     TEXT NOT NULL,
        color    INTEGER NOT NULL,
        kind     TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        amount      REAL NOT NULL,
        type        TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        date        TEXT NOT NULL,
        note        TEXT NOT NULL DEFAULT '',
        account     TEXT NOT NULL DEFAULT 'Cash',
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL UNIQUE,
        amount      REAL NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meta (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_tx_date ON transactions (date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_tx_category ON transactions (category_id)',
    );

    for (final category in StarterData.categories) {
      await db.insert('categories', category);
    }
  }
}

/// The category set that ships with a fresh install.
class StarterData {
  StarterData._();

  static List<Map<String, Object?>> get categories => <Map<String, Object?>>[
        _c('Food & Dining', 'طعام ومطاعم', 'restaurant', 3, 'expense'),
        _c('Groceries', 'بقالة', 'groceries', 5, 'expense'),
        _c('Transport', 'مواصلات', 'transport', 2, 'expense'),
        _c('Rent & Home', 'إيجار وسكن', 'home', 0, 'expense'),
        _c('Bills & Utilities', 'فواتير ومرافق', 'bills', 8, 'expense'),
        _c('Health', 'صحة', 'health', 6, 'expense'),
        _c('Shopping', 'تسوق', 'shopping', 4, 'expense'),
        _c('Entertainment', 'ترفيه', 'entertainment', 1, 'expense'),
        _c('Education', 'تعليم', 'education', 7, 'expense'),
        _c('Travel', 'سفر', 'travel', 9, 'expense'),
        _c('Coffee', 'قهوة', 'coffee', 8, 'expense'),
        _c('Fitness', 'رياضة', 'fitness', 5, 'expense'),
        _c('Salary', 'راتب', 'salary', 0, 'income'),
        _c('Freelance', 'عمل حر', 'freelance', 2, 'income'),
        _c('Gifts', 'هدايا', 'gift', 4, 'income'),
      ];

  static Map<String, Object?> _c(
    String en,
    String ar,
    String icon,
    int color,
    String kind,
  ) =>
      <String, Object?>{
        'name_en': en,
        'name_ar': ar,
        'icon': icon,
        'color': color,
        'kind': kind,
      };
}
