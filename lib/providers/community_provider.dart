import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/providers/auth_provider.dart';
import 'package:recall_app/providers/study_set_provider.dart';
import 'package:recall_app/services/community_service.dart';
import 'package:recall_app/services/local_storage_service.dart';

final communityServiceProvider = Provider<CommunityService>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return CommunityService(supabaseService: supabase);
});

/// Current sort option for public sets.
final communitySortProvider =
    StateProvider<CommunitySortOption>((ref) => CommunitySortOption.trending);

/// Current category filter (empty = all).
final communityCategoryProvider = StateProvider<String>((ref) => '');

/// Query for fetching public study sets.
@immutable
class PublicSetsQuery {
  final String? search;
  final CommunitySortOption sort;
  final String category;

  const PublicSetsQuery({
    this.search,
    this.sort = CommunitySortOption.trending,
    this.category = '',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicSetsQuery &&
          search == other.search &&
          sort == other.sort &&
          category == other.category;

  @override
  int get hashCode => Object.hash(search, sort, category);
}

/// Fetches public study sets with sort + category + search.
final publicStudySetsProvider =
    FutureProvider.family<List<PublicStudySet>, PublicSetsQuery>(
        (ref, query) async {
  final service = ref.watch(communityServiceProvider);
  return service.fetchPublicSets(
    query: query.search,
    sort: query.sort,
    category: query.category,
  );
});

/// Simple provider for backward compat: fetch by search string only.
final publicSetsBySearchProvider =
    FutureProvider.family<List<PublicStudySet>, String?>((ref, query) async {
  final service = ref.watch(communityServiceProvider);
  return service.fetchPublicSets(query: query);
});

/// Checks if a given study set is published by the current user.
final isPublishedProvider =
    FutureProvider.family<bool, String>((ref, studySetId) async {
  ref.watch(currentUserProvider);
  final service = ref.watch(communityServiceProvider);
  return service.isPublished(studySetId);
});

/// Fetches a user's public profile.
final userProfileProvider =
    FutureProvider.family<UserPublicProfile, String>((ref, userId) async {
  final service = ref.watch(communityServiceProvider);
  return service.fetchUserProfile(userId);
});

/// Fetches public sets for a specific user.
final userPublicSetsProvider =
    FutureProvider.family<List<PublicStudySet>, String>((ref, userId) async {
  final service = ref.watch(communityServiceProvider);
  return service.fetchUserPublicSets(userId);
});

final communityFriendIdsProvider =
    StateNotifierProvider<CommunityFriendIdsNotifier, List<String>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return CommunityFriendIdsNotifier(localStorage);
});

class CommunityFriendIdsNotifier extends StateNotifier<List<String>> {
  CommunityFriendIdsNotifier(this._localStorage)
      : super(_localStorage.getCommunityFriendIds());

  final LocalStorageService _localStorage;

  Future<void> add(String userId) async {
    if (state.contains(userId)) return;
    final next = [...state, userId];
    await _localStorage.saveCommunityFriendIds(next);
    state = next;
  }

  Future<void> remove(String userId) async {
    final next = [...state]..removeWhere((id) => id == userId);
    await _localStorage.saveCommunityFriendIds(next);
    state = next;
  }
}
