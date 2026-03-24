import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider =
    StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(null) {
    _init();
  }

  Future<void> _init() async {
    final fbUser = _authService.currentFirebaseUser;
    if (fbUser != null) {
      final user = await _authService.getUserFromFirestore(fbUser.uid);
      if (user != null) state = user;
    }
    _authService.authStateChanges.listen((fbUser) async {
      if (fbUser == null) {
        state = null;
      } else if (state == null || state!.id != fbUser.uid) {
        final user = await _authService.getUserFromFirestore(fbUser.uid);
        if (user != null) state = user;
      }
    });
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );
      if (user == null) {
        return 'Authentication failed. Please try again.';
      }
      state = user;
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
      final user = await _authService.signIn(
        email: email,
        password: password,
      );
      if (user == null) {
        return 'Authentication failed. Please try again.';
      }
      state = user;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = null;
  }

  Future<String?> updateProfile({
    String? name,
    int? age,
    String? address,
    String? bio,
  }) async {
    if (state == null) return 'No user logged in';

    try {
      final user = await _authService.updateProfile(
        userId: state!.id,
        name: name,
        age: age,
        address: address,
        bio: bio,
      );
      if (user == null) {
        return 'Failed to update profile. Please try again.';
      }
      state = user;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfileImage(File imageFile) async {
    if (state == null) return 'No user logged in';

    try {
      final user = await _authService.updateProfile(
        userId: state!.id,
        profileImage: imageFile,
      );
      if (user == null) {
        return 'Failed to update profile image. Please try again.';
      }
      state = user;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> clearAllData() async {
    if (state == null) return 'No user logged in';

    try {
      await _authService.deleteAllUserData(state!.id);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
