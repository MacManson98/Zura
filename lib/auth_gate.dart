// File: lib/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'screens/auth/login_screen.dart';
import 'main_navigation.dart';
import 'models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                  if (!kIsWeb && Platform.isIOS) ...[
                    SizedBox(height: 8),
                    Text(
                      'Initializing iOS environment...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (kDebugMode) {
          print('🔥 Auth state changed:');
          print('  user: $user');
          print('  isAnonymous: ${user?.isAnonymous}');
          print('  uid: ${user?.uid}');
        }
        
        if (user == null || user.isAnonymous) {
          if (kDebugMode) {
            print('➡️ Showing LoginScreen');
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
                      if (!kIsWeb && Platform.isIOS) ...[
                        SizedBox(height: 8),
                        Text(
                          'Preparing app for iOS...',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              if (kDebugMode) {
                print('❌ Error loading profile: ${snapshot.error}');
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
              print('➡️ Going to MainNavigation (movies will load internally)');
            }
            return MainNavigation(profile: profile);
          },
        );
      },
    );
  }

  // 🆕 ULTRA-AGGRESSIVE: Maximum delays and retry logic for iOS
  Future<UserProfile> _loadUserProfile(String uid) async {
    try {
      // 🆕 AGGRESSIVE iOS DELAY: Much longer delay before Firestore operations
      if (!kIsWeb && Platform.isIOS) {
        if (kDebugMode) {
          print("⏳ iOS: Waiting before Firestore operations...");
        }
        await Future.delayed(const Duration(milliseconds: 2000));
      }

      if (kDebugMode) {
        print("🔥 Starting Firestore profile load for uid: $uid");
      }

      DocumentSnapshot<Map<String, dynamic>>? doc;
      
      // 🆕 RETRY LOGIC: Multiple attempts for iOS Firestore operations
      if (!kIsWeb && Platform.isIOS) {
        for (int attempt = 1; attempt <= 3; attempt++) {
          try {
            if (kDebugMode) {
              print("📖 iOS Firestore attempt $attempt...");
            }
            doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .get();
            if (kDebugMode) {
              print("✅ iOS Firestore attempt $attempt succeeded");
            }
            break;
          } catch (e) {
            if (kDebugMode) {
              print("⚠️ iOS Firestore attempt $attempt failed: $e");
            }
            if (attempt < 3) {
              await Future.delayed(Duration(milliseconds: 1000 * attempt));
            } else {
              rethrow;
            }
          }
        }
      } else {
        // Android - normal approach
        doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
      }

      if (doc == null) {
        throw Exception("Failed to load user document after retries");
      }

      if (!doc.exists) {
        if (kDebugMode) {
          print("📝 Creating new user profile...");
        }
        
        final profile = UserProfile.empty().copyWith(
          uid: uid,
          name: FirebaseAuth.instance.currentUser?.email ?? '',
        );
        
        // 🆕 ADDITIONAL DELAY: Before write operations on iOS
        if (!kIsWeb && Platform.isIOS) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        // 🆕 RETRY WRITE OPERATIONS: Multiple attempts for iOS
        if (!kIsWeb && Platform.isIOS) {
          for (int attempt = 1; attempt <= 3; attempt++) {
            try {
              if (kDebugMode) {
                print("💾 iOS Firestore write attempt $attempt...");
              }
              await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .set(profile.toJson(), SetOptions(merge: true));
              if (kDebugMode) {
                print("✅ iOS Firestore write attempt $attempt succeeded");
              }
              break;
            } catch (e) {
              if (kDebugMode) {
                print("⚠️ iOS Firestore write attempt $attempt failed: $e");
              }
              if (attempt < 3) {
                await Future.delayed(Duration(milliseconds: 500 * attempt));
              } else {
                // If write fails, just return the profile anyway
                if (kDebugMode) {
                  print("⚠️ Write failed but continuing with profile");
                }
                break;
              }
            }
          }
        } else {
          await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(profile.toJson(), SetOptions(merge: true));
        }
        
        if (kDebugMode) {
          print('✅ Created new user profile');
        }
        return profile;
      } else {
        final profile = UserProfile.fromJson(doc.data()!);
        if (kDebugMode) {
          print('✅ Loaded existing user profile');
        }
        return profile;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in _loadUserProfile: $e');
      }
      
      // 🆕 ULTRA-AGGRESSIVE RETRY: One final attempt for iOS
      if (!kIsWeb && Platform.isIOS && 
          (e.toString().contains('path') || 
           e.toString().contains('permission') ||
           e.toString().contains('swift_getObjectType'))) {
        
        if (kDebugMode) {
          print('🔄 Final retry for iOS path/permission error...');
        }
        await Future.delayed(const Duration(milliseconds: 3000));
        
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
              print('✅ Final retry: created emergency profile');
            }
            return profile;
          } else {
            if (kDebugMode) {
              print('✅ Final retry: loaded existing profile');
            }
            return UserProfile.fromJson(doc.data()!);
          }
        } catch (retryError) {
          if (kDebugMode) {
            print('❌ Final retry also failed: $retryError');
          }
          
          // 🆕 EMERGENCY FALLBACK: Create offline profile
          final emergencyProfile = UserProfile.empty().copyWith(
            uid: uid,
            name: FirebaseAuth.instance.currentUser?.email ?? 'User',
          );
          if (kDebugMode) {
            print('🆘 Using emergency offline profile');
          }
          return emergencyProfile;
        }
      }
      
      rethrow;
    }
  }
}