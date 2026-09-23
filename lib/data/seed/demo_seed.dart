import 'dart:math';

import '../models/category.dart';
import '../models/transaction.dart';
import '../local/app_database.dart';

/// Generates a believable starting dataset so a fresh install is not empty.
///
/// Amounts are deterministic (fixed random seed) which keeps screenshots and
/// tests stable while still looking organic.
class DemoSeed {
  DemoSeed._();

  /// Builds demo transactions for the current month and the two before it.
  /// Category ids are resolved by English name at insert time.
  static List<MoneyTransaction> transactions(
    Map<String, int> categoryIds,
    DateTime now,
  ) {
    final random = Random(7);
    final result = <MoneyTransaction>[];
    final today = DateTime(now.year, now.month, now.day);

    for (var back = 2; back >= 0; back--) {
      final monthAnchor = DateTime(now.year, now.month - back, 1);
      final isCurrentMonth = back == 0;
      final daysInMonth =
          DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
      final lastDay = isCurrentMonth ? today.day : daysInMonth;

      void add(String category, int day, double amount, String note) {
        if (day > lastDay) return;
        final id = categoryIds[category];
        if (id == null) return;
        result.add(MoneyTransaction(
          amount: amount,
          type: category == 'Salary' || category == 'Freelance' ||
                  category == 'Gifts'
              ? TxType.income
              : TxType.expense,
          categoryId: id,
          date: DateTime(monthAnchor.year, monthAnchor.month, day, 12, 30),
          note: note,
          account: category == 'Salary' ? 'Bank' : 'Cash',
        ));
      }

      double jitter(double base, double spread) =>
          base + (random.nextDouble() * spread);

      // Fixed monthly commitments
      add('Salary', 1, 18500, 'Monthly salary');
      add('Rent & Home', 2, 4500, 'Apartment rent');
      add('Bills & Utilities', 5, jitter(620, 260), 'Electricity & water');
      add('Bills & Utilities', 6, 350, 'Internet');
      add('Fitness', 7, 450, 'Gym membership');

      // Everyday spending spread across the month
      add('Groceries', 3, jitter(480, 220), 'Weekly groceries');
      add('Groceries', 10, jitter(520, 240), 'Weekly groceries');
      add('Groceries', 17, jitter(460, 200), 'Weekly groceries');
      add('Groceries', 24, jitter(540, 260), 'Weekly groceries');
      add('Coffee', 4, 65, 'Morning coffee');
      add('Coffee', 9, 55, 'Coffee with friends');
      add('Coffee', 15, 70, 'Morning coffee');
      add('Coffee', 21, 60, 'Coffee break');
      add('Food & Dining', 6, jitter(180, 120), 'Dinner out');
      add('Food & Dining', 12, jitter(140, 90), 'Lunch');
      add('Food & Dining', 19, jitter(210, 140), 'Family dinner');
      add('Food & Dining', 26, jitter(160, 100), 'Takeaway');
      add('Transport', 4, 90, 'Fuel');
      add('Transport', 11, 120, 'Fuel');
      add('Transport', 18, 85, 'Ride hailing');
      add('Transport', 25, 110, 'Fuel');
      add('Shopping', 8, jitter(600, 500), 'Clothing');
      add('Entertainment', 14, 220, 'Cinema tickets');
      add('Health', 16, 380, 'Pharmacy');
      add('Education', 20, 900, 'Online course');
      add('Freelance', 22, jitter(2500, 1500), 'Client project');
    }

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Budget limits keyed by category English name.
  static const Map<String, double> budgets = <String, double>{
    'Food & Dining': 2500,
    'Groceries': 2200,
    'Transport': 900,
    'Bills & Utilities': 1500,
    'Shopping': 1500,
    'Entertainment': 800,
  };

  /// The set of categories that a fresh database starts with.
  static List<Map<String, Object?>> get categories => StarterData.categories;
}
