import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizlet_app/providers/study_set_provider.dart';

/// All unique tags across all study sets, sorted alphabetically.
final allTagsProvider = Provider<List<String>>((ref) {
  final studySets = ref.watch(studySetsProvider);
  final tags = <String>{};
  for (final set in studySets) {
    for (final card in set.cards) {
      tags.addAll(card.tags);
    }
  }
  final sorted = tags.toList()..sort();
  return sorted;
});
