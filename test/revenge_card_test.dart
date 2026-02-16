import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/home/widgets/revenge_card.dart';
import 'package:recall_app/providers/revenge_provider.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    required List<String> cardIds,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [revengeCardIdsProvider.overrideWithValue(cardIds)],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const Scaffold(body: RevengeCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('count=0 renders SizedBox.shrink', (tester) async {
    await pumpCard(tester, cardIds: []);

    // Should not render any visible content
    expect(find.text('Revenge Mode'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('count>0 shows title, count text, and play button', (
    tester,
  ) async {
    await pumpCard(tester, cardIds: ['c1', 'c2', 'c3']);

    expect(find.text('Revenge Mode'), findsOneWidget);
    expect(find.text('3 wrong cards waiting for you'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.byIcon(Icons.replay_rounded), findsOneWidget);
  });

  testWidgets('FilledButton is present and tappable when count>0', (
    tester,
  ) async {
    await pumpCard(tester, cardIds: ['c1']);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('single card shows correct count text', (tester) async {
    await pumpCard(tester, cardIds: ['c1']);

    expect(find.text('1 wrong cards waiting for you'), findsOneWidget);
  });
}
