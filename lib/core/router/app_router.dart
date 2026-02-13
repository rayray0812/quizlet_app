import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/features/auth/screens/forgot_password_screen.dart';
import 'package:recall_app/features/auth/screens/login_screen.dart';
import 'package:recall_app/features/auth/screens/signup_screen.dart';
import 'package:recall_app/features/admin/screens/admin_management_screen.dart';
import 'package:recall_app/features/home/screens/home_screen.dart';
import 'package:recall_app/features/home/screens/card_editor_screen.dart';
import 'package:recall_app/features/import/screens/web_import_screen.dart';
import 'package:recall_app/features/import/screens/review_import_screen.dart';
import 'package:recall_app/features/import/screens/photo_import_screen.dart';
import 'package:recall_app/features/study/screens/study_mode_picker_screen.dart';
import 'package:recall_app/features/study/screens/flashcard_screen.dart';
import 'package:recall_app/features/study/screens/quiz_screen.dart';
import 'package:recall_app/features/study/screens/matching_game_screen.dart';
import 'package:recall_app/features/study/screens/srs_review_screen.dart';
import 'package:recall_app/features/study/screens/review_summary_screen.dart';
import 'package:recall_app/features/study/screens/speaking_practice_screen.dart';
import 'package:recall_app/features/stats/screens/stats_screen.dart';
import 'package:recall_app/features/home/screens/search_screen.dart';
import 'package:recall_app/features/study/screens/custom_study_screen.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/services/supabase_service.dart';

StudySet? extractStudySetExtra(Object? extra) {
  return extra is StudySet ? extra : null;
}

Map<String, dynamic> extractMapExtra(Object? extra) {
  return extra is Map<String, dynamic> ? extra : const <String, dynamic>{};
}

int? extractOptionalIntExtra(Object? extra, String key) {
  final data = extractMapExtra(extra);
  final value = data[key];
  return value is int ? value : null;
}

const Set<String> _publicRoutePaths = {
  '/',
  '/login',
  '/signup',
  '/forgot-password',
};

bool isAuthRoutePath(String path) {
  return path == '/login' || path == '/signup' || path == '/forgot-password';
}

bool isProtectedRoutePath(String path) {
  return !_publicRoutePaths.contains(path);
}

String? normalizePostAuthRedirect(String? from) {
  if (from == null || from.isEmpty) return null;
  final uri = Uri.tryParse(from);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return null;
  if (!uri.path.startsWith('/')) return null;
  if (isAuthRoutePath(uri.path)) return '/';
  return uri.toString();
}

String? resolveAppRedirect({
  required bool isAuthenticated,
  required String matchedLocation,
  required Uri currentUri,
}) {
  if (!isAuthenticated && isProtectedRoutePath(matchedLocation)) {
    return Uri(
      path: '/login',
      queryParameters: {'from': currentUri.toString()},
    ).toString();
  }

  if (isAuthenticated && isAuthRoutePath(matchedLocation)) {
    return normalizePostAuthRedirect(currentUri.queryParameters['from']) ?? '/';
  }

  return null;
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createAppRouter({
  required SupabaseService supabaseService,
  required Listenable refreshListenable,
}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) async {
      final isAuthenticated = supabaseService.currentUser != null;
      final baseRedirect = resolveAppRedirect(
        isAuthenticated: isAuthenticated,
        matchedLocation: state.matchedLocation,
        currentUri: state.uri,
      );
      if (baseRedirect != null) return baseRedirect;

      if (state.matchedLocation == '/admin') {
        final isAdmin = await supabaseService.isCurrentUserAdmin();
        if (!isAdmin) return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const WebImportScreen(),
      ),
      GoRoute(
        path: '/import/review',
        builder: (context, state) {
          final studySet = extractStudySetExtra(state.extra);
          if (studySet == null) {
            return const HomeScreen();
          }
          return ReviewImportScreen(studySet: studySet);
        },
      ),
      GoRoute(
        path: '/import/photo',
        builder: (context, state) => const PhotoImportScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) {
          final extra = state.extra;
          final tags = extra is Map<String, dynamic>
              ? (extra['tags'] as List<dynamic>?)?.cast<String>()
              : null;
          return SrsReviewScreen(filterTags: tags);
        },
      ),
      GoRoute(
        path: '/review/summary',
        builder: (context, state) {
          final data = extractMapExtra(state.extra);
          return ReviewSummaryScreen(
            totalReviewed: data['totalReviewed'] as int? ?? 0,
            againCount: data['againCount'] as int? ?? 0,
            hardCount: data['hardCount'] as int? ?? 0,
            goodCount: data['goodCount'] as int? ?? 0,
            easyCount: data['easyCount'] as int? ?? 0,
          );
        },
      ),
      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminManagementScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/study/custom',
        builder: (context, state) => const CustomStudyScreen(),
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
            path: 'srs',
            builder: (context, state) {
              final setId = state.pathParameters['setId']!;
              return SrsReviewScreen(setId: setId);
            },
          ),
          GoRoute(
            path: 'flashcards',
            builder: (context, state) {
              final setId = state.pathParameters['setId']!;
              return FlashcardScreen(setId: setId);
            },
          ),
          GoRoute(
            path: 'speaking',
            builder: (context, state) {
              final setId = state.pathParameters['setId']!;
              return SpeakingPracticeScreen(setId: setId);
            },
          ),
          GoRoute(
            path: 'quiz',
            builder: (context, state) {
              final setId = state.pathParameters['setId']!;
              final questionCount = extractOptionalIntExtra(
                state.extra,
                'questionCount',
              );
              return QuizScreen(setId: setId, questionCount: questionCount);
            },
          ),
          GoRoute(
            path: 'match',
            builder: (context, state) {
              final setId = state.pathParameters['setId']!;
              final pairCount = extractOptionalIntExtra(
                state.extra,
                'pairCount',
              );
              return MatchingGameScreen(setId: setId, pairCount: pairCount);
            },
          ),
        ],
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final refreshListenable = GoRouterRefreshStream(
    supabaseService.authStateChanges,
  );
  ref.onDispose(refreshListenable.dispose);

  final router = createAppRouter(
    supabaseService: supabaseService,
    refreshListenable: refreshListenable,
  );
  ref.onDispose(router.dispose);
  return router;
});
