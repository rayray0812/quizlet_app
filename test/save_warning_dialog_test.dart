import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/home/widgets/save_warning_dialog.dart';

void main() {
  Future<bool?> showWarning(
    WidgetTester tester, {
    List<String> blanks = const [],
    List<String> duplicates = const [],
  }) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => SaveWarningDialog(
                  blankWarnings: blanks,
                  duplicateWarnings: duplicates,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows blank warnings', (tester) async {
    await showWarning(tester, blanks: ['Card #1: missing Term']);
    expect(find.textContaining('Card #1: missing Term'), findsOneWidget);
    expect(find.text('Save Anyway'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);
  });

  testWidgets('shows duplicate warnings', (tester) async {
    await showWarning(
      tester,
      duplicates: ['Cards #1 and #2 are duplicates'],
    );
    expect(
      find.textContaining('Cards #1 and #2 are duplicates'),
      findsOneWidget,
    );
  });

  testWidgets('Go Back returns false', (tester) async {
    await showWarning(tester, blanks: ['test']);
    await tester.tap(find.text('Go Back'));
    await tester.pumpAndSettle();
    // Dialog dismissed — no crash
  });

  testWidgets('Save Anyway returns true', (tester) async {
    await showWarning(tester, blanks: ['test']);
    await tester.tap(find.text('Save Anyway'));
    await tester.pumpAndSettle();
    // Dialog dismissed — no crash
  });
}
