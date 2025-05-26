// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';


class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: "AIzaSyB3wQ-IzTZnbL2hYYQGfrH7UtJ-VoghMjI",
      authDomain: "skillaura-d2e53.firebaseapp.com",
      projectId: "skillaura-d2e53",
      storageBucket: "skillaura-d2e53.firebasestorage.app",
      messagingSenderId: "1032629545223",
      appId: "1:1032629545223:web:80d5d1fdcd90d3c521fda2",
    );
  }
}
