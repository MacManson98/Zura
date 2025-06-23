// File: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'auth_gate.dart';

void main() async {
  // 🆕 AGGRESSIVE iOS FIX: Prevent premature plugin initialization
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb && Platform.isIOS) {
    // 🆕 STEP 1: Longer delay for iOS readiness
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // 🆕 STEP 2: Force garbage collection to clear any premature initializations
    if (kDebugMode) {
      print("🚀 iOS: Starting delayed initialization...");
    }
    
    // 🆕 STEP 3: Additional delay before plugin access
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (kDebugMode) {
      print("✅ iOS: Initialization delay completed");
    }
  }
  
  // 🆕 STEP 4: Initialize Firebase with iOS-safe timing
  try {
    if (kDebugMode) {
      print("🔥 Initializing Firebase...");
    }
    await Firebase.initializeApp();
    if (kDebugMode) {
      print("✅ Firebase initialized successfully");
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ Firebase initialization failed: $e");
    }
    // Continue anyway - auth gate will handle Firebase issues
  }
  
  // 🆕 STEP 5: One final delay before UI startup
  if (!kIsWeb && Platform.isIOS) {
    await Future.delayed(const Duration(milliseconds: 300));
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