import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:recall_app/services/supabase_service.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  if (!supabaseService.isAvailable) {
    return const Stream<AuthState>.empty();
  }
  return supabaseService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  // Recompute when auth state changes.
  ref.watch(authStateProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  return supabaseService.currentUser;
});
