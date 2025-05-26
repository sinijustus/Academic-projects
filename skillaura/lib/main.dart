import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:skillaura/screens/login_screen.dart';
import 'package:logger/logger.dart';

final logger = Logger(
  level: kReleaseMode ? Level.nothing : Level.debug,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      logger.i("✅ Firebase initialized successfully.");
    }
  } catch (e, stackTrace) {
    logger.e("❌ Firebase initialization failed.", error: e, stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillAura',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
