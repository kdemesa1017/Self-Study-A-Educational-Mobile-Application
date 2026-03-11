import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((firebaseUser) {
    if (firebaseUser != null) {
      return authService.currentLocalUser;
    }
    return null;
  });
});

final currentUserProvider = StateNotifierProvider<AuthNotifier, UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<UserModel?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(_authService.currentLocalUser);

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

  Future<void> syncUserData() async {
    if (state != null) {
      await _authService.syncUserData(state!.id);
      state = _authService.currentLocalUser;
    }
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
      state = user;
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateProfileImage(dynamic imageFile) async {
    if (state == null) return 'No user logged in';

    try {
      final user = await _authService.updateProfile(
        userId: state!.id,
        profileImage: imageFile,
      );
      state = user;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
