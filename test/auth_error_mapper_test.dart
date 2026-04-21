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
    expect(
      message,
      '\u6B64\u767B\u5165\u65B9\u5F0F\u5C1A\u672A\u555F\u7528\u3002',
    );
  });

  test('strips Exception prefix', () {
    final message = mapAuthErrorMessage('Exception: Something bad happened');
    expect(message, 'Something bad happened');
  });

  test('maps supabase missing config/define error', () {
    final message = mapAuthErrorMessage(
      'ReferenceError: supabase is not defined',
    );
    expect(
      message,
      '\u76EE\u524D\u7248\u672C\u672A\u8A2D\u5B9A Supabase\uFF08\u9700\u8981 --dart-define \u6216 --dart-define-from-file\uFF09\u3002',
    );
  });

  test('maps failed host lookup before generic socket error', () {
    final message = mapAuthErrorMessage(
      'ClientException with SocketException: Failed host lookup: '
      'jijyptcixzievhdohzje.supabase.co',
    );
    expect(
      message,
      '\u7121\u6CD5\u9023\u5230\u4F3A\u670D\u5668\uFF08DNS \u89E3\u6790\u5931\u6557\uFF09\uFF0C\u8ACB\u6AA2\u67E5\u7DB2\u8DEF\u3001VPN \u6216 Supabase API \u7DB2\u5740\u8A2D\u5B9A\u3002',
    );
  });

  test('maps timeout separately from generic network error', () {
    final message = mapAuthErrorMessage(
      'TimeoutException after 0:00:15.000000',
    );
    expect(
      message,
      '\u767B\u5165\u903E\u6642\uFF0C\u8ACB\u78BA\u8A8D\u7DB2\u8DEF\u53EF\u9023\u7DDA\u5F8C\u518D\u8A66\u3002',
    );
  });

  test('maps generic network error', () {
    final message = mapAuthErrorMessage('Network request failed');
    expect(
      message,
      '\u7DB2\u8DEF\u7570\u5E38\uFF0C\u8ACB\u6AA2\u67E5\u9023\u7DDA\u5F8C\u518D\u8A66\u3002',
    );
  });
}
