import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/providers/auth_provider.dart';

/// Lightweight profile data holder.
class UserProfile {
  final String displayName;
  final String bio;
  final String avatarUrl;

  const UserProfile({
    this.displayName = '',
    this.bio = '',
    this.avatarUrl = '',
  });

  UserProfile copyWith({
    String? displayName,
    String? bio,
    String? avatarUrl,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

/// Keys used to persist guest profile in Hive settings box.
const _kDisplayName = 'profile_display_name';
const _kBio = 'profile_bio';
const _kAvatarUrl = 'profile_avatar_url';

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return _fetchFromSupabase();
    }
    // Guest: load from Hive settings box.
    return _loadFromHive();
  }

  Future<UserProfile?> _fetchFromSupabase() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final row = await supabase.fetchProfile();
      if (row == null) return const UserProfile();
      final profile = UserProfile(
        displayName: row['display_name'] as String? ?? '',
        bio: row['bio'] as String? ?? '',
        avatarUrl: row['avatar_url'] as String? ?? '',
      );
      // Cache to Hive for offline access.
      _saveToHive(profile);
      return profile;
    } catch (e) {
      debugPrint('ProfileNotifier: fetchProfile failed: $e');
      // Fallback to Hive cache.
      return _loadFromHive();
    }
  }

  UserProfile _loadFromHive() {
    final box = Hive.box(AppConstants.hiveSettingsBox);
    return UserProfile(
      displayName: box.get(_kDisplayName, defaultValue: '') as String,
      bio: box.get(_kBio, defaultValue: '') as String,
      avatarUrl: box.get(_kAvatarUrl, defaultValue: '') as String,
    );
  }

  void _saveToHive(UserProfile profile) {
    final box = Hive.box(AppConstants.hiveSettingsBox);
    box.put(_kDisplayName, profile.displayName);
    box.put(_kBio, profile.bio);
    box.put(_kAvatarUrl, profile.avatarUrl);
  }

  Future<void> updateDisplayName(String name) async {
    final current = state.valueOrNull ?? const UserProfile();
    final updated = current.copyWith(displayName: name);
    state = AsyncData(updated);
    _saveToHive(updated);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref.read(supabaseServiceProvider).updateProfile(displayName: name);
      } catch (e) {
        debugPrint('ProfileNotifier: updateDisplayName failed: $e');
      }
    }
  }

  Future<void> updateBio(String bio) async {
    final current = state.valueOrNull ?? const UserProfile();
    final updated = current.copyWith(bio: bio);
    state = AsyncData(updated);
    _saveToHive(updated);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref.read(supabaseServiceProvider).updateProfile(bio: bio);
      } catch (e) {
        debugPrint('ProfileNotifier: updateBio failed: $e');
      }
    }
  }

  Future<void> uploadAndSetAvatar(Uint8List bytes, String fileExt) async {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        final url = await ref.read(supabaseServiceProvider).uploadAvatar(bytes, fileExt);
        final current = state.valueOrNull ?? const UserProfile();
        final updated = current.copyWith(avatarUrl: url);
        state = AsyncData(updated);
        _saveToHive(updated);
        await ref.read(supabaseServiceProvider).updateProfile(avatarUrl: url);
      } catch (e) {
        debugPrint('ProfileNotifier: uploadAndSetAvatar failed: $e');
      }
    } else {
      // Guest mode: no upload, could store local path but we skip for now.
      debugPrint('ProfileNotifier: avatar upload skipped in guest mode');
    }
  }

  /// Save display name + bio in one call.
  Future<void> saveProfile({required String displayName, required String bio}) async {
    final current = state.valueOrNull ?? const UserProfile();
    final updated = current.copyWith(displayName: displayName, bio: bio);
    state = AsyncData(updated);
    _saveToHive(updated);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref.read(supabaseServiceProvider).updateProfile(
              displayName: displayName,
              bio: bio,
            );
      } catch (e) {
        debugPrint('ProfileNotifier: saveProfile failed: $e');
      }
    }
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() => ProfileNotifier());
