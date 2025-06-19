// File: lib/auth_gate.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/login_screen.dart';
import 'main_navigation.dart';
import 'models/user_profile.dart';
import 'movie.dart';
import 'utils/tmdb_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/debug_loader.dart';
import 'services/session_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE5A00D),
              ),
            ),
          );
        }

        final user = snapshot.data;
        DebugLogger.log('🔥 Auth state changed:');
        DebugLogger.log('  user: $user');
        DebugLogger.log('  isAnonymous: ${user?.isAnonymous}');
        DebugLogger.log('  uid: ${user?.uid}');
        
        if (user == null || user.isAnonymous) {
          DebugLogger.log('➡️ Showing LoginScreen');
          return const LoginScreen();
        }

        return FutureBuilder<UserProfileScreenBundle>(
          future: _loadUserProfileAndMovies(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFF121212),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.movie_filter,
                        size: 64,
                        color: Color(0xFFE5A00D),
                      ),
                      SizedBox(height: 24),
                      CircularProgressIndicator(
                        color: Color(0xFFE5A00D),
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
              DebugLogger.log('❌ Error loading profile: ${snapshot.error}');
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
                      // 🆕 FIXED: Retry without signing out
                      ElevatedButton(
                        onPressed: () {
                          // Force rebuild to retry loading
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
                      // 🆕 SEPARATE: Sign out option if user wants it
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

            // 🆕 OPTIONAL: Add cleanup after successful authentication
            final data = snapshot.data!;

            // Add this line after successful profile load:
            _performPostAuthCleanup();

            DebugLogger.log('➡️ Going directly to MainNavigation');
            return MainNavigation(
              profile: data.profile, 
              movies: data.movies,
            );
          },
        );
      },
    );
  }
  Future<void> _performPostAuthCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt('last_cleanup') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Run cleanup every 6 hours, but only after authentication
      if (now - lastCleanup > 6 * 60 * 60 * 1000) {
        DebugLogger.log("🧹 Starting post-auth cleanup...");
        await SessionService.performMaintenanceCleanup();
        await prefs.setInt('last_cleanup', now);
        DebugLogger.log("✅ Post-auth cleanup completed");
      }
    } catch (e) {
      DebugLogger.log("Note: Post-auth cleanup failed: $e");
    }
  }

  Future<UserProfileScreenBundle> _loadUserProfileAndMovies(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      late final UserProfile profile;

      if (!doc.exists) {
        // ✅ NEW USERS: Create profile and save to database
        profile = UserProfile.empty().copyWith(
          uid: uid,
          name: FirebaseAuth.instance.currentUser?.email ?? '',
        );
        await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(profile.toJson(), SetOptions(merge: true));
        
        DebugLogger.log('✅ Created new user profile');
      } else {
        // ✅ EXISTING USERS: Load their profile
        profile = UserProfile.fromJson(doc.data()!);
        DebugLogger.log('✅ Loaded existing user profile');
      }

      final movies = await TMDBApi.getPopularMovies();
      return UserProfileScreenBundle(profile, movies);
    } catch (e) {
      DebugLogger.log('❌ Error in _loadUserProfileAndMovies: $e');
      rethrow;
    }
  }
}

class UserProfileScreenBundle {
  final UserProfile profile;
  final List<Movie> movies;

  UserProfileScreenBundle(this.profile, this.movies);
}