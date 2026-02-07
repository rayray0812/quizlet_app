// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/study/screens/speaking_practice_screen.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/local_storage_service.dart';
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

class _FakeSpeechToTextPlatform extends SpeechToTextPlatform {
  _FakeSpeechToTextPlatform({
    required this.recognizedWords,
    required this.confidence,
  });

  String recognizedWords;
  double confidence;

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> initialize({
    debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async {
    return true;
  }

  @override
  Future<bool> listen({
    String? localeId,
    partialResults = true,
    onDevice = false,
    int listenMode = 0,
    sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    Future<void>.microtask(() {
      onStatus?.call('listening');
      final payload = jsonEncode(<String, dynamic>{
        'alternates': <Map<String, dynamic>>[
          <String, dynamic>{
            'recognizedWords': recognizedWords,
            'confidence': confidence,
          },
        ],
        'finalResult': true,
      });
      onTextRecognition?.call(payload);
      onStatus?.call('done');
      onStatus?.call('notListening');
    });
    return true;
  }

  @override
  Future<List<dynamic>> locales() async {
    return <String>[
      'en-US:English (US)',
      'zh-TW:Chinese (Taiwan)',
    ];
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> cancel() async {}
}

class _FakeLocalStorageService extends LocalStorageService {
  _FakeLocalStorageService(this.studySets);

  final List<StudySet> studySets;
  final Map<String, CardProgress> _progressByCardId = <String, CardProgress>{};
  final List<ReviewLog> savedLogs = <ReviewLog>[];

  @override
  List<StudySet> getAllStudySets() => studySets;

  @override
  List<CardProgress> getAllCardProgress() => _progressByCardId.values.toList();

  @override
  Future<void> saveCardProgress(CardProgress progress) async {
    _progressByCardId[progress.cardId] = progress;
  }

  @override
  Future<void> deleteCardProgress(String cardId) async {
    _progressByCardId.remove(cardId);
  }

  @override
  Future<void> saveReviewLog(ReviewLog log) async {
    savedLogs.add(log);
  }

  @override
  List<ReviewLog> getAllReviewLogs() => savedLogs;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fakeSpeechPlatform = _FakeSpeechToTextPlatform(
    recognizedWords: 'I use apple every day.',
    confidence: 0.95,
  );
  SpeechToTextPlatform.instance = fakeSpeechPlatform;

  Future<_FakeLocalStorageService> pumpScreen(
    WidgetTester tester, {
    required double confidence,
  }) async {
    fakeSpeechPlatform.recognizedWords = 'I use apple every day.';
    fakeSpeechPlatform.confidence = confidence;

    final fakeStorage = _FakeLocalStorageService(<StudySet>[
      StudySet(
        id: 'set-1',
        title: 'Demo',
        createdAt: DateTime.utc(2026, 2, 1),
        cards: const <Flashcard>[
          Flashcard(id: 'c1', term: 'apple', definition: 'fruit'),
          Flashcard(id: 'c2', term: 'banana', definition: 'fruit'),
        ],
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          localStorageServiceProvider.overrideWithValue(fakeStorage),
        ],
        child: MaterialApp(
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale('zh'),
          ],
          home: const SpeakingPracticeScreen(setId: 'set-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();
    return fakeStorage;
  }

  testWidgets(
    'auto score writes speaking log and advances to next card',
    (tester) async {
      final fakeStorage = await pumpScreen(tester, confidence: 0.95);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.text('Auto score'));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(fakeStorage.savedLogs.length, 1);
      expect(fakeStorage.savedLogs.first.reviewType, 'speaking');
      expect(fakeStorage.savedLogs.first.speakingScore, isNotNull);
      expect(fakeStorage.savedLogs.first.speakingScore, 5);
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );

  testWidgets(
    'auto score with low confidence is downgraded',
    (tester) async {
      final fakeStorage = await pumpScreen(tester, confidence: 0.2);
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tap(find.text('Auto score'));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(fakeStorage.savedLogs.length, 1);
      expect(fakeStorage.savedLogs.first.reviewType, 'speaking');
      expect(fakeStorage.savedLogs.first.speakingScore, 3);
      expect(find.text('2 / 2'), findsOneWidget);
    },
  );
}
