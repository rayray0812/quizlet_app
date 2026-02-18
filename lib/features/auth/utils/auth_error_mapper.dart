String mapAuthErrorMessage(String rawError) {
  final lower = rawError.toLowerCase();

  if (lower.contains('invalid login') ||
      lower.contains('invalid email or password')) {
    return '帳號或密碼錯誤。';
  }
  if (lower.contains('email not confirmed')) {
    return '請先完成信箱驗證再登入。';
  }
  if (lower.contains('user already registered')) {
    return '這個信箱已經註冊過。';
  }
  if (lower.contains('network') || lower.contains('socketexception')) {
    return '網路異常，請檢查連線後再試。';
  }
  if (lower.contains('failed host lookup') || lower.contains('failed host')) {
    return '無法連到伺服器（DNS 解析失敗），請檢查網路、VPN 或 API 網址設定。';
  }
  if (lower.contains('timed out') || lower.contains('timeout')) {
    return '連線逾時，請稍後再試。';
  }
  if (lower.contains('weak password')) {
    return '密碼強度不足，至少需 6 個字元。';
  }
  if (lower.contains('provider is not enabled')) {
    return '此登入方式尚未啟用。';
  }
  if (lower.contains('supabase is not configured') ||
      lower.contains('provide supabase_url') ||
      lower.contains('supabase is not defined')) {
    return '目前版本未設定 Supabase（需要 --dart-define 或 --dart-define-from-file）。';
  }
  if (lower.contains('cancelled') || lower.contains('canceled')) {
    return '登入已取消。';
  }
  if (lower.startsWith('exception: ')) {
    return rawError.substring('Exception: '.length);
  }
  return rawError;
}
