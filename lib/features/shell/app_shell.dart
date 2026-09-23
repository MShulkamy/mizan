import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/app_localizations.dart';
import '../activity/activity_screen.dart';
import '../budgets/budgets_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../editor/transaction_editor.dart';
import '../insights/insights_screen.dart';
import '../settings/settings_screen.dart';

/// Root navigation shell: a five-tab layout with a shared quick-add button.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final screens = <Widget>[
      DashboardScreen(
        onOpenActivity: () => _goTo(1),
        onOpenBudgets: () => _goTo(2),
      ),
      const ActivityScreen(),
      const BudgetsScreen(),
      const InsightsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      floatingActionButton: _index == 4
          ? null
          : FloatingActionButton(
              onPressed: () => showTransactionEditor(context),
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: <NavigationDestination>[
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.t('navHome'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long_rounded),
            label: l10n.t('navActivity'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.savings_outlined),
            selectedIcon: const Icon(Icons.savings_rounded),
            label: l10n.t('navBudgets'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l10n.t('navInsights'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n.t('navSettings'),
          ),
        ],
      ),
    );
  }
}
