import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/analytics.dart';
import '../../data/models/category.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../widgets/budget_progress_bar.dart';
import '../../widgets/category_avatar.dart';
import '../../widgets/month_switcher.dart';
import '../../widgets/surface_card.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final month = ref.watch(selectedMonthProvider);
    final breakdown = ref.watch(breakdownProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('budgets')),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.t('addBudget')),
      ),
      body: SafeArea(
        top: false,
        child: breakdown.when(
          data: (items) {
            final budgeted =
                items.where((i) => i.limit != null).toList(growable: false);
            if (budgeted.isEmpty) {
              return EmptyState(
                icon: Icons.savings_rounded,
                title: l10n.t('noBudgetYet'),
                message: l10n.t('noBudgetHint'),
              );
            }

            final totalLimit =
                budgeted.fold<double>(0, (s, i) => s + (i.limit ?? 0));
            final totalSpent = budgeted.fold<double>(0, (s, i) => s + i.amount);

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
              children: <Widget>[
                _TotalsCard(
                  totalLimit: totalLimit,
                  totalSpent: totalSpent,
                  currency: settings.currency,
                ),
                const SizedBox(height: 18),
                for (final item in budgeted) ...<Widget>[
                  _BudgetCard(
                    item: item,
                    currency: settings.currency,
                    onTap: () => _openEditor(context, ref, item: item),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    CategorySpend? item,
  }) async {
    final categories = await ref.read(repositoryProvider).categories();
    if (!context.mounted) return;

    final result = await showDialog<_BudgetResult>(
      context: context,
      builder: (_) => _BudgetEditorDialog(
        categories: categories.where((c) => c.kind == TxType.expense).toList(),
        existing: item,
        currency: ref.read(settingsProvider).currency,
      ),
    );
    if (result == null) return;

    final repo = ref.read(repositoryProvider);
    if (result.deleted) {
      await repo.deleteBudget(result.categoryId);
    } else if (result.limit != null) {
      await repo.setBudget(result.categoryId, result.limit!);
    }
    refreshFinancialData(ref);
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({
    required this.totalLimit,
    required this.totalSpent,
    required this.currency,
  });

  final double totalLimit;
  final double totalSpent;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final remaining = totalLimit - totalSpent;
    final progress = totalLimit <= 0 ? 0.0 : totalSpent / totalLimit;

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _metric(
                  context,
                  l10n.t('spent'),
                  Formatters.currency(totalSpent, currency),
                  theme.colorScheme.error,
                ),
              ),
              Expanded(
                child: _metric(
                  context,
                  l10n.t('remaining'),
                  Formatters.currency(remaining.abs(), currency),
                  remaining >= 0
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.error,
                ),
              ),
              Expanded(
                child: _metric(
                  context,
                  l10n.t('budget'),
                  Formatters.currency(totalLimit, currency),
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          BudgetProgressBar(
            progress: progress,
            color: remaining >= 0
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
            overBudget: remaining < 0,
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.item,
    required this.currency,
    required this.onTap,
  });

  final CategorySpend item;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final over = item.isOverBudget;
    final color = over ? theme.colorScheme.error : item.category.color;

    return SurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CategoryAvatar(category: item.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.category.name(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.currency(item.amount, currency, compact: true)} ${l10n.t('ofBudget')} ${Formatters.currency(item.limit ?? 0, currency, compact: true)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (over)
                TagPill(
                  label: l10n.t('overBudget'),
                  color: theme.colorScheme.error,
                  icon: Icons.warning_amber_rounded,
                )
              else
                Text(
                  Formatters.percent(item.progress),
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
            ],
          ),
          const SizedBox(height: 12),
          BudgetProgressBar(
            progress: item.progress,
            color: color,
            overBudget: over,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(
                over
                    ? Icons.arrow_upward_rounded
                    : Icons.check_circle_outline_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                over
                    ? '${Formatters.currency(item.amount - (item.limit ?? 0), currency)} ${l10n.t('overBudget')}'
                    : '${Formatters.currency(item.remaining, currency)} ${l10n.t('remaining')}',
                style: theme.textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetResult {
  const _BudgetResult({
    required this.categoryId,
    this.limit,
    this.deleted = false,
  });

  final int categoryId;
  final double? limit;
  final bool deleted;
}

class _BudgetEditorDialog extends StatefulWidget {
  const _BudgetEditorDialog({
    required this.categories,
    required this.currency,
    this.existing,
  });

  final List<Category> categories;
  final String currency;
  final CategorySpend? existing;

  @override
  State<_BudgetEditorDialog> createState() => _BudgetEditorDialogState();
}

class _BudgetEditorDialogState extends State<_BudgetEditorDialog> {
  late final TextEditingController _controller;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.category.id;
    _controller = TextEditingController(
      text: widget.existing?.limit == null
          ? ''
          : widget.existing!.limit!.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final editing = widget.existing != null;

    return AlertDialog(
      title: Text(editing ? l10n.t('budget') : l10n.t('addBudget')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (!editing) ...<Widget>[
              Text(l10n.t('category'), style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.categories.map((category) {
                  final selected = category.id == _categoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = category.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? category.color.withValues(alpha: 0.18)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: selected
                              ? category.color
                              : theme.colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(category.icon,
                              size: 15, color: category.color),
                          const SizedBox(width: 6),
                          Text(
                            category.name(
                              Localizations.localeOf(context).languageCode,
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],
            Text(l10n.t('monthlyLimit'), style: theme.textTheme.labelSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                prefixText: '${Formatters.currencySymbol(widget.currency)} ',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (editing)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _BudgetResult(
                categoryId: widget.existing!.category.id,
                deleted: true,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.t('delete')),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_controller.text.trim());
            if (_categoryId == null || amount == null || amount <= 0) return;
            Navigator.pop(
              context,
              _BudgetResult(categoryId: _categoryId!, limit: amount),
            );
          },
          child: Text(l10n.t('save')),
        ),
      ],
    );
  }
}
