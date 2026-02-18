import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/widgets/adaptive_glass_card.dart';
import 'package:recall_app/features/auth/utils/auth_error_mapper.dart';
import 'package:recall_app/features/auth/widgets/auth_form.dart';
import 'package:recall_app/features/auth/widgets/social_auth_buttons.dart';
import 'package:recall_app/providers/auth_analytics_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';

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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -44,
            right: -30,
            child: _AuthGlow(
              size: 190,
              color: AppTheme.cyan.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 100,
            left: -36,
            child: _AuthGlow(
              size: 170,
              color: AppTheme.indigo.withValues(alpha: 0.1),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.26),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      size: 40,
                      color: AppTheme.indigo,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    AppConstants.appName,
                    style: GoogleFonts.notoSerifTc(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '歡迎回來，繼續你的學習節奏',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  AdaptiveGlassCard(
                    borderRadius: 20,
                    fillColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.58),
                    borderColor: Colors.white.withValues(alpha: 0.26),
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                    child: AuthForm(
                      buttonText: l10n.logIn,
                      buttonColor: AppTheme.indigo,
                      onSubmit: (email, password) async {
                        final supabase = ref.read(supabaseServiceProvider);
                        final analytics = ref.read(authAnalyticsServiceProvider);
                        try {
                          await supabase
                              .signIn(email: email, password: password)
                              .timeout(const Duration(seconds: 15));
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
                          final lower = e.toString().toLowerCase();
                          if (lower.contains('email not confirmed') &&
                              context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Email 尚未驗證，請到信箱點擊驗證連結。'),
                                action: SnackBarAction(
                                  label: '重寄',
                                  onPressed: () {
                                    supabase.resendSignupConfirmation(email);
                                  },
                                ),
                              ),
                            );
                          }
                          final msg = mapAuthErrorMessage(e.toString());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                          throw Exception(msg);
                        }
                      },
                      secondaryActionText: '使用 Magic Link',
                      onSecondaryAction: (email) async {
                        final supabase = ref.read(supabaseServiceProvider);
                        final analytics = ref.read(authAnalyticsServiceProvider);
                        try {
                          await supabase
                              .signInWithMagicLink(email)
                              .timeout(const Duration(seconds: 15));
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
                          final msg = mapAuthErrorMessage(e.toString());
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                          throw Exception(msg);
                        }
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Magic Link 已寄出，請到信箱確認。')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push(_withFrom('/forgot-password', from)),
                    child: const Text('忘記密碼？'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '或',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.push(_withFrom('/signup', from)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      l10n.noAccountSignUp,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: Text(
                      l10n.skipGuest,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.02),
              Colors.transparent,
            ],
            stops: const [0, 0.64, 1],
          ),
        ),
      ),
    );
  }
}
