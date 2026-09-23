import 'package:sqflite/sqflite.dart';

import '../local/app_database.dart';
import '../models/analytics.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../seed/demo_seed.dart';

/// Data access contract for the app. Keeping this abstract lets tests swap in
/// a lightweight fake and keeps the UI independent of SQLite.
abstract class FinanceRepository {
  Future<List<Category>> categories();

  Future<List<MoneyTransaction>> transactions({
    DateTime? month,
    TxType? type,
    String? query,
  });

  Future<int> addTransaction(MoneyTransaction transaction);

  Future<void> updateTransaction(MoneyTransaction transaction);

  Future<void> deleteTransaction(int id);

  Future<List<Budget>> budgets();

  Future<void> setBudget(int categoryId, double limit);

  Future<void> deleteBudget(int categoryId);

  Future<MonthlySummary> summary(DateTime month);

  Future<List<CategorySpend>> categoryBreakdown(DateTime month);

  Future<List<MonthlyPoint>> monthlySeries(DateTime end, int months);

  Future<double> allTimeBalance();

  Future<void> resetDemoData();
}

/// SQLite-backed implementation used in production.
class SqliteFinanceRepository implements FinanceRepository {
  SqliteFinanceRepository(this._db);

  final Database _db;

  static const String _seedKey = 'demo_seeded';

  Future<void> ensureSeeded() async {
    final rows = await _db.query(
      'meta',
      where: 'key = ?',
      whereArgs: <Object?>[_seedKey],
      limit: 1,
    );
    if (rows.isNotEmpty) return;
    await _insertDemoData();
    await _db.insert('meta', <String, Object?>{
      'key': _seedKey,
      'value': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, int>> _categoryIdByName() async {
    final rows = await _db.query('categories', columns: <String>['id', 'name_en']);
    return <String, int>{
      for (final row in rows) row['name_en'] as String: row['id'] as int,
    };
  }

  Future<void> _insertDemoData() async {
    final ids = await _categoryIdByName();
    final batch = _db.batch();
    for (final tx in DemoSeed.transactions(ids, DateTime.now())) {
      batch.insert('transactions', tx.toMap());
    }
    for (final entry in DemoSeed.budgets.entries) {
      final id = ids[entry.key];
      if (id == null) continue;
      batch.insert('budgets', <String, Object?>{
        'category_id': id,
        'amount': entry.value,
      });
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Category>> categories() async {
    final rows = await _db.query('categories', orderBy: 'id ASC');
    return rows.map(Category.fromMap).toList();
  }

  @override
  Future<List<MoneyTransaction>> transactions({
    DateTime? month,
    TxType? type,
    String? query,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (month != null) {
      where.add('substr(date, 1, 7) = ?');
      args.add(_monthKey(month));
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type.db);
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add('note LIKE ?');
      args.add('%${query.trim()}%');
    }

    final rows = await _db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  @override
  Future<int> addTransaction(MoneyTransaction transaction) {
    final map = transaction.toMap()..remove('id');
    return _db.insert('transactions', map);
  }

  @override
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    final id = transaction.id;
    if (id == null) return;
    await _db.update(
      'transactions',
      transaction.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    await _db.delete('transactions', where: 'id = ?', whereArgs: <Object?>[id]);
  }

  @override
  Future<List<Budget>> budgets() async {
    final rows = await _db.query('budgets', orderBy: 'id ASC');
    return rows.map(Budget.fromMap).toList();
  }

  @override
  Future<void> setBudget(int categoryId, double limit) async {
    await _db.insert(
      'budgets',
      <String, Object?>{'category_id': categoryId, 'amount': limit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteBudget(int categoryId) async {
    await _db.delete(
      'budgets',
      where: 'category_id = ?',
      whereArgs: <Object?>[categoryId],
    );
  }

  @override
  Future<MonthlySummary> summary(DateTime month) async {
    final current = await _totals(month);
    final previous = await _totals(
      DateTime(month.year, month.month - 1, 1),
    );
    return MonthlySummary(
      income: current.$1,
      expense: current.$2,
      previousExpense: previous.$2,
    );
  }

  Future<(double, double)> _totals(DateTime month) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income'  THEN amount END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS expense
      FROM transactions
      WHERE substr(date, 1, 7) = ?
      ''',
      <Object?>[_monthKey(month)],
    );
    final row = rows.first;
    return (
      (row['income'] as num).toDouble(),
      (row['expense'] as num).toDouble(),
    );
  }

  @override
  Future<List<CategorySpend>> categoryBreakdown(DateTime month) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        c.id, c.name_en, c.name_ar, c.icon, c.color, c.kind,
        COALESCE(SUM(t.amount), 0) AS total,
        b.amount AS limit_amount
      FROM categories c
      LEFT JOIN transactions t
        ON t.category_id = c.id
        AND t.type = 'expense'
        AND substr(t.date, 1, 7) = ?
      LEFT JOIN budgets b ON b.category_id = c.id
      WHERE c.kind = 'expense'
      GROUP BY c.id
      HAVING total > 0 OR limit_amount IS NOT NULL
      ORDER BY total DESC, c.id ASC
      ''',
      <Object?>[_monthKey(month)],
    );

    return rows.map((row) {
      final category = Category.fromMap(row);
      return CategorySpend(
        category: category,
        amount: (row['total'] as num).toDouble(),
        limit: row['limit_amount'] == null
            ? null
            : (row['limit_amount'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<List<MonthlyPoint>> monthlySeries(DateTime end, int months) async {
    final points = <MonthlyPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(end.year, end.month - i, 1);
      final totals = await _totals(month);
      points.add(MonthlyPoint(
        month: month,
        income: totals.$1,
        expense: totals.$2,
      ));
    }
    return points;
  }

  @override
  Future<double> allTimeBalance() async {
    final rows = await _db.rawQuery(
      '''
      SELECT COALESCE(SUM(
        CASE WHEN type = 'income' THEN amount ELSE -amount END
      ), 0) AS balance
      FROM transactions
      ''',
    );
    return (rows.first['balance'] as num).toDouble();
  }

  @override
  Future<void> resetDemoData() async {
    await _db.delete('transactions');
    await _db.delete('budgets');
    await _insertDemoData();
    await _db.insert(
      'meta',
      <String, Object?>{
        'key': _seedKey,
        'value': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String _monthKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}';
}

/// Convenience factory used by the provider layer.
Future<SqliteFinanceRepository> openFinanceRepository() async {
  final db = await AppDatabase.instance();
  final repo = SqliteFinanceRepository(db);
  await repo.ensureSeeded();
  return repo;
}
