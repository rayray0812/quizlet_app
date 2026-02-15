import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/home/widgets/daily_challenge_card.dart';
import 'package:recall_app/providers/daily_challenge_provider.dart';

void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required DailyChallengeStatus status,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dailyChallengeStatusProvider.overrideWithValue(status)],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: DailyChallengeCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows completed state with green check icon', (tester) async {
    await pumpCard(
      tester,
      status: const DailyChallengeStatus(
        target: 10,
        reviewedToday: 10,
        remaining: 0,
        dueNow: 5,
        currentStreak: 4,
        isCompleted: true,
      ),
    );

    expect(find.text('Today complete: 10/10'), findsOneWidget);
    expect(
      find.text('Great work. Come back tomorrow for a new run.'),
      findsOneWidget,
    );
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('4 day streak'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    final button = tester.widget<ButtonStyleButton>(
      find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows no due cards state with fire icon', (tester) async {
    await pumpCard(
      tester,
      status: const DailyChallengeStatus(
        target: 10,
        reviewedToday: 3,
        remaining: 7,
        dueNow: 0,
        currentStreak: 1,
        isCompleted: false,
      ),
    );

    expect(find.text('Progress: 3/10'), findsOneWidget);
    expect(
      find.text('No due cards now. Review later to continue.'),
      findsOneWidget,
    );
    expect(find.text('Play'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

    final button = tester.widget<ButtonStyleButton>(
      find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('shows playable state with max cards from remaining', (
    tester,
  ) async {
    await pumpCard(
      tester,
      status: const DailyChallengeStatus(
        target: 10,
        reviewedToday: 7,
        remaining: 3,
        dueNow: 12,
        currentStreak: 2,
        isCompleted: false,
      ),
    );

    expect(find.text('Progress: 7/10'), findsOneWidget);
    expect(find.text('Next run: 3 cards'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('2 day streak'), findsOneWidget);

    final button = tester.widget<ButtonStyleButton>(
      find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(button.onPressed, isNotNull);
  });
}
