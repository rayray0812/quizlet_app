import 'package:flutter/foundation.dart';
import 'package:recall_app/core/constants/supabase_constants.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/models/flashcard.dart';
import 'package:recall_app/models/review_log.dart';
import 'package:recall_app/models/folder.dart';
import 'package:recall_app/models/study_set.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseClient? get _clientOrNull {
    if (!SupabaseConstants.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient? get clientOrNull => _clientOrNull;

  bool get isAvailable => _clientOrNull != null;

  // Auth
  User? get currentUser => _clientOrNull?.auth.currentUser;

  Stream<AuthState> get authStateChanges =>
      _clientOrNull?.auth.onAuthStateChange ?? const Stream<AuthState>.empty();

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return await client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    final client = _clientOrNull;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      // Network/DNS failures (e.g., failed host lookup) should not crash logout flow.
      debugPrint('Supabase signOut failed: $e');
    }
  }

  Future<void> signOutAllSessions() async {
    final client = _clientOrNull;
    if (client == null) return;
    try {
      await client.auth.signOut(scope: SignOutScope.global);
    } catch (_) {
      // Keep local UX responsive even when remote revoke cannot be reached.
    }
  }

  /// Matches SQL `is_global_admin()`: only super_admin / org_admin with global scope.
  Future<bool> isCurrentUserAdmin() async {
    final client = _clientOrNull;
    final user = currentUser;
    if (client == null || user == null) {
      debugPrint('[Admin] client=$client user=$user → false (null)');
      return false;
    }
    try {
      final rpcResult = await client.rpc(
        'is_global_admin',
        params: {'uid': user.id},
      );
      debugPrint('[Admin] RPC is_global_admin returned: $rpcResult (${rpcResult.runtimeType})');
      if (rpcResult is bool) return rpcResult;
      if (rpcResult is num) return rpcResult != 0;
      if (rpcResult is String) {
        final value = rpcResult.trim().toLowerCase();
        if (value == 'true' || value == 't' || value == '1') return true;
        if (value == 'false' || value == 'f' || value == '0') return false;
      }
      debugPrint('[Admin] RPC returned unhandled type, falling through');
    } catch (e) {
      debugPrint('[Admin] RPC failed: $e — trying table query');
    }
    try {
      final rows = await client
          .from(SupabaseConstants.adminRoleBindingsTable)
          .select('id')
          .eq('admin_user_id', user.id)
          .eq('scope_type', 'global')
          .inFilter('role_key', ['super_admin', 'org_admin'])
          .limit(1);
      final result = (rows as List).isNotEmpty;
      debugPrint('[Admin] Table query rows=$rows → $result');
      return result;
    } catch (e) {
      debugPrint('[Admin] Table query failed: $e → false');
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    final client = _requireClient();
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConstants.authRedirectUrl,
    );
  }

  Future<bool> signInWithApple() async {
    final client = _requireClient();
    return await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: SupabaseConstants.authRedirectUrl,
    );
  }

  Future<void> signInWithMagicLink(String email) async {
    final client = _requireClient();
    await client.auth.signInWithOtp(
      email: email,
      emailRedirectTo: SupabaseConstants.authRedirectUrl,
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    final client = _requireClient();
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> resendSignupConfirmation(String email) async {
    final client = _requireClient();
    await client.auth.resend(
      email: email,
      type: OtpType.signup,
      emailRedirectTo: SupabaseConstants.authRedirectUrl,
    );
  }

  /// Try to fully delete current user account via RPC `delete_my_account`.
  /// If RPC is unavailable, it falls back to deleting user-owned app data.
  /// Returns true when auth identity is fully deleted, false when only data is deleted.
  Future<bool> deleteCurrentAccount({String? passwordForReauth}) async {
    final client = _requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }

    final password = passwordForReauth?.trim() ?? '';
    if (password.isNotEmpty && (user.email ?? '').isNotEmpty) {
      await client.auth.signInWithPassword(
        email: user.email!,
        password: password,
      );
    }

    try {
      await client.rpc('delete_my_account');
      return true;
    } catch (_) {
      final userId = user.id;
      await client
          .from(SupabaseConstants.reviewLogsTable)
          .delete()
          .eq('user_id', userId);
      await client
          .from(SupabaseConstants.cardProgressTable)
          .delete()
          .eq('user_id', userId);
      await client
          .from(SupabaseConstants.studySetsTable)
          .delete()
          .eq('user_id', userId);
      return false;
    } finally {
      await client.auth.signOut(scope: SignOutScope.global);
    }
  }

  /// Validate the restored session against Supabase.
  /// Returns true if current session is still valid.
  Future<bool> validateAndRestoreSession() async {
    final client = _clientOrNull;
    if (client == null) return false;

    final session = client.auth.currentSession;
    if (session == null) return false;

    try {
      await client.auth.getUser();
      return client.auth.currentUser != null;
    } catch (_) {
      try {
        await client.auth.signOut();
      } catch (_) {}
      return false;
    }
  }

  // Data
  Future<void> upsertStudySet(StudySet studySet) async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    await client.from(SupabaseConstants.studySetsTable).upsert({
      'id': studySet.id,
      'user_id': userId,
      'title': studySet.title,
      'description': studySet.description,
      'cards': studySet.cards.map((c) => c.toJson()).toList(),
      'created_at': studySet.createdAt.toIso8601String(),
      'updated_at': (studySet.updatedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
      'folder_id': studySet.folderId,
    });
  }

  // Folders
  Future<void> upsertFolder(Folder folder) async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    await client.from(SupabaseConstants.foldersTable).upsert({
      'id': folder.id,
      'user_id': userId,
      'name': folder.name,
      'color_hex': folder.colorHex,
      'icon_code_point': folder.iconCodePoint,
      'created_at': folder.createdAt.toIso8601String(),
      'updated_at': (folder.updatedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
    });
  }

  Future<List<Folder>> fetchFolders() async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.foldersTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map(_rowToFolder).toList();
  }

  Future<List<({String id, DateTime updatedAt})>> fetchFolderManifest() async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.foldersTable)
        .select('id, updated_at')
        .eq('user_id', userId);

    return (response as List).map((row) {
      return (
        id: row['id'] as String,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
    }).toList();
  }

  Future<List<Folder>> fetchFoldersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.foldersTable)
        .select()
        .eq('user_id', userId)
        .inFilter('id', ids);

    return (response as List).map(_rowToFolder).toList();
  }

  Future<void> deleteFolderById(String folderId) async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    await client
        .from(SupabaseConstants.foldersTable)
        .delete()
        .eq('user_id', userId)
        .eq('id', folderId);
  }

  Folder _rowToFolder(dynamic row) {
    return Folder(
      id: row['id'] as String,
      name: row['name'] as String,
      colorHex: row['color_hex'] as String,
      iconCodePoint: row['icon_code_point'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      isSynced: true,
    );
  }

  Future<void> deleteStudySetById(String setId) async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    await client
        .from(SupabaseConstants.studySetsTable)
        .delete()
        .eq('user_id', userId)
        .eq('id', setId);
  }

  Future<void> upsertCardProgress(List<CardProgress> progresses) async {
    if (progresses.isEmpty) return;

    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    final rows = progresses
        .map(
          (p) => {
            'card_id': p.cardId,
            'set_id': p.setId,
            'user_id': userId,
            'stability': p.stability,
            'difficulty': p.difficulty,
            'reps': p.reps,
            'lapses': p.lapses,
            'state': p.state,
            'last_review': p.lastReview?.toIso8601String(),
            'due': p.due?.toIso8601String(),
            'scheduled_days': p.scheduledDays,
            'elapsed_days': p.elapsedDays,
          },
        )
        .toList();

    await client.from(SupabaseConstants.cardProgressTable).upsert(rows);
  }

  Future<void> upsertReviewLogs(List<ReviewLog> logs) async {
    if (logs.isEmpty) return;

    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    final rows = logs
        .map(
          (log) => {
            'id': log.id,
            'card_id': log.cardId,
            'set_id': log.setId,
            'user_id': userId,
            'rating': log.rating,
            'state': log.state,
            'reviewed_at': log.reviewedAt.toIso8601String(),
            'elapsed_days': log.elapsedDays,
            'scheduled_days': log.scheduledDays,
            'last_stability': log.lastStability,
            'last_difficulty': log.lastDifficulty,
          },
        )
        .toList();

    await client.from(SupabaseConstants.reviewLogsTable).upsert(rows);
  }

  Future<List<StudySet>> fetchStudySets() async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.studySetsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map(_rowToStudySet).toList();
  }

  /// Fetch only id + updated_at for delta comparison (lightweight).
  Future<List<({String id, DateTime updatedAt})>>
  fetchStudySetManifest() async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.studySetsTable)
        .select('id, updated_at')
        .eq('user_id', userId);

    return (response as List).map((row) {
      return (
        id: row['id'] as String,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
    }).toList();
  }

  /// Fetch full data for specific set IDs only.
  Future<List<StudySet>> fetchStudySetsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.studySetsTable)
        .select()
        .eq('user_id', userId)
        .inFilter('id', ids);

    return (response as List).map(_rowToStudySet).toList();
  }

  Future<List<CardProgress>> fetchCardProgressBySetIds(
    List<String> setIds,
  ) async {
    if (setIds.isEmpty) return [];

    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.cardProgressTable)
        .select()
        .eq('user_id', userId)
        .inFilter('set_id', setIds);

    return (response as List).map(_rowToCardProgress).toList();
  }

  Future<List<ReviewLog>> fetchReviewLogsBySetIds(List<String> setIds) async {
    if (setIds.isEmpty) return [];

    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return [];

    final response = await client
        .from(SupabaseConstants.reviewLogsTable)
        .select()
        .eq('user_id', userId)
        .inFilter('set_id', setIds);

    return (response as List).map(_rowToReviewLog).toList();
  }

  StudySet _rowToStudySet(dynamic row) {
    final cardsJson = (row['cards'] as List?) ?? [];
    return StudySet(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      cards: cardsJson
          .map((c) => Flashcard.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      isSynced: true,
    );
  }

  CardProgress _rowToCardProgress(dynamic row) {
    return CardProgress(
      cardId: row['card_id'] as String,
      setId: row['set_id'] as String,
      stability: (row['stability'] as num?)?.toDouble() ?? 0.0,
      difficulty: (row['difficulty'] as num?)?.toDouble() ?? 0.0,
      reps: row['reps'] as int? ?? 0,
      lapses: row['lapses'] as int? ?? 0,
      state: row['state'] as int? ?? 0,
      lastReview: row['last_review'] != null
          ? DateTime.parse(row['last_review'] as String)
          : null,
      due: row['due'] != null ? DateTime.parse(row['due'] as String) : null,
      scheduledDays: row['scheduled_days'] as int? ?? 0,
      elapsedDays: row['elapsed_days'] as int? ?? 0,
      isSynced: true,
    );
  }

  ReviewLog _rowToReviewLog(dynamic row) {
    return ReviewLog(
      id: row['id'] as String,
      cardId: row['card_id'] as String,
      setId: row['set_id'] as String,
      rating: row['rating'] as int,
      state: row['state'] as int,
      reviewedAt: DateTime.parse(row['reviewed_at'] as String),
      elapsedDays: row['elapsed_days'] as int? ?? 0,
      scheduledDays: row['scheduled_days'] as int? ?? 0,
      lastStability: (row['last_stability'] as num?)?.toDouble() ?? 0.0,
      lastDifficulty: (row['last_difficulty'] as num?)?.toDouble() ?? 0.0,
      isSynced: true,
    );
  }

  // -- Profile --

  /// Fetch the current user's profile from Supabase.
  Future<Map<String, dynamic>?> fetchProfile() async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return null;

    final response = await client
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  /// Update display_name, bio, and/or avatar_url on the profiles table.
  Future<void> updateProfile({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) async {
    final client = _clientOrNull;
    final userId = currentUser?.id;
    if (client == null || userId == null) return;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (displayName != null) updates['display_name'] = displayName;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await client
        .from(SupabaseConstants.profilesTable)
        .update(updates)
        .eq('user_id', userId);
  }

  /// Upload avatar bytes to the `avatars` bucket and return the public URL.
  Future<String> uploadAvatar(Uint8List bytes, String fileExt) async {
    final client = _requireClient();
    final userId = currentUser?.id;
    if (userId == null) throw StateError('No signed-in user.');

    final path = '$userId/avatar.$fileExt';
    await client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return client.storage.from('avatars').getPublicUrl(path);
  }

  SupabaseClient _requireClient() {
    final client = _clientOrNull;
    if (client == null) {
      throw StateError(
        'Supabase is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define.',
      );
    }
    return client;
  }
}


