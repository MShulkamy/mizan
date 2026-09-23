import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../widgets/surface_card.dart';

/// Opens the add/edit transaction sheet.
Future<void> showTransactionEditor(
  BuildContext context, {
  MoneyTransaction? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TransactionEditor(existing: existing),
  );
}

class _TransactionEditor extends ConsumerStatefulWidget {
  const _TransactionEditor({this.existing});

  final MoneyTransaction? existing;

  @override
  ConsumerState<_TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends ConsumerState<_TransactionEditor> {
  late TxType _type;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  int? _categoryId;
  late DateTime _date;
  String _account = 'Cash';
  String? _amountError;

  bool get _isEditing => widget.existing != null;

  static const List<String> _accounts = <String>['Cash', 'Bank', 'Card'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? TxType.expense;
    _amountController = TextEditingController(
      text: existing == null ? '' : _trimAmount(existing.amount),
    );
    _noteController = TextEditingController(text: existing?.note ?? '');
    _categoryId = existing?.categoryId;
    _date = existing?.date ?? DateTime.now();
    _account = existing?.account ?? 'Cash';
  }

  String _trimAmount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _amountError = l10n.t('invalidAmount'));
      return;
    }
    if (_categoryId == null) return;

    final repo = ref.read(repositoryProvider);
    final transaction = MoneyTransaction(
      id: widget.existing?.id,
      amount: amount,
      type: _type,
      categoryId: _categoryId!,
      date: _date,
      note: _noteController.text.trim(),
      account: _account,
    );

    if (_isEditing) {
      await repo.updateTransaction(transaction);
    } else {
      await repo.addTransaction(transaction);
    }

    if (!mounted) return;
    refreshFinancialData(ref);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('saved'))),
    );
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('deleteTransaction')),
        content: Text(l10n.t('deleteTransactionBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(repositoryProvider).deleteTransaction(widget.existing!.id!);
    if (!mounted) return;
    refreshFinancialData(ref);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('deleted'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        _isEditing
                            ? l10n.t('editTransaction')
                            : l10n.t('addTransaction'),
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    if (_isEditing)
                      IconButton(
                        onPressed: _delete,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: <Widget>[
                    _TypeToggle(
                      type: _type,
                      onChanged: (value) => setState(() {
                        _type = value;
                        _categoryId = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    _AmountField(
                      controller: _amountController,
                      currency: settings.currency,
                      errorText: _amountError,
                      onChanged: (_) {
                        if (_amountError != null) {
                          setState(() => _amountError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 22),
                    Text(l10n.t('category'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    categoriesAsync.when(
                      data: (categories) {
                        final filtered = categories
                            .where((c) => c.kind == _type)
                            .toList(growable: false);
                        return _CategoryPicker(
                          categories: filtered,
                          selectedId: _categoryId,
                          onSelected: (id) => setState(() => _categoryId = id),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 22),
                    Text(l10n.t('account'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _accounts
                          .map((account) => ChoiceChip(
                                label: Text(account),
                                selected: _account == account,
                                onSelected: (_) =>
                                    setState(() => _account = account),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 22),
                    Text(l10n.t('date'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      onTap: _pickDate,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${Formatters.weekday(_date)}, ${Formatters.dayMonth(_date)} ${_date.year}',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(l10n.t('note'), style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _noteController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(hintText: l10n.t('noteHint')),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(l10n.t('save')),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.type, required this.onChanged});

  final TxType type;
  final ValueChanged<TxType> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: <Widget>[
          _segment(context, l10n.t('expense'), TxType.expense,
              theme.colorScheme.error),
          _segment(context, l10n.t('income'), TxType.income,
              theme.colorScheme.tertiary),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    String label,
    TxType value,
    Color color,
  ) {
    final theme = Theme.of(context);
    final selected = value == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm - 3),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.currency,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: errorText != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context).t('amount'),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                Formatters.currencySymbol(currency),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9.]'),
                    ),
                  ],
                  style: theme.textTheme.displaySmall,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: '0',
                  ),
                ),
              ),
            ],
          ),
          if (errorText != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: categories.map((category) {
        final selected = category.id == selectedId;
        return GestureDetector(
          onTap: () => onSelected(category.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? category.color.withValues(alpha: 0.18)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: selected ? category.color : theme.colorScheme.outline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(category.icon, size: 17, color: category.color),
                const SizedBox(width: 7),
                Text(
                  category.name(
                    Localizations.localeOf(context).languageCode,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
