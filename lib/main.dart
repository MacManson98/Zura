// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'auth_gate.dart';

void main() async {
  // ✅ NO DELAYS: Normal app startup
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase normally
  try {
    await Firebase.initializeApp();
    if (kDebugMode) {
      print("✅ Firebase initialized successfully");
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ Firebase initialization failed: $e");
    }
  }
  
  runApp(ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => const MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zura',
      theme: ThemeData.dark(),
      home: const AuthGate(),
    );
  }
}