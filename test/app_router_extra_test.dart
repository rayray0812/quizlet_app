import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/models/study_set.dart';

void main() {
  test('extractStudySetExtra returns null for invalid type', () {
    expect(extractStudySetExtra('bad-extra'), isNull);
  });

  test('extractStudySetExtra returns study set for valid extra', () {
    final set = StudySet(
      id: 's1',
      title: 'Test',
      createdAt: DateTime.utc(2026, 2, 6),
    );

    final result = extractStudySetExtra(set);
    expect(result, isNotNull);
    expect(result!.id, 's1');
  });

  test('extractMapExtra returns empty map for invalid extra', () {
    final map = extractMapExtra(123);
    expect(map, isEmpty);
  });

  test('extractOptionalIntExtra returns nullable int from map', () {
    expect(extractOptionalIntExtra({'questionCount': 10}, 'questionCount'), 10);
    expect(extractOptionalIntExtra({'questionCount': '10'}, 'questionCount'),
        isNull);
    expect(extractOptionalIntExtra('bad', 'questionCount'), isNull);
  });
}

