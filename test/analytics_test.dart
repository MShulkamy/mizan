import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/data/models/analytics.dart';
import 'package:mizan/data/models/category.dart';

void main() {
  group('MonthlySummary', () {
    test('computes balance as income minus expense', () {
      const summary = MonthlySummary(
        income: 5000,
        expense: 3200,
        previousExpense: 3000,
      );
      expect(summary.balance, 1800);
    });

    test('computes savings rate from income', () {
      const summary = MonthlySummary(
        income: 5000,
        expense: 4000,
        previousExpense: 0,
      );
      expect(summary.savingsRate, closeTo(0.2, 0.0001));
    });

    test('expense delta compares against the previous month', () {
      const summary = MonthlySummary(
        income: 0,
        expense: 1500,
        previousExpense: 1000,
      );
      expect(summary.expenseDelta, closeTo(0.5, 0.0001));
    });

    test('expense delta is zero when there is no previous data', () {
      const summary = MonthlySummary(
        income: 0,
        expense: 1500,
        previousExpense: 0,
      );
      expect(summary.expenseDelta, 0);
    });
  });

  group('CategorySpend', () {
    const category = Category(
      id: 1,
      nameEn: 'Food',
      nameAr: 'طعام',
      iconKey: 'restaurant',
      colorIndex: 0,
      kind: TxType.expense,
    );

    test('flags over budget correctly', () {
      const item = CategorySpend(category: category, amount: 1200, limit: 1000);
      expect(item.isOverBudget, isTrue);
      expect(item.remaining, -200);
    });

    test('progress is clamped', () {
      const item = CategorySpend(category: category, amount: 3000, limit: 1000);
      expect(item.progress, lessThanOrEqualTo(1.5));
    });

    test('has no budget by default', () {
      const item = CategorySpend(category: category, amount: 500);
      expect(item.limit, isNull);
      expect(item.isOverBudget, isFalse);
    });
  });
}
