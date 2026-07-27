import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Stores only the non-secret profile needed to open a previously signed-in
/// account while Firestore is unavailable. Passwords and Firebase tokens are
/// never written here; Firebase Auth keeps its own encrypted session.
class LocalUserStore {
  static const _activeUserIdKey = 'active_user_id';
  static const _userKeyPrefix = 'cached_user_';

  Future<void> save(UserModel user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_activeUserIdKey, user.id);
    await preferences.setString(
      '$_userKeyPrefix${user.id}',
      jsonEncode(user.toFirestore()),
    );
  }

  Future<String?> getActiveUserId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_activeUserIdKey);
  }

  Future<bool> hasActiveSession() async {
    final activeUserId = await getActiveUserId();
    if (activeUserId == null) return false;
    return read(activeUserId) != null;
  }

  Future<UserModel?> readActiveUser() async {
    final activeUserId = await getActiveUserId();
    if (activeUserId == null) return null;
    return read(activeUserId);
  }

  Future<UserModel?> read(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final rawUser = preferences.getString('$_userKeyPrefix$userId');
    if (rawUser == null) return null;

    try {
      final data = Map<String, dynamic>.from(jsonDecode(rawUser) as Map);
      return UserModel.fromFirestore(data);
    } catch (_) {
      await preferences.remove('$_userKeyPrefix$userId');
      return null;
    }
  }

  Future<void> clear(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_userKeyPrefix$userId');
    if (preferences.getString(_activeUserIdKey) == userId) {
      await preferences.remove(_activeUserIdKey);
    }
  }
}
