import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🆕 iOS-SPECIFIC: Add initialization delay to prevent path_provider crashes
  if (!kIsWeb && Platform.isIOS) {
    // Wait for iOS to be fully ready before initializing plugins
    await Future.delayed(const Duration(milliseconds: 500));
  }
  
  await Firebase.initializeApp();
  
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
    // App lifecycle handling can go here if needed
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