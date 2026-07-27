import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/local_user_store.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final localUserStoreProvider = Provider<LocalUserStore>(
  (ref) => LocalUserStore(),
);

/// Exposes [UserModel?] as an [AsyncValue] so the UI can distinguish between:
///   - [AsyncLoading]      → Firebase Auth not yet resolved
///   - [AsyncData(null)]   → definitely signed out
///   - [AsyncData(user)]   → authenticated, user data ready
final currentUserProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  AuthService get _authService => ref.read(authServiceProvider);
  LocalUserStore get _localUserStore => ref.read(localUserStoreProvider);

  @override
  Future<UserModel?> build() async {
    // Subscribe to auth state FIRST — before any await — so we never miss events.
    late final StreamSubscription<dynamic> sub;
    final completer = Completer<UserModel?>();

    sub = _authService.authStateChanges.listen((fbUser) async {
      if (!completer.isCompleted) {
        final user = await _resolveAuthUser(fbUser);
        completer.complete(user);
      } else {
        // Subsequent auth events (explicit sign-out, token refresh, etc.)
        if (fbUser == null) {
          // Ignore transient nulls — only sign out when local session was cleared.
          final stillHasSession = await _localUserStore.hasActiveSession();
          if (!stillHasSession) {
            state = const AsyncData(null);
          }
        } else {
          state = const AsyncLoading();
          final user = await _restoreUser(fbUser);
          state = AsyncData(user);
        }
      }
    });

    ref.onDispose(sub.cancel);

    // Restore the last signed-in account immediately on cold start so the app
    // opens on home after closing, swiping from recents, or rebooting the phone.
    final cachedSession = await _localUserStore.readActiveUser();
    if (cachedSession != null && !completer.isCompleted) {
      state = AsyncData(cachedSession);
    }

    final fbUser = _authService.currentFirebaseUser;
    if (fbUser != null) {
      final cached = await _localUserStore.read(fbUser.uid);
      if (cached != null && !completer.isCompleted) {
        state = AsyncData(cached);
      }
    }

    return completer.future;
  }

  /// Resolves auth on startup. Firebase may briefly report no user while it
  /// reads the persisted session from disk — fall back to the local session
  /// marker so users are not sent to login unless they explicitly signed out.
  Future<UserModel?> _resolveAuthUser(dynamic fbUser) async {
    if (fbUser != null) {
      return _restoreUser(fbUser);
    }

    return _localUserStore.readActiveUser();
  }

  /// Restores a [UserModel] for [fbUser]:
  ///   1. Check local SharedPreferences cache first (works offline).
  ///   2. Try Firestore for fresh data (works online).
  ///   3. Fall back to building a minimal model from Firebase Auth data
  ///      so the user is NEVER kicked to login just because they are offline.
  Future<UserModel?> _restoreUser(dynamic fbUser) async {
    final uid = fbUser.uid as String;

    // Step 1: local cache
    final cachedUser = await _localUserStore.read(uid);
    if (cachedUser != null) {
      // Show cached immediately, then try to refresh from Firestore.
      state = AsyncData(cachedUser);
    }

    // Step 2: Firestore (best-effort, may fail offline)
    try {
      final remoteUser = await _authService.getUserFromFirestore(uid);
      if (remoteUser != null) {
        await _localUserStore.save(remoteUser);
        return remoteUser;
      }
    } catch (_) {
      // Offline or network error — fall through to cached / minimal model.
    }

    if (cachedUser != null) return cachedUser;

    // Step 3: Firebase Auth has a valid session but we have no cached profile
    // (e.g. first launch after clearing app data, still offline).
    // Build a minimal UserModel from Firebase Auth metadata so the user
    // stays logged in and can use cached quiz data.
    final email = (fbUser.email as String?) ?? '';
    final displayName = (fbUser.displayName as String?) ?? email.split('@').first;
    final minimal = UserModel(
      id: uid,
      email: email,
      name: displayName.isEmpty ? 'Student' : displayName,
      createdAt: DateTime.now(),
    );
    // Do NOT save this minimal model — it will be overwritten by Firestore
    // the next time the user goes online.
    return minimal;
  }

  // ── Auth actions ─────────────────────────────────────────────────────────────

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    int? age,
    String? school,
    String? gradeLevel,
  }) async {
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        age: age,
        school: school,
        gradeLevel: gradeLevel,
      );
      if (user == null) return 'Authentication failed. Please try again.';
      state = AsyncData(user);
      await _localUserStore.save(user);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authService.signIn(email: email, password: password);
      if (user == null) return 'Authentication failed. Please try again.';
      state = AsyncData(user);
      await _localUserStore.save(user);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    final userId =
        state.valueOrNull?.id ?? _authService.currentFirebaseUser?.uid;
    // Clear local session first so auth stream null events cannot resurrect it.
    if (userId != null) await _localUserStore.clear(userId);
    await _authService.signOut();
    state = const AsyncData(null);
  }

  Future<String?> updateProfile({
    String? name,
    int? age,
    String? address,
    String? bio,
    Uint8List? profileImageBytes,
  }) async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return 'No user logged in';
    try {
      final user = await _authService.updateProfile(
        userId: currentUser.id,
        name: name,
        age: age,
        address: address,
        bio: bio,
        profileImageBytes: profileImageBytes,
      );
      if (user == null) return 'Failed to update profile. Please try again.';
      state = AsyncData(user);
      await _localUserStore.save(user);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Writes streak data directly to Firestore (called by [StreakNotifier]).
  Future<void> updateStreakInFirestore({
    required String userId,
    required int streakCount,
    required String lastStreakDate,
  }) async {
    await _authService.updateStreak(
      userId: userId,
      streakCount: streakCount,
      lastStreakDate: lastStreakDate,
    );
    // Also update local state.
    final current = state.valueOrNull;
    if (current != null) {
      final updated = current.copyWith(
        streakCount: streakCount,
        lastStreakDate: lastStreakDate,
        pendingStreakSync: false,
      );
      state = AsyncData(updated);
      await _localUserStore.save(updated);
    }
  }

  Future<String?> clearAllData() async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return 'No user logged in';
    try {
      await _authService.deleteAllUserData(currentUser.id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
