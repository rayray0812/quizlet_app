import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/auth/widgets/social_auth_buttons.dart';

void main() {
  test('isOAuthCancelError detects common cancel patterns', () {
    expect(isOAuthCancelError('Auth: user canceled the flow'), isTrue);
    expect(isOAuthCancelError('access_denied'), isTrue);
    expect(isOAuthCancelError('popup_closed_by_user'), isTrue);
  });

  test('buildOAuthRetryMessage returns canceled text when canceled', () {
    final message = buildOAuthRetryMessage(
      providerName: 'Google',
      rawError: 'access_denied',
      canceledByResult: false,
    );
    expect(message, 'Google \u767B\u5165\u5DF2\u53D6\u6D88\u3002');
  });

  test(
    'buildOAuthRetryMessage returns mapped failure for non-cancel errors',
    () {
      final message = buildOAuthRetryMessage(
        providerName: 'Google',
        rawError: 'Provider is not enabled',
        canceledByResult: false,
      );
      expect(message, '\u6B64\u767B\u5165\u65B9\u5F0F\u5C1A\u672A\u555F\u7528\u3002');
    },
  );

  test('buildOAuthRetryMessage returns fallback for empty errors', () {
    final message = buildOAuthRetryMessage(
      providerName: 'Apple',
      rawError: '',
      canceledByResult: false,
    );
    expect(message, 'Apple \u767B\u5165\u5931\u6557\uFF0C\u8ACB\u518D\u8A66\u4E00\u6B21\u3002');
  });
}
