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

  test('extractOptionalBoolExtra returns nullable bool from map', () {
    expect(extractOptionalBoolExtra({'challengeMode': true}, 'challengeMode'),
        isTrue);
    expect(
        extractOptionalBoolExtra({'challengeMode': 'true'}, 'challengeMode'),
        isNull);
    expect(extractOptionalBoolExtra('bad', 'challengeMode'), isNull);
  });

  test('isProtectedRoutePath marks auth and home as public', () {
    expect(isProtectedRoutePath('/'), isFalse);
    expect(isProtectedRoutePath('/login'), isFalse);
    expect(isProtectedRoutePath('/signup'), isFalse);
    expect(isProtectedRoutePath('/forgot-password'), isFalse);
    expect(isProtectedRoutePath('/stats'), isTrue);
  });

  test('normalizePostAuthRedirect sanitizes from target', () {
    expect(normalizePostAuthRedirect('/review'), '/review');
    expect(normalizePostAuthRedirect('/study/s1/quiz?count=10'),
        '/study/s1/quiz?count=10');
    expect(normalizePostAuthRedirect('/login?from=%2Freview'), '/');
    expect(normalizePostAuthRedirect('https://evil.example/review'), isNull);
    expect(normalizePostAuthRedirect('review'), isNull);
  });

  test('resolveAppRedirect sends unauthenticated users to login with from', () {
    final redirect = resolveAppRedirect(
      isAuthenticated: false,
      matchedLocation: '/stats',
      currentUri: Uri.parse('/stats?tab=weekly'),
    );

    expect(redirect, '/login?from=%2Fstats%3Ftab%3Dweekly');
  });

  test('resolveAppRedirect sends authenticated users away from auth pages', () {
    final redirect = resolveAppRedirect(
      isAuthenticated: true,
      matchedLocation: '/login',
      currentUri: Uri.parse('/login?from=%2Freview'),
    );

    expect(redirect, '/review');
  });
}
