import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/auth_analytics_provider.dart';
import 'package:recall_app/providers/biometric_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/providers/sync_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppAuthLifecycleGate extends ConsumerStatefulWidget {
  final Widget child;

  const AppAuthLifecycleGate({super.key, required this.child});

  @override
  ConsumerState<AppAuthLifecycleGate> createState() =>
      _AppAuthLifecycleGateState();
}

class _AppAuthLifecycleGateState extends ConsumerState<AppAuthLifecycleGate>
    with WidgetsBindingObserver {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  bool _lockOnResume = false;
  bool _sessionValidated = false;
  ProviderSubscription<AsyncValue<AuthState>>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _validateSessionAtLaunch();
    });
    _authStateSubscription = ref.listenManual<AsyncValue<AuthState>>(
      authStateProvider,
      (previous, next) {
        next.whenData((authState) {
          if (authState.event == AuthChangeEvent.signedOut) {
            Future<void>(() {
              if (!mounted) return;
              ref.read(studySetsProvider.notifier).refresh();
              setState(() {
                _isLocked = false;
                _lockOnResume = false;
              });
            });
            return;
          }

          if (authState.event == AuthChangeEvent.initialSession ||
              authState.event == AuthChangeEvent.signedIn ||
              authState.event == AuthChangeEvent.tokenRefreshed ||
              authState.event == AuthChangeEvent.userUpdated) {
            Future<void>(() {
              if (!mounted) return;
              ref.invalidate(syncProvider);
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _validateSessionAtLaunch() async {
    if (_sessionValidated) return;
    _sessionValidated = true;
    final supabase = ref.read(supabaseServiceProvider);
    final valid = await supabase.validateAndRestoreSession();
    if (!mounted) return;
    if (valid) {
      Future<void>(() {
        if (!mounted) return;
        ref.invalidate(syncProvider);
      });
    } else {
      Future<void>(() {
        if (!mounted) return;
        ref.read(studySetsProvider.notifier).refresh();
      });
    }
  }

  Future<void> _tryBiometricUnlock() async {
    if (!mounted || _isAuthenticating) return;
    final enabled = ref.read(biometricQuickUnlockProvider);
    final user = ref.read(currentUserProvider);
    if (!enabled || user == null || !_lockOnResume) return;

    final biometricService = ref.read(biometricServiceProvider);
    final available = await biometricService.isBiometricAvailable();
    if (!mounted || !available) return;

    setState(() {
      _isLocked = true;
      _isAuthenticating = true;
    });

    final success = await biometricService.authenticateForUnlock();
    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
      if (success) {
        _isLocked = false;
        _lockOnResume = false;
      } else {
        _isLocked = true;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _lockOnResume = true;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      unawaited(_tryBiometricUnlock());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLocked) return widget.child;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ColoredBox(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_rounded, size: 44),
                    const SizedBox(height: 12),
                    const Text(
                      'Biometric Unlock Required',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Authenticate to continue with your signed-in account.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAuthenticating
                            ? null
                            : _tryBiometricUnlock,
                        icon: _isAuthenticating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fingerprint_rounded),
                        label: Text(
                          _isAuthenticating ? 'Unlocking...' : 'Unlock',
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isAuthenticating
                            ? null
                            : () async {
                                await ref
                                    .read(authAnalyticsServiceProvider)
                                    .logAuthEvent(
                                      action: 'sign_out',
                                      provider: 'session',
                                      result: 'local',
                                    );
                                await ref
                                    .read(supabaseServiceProvider)
                                    .signOut();
                              },
                        child: const Text('Sign Out'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
