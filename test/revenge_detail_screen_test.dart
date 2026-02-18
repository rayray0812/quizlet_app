import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/study/screens/revenge_detail_screen.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/providers/revenge_provider.dart';
import 'package:recall_app/providers/stats_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/local_storage_service.dart';

void main() {
  setUpAll(() async {
    Hive.init('.');
    // Open all boxes needed by LocalStorageService / StudySetsNotifier
    if (!Hive.isBoxOpen(AppConstants.hiveStudySetsBox)) {
      await Hive.openBox(AppConstants.hiveStudySetsBox);
    }
    if (!Hive.isBoxOpen(AppConstants.hiveCardProgressBox)) {
      await Hive.openBox(AppConstants.hiveCardProgressBox);
    }
    if (!Hive.isBoxOpen(AppConstants.hiveReviewLogsBox)) {
      await Hive.openBox(AppConstants.hiveReviewLogsBox);
    }
    if (!Hive.isBoxOpen(AppConstants.hiveSettingsBox)) {
      await Hive.openBox(AppConstants.hiveSettingsBox);
    }
  });

  final testSets = [
    StudySet(
      id: 'set-1',
      title: 'English Vocab',
      createdAt: DateTime.utc(2026, 1, 1),
      cards: [
        const Flashcard(id: 'c1', term: 'apple', definition: 'a fruit'),
        const Flashcard(id: 'c2', term: 'book', definition: 'to read'),
        const Flashcard(id: 'c3', term: 'cat', definition: 'an animal'),
        const Flashcard(id: 'c4', term: 'dog', definition: 'a pet'),
      ],
    ),
    StudySet(
      id: 'set-2',
      title: 'Math Terms',
      createdAt: DateTime.utc(2026, 1, 1),
      cards: [
        const Flashcard(id: 'c5', term: 'sum', definition: 'addition result'),
      ],
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    Map<String, List<String>>? cardsBySet,
    RevengeStats? stats,
    List<String>? cardIds,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allReviewLogsProvider.overrideWithValue(const []),
          studySetsProvider.overrideWith((ref) {
            final notifier = StudySetsNotifier(LocalStorageService());
            // ignore: invalid_use_of_protected_member
            notifier.state = testSets;
            return notifier;
          }),
          revengeCardsBySetProvider.overrideWithValue(
            cardsBySet ?? {
              'set-1': ['c1', 'c2'],
              'set-2': ['c5'],
            },
          ),
          revengeStatsProvider.overrideWithValue(
            stats ?? const RevengeStats(
              totalWrong: 3,
              clearedCount: 1,
              clearRate: 0.33,
              topWrong: [
                (cardId: 'c1', setId: 'set-1', wrongCount: 3),
                (cardId: 'c2', setId: 'set-1', wrongCount: 2),
              ],
            ),
          ),
          revengeCardIdsProvider.overrideWithValue(
            cardIds ?? ['c1', 'c2', 'c5'],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: const RevengeDetailScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders lookback day segments', (tester) async {
    await pumpScreen(tester);

    expect(find.text('3 days'), findsOneWidget);
    expect(find.text('7 days'), findsOneWidget);
    expect(find.text('14 days'), findsOneWidget);
    expect(find.text('30 days'), findsOneWidget);
  });

  testWidgets('renders stats section', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Clear Rate'), findsOneWidget);
  });

  testWidgets('renders action buttons', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Flip Review'), findsOneWidget);
    expect(find.text('Quiz Mode'), findsOneWidget);
  });

  testWidgets('shows need-more-cards hint when < 4 cards', (tester) async {
    await pumpScreen(
      tester,
      cardsBySet: {'set-1': ['c1', 'c2']},
      stats: const RevengeStats(
        totalWrong: 2,
        clearedCount: 0,
        clearRate: 0.0,
        topWrong: [],
      ),
      cardIds: ['c1', 'c2'],
    );

    expect(
      find.text('Need at least 4 wrong cards for quiz'),
      findsOneWidget,
    );
  });
}
