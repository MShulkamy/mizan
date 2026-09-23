import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../core/utils/formatters.dart';
import '../data/models/category.dart';
import '../data/models/transaction.dart';
import 'category_avatar.dart';

/// A single row in the activity list.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.category,
    required this.currency,
    this.onTap,
    this.showDate = false,
  });

  final MoneyTransaction transaction;
  final Category category;
  final String currency;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isIncome = transaction.isIncome;
    final amountColor = isIncome
        ? theme.colorScheme.tertiary
        : theme.colorScheme.error;

    final title = transaction.note.trim().isEmpty
        ? l10n.categoryName(category.nameEn, category.nameAr)
        : transaction.note;

    final subtitleParts = <String>[
      l10n.categoryName(category.nameEn, category.nameAr),
      transaction.account,
      if (showDate) Formatters.dayMonth(transaction.date),
    ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: <Widget>[
            CategoryAvatar(category: category),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleParts.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${isIncome ? '+' : '−'}${Formatters.currency(transaction.amount, currency)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
