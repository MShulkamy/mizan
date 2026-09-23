import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/analytics.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../widgets/charts.dart';
import '../../widgets/surface_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final month = ref.watch(selectedMonthProvider);
    final series = ref.watch(seriesProvider);
    final breakdown = ref.watch(breakdownProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('insights'))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
          children: <Widget>[
            series.when(
              data: (points) => _TrendCard(
                points: points,
                currency: settings.currency,
              ),
              loading: () => const _Loading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            series.when(
              data: (points) {
                final active =
                    points.where((p) => p.expense > 0 || p.income > 0).toList();
                final avg = active.isEmpty
                    ? 0.0
                    : active.fold<double>(0, (s, p) => s + p.expense) /
                        active.length;
                final totalIncome =
                    active.fold<double>(0, (s, p) => s + p.income);
                final totalExpense =
                    active.fold<double>(0, (s, p) => s + p.expense);
                final savings = totalIncome <= 0
                    ? 0.0
                    : (totalIncome - totalExpense) / totalIncome;

                return Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricCard(
                        label: l10n.t('averageMonthlySpend'),
                        value: Formatters.currency(avg, settings.currency,
                            compact: true),
                        icon: Icons.stacked_line_chart_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: l10n.t('savingsRate'),
                        value: Formatters.percent(savings),
                        icon: Icons.savings_rounded,
                        color: savings >= 0
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const _Loading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 26),
            SectionHeader(title: l10n.t('topCategories')),
            breakdown.when(
              data: (items) => _TopCategories(
                items: items.where((i) => i.amount > 0).toList(),
                currency: settings.currency,
              ),
              loading: () => const _Loading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 26),
            SectionHeader(title: l10n.t('incomeVsExpense')),
            series.when(
              data: (points) => SurfaceCard(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        _legend(
                          context,
                          l10n.t('income'),
                          theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 16),
                        _legend(
                          context,
                          l10n.t('expense'),
                          theme.colorScheme.error,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GroupedBarChart(
                      points: points,
                      incomeColor: theme.colorScheme.tertiary,
                      expenseColor: theme.colorScheme.error,
                      labelBuilder: Formatters.monthShort,
                    ),
                  ],
                ),
              ),
              loading: () => const _Loading(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${l10n.t('thisMonth')}: ${Formatters.monthYear(month)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(BuildContext context, String label, Color color) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.points, required this.currency});

  final List<MonthlyPoint> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final last = points.isEmpty ? null : points.last;
    final previous = points.length < 2 ? null : points[points.length - 2];
    final delta = (last == null || previous == null || previous.expense <= 0)
        ? 0.0
        : (last.expense - previous.expense) / previous.expense;
    final improving = delta <= 0;

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  improving ? l10n.t('onTrack') : l10n.t('overspending'),
                  style: theme.textTheme.titleLarge,
                ),
              ),
              Icon(
                improving
                    ? Icons.verified_rounded
                    : Icons.error_outline_rounded,
                color: improving
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.error,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.t('last6Months')} · ${l10n.t('expense')}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
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
          const SizedBox(height: 14),
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 3),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _TopCategories extends StatelessWidget {
  const _TopCategories({required this.items, required this.currency});

  final List<CategorySpend> items;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final max = items.first.amount;
    final top = items.take(6).toList();

    return SurfaceCard(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < top.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Text(
                    top[i].category.name(
                      Localizations.localeOf(context).languageCode,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: max <= 0 ? 0 : top[i].amount / max,
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 7,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          top[i].category.color,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 74,
                  child: Text(
                    Formatters.currency(top[i].amount, currency, compact: true),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SurfaceCard(
      child: SizedBox(
        height: 110,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
