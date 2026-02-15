import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/study/widgets/text_input_question.dart';

void main() {
  Widget buildWidget({
    String definition = 'A greeting',
    String correctAnswer = 'hello',
    required void Function(bool) onAnswered,
  }) {
    return MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextInputQuestion(
            definition: definition,
            correctAnswer: correctAnswer,
            onAnswered: onAnswered,
          ),
        ),
      ),
    );
  }

  testWidgets('renders definition and input field', (tester) async {
    await tester.pumpWidget(buildWidget(onAnswered: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('A greeting'), findsOneWidget);
    expect(find.text('Type your answer'), findsOneWidget);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('correct answer shows correct feedback', (tester) async {
    bool? result;
    await tester.pumpWidget(buildWidget(onAnswered: (v) => result = v));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text('Correct answer'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('wrong answer shows the correct answer', (tester) async {
    bool? result;
    await tester.pumpWidget(buildWidget(onAnswered: (v) => result = v));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
    expect(find.text('Almost! The correct answer is:'), findsOneWidget);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('empty input does not submit', (tester) async {
    bool called = false;
    await tester.pumpWidget(buildWidget(onAnswered: (_) => called = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });
}
