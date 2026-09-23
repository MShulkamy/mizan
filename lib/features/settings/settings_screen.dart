import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../../widgets/surface_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings'))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 120),
          children: <Widget>[
            _SectionLabel(label: l10n.t('appearance')),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(l10n.t('theme'), style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _Segmented<ThemeMode>(
                    value: settings.themeMode,
                    options: <_Option<ThemeMode>>[
                      _Option(ThemeMode.system, l10n.t('themeSystem'),
                          Icons.brightness_auto_rounded),
                      _Option(ThemeMode.light, l10n.t('themeLight'),
                          Icons.light_mode_rounded),
                      _Option(ThemeMode.dark, l10n.t('themeDark'),
                          Icons.dark_mode_rounded),
                    ],
                    onChanged: controller.setThemeMode,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(label: l10n.t('language')),
            SurfaceCard(
              child: _Segmented<String>(
                value: settings.localeCode,
                options: <_Option<String>>[
                  const _Option('en', 'English', Icons.language_rounded),
                  const _Option('ar', 'العربية', Icons.translate_rounded),
                ],
                onChanged: controller.setLocale,
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(label: l10n.t('currency')),
            SurfaceCard(
              child: DropdownButtonFormField<String>(
                initialValue: settings.currency,
                items: Formatters.currencies
                    .map(
                      (code) => DropdownMenuItem<String>(
                        value: code,
                        child: Text(
                          '$code · ${Formatters.currencySymbol(code)}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) controller.setCurrency(value);
                },
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(label: l10n.t('data')),
            SurfaceCard(
              onTap: () => _confirmReset(context, ref),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.restart_alt_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          l10n.t('resetDemoData'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.t('resetDemoDataBody'),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(label: l10n.t('about')),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          Icons.balance_rounded,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.t('appName'),
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              '${l10n.t('version')} $appVersion',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.t('aboutBody'),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('resetDemoData')),
        content: Text(l10n.t('resetDemoDataBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.t('reset')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(repositoryProvider).resetDemoData();
    refreshFinancialData(ref);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.t('demoDataRestored'))),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.1),
      ),
    );
  }
}

class _Option<T> {
  const _Option(this.value, this.label, this.icon);

  final T value;
  final String label;
  final IconData icon;
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<_Option<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option.value == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm - 3),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      option.icon,
                      size: 18,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: selected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
