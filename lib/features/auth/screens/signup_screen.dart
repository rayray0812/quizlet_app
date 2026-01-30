import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizlet_app/features/auth/widgets/auth_form.dart';
import 'package:quizlet_app/providers/auth_provider.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
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
              'Create Account',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AuthForm(
              buttonText: 'Sign Up',
              onSubmit: (email, password) async {
                final supabase = ref.read(supabaseServiceProvider);
                await supabase.signUp(email: email, password: password);
                if (context.mounted) context.go('/');
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Already have an account? Log In'),
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
