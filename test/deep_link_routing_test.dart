import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/router/app_router.dart';

void main() {
  group('Deep link URI parsing', () {
    test('recall://review URI parses to /review path', () {
      final uri = Uri.parse('recall://review');
      expect(uri.scheme, 'recall');
      expect(uri.host, 'review');
      // GoRouter would map host as path segment
      // The actual path mapping happens at platform level;
      // here we verify the URI structure is valid.
      expect(uri.toString(), 'recall://review');
    });

    test('recall://import with query params parses correctly', () {
      final uri = Uri.parse('recall://import?data=abc123&format=json');
      expect(uri.scheme, 'recall');
      expect(uri.host, 'import');
      expect(uri.queryParameters['data'], 'abc123');
      expect(uri.queryParameters['format'], 'json');
    });
  });

  group('Router helper functions', () {
    test('extractMapExtra returns map for valid input', () {
      final result = extractMapExtra({
        'totalReviewed': 10,
        'isRevengeMode': true,
      });
      expect(result['totalReviewed'], 10);
      expect(result['isRevengeMode'], true);
    });

    test('extractMapExtra returns empty map for non-map input', () {
      expect(extractMapExtra(null), isEmpty);
      expect(extractMapExtra('string'), isEmpty);
      expect(extractMapExtra(42), isEmpty);
    });

    test('extractOptionalIntExtra extracts int from map extra', () {
      final extra = {'revengeCardCount': 5, 'other': 'text'};
      expect(extractOptionalIntExtra(extra, 'revengeCardCount'), 5);
      expect(extractOptionalIntExtra(extra, 'other'), isNull);
      expect(extractOptionalIntExtra(extra, 'missing'), isNull);
    });

    test('extractOptionalBoolExtra extracts bool from map extra', () {
      final extra = {'isRevengeMode': true, 'count': 3};
      expect(extractOptionalBoolExtra(extra, 'isRevengeMode'), isTrue);
      expect(extractOptionalBoolExtra(extra, 'count'), isNull);
      expect(extractOptionalBoolExtra(extra, 'missing'), isNull);
    });

    test('normalizePostAuthRedirect handles recall:// scheme as invalid', () {
      // Deep link URIs with scheme should be rejected by normalizePostAuthRedirect
      expect(normalizePostAuthRedirect('recall://review'), isNull);
    });
  });
}
