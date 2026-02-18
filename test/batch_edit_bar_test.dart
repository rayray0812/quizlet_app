import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/home/widgets/batch_edit_bar.dart';

void main() {
  Widget buildBar({
    int selectedCount = 3,
    VoidCallback? onDelete,
    VoidCallback? onAddTag,
    VoidCallback? onRemoveTag,
    VoidCallback? onAiGenerate,
  }) {
    return MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      locale: const Locale('en'),
      home: Scaffold(
        body: BatchEditBar(
          selectedCount: selectedCount,
          onDelete: onDelete ?? () {},
          onAddTag: onAddTag ?? () {},
          onRemoveTag: onRemoveTag ?? () {},
          onAiGenerate: onAiGenerate ?? () {},
        ),
      ),
    );
  }

  testWidgets('shows selected count', (tester) async {
    await tester.pumpWidget(buildBar(selectedCount: 5));
    await tester.pumpAndSettle();
    expect(find.text('5 selected'), findsOneWidget);
  });

  testWidgets('delete button calls callback', (tester) async {
    bool called = false;
    await tester.pumpWidget(buildBar(onDelete: () => called = true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    expect(called, isTrue);
  });

  testWidgets('add tag button calls callback', (tester) async {
    bool called = false;
    await tester.pumpWidget(buildBar(onAddTag: () => called = true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.label_outline));
    expect(called, isTrue);
  });

  testWidgets('remove tag button calls callback', (tester) async {
    bool called = false;
    await tester.pumpWidget(buildBar(onRemoveTag: () => called = true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.label_off_outlined));
    expect(called, isTrue);
  });

  testWidgets('ai generate button calls callback', (tester) async {
    bool called = false;
    await tester.pumpWidget(buildBar(onAiGenerate: () => called = true));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.auto_awesome_rounded));
    expect(called, isTrue);
  });
}
