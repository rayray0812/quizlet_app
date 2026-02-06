import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quizlet_app/core/router/app_router.dart';
import 'package:quizlet_app/core/theme/app_theme.dart';
import 'package:quizlet_app/core/l10n/app_localizations.dart';
import 'package:quizlet_app/core/constants/app_constants.dart';
import 'package:quizlet_app/providers/locale_provider.dart';
import 'package:quizlet_app/providers/theme_provider.dart';

class QuizletApp extends ConsumerWidget {
  const QuizletApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
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
