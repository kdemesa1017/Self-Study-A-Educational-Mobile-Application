import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with web options if on web
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBPf3hqZA2sUTlnLKHs5Wt7uwt4-snuoOA",
        authDomain: "self-study-app-66c44.firebaseapp.com",
        projectId: "self-study-app-66c44",
        storageBucket: "self-study-app-66c44.firebasestorage.app",
        messagingSenderId: "1022393083216",
        appId: "1:1022393083216:web:4d72a1ae764e7e45a53855",
        measurementId: "G-YN420FX9G1",
      ),
    );
  } else {
    // Mobile uses google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  }

  // Initialize Local Storage (Hive)
  await LocalStorageService.initialize();

  runApp(
    const ProviderScope(
      child: SelfStudyApp(),
    ),
  );
}
