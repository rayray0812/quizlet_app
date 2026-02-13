import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    child: MaterialApp.router(routerConfig: router),
  );
}

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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'ray@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'magic@example.com',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Send Magic Link'));
    await tester.pumpAndSettle();

    expect(fakeSupabase.magicLinkEmail, 'magic@example.com');
    expect(
      find.text('Magic link sent. Check your email to sign in quickly.'),
      findsOneWidget,
    );
  });

  testWidgets('google oauth button triggers provider sign in', (tester) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(fakeSupabase: fakeSupabase, initialLocation: '/login'),
    );

    final googleButton = find.text('Continue with Google');
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

    final guestButton = find.text('Skip / Continue as Guest');
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

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'new@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();

    expect(fakeSupabase.signUpEmail, 'new@example.com');
    expect(fakeSupabase.signUpPassword, 'password123');
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('logout button signs out and returns to login', (tester) async {
    final fakeSupabase = _FakeSupabaseService();
    await tester.pumpWidget(
      _buildTestApp(fakeSupabase: fakeSupabase, initialLocation: '/home'),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(fakeSupabase.signOutCalls, 1);
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
