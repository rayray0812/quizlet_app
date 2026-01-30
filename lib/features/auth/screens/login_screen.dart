import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/features/auth/widgets/auth_form.dart';
import 'package:quizlet_app/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.school,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome Back',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AuthForm(
              buttonText: 'Log In',
              onSubmit: (email, password) async {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.signIn(email: email, password: password);
                if (context.mounted) context.go('/');
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text("Don't have an account? Sign Up"),
            ),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Skip / Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}
