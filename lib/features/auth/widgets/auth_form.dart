import 'package:flutter/material.dart';
import 'package:recall_app/core/theme/app_theme.dart';
import 'package:recall_app/features/auth/utils/auth_error_mapper.dart';

class AuthForm extends StatefulWidget {
  final String buttonText;
  final Color buttonColor;
  final Future<void> Function(String email, String password) onSubmit;
  final String? secondaryActionText;
  final Future<void> Function(String email)? onSecondaryAction;

  const AuthForm({
    super.key,
    required this.buttonText,
    required this.onSubmit,
    this.buttonColor = AppTheme.indigo,
    this.secondaryActionText,
    this.onSecondaryAction,
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      setState(() => _error = mapAuthErrorMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _runSecondaryAction() async {
    final secondaryAction = widget.onSecondaryAction;
    if (secondaryAction == null) return;

    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await secondaryAction(email);
    } catch (e) {
      setState(() => _error = mapAuthErrorMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            obscureText: true,
            validator: (v) => v == null || v.length < 6
                ? 'Password must be at least 6 characters'
                : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: AppTheme.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.buttonColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.buttonText),
          ),
          if (widget.secondaryActionText != null &&
              widget.onSecondaryAction != null) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : _runSecondaryAction,
              child: Text(widget.secondaryActionText!),
            ),
          ],
        ],
      ),
    );
  }
}
