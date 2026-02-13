import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/auth/utils/auth_error_mapper.dart';

void main() {
  test('maps invalid credentials error', () {
    final message = mapAuthErrorMessage(
      'AuthApiException: Invalid login credentials',
    );
    expect(message, 'Invalid email or password.');
  });

  test('maps provider disabled error', () {
    final message = mapAuthErrorMessage('Provider is not enabled');
    expect(message, 'This sign-in provider is not enabled yet.');
  });

  test('strips Exception prefix', () {
    final message = mapAuthErrorMessage('Exception: Something bad happened');
    expect(message, 'Something bad happened');
  });
}
