String mapAuthErrorMessage(String rawError) {
  final lower = rawError.toLowerCase();

  if (lower.contains('invalid login') ||
      lower.contains('invalid email or password')) {
    return 'Invalid email or password.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Please verify your email before logging in.';
  }
  if (lower.contains('user already registered')) {
    return 'This email is already registered.';
  }
  if (lower.contains('network') || lower.contains('socketexception')) {
    return 'Network error. Please check your connection.';
  }
  if (lower.contains('failed host lookup') || lower.contains('failed host')) {
    return 'Cannot reach server (DNS lookup failed). Check network, VPN, or API host URL.';
  }
  if (lower.contains('timed out') || lower.contains('timeout')) {
    return 'Request timed out. Please try again.';
  }
  if (lower.contains('weak password')) {
    return 'Password is too weak. Use at least 6 characters.';
  }
  if (lower.contains('provider is not enabled')) {
    return 'This sign-in provider is not enabled yet.';
  }
  if (lower.contains('supabase is not configured') ||
      lower.contains('provide supabase_url') ||
      lower.contains('supabase is not defined')) {
    return 'Supabase is not configured for this build. Run with --dart-define (or --dart-define-from-file).';
  }
  if (lower.contains('cancelled') || lower.contains('canceled')) {
    return 'Sign-in was canceled.';
  }
  if (lower.startsWith('exception: ')) {
    return rawError.substring('Exception: '.length);
  }
  return rawError;
}
