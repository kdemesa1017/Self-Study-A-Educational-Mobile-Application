import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../services/local_quiz_store.dart';

final localQuizStoreProvider = Provider<LocalQuizStore>(
  (_) => LocalQuizStore(),
);

/// Manages the user's daily login streak.
///
/// Rules:
///   • If today was already counted  → no change.
///   • If today is the day after the last streak date → streak + 1.
///   • If more than 1 day has passed → reset to 1 (still counts today).
///   • When online  → write to Firestore immediately.
///   • When offline → write locally and mark [pendingStreakSync = true].
///                    A connectivity listener syncs once online.
final streakProvider =
    AsyncNotifierProvider<StreakNotifier, int>(StreakNotifier.new);

class StreakNotifier extends AsyncNotifier<int> {
  @override
  Future<int> build() async {
    // Wait for auth to resolve.
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return 0;

    final store = ref.read(localQuizStoreProvider);
    final today = _todayStr();

    // Already counted today — nothing to do.
    if (user.lastStreakDate == today) return user.streakCount;

    // Calculate new streak count.
    final newCount = _calcStreak(user.lastStreakDate, user.streakCount, today);

    // Check connectivity.
    final isOnline = await ref.read(connectivityServiceProvider).isOnline;

    if (isOnline) {
      await _syncToFirestore(user.id, newCount, today, store);
    } else {
      // Save locally as pending.
      await store.savePendingStreak(user.id, newCount, today);
      // Update local cached profile.
      final updated = user.copyWith(
        streakCount: newCount,
        lastStreakDate: today,
        pendingStreakSync: true,
      );
      await store.saveUser(updated);
      // Listen for connectivity and sync when online.
      _listenForConnectivity(user.id, newCount, today, store);
    }

    return newCount;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  int _calcStreak(String? lastDate, int currentCount, String today) {
    if (lastDate == null) return 1;
    try {
      final last = DateTime.parse(lastDate);
      final todayDate = DateTime.parse(today);
      final diff = todayDate.difference(last).inDays;
      if (diff == 1) return currentCount + 1; // Consecutive
      if (diff > 1) return 1; // Missed day(s) — reset
      return currentCount; // Same day — shouldn't reach here
    } catch (_) {
      return 1;
    }
  }

  Future<void> _syncToFirestore(
    String userId,
    int newCount,
    String today,
    LocalQuizStore store,
  ) async {
    try {
      final authNotifier = ref.read(currentUserProvider.notifier);
      await authNotifier.updateStreakInFirestore(
        userId: userId,
        streakCount: newCount,
        lastStreakDate: today,
      );
      await store.clearPendingStreak(userId);
    } catch (_) {
      // Firestore unavailable — fall back to local pending.
      await store.savePendingStreak(userId, newCount, today);
    }
  }

  void _listenForConnectivity(
    String userId,
    int pendingCount,
    String pendingDate,
    LocalQuizStore store,
  ) {
    ref.listen<AsyncValue<bool>>(isOnlineProvider, (_, next) async {
      if (next.valueOrNull == true) {
        await _syncToFirestore(userId, pendingCount, pendingDate, store);
        state = AsyncData(pendingCount);
      }
    });
  }

  static String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }
}
