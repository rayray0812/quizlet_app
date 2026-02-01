import 'package:go_router/go_router.dart';
import 'package:quizlet_app/features/auth/screens/login_screen.dart';
import 'package:quizlet_app/features/auth/screens/signup_screen.dart';
import 'package:quizlet_app/features/home/screens/home_screen.dart';
import 'package:quizlet_app/features/home/screens/card_editor_screen.dart';
import 'package:quizlet_app/features/import/screens/web_import_screen.dart';
import 'package:quizlet_app/features/import/screens/review_import_screen.dart';
import 'package:quizlet_app/features/study/screens/study_mode_picker_screen.dart';
import 'package:quizlet_app/features/study/screens/flashcard_screen.dart';
import 'package:quizlet_app/features/study/screens/quiz_screen.dart';
import 'package:quizlet_app/features/study/screens/matching_game_screen.dart';
import 'package:quizlet_app/models/study_set.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/import',
      builder: (context, state) => const WebImportScreen(),
    ),
    GoRoute(
      path: '/import/review',
      builder: (context, state) {
        final studySet = state.extra as StudySet;
        return ReviewImportScreen(studySet: studySet);
      },
    ),
    GoRoute(
      path: '/edit/:setId',
      builder: (context, state) {
        final setId = state.pathParameters['setId']!;
        return CardEditorScreen(setId: setId);
      },
    ),
    GoRoute(
      path: '/study/:setId',
      builder: (context, state) {
        final setId = state.pathParameters['setId']!;
        return StudyModePickerScreen(setId: setId);
      },
      routes: [
        GoRoute(
          path: 'flashcards',
          builder: (context, state) {
            final setId = state.pathParameters['setId']!;
            return FlashcardScreen(setId: setId);
          },
        ),
        GoRoute(
          path: 'quiz',
          builder: (context, state) {
            final setId = state.pathParameters['setId']!;
            final extra = state.extra as Map<String, dynamic>?;
            final questionCount = extra?['questionCount'] as int?;
            return QuizScreen(setId: setId, questionCount: questionCount);
          },
        ),
        GoRoute(
          path: 'match',
          builder: (context, state) {
            final setId = state.pathParameters['setId']!;
            final extra = state.extra as Map<String, dynamic>?;
            final pairCount = extra?['pairCount'] as int?;
            return MatchingGameScreen(setId: setId, pairCount: pairCount);
          },
        ),
      ],
    ),
  ],
);
