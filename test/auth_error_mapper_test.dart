import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/features/auth/utils/auth_error_mapper.dart';

void main() {
  test('maps invalid credentials error', () {
    final message = mapAuthErrorMessage(
      'AuthApiException: Invalid login credentials',
    );
    expect(message, '\u5E33\u865F\u6216\u5BC6\u78BC\u932F\u8AA4\u3002');
  });

  test('maps provider disabled error', () {
    final message = mapAuthErrorMessage('Provider is not enabled');
    expect(message, '\u6B64\u767B\u5165\u65B9\u5F0F\u5C1A\u672A\u555F\u7528\u3002');
  });

  test('strips Exception prefix', () {
    final message = mapAuthErrorMessage('Exception: Something bad happened');
    expect(message, 'Something bad happened');
  });

  test('maps supabase missing config/define error', () {
    final message = mapAuthErrorMessage('ReferenceError: supabase is not defined');
    expect(
      message,
      '\u76EE\u524D\u7248\u672C\u672A\u8A2D\u5B9A Supabase\uFF08\u9700\u8981 --dart-define \u6216 --dart-define-from-file\uFF09\u3002',
    );
  });
}
