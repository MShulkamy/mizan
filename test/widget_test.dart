import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/app.dart';
import 'package:mizan/state/providers.dart';
import 'package:mizan/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_repository.dart';

void main() {
  testWidgets('dashboard renders its core sections', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          repositoryProvider.overrideWithValue(FakeFinanceRepository()),
        ],
        child: const MizanApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Know where your money goes'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Spending by category'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Recent activity'),
      find.byType(ListView).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(find.text('Recent activity'), findsOneWidget);
  });

  testWidgets('switching tabs shows the activity list', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          repositoryProvider.overrideWithValue(FakeFinanceRepository()),
        ],
        child: const MizanApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Activity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dinner out'), findsWidgets);
  });
}
