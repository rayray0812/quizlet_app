import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:recall_app/features/auth/utils/auth_error_mapper.dart';
import 'package:recall_app/services/auth_analytics_service.dart';
import 'package:recall_app/services/supabase_service.dart';

bool isOAuthCancelError(String rawError) {
  final lower = rawError.toLowerCase();
  return lower.contains('cancel') ||
      lower.contains('access_denied') ||
      lower.contains('popup_closed') ||
      lower.contains('user closed');
}

String buildOAuthRetryMessage({
  required String providerName,
  required String? rawError,
  required bool canceledByResult,
}) {
  final canceled =
      canceledByResult ||
      (rawError != null && rawError.isNotEmpty && isOAuthCancelError(rawError));
  if (canceled) return '$providerName sign-in was canceled.';
  if (rawError == null || rawError.isEmpty) {
    return '$providerName sign-in failed. Please try again.';
  }
  return mapAuthErrorMessage(rawError);
}

class SocialAuthButtons extends StatefulWidget {
  final SupabaseService supabase;
  final AuthAnalyticsService analytics;

  const SocialAuthButtons({
    super.key,
    required this.supabase,
    required this.analytics,
  });

  @override
  State<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends State<SocialAuthButtons> {
  bool _googleLoading = false;
  bool _appleLoading = false;

  bool get _showApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  void _showRetrySnackBar({
    required String providerName,
    required Future<void> Function() onRetry,
    String? rawError,
    bool canceledByResult = false,
  }) {
    final message = buildOAuthRetryMessage(
      providerName: providerName,
      rawError: rawError,
      canceledByResult: canceledByResult,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Retry', onPressed: () => onRetry()),
      ),
    );
  }

  Future<void> _signInGoogle() async {
    setState(() => _googleLoading = true);
    try {
      final launched = await widget.supabase.signInWithGoogle();
      if (!mounted) return;
      if (!launched) {
        await widget.analytics.logAuthEvent(
          action: 'sign_in',
          provider: 'google',
          result: 'canceled',
        );
        _showRetrySnackBar(
          providerName: 'Google',
          onRetry: _signInGoogle,
          canceledByResult: true,
        );
      } else {
        await widget.analytics.logAuthEvent(
          action: 'sign_in',
          provider: 'google',
          result: 'redirect_started',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await widget.analytics.logAuthEvent(
        action: 'sign_in',
        provider: 'google',
        result: 'failure',
        note: e.toString(),
      );
      _showRetrySnackBar(
        providerName: 'Google',
        onRetry: _signInGoogle,
        rawError: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  Future<void> _signInApple() async {
    setState(() => _appleLoading = true);
    try {
      final launched = await widget.supabase.signInWithApple();
      if (!mounted) return;
      if (!launched) {
        await widget.analytics.logAuthEvent(
          action: 'sign_in',
          provider: 'apple',
          result: 'canceled',
        );
        _showRetrySnackBar(
          providerName: 'Apple',
          onRetry: _signInApple,
          canceledByResult: true,
        );
      } else {
        await widget.analytics.logAuthEvent(
          action: 'sign_in',
          provider: 'apple',
          result: 'redirect_started',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await widget.analytics.logAuthEvent(
        action: 'sign_in',
        provider: 'apple',
        result: 'failure',
        note: e.toString(),
      );
      _showRetrySnackBar(
        providerName: 'Apple',
        onRetry: _signInApple,
        rawError: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _googleLoading ? null : _signInGoogle,
          icon: _googleLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.g_mobiledata_rounded, size: 28),
          label: const Text('Continue with Google'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_showApple) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _appleLoading ? null : _signInApple,
            icon: _appleLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.apple_rounded),
            label: const Text('Continue with Apple'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}
