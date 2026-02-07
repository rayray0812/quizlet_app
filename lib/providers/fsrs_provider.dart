import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_app/models/card_progress.dart';
import 'package:recall_app/services/fsrs_service.dart';
import 'package:recall_app/providers/study_set_provider.dart';

/// Singleton FsrsService provider.
final fsrsServiceProvider = Provider<FsrsService>((ref) {
  return FsrsService();
});

/// All CardProgress entries from local storage.
final allCardProgressProvider = Provider<List<CardProgress>>((ref) {
  // Re-read whenever study sets change (which triggers progress init)
  ref.watch(studySetsProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getAllCardProgress();
});

/// Clock source for due-card calculations (injectable for tests).
final dueClockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});

/// Emits immediately, then every minute to invalidate due-card providers.
final dueTickerProvider = StreamProvider<int>((ref) async* {
  yield 0;
  yield* Stream.periodic(
    const Duration(minutes: 1),
    (count) => count + 1,
  );
});

/// Due cards across all study sets.
final dueCardsProvider = Provider<List<CardProgress>>((ref) {
  ref.watch(dueTickerProvider);
  final all = ref.watch(allCardProgressProvider);
  final now = ref.watch(dueClockProvider).call();
  return all.where((p) {
    if (p.due == null) return true; // New cards
    return p.due!.isBefore(now) || p.due!.isAtSameMomentAs(now);
  }).toList();
});

/// Total due card count.
final dueCountProvider = Provider<int>((ref) {
  return ref.watch(dueCardsProvider).length;
});

/// Due cards for a specific study set.
final dueCardsForSetProvider =
    Provider.family<List<CardProgress>, String>((ref, setId) {
  final due = ref.watch(dueCardsProvider);
  return due.where((p) => p.setId == setId).toList();
});

/// Due count for a specific study set.
final dueCountForSetProvider = Provider.family<int, String>((ref, setId) {
  return ref.watch(dueCardsForSetProvider(setId)).length;
});

/// Breakdown of due cards: new / learning / review.
final dueBreakdownProvider = Provider<({int newCount, int learning, int review})>((ref) {
  final due = ref.watch(dueCardsProvider);
  int newCount = 0;
  int learning = 0;
  int review = 0;

  for (final p in due) {
    switch (p.state) {
      case 0:
        newCount++;
        break;
      case 1:
        learning++;
        break;
      case 2:
      case 3:
        review++;
        break;
    }
  }

  return (newCount: newCount, learning: learning, review: review);
});

/// Breakdown for a specific set.
final dueBreakdownForSetProvider =
    Provider.family<({int newCount, int learning, int review}), String>(
        (ref, setId) {
  final due = ref.watch(dueCardsForSetProvider(setId));
  int newCount = 0;
  int learning = 0;
  int review = 0;

  for (final p in due) {
    switch (p.state) {
      case 0:
        newCount++;
        break;
      case 1:
        learning++;
        break;
      case 2:
      case 3:
        review++;
        break;
    }
  }

  return (newCount: newCount, learning: learning, review: review);
});

