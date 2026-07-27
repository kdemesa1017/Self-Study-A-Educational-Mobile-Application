import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel?> getUserFromFirestore(
    String uid, {
    bool forceServer = false,
  }) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc;

      if (forceServer) {
        try {
          doc = await _firestore
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.server))
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
              );
        } on FirebaseException {
          doc = await _firestore
              .collection('users')
              .doc(uid)
              .get()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
              );
        }
      } else {
        doc = await _firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
            );
      }

      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    int? age,
    String? school,
    String? gradeLevel,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final user = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          age: age,
          school: school,
          gradeLevel: gradeLevel,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.id)
            .set(user.toFirestore())
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out. Please check your internet connection.',
            );
        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw '${_handleAuthError(e)} (code: ${e.code})';
    }
    return null;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        final user = await getUserFromFirestore(
          result.user!.uid,
          forceServer: true,
        );
        if (user != null) return user;

        return UserModel(
          id: result.user!.uid,
          email: email,
          name: result.user!.displayName ?? email.split('@')[0],
          createdAt: DateTime.now(),
        );
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Writes streak fields to Firestore without touching other profile data.
  Future<void> updateStreak({
    required String userId,
    required int streakCount,
    required String lastStreakDate,
  }) async {
    await _firestore.collection('users').doc(userId).set(
      {'streakCount': streakCount, 'lastStreakDate': lastStreakDate},
      SetOptions(merge: true),
    ).timeout(const Duration(seconds: 8), onTimeout: () => throw 'Timeout');
  }

  Future<UserModel?> updateProfile({
    required String userId,
    String? name,
    int? age,
    String? address,
    String? bio,
    Uint8List? profileImageBytes,
  }) async {
    try {
      String? profileImageBase64;
      if (profileImageBytes != null) {
        // Firestore documents are limited to 1 MiB. The picker already
        // downscales the image, and this guard leaves room for base64 overhead
        // and the rest of the profile document.
        const maxAvatarBytes = 600 * 1024;
        if (profileImageBytes.lengthInBytes > maxAvatarBytes) {
          throw 'Please choose a smaller profile photo.';
        }
        profileImageBase64 = base64Encode(profileImageBytes);
      }

      final nowIso = DateTime.now().toIso8601String();
      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (age != null) 'age': age,
        if (address != null) 'address': address,
        if (bio != null) 'bio': bio,
        if (profileImageBase64 != null)
          'profileImageBase64': profileImageBase64,
        'lastSyncedAt': nowIso,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .set(updates, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
          );

      // Read back the full user document. If it doesn't exist or is missing
      // required fields (from older accounts), create a minimal base doc.
      var userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
          );
      if (!userDoc.exists || userDoc.data() == null) {
        final fbUser = _auth.currentUser;
        final base = <String, dynamic>{
          'id': userId,
          'email': fbUser?.email ?? '',
          'name':
              name ??
              fbUser?.displayName ??
              (fbUser?.email?.split('@').first ?? 'User'),
          'createdAt': DateTime.now().toIso8601String(),
          ...updates,
        };
        await _firestore
            .collection('users')
            .doc(userId)
            .set(base, SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
            );
        userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
            );
      }

      if (!userDoc.exists || userDoc.data() == null) return null;
      final data = userDoc.data()!;
      if (data['id'] == null ||
          data['email'] == null ||
          data['name'] == null ||
          data['createdAt'] == null) {
        final fbUser = _auth.currentUser;
        await _firestore
            .collection('users')
            .doc(userId)
            .set({
              'id': userId,
              'email': fbUser?.email ?? data['email'] ?? '',
              'name': data['name'] ?? name ?? fbUser?.displayName ?? 'User',
              'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
            }, SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
            );
        userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get()
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw 'Connection timed out. Please check your internet connection or disable your ad blocker (e.g. Brave Shield, uBlock Origin) if it is blocking Firebase.',
            );
      }

      if (!userDoc.exists || userDoc.data() == null) return null;
      return UserModel.fromFirestore(userDoc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteAllUserData(String userId) async {
    try {
      final quizzesSnapshot =
          await _firestore
              .collection('quizzes')
              .where('userId', isEqualTo: userId)
              .get();

      final List<DocumentReference<Map<String, dynamic>>> refsToDelete = [];

      for (final quizDoc in quizzesSnapshot.docs) {
        final questionsSnapshot =
            await _firestore
                .collection('questions')
                .where('quizId', isEqualTo: quizDoc.id)
                .get();

        for (final qDoc in questionsSnapshot.docs) {
          refsToDelete.add(qDoc.reference);
        }

        refsToDelete.add(quizDoc.reference);
      }

      refsToDelete.add(_firestore.collection('users').doc(userId));

      // Firestore write batch limit is 500. Keep a safe margin.
      const chunkSize = 450;
      for (var i = 0; i < refsToDelete.length; i += chunkSize) {
        final batch = _firestore.batch();
        final end =
            (i + chunkSize) > refsToDelete.length
                ? refsToDelete.length
                : (i + chunkSize);
        for (final ref in refsToDelete.sublist(i, end)) {
          batch.delete(ref);
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      // Surface the error so UI can display it.
      throw e.message ?? 'Failed to delete user data.';
    } catch (e) {
      throw 'Failed to delete user data.';
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-login-credentials':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
