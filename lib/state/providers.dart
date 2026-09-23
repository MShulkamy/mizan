import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/analytics.dart';
import '../data/models/budget.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../data/repositories/finance_repository.dart';

/// Overridden in `main()` with an opened [SqliteFinanceRepository].
final repositoryProvider = Provider<FinanceRepository>(
  (ref) => throw UnimplementedError('repositoryProvider not overridden'),
);

/// The month the dashboard and activity screens are focused on.
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final categoriesProvider = FutureProvider<List<Category>>(
  (ref) => ref.watch(repositoryProvider).categories(),
);

/// Synchronous id -> category lookup for list rendering.
final categoryMapProvider = Provider<Map<int, Category>>((ref) {
  final list = ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
  return <int, Category>{for (final category in list) category.id: category};
});

final summaryProvider = FutureProvider<MonthlySummary>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(repositoryProvider).summary(month);
});

final allTimeBalanceProvider = FutureProvider<double>(
  (ref) => ref.watch(repositoryProvider).allTimeBalance(),
);

final breakdownProvider = FutureProvider<List<CategorySpend>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(repositoryProvider).categoryBreakdown(month);
});

final seriesProvider = FutureProvider<List<MonthlyPoint>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(repositoryProvider).monthlySeries(month, 6);
});

final budgetsProvider = FutureProvider<List<Budget>>(
  (ref) => ref.watch(repositoryProvider).budgets(),
);

/// Filter state for the activity list.
class ActivityFilter {
  const ActivityFilter({this.type, this.query = ''});

  final TxType? type;
  final String query;

  ActivityFilter copyWith({TxType? type, String? query, bool clearType = false}) =>
      ActivityFilter(
        type: clearType ? null : (type ?? this.type),
        query: query ?? this.query,
      );

  @override
  bool operator ==(Object other) =>
      other is ActivityFilter && other.type == type && other.query == query;

  @override
  int get hashCode => Object.hash(type, query);
}

final activityFilterProvider =
    StateProvider<ActivityFilter>((ref) => const ActivityFilter());

final activityTransactionsProvider =
    FutureProvider<List<MoneyTransaction>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  final filter = ref.watch(activityFilterProvider);
  return ref.watch(repositoryProvider).transactions(
        month: month,
        type: filter.type,
        query: filter.query,
      );
});

final recentTransactionsProvider =
    FutureProvider<List<MoneyTransaction>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final all = await ref.watch(repositoryProvider).transactions(month: month);
  return all.take(5).toList();
});

/// Invalidates every provider that reads transaction or budget data.
void refreshFinancialData(WidgetRef ref) {
  ref.invalidate(summaryProvider);
  ref.invalidate(allTimeBalanceProvider);
  ref.invalidate(breakdownProvider);
  ref.invalidate(seriesProvider);
  ref.invalidate(activityTransactionsProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(budgetsProvider);
}
