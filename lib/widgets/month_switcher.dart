import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../core/utils/formatters.dart';

/// Left/right month selector used on the dashboard, activity and budget screens.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
    this.allowFuture = false,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final bool allowFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final atCurrentMonth = DateUtilsX.isSameMonth(month, now);
    final nextDisabled = atCurrentMonth && !allowFuture;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _NavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => onChanged(DateUtilsX.addMonths(month, -1)),
          semanticLabel: 'Previous month',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            Formatters.monthYear(month),
            style: theme.textTheme.titleMedium,
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          onTap: nextDisabled
              ? null
              : () => onChanged(DateUtilsX.addMonths(month, 1)),
          semanticLabel: 'Next month',
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              icon,
              size: 20,
              color: disabled
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
