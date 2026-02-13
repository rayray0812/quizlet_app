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
    expect(message, 'Google sign-in was canceled.');
  });

  test(
    'buildOAuthRetryMessage returns mapped failure for non-cancel errors',
    () {
      final message = buildOAuthRetryMessage(
        providerName: 'Google',
        rawError: 'Provider is not enabled',
        canceledByResult: false,
      );
      expect(message, 'This sign-in provider is not enabled yet.');
    },
  );

  test('buildOAuthRetryMessage returns fallback for empty errors', () {
    final message = buildOAuthRetryMessage(
      providerName: 'Apple',
      rawError: '',
      canceledByResult: false,
    );
    expect(message, 'Apple sign-in failed. Please try again.');
  });
}
