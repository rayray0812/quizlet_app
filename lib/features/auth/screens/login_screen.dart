import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/features/auth/widgets/auth_form.dart';
import 'package:recall_app/features/auth/widgets/social_auth_buttons.dart';
import 'package:recall_app/providers/auth_analytics_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  String _withFrom(String path, String? from) {
    if (from == null || from.isEmpty) return path;
    return Uri(path: path, queryParameters: {'from': from}).toString();
  }

  String _postAuthPath(String? from) {
    if (from == null || from.isEmpty) return '/';
    return from;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final from = GoRouterState.of(context).uri.queryParameters['from'];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 56),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.indigo.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 40,
                  color: AppTheme.indigo,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.indigo,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome Back',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              AuthForm(
                buttonText: 'Log In',
                buttonColor: AppTheme.indigo,
                onSubmit: (email, password) async {
                  final supabase = ref.read(supabaseServiceProvider);
                  final analytics = ref.read(authAnalyticsServiceProvider);
                  try {
                    await supabase.signIn(email: email, password: password);
                    await analytics.logAuthEvent(
                      action: 'sign_in',
                      provider: 'email',
                      result: 'success',
                    );
                    if (context.mounted) context.go(_postAuthPath(from));
                  } catch (e) {
                    await analytics.logAuthEvent(
                      action: 'sign_in',
                      provider: 'email',
                      result: 'failure',
                      note: e.toString(),
                    );
                    rethrow;
                  }
                },
                secondaryActionText: 'Send Magic Link',
                onSecondaryAction: (email) async {
                  final supabase = ref.read(supabaseServiceProvider);
                  final analytics = ref.read(authAnalyticsServiceProvider);
                  try {
                    await supabase.signInWithMagicLink(email);
                    await analytics.logAuthEvent(
                      action: 'magic_link',
                      provider: 'email',
                      result: 'sent',
                    );
                  } catch (e) {
                    await analytics.logAuthEvent(
                      action: 'magic_link',
                      provider: 'email',
                      result: 'failure',
                      note: e.toString(),
                    );
                    rethrow;
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Magic link sent. Check your email to sign in quickly.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () =>
                    context.push(_withFrom('/forgot-password', from)),
                child: const Text('Forgot password?'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),
              SocialAuthButtons(
                supabase: ref.read(supabaseServiceProvider),
                analytics: ref.read(authAnalyticsServiceProvider),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => context.push(_withFrom('/signup', from)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(
                  'Skip / Continue as Guest',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
