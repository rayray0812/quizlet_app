import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:recall_app/core/constants/app_constants.dart';

enum SortOption {
  newestFirst,
  alphabetical,
  mostDue,
  lastStudied,
}

final sortOptionProvider =
    StateNotifierProvider<SortOptionNotifier, SortOption>((ref) {
  return SortOptionNotifier();
});

class SortOptionNotifier extends StateNotifier<SortOption> {
  SortOptionNotifier() : super(SortOption.newestFirst) {
    _load();
  }

  void _load() {
    try {
      final box = Hive.box(AppConstants.hiveSettingsBox);
      final index = box.get('sort_option', defaultValue: 0) as int;
      if (index >= 0 && index < SortOption.values.length) {
        state = SortOption.values[index];
      }
    } catch (_) {
      // Box not available — keep default.
    }
  }

  void setOption(SortOption option) {
    state = option;
    try {
      Hive.box(AppConstants.hiveSettingsBox).put('sort_option', option.index);
    } catch (_) {
      // Persist failed — in-memory state still updated.
    }
  }
}
