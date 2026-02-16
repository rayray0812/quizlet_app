import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/study/widgets/quiz_option_tile.dart';

void main() {
  Future<void> pumpTile(
    WidgetTester tester, {
    required QuizOptionState state,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuizOptionTile(
            text: 'Test option',
            state: state,
            onTap: onTap,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('normal state shows no check or cancel icon', (tester) async {
    await pumpTile(tester, state: QuizOptionState.normal);

    expect(find.text('Test option'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
  });

  testWidgets('correct state shows green check icon', (tester) async {
    await pumpTile(tester, state: QuizOptionState.correct);

    expect(find.text('Test option'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
  });

  testWidgets('incorrect state shows red cancel icon', (tester) async {
    await pumpTile(tester, state: QuizOptionState.incorrect);

    expect(find.text('Test option'), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('onTap callback fires on tap', (tester) async {
    var tapped = false;
    await pumpTile(
      tester,
      state: QuizOptionState.normal,
      onTap: () => tapped = true,
    );

    // Use tap on the GestureDetector area
    await tester.tap(find.text('Test option'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
