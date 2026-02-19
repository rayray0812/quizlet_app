import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:recall_app/core/router/app_router.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/features/auth/widgets/app_auth_lifecycle_gate.dart';
import 'package:recall_app/providers/locale_provider.dart';
import 'package:recall_app/features/pomodoro/widgets/pomodoro_fab.dart';

class RecallApp extends ConsumerWidget {
  const RecallApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return AppAuthLifecycleGate(
          child: Stack(children: [child, const PomodoroFab()]),
        );
      },
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('zh', 'TW'), Locale('en', 'US')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
