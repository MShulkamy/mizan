/// Value objects produced by the analytics queries.
library;

import 'category.dart';

/// Totals for a single month.
class MonthlySummary {
  const MonthlySummary({
    required this.income,
    required this.expense,
    required this.previousExpense,
  });

  final double income;
  final double expense;
  final double previousExpense;

  double get balance => income - expense;

  /// Positive means spending is higher than the previous month.
  double get expenseDelta =>
      previousExpense <= 0 ? 0 : (expense - previousExpense) / previousExpense;

  double get savingsRate => income <= 0 ? 0 : (income - expense) / income;
}

/// Amount spent in one category, plus the optional budget for it.
class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.amount,
    this.limit,
  });

  final Category category;
  final double amount;
  final double? limit;

  double get progress =>
      (limit == null || limit! <= 0) ? 0 : (amount / limit!).clamp(0, 1.5);

  bool get isOverBudget => limit != null && limit! > 0 && amount > limit!;

  double get remaining => (limit ?? 0) - amount;
}

/// A single point on the trend chart.
class MonthlyPoint {
  const MonthlyPoint({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final double income;
  final double expense;
}
