import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';
import 'package:recall_app/models/badge.dart';
import 'package:recall_app/services/badge_definitions.dart';
import 'package:recall_app/services/badge_checker.dart';
import 'package:recall_app/providers/study_set_provider.dart';

final badgeProvider =
    StateNotifierProvider<BadgeNotifier, List<AppBadge>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return BadgeNotifier(BadgeChecker(localStorage));
});

class BadgeNotifier extends StateNotifier<List<AppBadge>> {
  final BadgeChecker _checker;

  BadgeNotifier(this._checker) : super([]) {
    _load();
  }

  Box get _box => Hive.box(AppConstants.hiveSettingsBox);

  void _load() {
    final definitions = BadgeDefinitions.all();
    final savedJson = _box.get('badges_unlocked', defaultValue: '{}') as String;
    final Map<String, dynamic> saved =
        json.decode(savedJson) as Map<String, dynamic>;

    state = definitions.map((badge) {
      final unlockedAtStr = saved[badge.id] as String?;
      if (unlockedAtStr != null) {
        return badge.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.tryParse(unlockedAtStr),
        );
      }
      return badge;
    }).toList();
  }

  List<String> checkAndUnlock() {
    final results = _checker.checkAll();
    final newlyUnlocked = <String>[];
    final savedJson = _box.get('badges_unlocked', defaultValue: '{}') as String;
    final Map<String, dynamic> saved =
        Map<String, dynamic>.from(json.decode(savedJson) as Map);

    for (final entry in results.entries) {
      if (entry.value && !saved.containsKey(entry.key)) {
        saved[entry.key] = DateTime.now().toUtc().toIso8601String();
        newlyUnlocked.add(entry.key);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      _box.put('badges_unlocked', json.encode(saved));
      _load();
    }

    return newlyUnlocked;
  }

  bool unlockById(String badgeId) {
    final savedJson = _box.get('badges_unlocked', defaultValue: '{}') as String;
    final Map<String, dynamic> saved =
        Map<String, dynamic>.from(json.decode(savedJson) as Map);
    if (saved.containsKey(badgeId)) return false;

    saved[badgeId] = DateTime.now().toUtc().toIso8601String();
    _box.put('badges_unlocked', json.encode(saved));
    _load();
    return true;
  }
}
