import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/features/auth/utils/auth_error_mapper.dart';
import 'package:recall_app/features/auth/widgets/auth_form.dart';
import 'package:recall_app/features/auth/widgets/social_auth_buttons.dart';
import 'package:recall_app/providers/auth_analytics_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/theme/app_theme.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

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
                  color: AppTheme.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  size: 40,
                  color: AppTheme.purple,
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
                'Create Account',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              AuthForm(
                buttonText: 'Sign Up',
                buttonColor: AppTheme.purple,
                onSubmit: (email, password) async {
                  final supabase = ref.read(supabaseServiceProvider);
                  final analytics = ref.read(authAnalyticsServiceProvider);
                  try {
                    final response = await supabase.signUp(
                      email: email,
                      password: password,
                    );
                    if (!context.mounted) return;

                    if (response.session == null) {
                      await analytics.logAuthEvent(
                        action: 'sign_up',
                        provider: 'email',
                        result: 'verification_required',
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Account created. Please verify your email before login.',
                          ),
                          action: SnackBarAction(
                            label: 'Resend',
                            onPressed: () {
                              supabase.resendSignupConfirmation(email);
                            },
                          ),
                        ),
                      );
                      context.go(_withFrom('/login', from));
                      return;
                    }
                    await analytics.logAuthEvent(
                      action: 'sign_up',
                      provider: 'email',
                      result: 'success',
                    );
                    if (!context.mounted) return;
                    context.go(_postAuthPath(from));
                  } catch (e) {
                    await analytics.logAuthEvent(
                      action: 'sign_up',
                      provider: 'email',
                      result: 'failure',
                      note: e.toString(),
                    );
                    final msg = mapAuthErrorMessage(e.toString());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(msg)),
                      );
                    }
                    throw Exception(msg);
                  }
                },
              ),
              const SizedBox(height: 16),
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
                onPressed: () => context.push(_withFrom('/login', from)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Already have an account? Log In',
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
