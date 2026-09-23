import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/analytics.dart';
import '../../data/models/category.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../widgets/budget_progress_bar.dart';
import '../../widgets/charts.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/month_switcher.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/transaction_tile.dart';
import '../editor/transaction_editor.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    super.key,
    required this.onOpenActivity,
    required this.onOpenBudgets,
  });

  final VoidCallback onOpenActivity;
  final VoidCallback onOpenBudgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(summaryProvider);
    final balance = ref.watch(allTimeBalanceProvider);
    final breakdown = ref.watch(breakdownProvider);
    final recent = ref.watch(recentTransactionsProvider);
    final categoryMap = ref.watch(categoryMapProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => refreshFinancialData(ref),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
            children: <Widget>[
              _Header(greeting: _greeting(l10n), tagline: l10n.t('appTagline')),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MonthSwitcher(
                  month: month,
                  onChanged: (value) =>
                      ref.read(selectedMonthProvider.notifier).state = value,
                ),
              ),
              const SizedBox(height: 16),
              _BalanceCard(
                balance: balance.valueOrNull ?? 0,
                summary: summary.valueOrNull,
                currency: settings.currency,
                loading: balance.isLoading || summary.isLoading,
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCard(
                      label: l10n.t('income'),
                      amount: summary.valueOrNull?.income ?? 0,
                      currency: settings.currency,
                      icon: Icons.arrow_downward_rounded,
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: l10n.t('expense'),
                      amount: summary.valueOrNull?.expense ?? 0,
                      currency: settings.currency,
                      icon: Icons.arrow_upward_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeader(title: l10n.t('spendingByCategory')),
              breakdown.when(
                data: (items) => _SpendingCard(
                  items: items,
                  currency: settings.currency,
                ),
                loading: () => const _LoadingCard(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: l10n.t('budgets'),
                actionLabel: l10n.t('seeAll'),
                onAction: onOpenBudgets,
              ),
              breakdown.when(
                data: (items) => _BudgetPreview(
                  items: items.where((i) => i.limit != null).toList(),
                  currency: settings.currency,
                ),
                loading: () => const _LoadingCard(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: l10n.t('recentActivity'),
                actionLabel: l10n.t('seeAll'),
                onAction: onOpenActivity,
              ),
              recent.when(
                data: (items) => items.isEmpty
                    ? SurfaceCard(
                        child: EmptyState(
                          icon: Icons.receipt_long_rounded,
                          title: l10n.t('noTransactions'),
                          message: l10n.t('noTransactionsHint'),
                        ),
                      )
                    : SurfaceCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        child: Column(
                          children: items
                              .map(
                                (tx) => TransactionTile(
                                  transaction: tx,
                                  category: categoryMap[tx.categoryId] ??
                                      _fallbackCategory,
                                  currency: settings.currency,
                                  onTap: () => showTransactionEditor(
                                    context,
                                    existing: tx,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                loading: () => const _LoadingCard(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static final Category _fallbackCategory = Category(
    id: -1,
    nameEn: 'Other',
    nameAr: 'أخرى',
    iconKey: 'category',
    colorIndex: 9,
    kind: TxType.expense,
  );

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (l10n.isArabic) {
      if (hour < 12) return 'صباح الخير';
      if (hour < 18) return 'مساء الخير';
      return 'مساء الخير';
    }
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.greeting, required this.tagline});

  final String greeting;
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(greeting, style: theme.textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(tagline, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.balance_rounded,
            color: theme.colorScheme.onPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.summary,
    required this.currency,
    required this.loading,
  });

  final double balance;
  final MonthlySummary? summary;
  final String currency;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final delta = summary?.expenseDelta ?? 0;
    final isUp = delta > 0.001;
    final isFlat = delta.abs() <= 0.001;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0E7C66), Color(0xFF0A5C4C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF0E7C66).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.t('totalBalance'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 6),
          loading
              ? const SizedBox(
                  height: 40,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Text(
                  Formatters.currency(balance, currency),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                  ),
                ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      isFlat
                          ? Icons.remove_rounded
                          : isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isFlat
                          ? l10n.t('thisMonth')
                          : '${Formatters.percent(delta.abs())} '
                              '${isUp ? l10n.t('higherThanLastMonth') : l10n.t('lowerThanLastMonth')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final String currency;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              Formatters.currency(amount, currency, compact: true),
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({required this.items, required this.currency});

  final List<CategorySpend> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final visible = items.where((i) => i.amount > 0).toList();
    if (visible.isEmpty) {
      return SurfaceCard(
        child: EmptyState(
          icon: Icons.donut_large_rounded,
          title: l10n.t('noTransactions'),
          message: l10n.t('noTransactionsHint'),
        ),
      );
    }

    final top = visible.take(5).toList();
    final othersTotal = visible.skip(5).fold<double>(0, (s, i) => s + i.amount);
    final segments = <DonutSegment>[
      for (final item in top)
        DonutSegment(value: item.amount, color: item.category.color),
      if (othersTotal > 0)
        DonutSegment(
          value: othersTotal,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
    ];
    final total = visible.fold<double>(0, (s, i) => s + i.amount);

    return SurfaceCard(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              DonutChart(
                segments: segments,
                size: 132,
                strokeWidth: 18,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.t('spent'),
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.compactNumber(total),
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: <Widget>[
                    for (var i = 0; i < top.length && i < 5; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: top[i].category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                top[i].category.name(
                                  Localizations.localeOf(context).languageCode,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              Formatters.currency(
                                top[i].amount,
                                currency,
                                compact: true,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetPreview extends StatelessWidget {
  const _BudgetPreview({required this.items, required this.currency});

  final List<CategorySpend> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (items.isEmpty) {
      return SurfaceCard(
        child: EmptyState(
          icon: Icons.savings_rounded,
          title: l10n.t('noBudgetYet'),
          message: l10n.t('noBudgetHint'),
        ),
      );
    }

    final shown = items.take(3).toList();

    return SurfaceCard(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < shown.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 16),
            _row(context, shown[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, CategorySpend item) {
    final theme = Theme.of(context);
    final color = item.isOverBudget
        ? theme.colorScheme.error
        : item.category.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            CategoryAvatar(category: item.category, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.category.name(
                  Localizations.localeOf(context).languageCode,
                ),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              '${Formatters.currency(item.amount, currency, compact: true)} / ${Formatters.currency(item.limit ?? 0, currency, compact: true)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        BudgetProgressBar(
          progress: item.progress,
          color: color,
          overBudget: item.isOverBudget,
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
