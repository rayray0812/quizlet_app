import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recall_app/core/l10n/app_localizations.dart';
import 'package:recall_app/features/auth/screens/login_screen.dart';
import 'package:recall_app/features/auth/screens/signup_screen.dart';
import 'package:recall_app/providers/auth_analytics_provider.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/services/auth_analytics_service.dart';
import 'package:recall_app/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseService extends SupabaseService {
  String? signInEmail;
  String? signInPassword;
  String? signUpEmail;
  String? signUpPassword;
  String? magicLinkEmail;
  int googleCalls = 0;
  int signOutCalls = 0;

  bool signInWithGoogleResult = true;
  bool signUpWithSession = false;

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    signInEmail = email;
    signInPassword = password;
    return AuthResponse();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    signUpEmail = email;
    signUpPassword = password;
    return AuthResponse(
      session: signUpWithSession ? Session.fromJson({}) : null,
    );
  }

  @override
  Future<void> signInWithMagicLink(String email) async {
    magicLinkEmail = email;
  }

  @override
  Future<bool> signInWithGoogle() async {
    googleCalls += 1;
    return signInWithGoogleResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  @override
  Stream<AuthState> get authStateChanges => const Stream<AuthState>.empty();
}

class _NoopAuthAnalyticsService extends AuthAnalyticsService {
  @override
  Future<void> logAuthEvent({
    required String action,
    required String provider,
    required String result,
    String note = '',
  }) async {}
}

class _LogoutScreen extends ConsumerWidget {
  const _LogoutScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ref.read(supabaseServiceProvider).signOut();
            if (context.mounted) context.go('/login');
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}

Widget _buildTestApp({
  required _FakeSupabaseService fakeSupabase,
  required String initialLocation,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('Guest Home'))),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const _LogoutScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      supabaseServiceProvider.overrideWithValue(fakeSupabase),
      authAnalyticsServiceProvider.overrideWithValue(
        _NoopAuthAnalyticsService(),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh')],
      locale: const Locale('zh'),
    ),
  );
}

// Chinese l10n strings used by the auth UI
const _email = '\u96FB\u5B50\u4FE1\u7BB1'; // 電子信箱
const _password = '\u5BC6\u78BC'; // 密碼
const _logIn = '\u767B\u5165'; // 登入
const _signUp = '\u8A3B\u518A'; // 註冊
const _appDisplayName = '\u62FE\u61B6'; // 拾憶
const _skipGuest = '\u7565\u904E / \u8A2A\u5BA2\u6A21\u5F0F'; // 略過 / 訪客模式
const _magicLink = '\u4F7F\u7528 Magic Link'; // 使用 Magic Link
const _magicLinkSent = 'Magic Link \u5DF2\u5BC4\u51FA\uFF0C\u8ACB\u5230\u4FE1\u7BB1\u78BA\u8A8D\u3002';
const _googleBtn = '\u4F7F\u7528 Google \u767B\u5165'; // 使用 Google 登入

void main() {
  testWidgets('login submits credentials and redirects to from route', (
    tester,
  ) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(
        fakeSupabase: fakeSupabase,
        initialLocation: '/login?from=%2Fhome',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, _email),
      'ray@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, _password),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, _logIn));
    await tester.pumpAndSettle();

    expect(fakeSupabase.signInEmail, 'ray@example.com');
    expect(fakeSupabase.signInPassword, 'password123');
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('magic link action sends email', (tester) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(fakeSupabase: fakeSupabase, initialLocation: '/login'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, _email),
      'magic@example.com',
    );
    await tester.tap(find.widgetWithText(TextButton, _magicLink));
    await tester.pumpAndSettle();

    expect(fakeSupabase.magicLinkEmail, 'magic@example.com');
    expect(find.text(_magicLinkSent), findsOneWidget);
  });

  testWidgets('google oauth button triggers provider sign in', (tester) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(fakeSupabase: fakeSupabase, initialLocation: '/login'),
    );
    await tester.pumpAndSettle();

    final googleButton = find.text(_googleBtn);
    await tester.ensureVisible(googleButton);
    await tester.tap(googleButton);
    await tester.pumpAndSettle();

    expect(fakeSupabase.googleCalls, 1);
  });

  testWidgets('guest button navigates to guest home', (tester) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(fakeSupabase: fakeSupabase, initialLocation: '/login'),
    );
    await tester.pumpAndSettle();

    final guestButton = find.text(_skipGuest);
    await tester.ensureVisible(guestButton);
    await tester.tap(guestButton);
    await tester.pumpAndSettle();

    expect(find.text('Guest Home'), findsOneWidget);
  });

  testWidgets('signup without session redirects to login', (tester) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(fakeSupabase: fakeSupabase, initialLocation: '/signup'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, _email),
      'new@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, _password),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, _signUp));
    await tester.pumpAndSettle();

    expect(fakeSupabase.signUpEmail, 'new@example.com');
    expect(fakeSupabase.signUpPassword, 'password123');
    expect(find.text(_appDisplayName), findsOneWidget);
  });

  testWidgets('logout button signs out and returns to login', (tester) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(fakeSupabase: fakeSupabase, initialLocation: '/home'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(fakeSupabase.signOutCalls, 1);
    expect(find.text(_appDisplayName), findsOneWidget);
  });
}
