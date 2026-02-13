import 'package:flutter_test/flutter_test.dart';
import 'package:recall_app/core/constants/supabase_constants.dart';

void main() {
  test('authRedirectUrl defaults to mobile callback on non-web', () {
    expect(
      SupabaseConstants.authRedirectUrl,
      SupabaseConstants.mobileRedirectUrl,
    );
  });
}
