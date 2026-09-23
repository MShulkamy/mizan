import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../widgets/month_switcher.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_tile.dart';
import '../editor/transaction_editor.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final month = ref.watch(selectedMonthProvider);
    final filter = ref.watch(activityFilterProvider);
    final transactions = ref.watch(activityTransactionsProvider);
    final categoryMap = ref.watch(categoryMapProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('navActivity')),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(
              child: MonthSwitcher(
                month: month,
                onChanged: (value) =>
                    ref.read(selectedMonthProvider.notifier).state = value,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => ref
                    .read(activityFilterProvider.notifier)
                    .update((state) => state.copyWith(query: value)),
                decoration: InputDecoration(
                  hintText: l10n.t('search'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: filter.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(activityFilterProvider.notifier)
                                .update((state) => state.copyWith(query: ''));
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: <Widget>[
                  _FilterChip(
                    label: l10n.t('all'),
                    selected: filter.type == null,
                    onTap: () => ref
                        .read(activityFilterProvider.notifier)
                        .update((state) => state.copyWith(clearType: true)),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.t('income'),
                    selected: filter.type == TxType.income,
                    color: theme.colorScheme.tertiary,
                    onTap: () => ref
                        .read(activityFilterProvider.notifier)
                        .update(
                            (state) => state.copyWith(type: TxType.income)),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: l10n.t('expense'),
                    selected: filter.type == TxType.expense,
                    color: theme.colorScheme.error,
                    onTap: () => ref
                        .read(activityFilterProvider.notifier)
                        .update(
                            (state) => state.copyWith(type: TxType.expense)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: transactions.when(
                data: (items) => items.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: filter.query.isEmpty
                            ? l10n.t('noTransactions')
                            : l10n.t('noResults'),
                        message: filter.query.isEmpty
                            ? l10n.t('noTransactionsHint')
                            : null,
                      )
                    : _GroupedList(
                        transactions: items,
                        categoryMap: categoryMap,
                        currency: settings.currency,
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('$error', textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = color ?? theme.colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? active.withValues(alpha: 0.16)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? active : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: selected ? active : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({
    required this.transactions,
    required this.categoryMap,
    required this.currency,
  });

  final List<MoneyTransaction> transactions;
  final Map<int, Category> categoryMap;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final groups = <DateTime, List<MoneyTransaction>>{};
    for (final tx in transactions) {
      final key = DateUtilsX.dayOnly(tx.date);
      groups.putIfAbsent(key, () => <MoneyTransaction>[]).add(tx);
    }

    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final today = DateUtilsX.dayOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final items = groups[day]!;
        final net = items.fold<double>(0, (sum, tx) => sum + tx.signedAmount);

        final String label;
        if (DateUtilsX.isSameDay(day, today)) {
          label = l10n.t('today');
        } else if (DateUtilsX.isSameDay(day, yesterday)) {
          label = l10n.t('yesterday');
        } else {
          label = '${Formatters.weekday(day)}, ${Formatters.dayMonth(day)}';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Row(
                children: <Widget>[
                  Text(label, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  Text(
                    '${net >= 0 ? '+' : '−'}${Formatters.currency(net.abs(), currency, compact: true)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: net >= 0
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Column(
                children: items
                    .map(
                      (tx) => TransactionTile(
                        transaction: tx,
                        category: categoryMap[tx.categoryId] ??
                            _fallback(categoryMap),
                        currency: currency,
                        onTap: () =>
                            showTransactionEditor(context, existing: tx),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Category _fallback(Map<int, Category> map) {
    if (map.isNotEmpty) return map.values.first;
    return const Category(
      id: -1,
      nameEn: 'Other',
      nameAr: 'أخرى',
      iconKey: 'category',
      colorIndex: 9,
      kind: TxType.expense,
    );
  }
}
