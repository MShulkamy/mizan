import 'package:mizan/data/models/analytics.dart';
import 'package:mizan/data/models/budget.dart';
import 'package:mizan/data/models/category.dart';
import 'package:mizan/data/models/transaction.dart';
import 'package:mizan/data/repositories/finance_repository.dart';

/// In-memory repository used by widget tests so they never touch SQLite.
class FakeFinanceRepository implements FinanceRepository {
  FakeFinanceRepository({List<MoneyTransaction>? transactions})
      : _transactions = List<MoneyTransaction>.from(
          transactions ?? _defaultTransactions(),
        );

  final List<MoneyTransaction> _transactions;
  final Map<int, double> _budgets = <int, double>{1: 2500, 2: 2200};
  int _nextId = 1000;

  static List<Category> get _categories => const <Category>[
        Category(
          id: 1,
          nameEn: 'Food & Dining',
          nameAr: 'طعام ومطاعم',
          iconKey: 'restaurant',
          colorIndex: 3,
          kind: TxType.expense,
        ),
        Category(
          id: 2,
          nameEn: 'Groceries',
          nameAr: 'بقالة',
          iconKey: 'groceries',
          colorIndex: 5,
          kind: TxType.expense,
        ),
        Category(
          id: 3,
          nameEn: 'Salary',
          nameAr: 'راتب',
          iconKey: 'salary',
          colorIndex: 0,
          kind: TxType.income,
        ),
      ];

  static List<MoneyTransaction> _defaultTransactions() {
    final now = DateTime.now();
    return <MoneyTransaction>[
      MoneyTransaction(
        id: 1,
        amount: 18500,
        type: TxType.income,
        categoryId: 3,
        date: DateTime(now.year, now.month, 1),
        note: 'Monthly salary',
      ),
      MoneyTransaction(
        id: 2,
        amount: 320,
        type: TxType.expense,
        categoryId: 1,
        date: DateTime(now.year, now.month, 4),
        note: 'Dinner out',
      ),
      MoneyTransaction(
        id: 3,
        amount: 480,
        type: TxType.expense,
        categoryId: 2,
        date: DateTime(now.year, now.month, 6),
        note: 'Weekly groceries',
      ),
    ];
  }

  @override
  Future<List<Category>> categories() async => _categories;

  @override
  Future<List<MoneyTransaction>> transactions({
    DateTime? month,
    TxType? type,
    String? query,
  }) async {
    return _transactions.where((tx) {
      if (month != null &&
          (tx.date.year != month.year || tx.date.month != month.month)) {
        return false;
      }
      if (type != null && tx.type != type) return false;
      if (query != null &&
          query.trim().isNotEmpty &&
          !tx.note.toLowerCase().contains(query.trim().toLowerCase())) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<int> addTransaction(MoneyTransaction transaction) async {
    final id = _nextId++;
    _transactions.add(transaction.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateTransaction(MoneyTransaction transaction) async {
    final index =
        _transactions.indexWhere((tx) => tx.id == transaction.id);
    if (index != -1) _transactions[index] = transaction;
  }

  @override
  Future<void> deleteTransaction(int id) async {
    _transactions.removeWhere((tx) => tx.id == id);
  }

  @override
  Future<List<Budget>> budgets() async => _budgets.entries
      .map((e) => Budget(id: e.key, categoryId: e.key, limit: e.value))
      .toList();

  @override
  Future<void> setBudget(int categoryId, double limit) async {
    _budgets[categoryId] = limit;
  }

  @override
  Future<void> deleteBudget(int categoryId) async {
    _budgets.remove(categoryId);
  }

  @override
  Future<MonthlySummary> summary(DateTime month) async {
    final scoped = await transactions(month: month);
    final income = scoped
        .where((t) => t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);
    final expense = scoped
        .where((t) => !t.isIncome)
        .fold<double>(0, (s, t) => s + t.amount);
    return MonthlySummary(
      income: income,
      expense: expense,
      previousExpense: 0,
    );
  }

  @override
  Future<List<CategorySpend>> categoryBreakdown(DateTime month) async {
    final scoped = await transactions(month: month);
    final result = <CategorySpend>[];
    for (final category in _categories) {
      final amount = scoped
          .where((t) => t.categoryId == category.id && !t.isIncome)
          .fold<double>(0, (s, t) => s + t.amount);
      if (amount <= 0 && !_budgets.containsKey(category.id)) continue;
      result.add(CategorySpend(
        category: category,
        amount: amount,
        limit: _budgets[category.id],
      ));
    }
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  @override
  Future<List<MonthlyPoint>> monthlySeries(DateTime end, int months) async {
    final points = <MonthlyPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final month = DateTime(end.year, end.month - i, 1);
      final scoped = await transactions(month: month);
      points.add(MonthlyPoint(
        month: month,
        income: scoped
            .where((t) => t.isIncome)
            .fold<double>(0, (s, t) => s + t.amount),
        expense: scoped
            .where((t) => !t.isIncome)
            .fold<double>(0, (s, t) => s + t.amount),
      ));
    }
    return points;
  }

  @override
  Future<double> allTimeBalance() async =>
      _transactions.fold<double>(0, (s, t) => s + t.signedAmount);

  @override
  Future<void> resetDemoData() async {
    _transactions
      ..clear()
      ..addAll(_defaultTransactions());
  }
}
