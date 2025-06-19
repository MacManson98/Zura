import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_gate.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // 🆕 REMOVED: Don't sign out user on app start
  // await FirebaseAuth.instance.signOut(); // ← REMOVED THIS LINE

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
    
    // 🆕 REMOVED: Don't run cleanup before authentication
    // _performStartupCleanup(); // ← REMOVED THIS LINE
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // 🆕 REMOVED: Don't run cleanup on app resume either
    // if (state == AppLifecycleState.resumed) {
    //   _performStartupCleanup(); // ← REMOVED THIS LINE
    // }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QueueTogether',
      theme: ThemeData.dark(),
      home: const AuthGate(),
    );
  }
}