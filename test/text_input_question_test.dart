import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      locale: const Locale('zh'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextInputQuestion(
              definition: definition,
              correctAnswer: correctAnswer,
              onAnswered: onAnswered,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders definition and input field', (tester) async {
    await tester.pumpWidget(buildWidget(onAnswered: (_) {}));
    await tester.pumpAndSettle();

    // Definition should be visible
    expect(find.text('A greeting'), findsOneWidget);
    // Should have a TextField (hidden blank-fill input)
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('correct answer shows correct feedback', (tester) async {
    bool? result;
    await tester.pumpWidget(buildWidget(onAnswered: (v) => result = v));
    await tester.pumpAndSettle();

    // Enter text into the hidden TextField — blank-fill auto-submits when
    // all characters are entered.
    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
