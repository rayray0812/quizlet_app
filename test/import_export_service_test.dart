import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/services/import_export_service.dart';

void main() {
  test('CSV parser supports quoted newlines and escaped quotes', () {
    final service = ImportExportService();
    const csv = 'term,definition\n'
        '"hello","line1\nline2"\n'
        '"say ""hi""","quoted ""text"""';

    final set = service.parseCsvForTesting(csv);

    expect(set, isNotNull);
    expect(set!.cards.length, 2);
    expect(set.cards[0].term, 'hello');
    expect(set.cards[0].definition, 'line1\nline2');
    expect(set.cards[1].term, 'say "hi"');
    expect(set.cards[1].definition, 'quoted "text"');
  });
}

