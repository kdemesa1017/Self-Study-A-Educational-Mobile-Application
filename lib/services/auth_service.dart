import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentFirebaseUser => _auth.currentUser;

  // Get current user from local storage
  UserModel? get currentLocalUser => LocalStorageService.getCurrentUser();

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        // Create user model
        final user = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          createdAt: DateTime.now(),
        );

        // Save to local storage
        await LocalStorageService.saveUser(user);
        await LocalStorageService.setCurrentUser(user.id);

        // Try to sync to Firestore if online
        try {
          await _firestore.collection('users').doc(user.id).set(user.toFirestore());
          final syncedUser = user.copyWith(lastSyncedAt: DateTime.now());
          await LocalStorageService.saveUser(syncedUser);
        } catch (e) {
          // Will sync later when online
        }

        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
    return null;
  }

  // Sign in with email and password
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
        // Try to get user from Firestore first
        UserModel? user;
        try {
          final doc = await _firestore.collection('users').doc(result.user!.uid).get();
          if (doc.exists && doc.data() != null) {
            user = UserModel.fromFirestore(doc.data()!);
          }
        } catch (e) {
          // Use local data if Firestore fails
        }

        // If not found online, check local storage
        user ??= LocalStorageService.getUser(result.user!.uid);

        // If still not found, create basic user model
        user ??= UserModel(
          id: result.user!.uid,
          email: email,
          name: email.split('@')[0],
          createdAt: DateTime.now(),
        );

        // Save to local storage
        await LocalStorageService.saveUser(user);
        await LocalStorageService.setCurrentUser(user.id);

        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await LocalStorageService.clearCurrentUser();
  }

  // Update user profile
  Future<UserModel?> updateProfile({
    required String userId,
    String? name,
    int? age,
    String? address,
    String? bio,
    File? profileImage,
  }) async {
    try {
      UserModel? user = LocalStorageService.getUser(userId);
      if (user == null) return null;

      String? profileImageUrl = user.profileImageUrl;

      // Upload new profile image if provided
      if (profileImage != null) {
        try {
          final ref = _storage.ref().child('profile_images/$userId.jpg');
          await ref.putFile(profileImage);
          profileImageUrl = await ref.getDownloadURL();
        } catch (e) {
          // Continue with existing URL if upload fails
        }
      }

      // Update user model
      user = user.copyWith(
        name: name,
        age: age,
        address: address,
        bio: bio,
        profileImageUrl: profileImageUrl,
      );

      // Save to local storage
      await LocalStorageService.saveUser(user);

      // Try to sync to Firestore
      try {
        await _firestore.collection('users').doc(userId).update({
          if (name != null) 'name': name,
          if (age != null) 'age': age,
          if (address != null) 'address': address,
          if (bio != null) 'bio': bio,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          'lastSyncedAt': DateTime.now().toIso8601String(),
        });
        
        final syncedUser = user.copyWith(lastSyncedAt: DateTime.now());
        await LocalStorageService.saveUser(syncedUser);
      } catch (e) {
        // Will sync later when online
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sync user data with Firestore
  Future<void> syncUserData(String userId) async {
    try {
      final localUser = LocalStorageService.getUser(userId);
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final firestoreUser = UserModel.fromFirestore(doc.data()!);
        
        // Use Firestore data if it's newer
        if (localUser == null || 
            (firestoreUser.lastSyncedAt != null && 
             (localUser.lastSyncedAt == null || 
              firestoreUser.lastSyncedAt!.isAfter(localUser.lastSyncedAt!)))) {
          await LocalStorageService.saveUser(firestoreUser);
        } else if (localUser.lastSyncedAt != null && 
                   (firestoreUser.lastSyncedAt == null || 
                    localUser.lastSyncedAt!.isAfter(firestoreUser.lastSyncedAt!))) {
          // Local is newer, upload to Firestore
          await _firestore.collection('users').doc(userId).set(localUser.toFirestore());
          final syncedUser = localUser.copyWith(lastSyncedAt: DateTime.now());
          await LocalStorageService.saveUser(syncedUser);
        }
      } else if (localUser != null) {
        // Upload local user to Firestore
        await _firestore.collection('users').doc(userId).set(localUser.toFirestore());
        final syncedUser = localUser.copyWith(lastSyncedAt: DateTime.now());
        await LocalStorageService.saveUser(syncedUser);
      }
    } catch (e) {
      // Sync failed, will try again later
    }
  }

  // Handle authentication errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
