// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'auth_gate.dart';
import 'utils/debug_loader.dart';
import 'utils/ios_readiness_detector.dart';

void main() async {
  // 🆕 SMART iOS FIX: Wait for actual iOS readiness
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && Platform.isIOS) {
    if (kDebugMode) {
      DebugLogger.log("🚀 iOS: Waiting for file system to be actually ready...");
    }
    
    // ✅ SMART: Actually test if iOS is ready instead of guessing
    final isReady = await IOSReadinessDetector.waitForIOSReadiness();
    
    if (!isReady) {
      if (kDebugMode) {
        DebugLogger.log("⚠️ iOS file system never became ready - proceeding anyway");
      }
    }
  }
  
  // Initialize Firebase now that iOS is ready (or we're on Android)
  try {
    if (kDebugMode) {
      DebugLogger.log("🔥 Initializing Firebase...");
    }
    await Firebase.initializeApp();
    if (kDebugMode) {
      DebugLogger.log("✅ Firebase initialized successfully");
    }
  } catch (e) {
    if (kDebugMode) {
      DebugLogger.log("❌ Firebase initialization failed: $e");
    }
    // Continue anyway - auth gate will handle Firebase issues
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // App lifecycle handling
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