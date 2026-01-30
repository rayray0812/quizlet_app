import 'package:flutter/material.dart';
import 'package:quizlet_app/core/router/app_router.dart';
import 'package:quizlet_app/core/theme/app_theme.dart';

class QuizletApp extends StatelessWidget {
  const QuizletApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuizletApp',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
