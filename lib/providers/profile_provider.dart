import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/providers/auth_provider.dart';

class UserProfile {
  final String displayName;
  final String bio;
  final String avatarUrl;

  const UserProfile({
    this.displayName = '',
    this.bio = '',
    this.avatarUrl = '',
  });

  UserProfile copyWith({String? displayName, String? bio, String? avatarUrl}) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

const _kDisplayName = 'profile_display_name';
const _kBio = 'profile_bio';
const _kAvatarUrl = 'profile_avatar_url';

String _sanitizeDisplayName(String value, String email) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final normalizedEmail = email.trim().toLowerCase();
  if (normalizedEmail.isEmpty) return trimmed;
  if (trimmed.toLowerCase() != normalizedEmail) return trimmed;
  final localPart = normalizedEmail.split('@').first.trim();
  return localPart;
}

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user != null) {
      return _fetchFromSupabase();
    }
    return const UserProfile();
  }

  Future<UserProfile?> _fetchFromSupabase() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final user = ref.read(currentUserProvider);
      final row = await supabase.fetchProfile();
      final fallbackName = supabase.preferredDisplayName(user);

      if (row == null) {
        final profile = UserProfile(displayName: fallbackName);
        _saveToHive(profile);
        return profile;
      }

      final remoteDisplayName = _sanitizeDisplayName(
        row['display_name'] as String? ?? '',
        user?.email ?? '',
      );
      final profile = UserProfile(
        displayName: remoteDisplayName.isNotEmpty
            ? remoteDisplayName
            : fallbackName,
        bio: row['bio'] as String? ?? '',
        avatarUrl: row['avatar_url'] as String? ?? '',
      );
      _saveToHive(profile);
      return profile;
    } catch (e) {
      debugPrint('ProfileNotifier: fetchProfile failed: $e');
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

  Future<void> clearCachedProfile() async {
    final box = Hive.box(AppConstants.hiveSettingsBox);
    await box.delete(_kDisplayName);
    await box.delete(_kBio);
    await box.delete(_kAvatarUrl);
    state = const AsyncData(UserProfile());
  }

  Future<void> updateDisplayName(String name) async {
    final current = state.valueOrNull ?? const UserProfile();
    final updated = current.copyWith(displayName: name);
    state = AsyncData(updated);
    _saveToHive(updated);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref
            .read(supabaseServiceProvider)
            .updateProfile(displayName: name);
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
    if (user == null) {
      debugPrint('ProfileNotifier: avatar upload skipped in guest mode');
      return;
    }

    try {
      final url = await ref
          .read(supabaseServiceProvider)
          .uploadAvatar(bytes, fileExt);
      final versionedUrl = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
      final current = state.valueOrNull ?? const UserProfile();
      final updated = current.copyWith(avatarUrl: versionedUrl);
      state = AsyncData(updated);
      _saveToHive(updated);
      await ref
          .read(supabaseServiceProvider)
          .updateProfile(avatarUrl: versionedUrl);
    } catch (e) {
      debugPrint('ProfileNotifier: uploadAndSetAvatar failed: $e');
    }
  }

  Future<void> saveProfile({
    required String displayName,
    required String bio,
  }) async {
    final current = state.valueOrNull ?? const UserProfile();
    final updated = current.copyWith(displayName: displayName, bio: bio);
    state = AsyncData(updated);
    _saveToHive(updated);

    final user = ref.read(currentUserProvider);
    if (user != null) {
      try {
        await ref
            .read(supabaseServiceProvider)
            .updateProfile(displayName: displayName, bio: bio);
      } catch (e) {
        debugPrint('ProfileNotifier: saveProfile failed: $e');
      }
    }
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(
  () => ProfileNotifier(),
);
