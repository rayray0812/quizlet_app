import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/study/widgets/true_false_question.dart';

void main() {
  Widget buildWidget({
    String term = 'apple',
    String shownDefinition = 'A fruit',
    bool isCorrectPair = true,
    required void Function(bool) onAnswered,
  }) {
    return MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TrueFalseQuestion(
            term: term,
            shownDefinition: shownDefinition,
            isCorrectPair: isCorrectPair,
            onAnswered: onAnswered,
          ),
        ),
      ),
    );
  }

  testWidgets('renders term and definition', (tester) async {
    await tester.pumpWidget(buildWidget(onAnswered: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('apple'), findsOneWidget);
    expect(find.text('A fruit'), findsOneWidget);
    expect(find.text('True'), findsOneWidget);
    expect(find.text('False'), findsOneWidget);
  });

  testWidgets('correct pair + tap True → correct', (tester) async {
    bool? result;
    await tester.pumpWidget(buildWidget(
      isCorrectPair: true,
      onAnswered: (v) => result = v,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('True'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('correct pair + tap False → incorrect', (tester) async {
    bool? result;
    await tester.pumpWidget(buildWidget(
      isCorrectPair: true,
      onAnswered: (v) => result = v,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('False'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('wrong pair + tap False → correct', (tester) async {
    bool? result;
    await tester.pumpWidget(buildWidget(
      isCorrectPair: false,
      onAnswered: (v) => result = v,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('False'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('cannot answer twice', (tester) async {
    int count = 0;
    await tester.pumpWidget(buildWidget(
      onAnswered: (_) => count++,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('True'));
    await tester.tap(find.text('False'));
    await tester.pumpAndSettle();

    expect(count, 1);
  });
}
