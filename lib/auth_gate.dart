// File: lib/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'screens/auth/login_screen.dart';
import 'main_navigation.dart';
import 'models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/debug_loader.dart';
import 'utils/ios_readiness_detector.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.movie_filter,
                    size: 64,
                    color: const Color(0xFFE5A00D),
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    color: const Color(0xFFE5A00D),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Checking authentication...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (kDebugMode) {
          DebugLogger.log('🔥 Auth state changed:');
          DebugLogger.log('  user: $user');
          DebugLogger.log('  isAnonymous: ${user?.isAnonymous}');
          DebugLogger.log('  uid: ${user?.uid}');
        }
        
        if (user == null || user.isAnonymous) {
          if (kDebugMode) {
            DebugLogger.log('➡️ Showing LoginScreen');
          }
          return const LoginScreen();
        }

        return FutureBuilder<UserProfile>(
          future: _loadUserProfile(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: const Color(0xFF121212),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.movie_filter,
                        size: 64,
                        color: const Color(0xFFE5A00D),
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(
                        color: const Color(0xFFE5A00D),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading your profile...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              if (kDebugMode) {
                DebugLogger.log('❌ Error loading profile: ${snapshot.error}');
              }
              return Scaffold(
                backgroundColor: const Color(0xFF121212),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Error loading profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const AuthGate()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A00D),
                        ),
                        child: const Text('Retry'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                        },
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final profile = snapshot.data!;
            if (kDebugMode) {
              DebugLogger.log('➡️ Going to MainNavigation');
            }
            return MainNavigation(profile: profile);
          },
        );
      },
    );
  }

  // ✅ SMART: iOS readiness confirmed in main(), minimal safety here
  Future<UserProfile> _loadUserProfile(String uid) async {
    try {
      if (kDebugMode) {
        DebugLogger.log("🔥 Starting Firestore profile load for uid: $uid");
        DebugLogger.log("📊 iOS ready status: ${IOSReadinessDetector.isReady}");
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          DebugLogger.log("📝 Creating new user profile...");
        }
        
        final profile = UserProfile.empty().copyWith(
          uid: uid,
          name: FirebaseAuth.instance.currentUser?.email ?? '',
        );
        
        await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(profile.toJson(), SetOptions(merge: true));
        
        if (kDebugMode) {
          DebugLogger.log('✅ Created new user profile');
        }
        return profile;
      } else {
        final profile = UserProfile.fromJson(doc.data()!);
        if (kDebugMode) {
          DebugLogger.log('✅ Loaded existing user profile');
        }
        return profile;
      }
    } catch (e) {
      if (kDebugMode) {
        DebugLogger.log('❌ Error in _loadUserProfile: $e');
      }
      
      // ✅ ONE RETRY: If there's still an issue, try once more
      if (!kIsWeb && Platform.isIOS) {
        if (kDebugMode) {
          DebugLogger.log('🔄 One retry for iOS...');
        }
        await Future.delayed(const Duration(milliseconds: 1000));
        
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();
          
          if (!doc.exists) {
            final profile = UserProfile.empty().copyWith(
              uid: uid,
              name: FirebaseAuth.instance.currentUser?.email ?? '',
            );
            if (kDebugMode) {
              DebugLogger.log('✅ Retry: created new profile');
            }
            return profile;
          } else {
            if (kDebugMode) {
              DebugLogger.log('✅ Retry: loaded existing profile');
            }
            return UserProfile.fromJson(doc.data()!);
          }
        } catch (retryError) {
          if (kDebugMode) {
            DebugLogger.log('❌ Retry also failed: $retryError');
          }
          
          // ✅ EMERGENCY: Create offline profile
          final emergencyProfile = UserProfile.empty().copyWith(
            uid: uid,
            name: FirebaseAuth.instance.currentUser?.email ?? 'User',
          );
          if (kDebugMode) {
            DebugLogger.log('🆘 Using emergency offline profile');
          }
          return emergencyProfile;
        }
      }
      
      rethrow;
    }
  }
}