import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../utils/user_profile_storage.dart';
import '../widgets/profile_reset_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
import 'package:flutter/foundation.dart';
import '../services/session_service.dart';
import '../utils/debug_loader.dart';
import 'liked_movies_screen.dart';
import 'matches_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile currentUser;
  final VoidCallback? onNavigateToMatches;

    const ProfileScreen({
    super.key, 
    required this.currentUser,
    this.onNavigateToMatches,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserProfile _profile;


  @override
  void initState() {
    super.initState();
    _profile = widget.currentUser;
  }

  void _refreshProfile() {
    setState(() {
      _profile = widget.currentUser;
    });
  }

  Future<void> _updateProfile(UserProfile updatedProfile) async {
    
    try {
      await UserProfileStorage.saveProfile(updatedProfile);
      setState(() {
        _profile = updatedProfile;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        ),
      );
    } finally {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header Section
              _buildHeaderSection(),
              
              // Content
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  children: [
                    // Stats Cards
                    _buildStatsSection(),
                    
                    SizedBox(height: 24.h),
                    
                    // Movie Preferences
                    _buildPreferencesSection(),
                    
                    SizedBox(height: 24.h),
                    
                    // Account Settings
                    _buildAccountSection(),
                    
                    SizedBox(height: 24.h),
                    
                    // App Settings
                    _buildAppSection(),
                    
                    SizedBox(height: 80.h), // Bottom padding for nav
                  ],
                ),
              ),
               if (kDebugMode) // Only shows in debug mode
                  Container(
                    margin: EdgeInsets.all(16.r),
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.red, width: 2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "🧹 DEBUG: Session Cleanup",
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Testing cleanup... check console')),
                                    );
                                    
                                    DebugLogger.log("🔍 === MANUAL CLEANUP TEST STARTED ===");
                                    
                                    // Check current sessions
                                    final beforeSnapshot = await FirebaseFirestore.instance
                                        .collection('swipeSessions')
                                        .get();
                                    
                                    DebugLogger.log("📊 Found ${beforeSnapshot.docs.length} total sessions");
                                    
                                    // Show session details
                                    for (int i = 0; i < beforeSnapshot.docs.length && i < 5; i++) {
                                      final doc = beforeSnapshot.docs[i];
                                      final data = doc.data();
                                      DebugLogger.log("Session ${i+1}: ${doc.id}");
                                      DebugLogger.log("  Created: ${data['createdAt']}");
                                      DebugLogger.log("  Status: ${data['status']}");
                                      
                                      if (data['createdAt'] != null) {
                                        try {
                                          final created = DateTime.parse(data['createdAt']);
                                          final age = DateTime.now().difference(created);
                                          DebugLogger.log("  Age: ${age.inHours}h ${age.inMinutes % 60}m");
                                          DebugLogger.log("  Would delete (24h rule): ${age.inHours > 24}");
                                        } catch (e) {
                                          DebugLogger.log("  Error parsing date: $e");
                                        }
                                      }
                                    }
                                    
                                    // Run cleanup
                                    DebugLogger.log("🧹 Running SessionService.performMaintenanceCleanup()...");
                                    await SessionService.performMaintenanceCleanup();
                                    
                                    // Check results
                                    final afterSnapshot = await FirebaseFirestore.instance
                                        .collection('swipeSessions')
                                        .get();
                                    
                                    final deleted = beforeSnapshot.docs.length - afterSnapshot.docs.length;
                                    DebugLogger.log("✅ CLEANUP COMPLETE!");
                                    DebugLogger.log("📊 Before: ${beforeSnapshot.docs.length} sessions");
                                    DebugLogger.log("📊 After: ${afterSnapshot.docs.length} sessions");
                                    DebugLogger.log("🗑️ Deleted: $deleted sessions");
                                    DebugLogger.log("🔍 === CLEANUP TEST FINISHED ===");
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Deleted $deleted sessions. Check console for details.'),
                                        backgroundColor: deleted > 0 ? Colors.green : Colors.orange,
                                      ),
                                    );
                                    
                                  } catch (e) {
                                    DebugLogger.log("❌ Cleanup test failed: $e");
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                child: Text("Test Cleanup", style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                              ),
                            ),
                            
                            SizedBox(width: 8.w),
                            
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    DebugLogger.log("🔥 === FORCE DELETE TEST STARTED ===");
                                    
                                    final now = DateTime.now();
                                    final cutoff = now.subtract(const Duration(hours: 1)); // 1 hour instead of 24
                                    
                                    final oldSessions = await FirebaseFirestore.instance
                                        .collection('swipeSessions')
                                        .where('createdAt', isLessThan: cutoff.toIso8601String())
                                        .get();
                                    
                                    DebugLogger.log("📊 Found ${oldSessions.docs.length} sessions older than 1 hour");
                                    
                                    if (oldSessions.docs.isNotEmpty) {
                                      final batch = FirebaseFirestore.instance.batch();
                                      
                                      for (final doc in oldSessions.docs) {
                                        DebugLogger.log("🗑️ Deleting: ${doc.id}");
                                        batch.delete(doc.reference);
                                      }
                                      
                                      await batch.commit();
                                      DebugLogger.log("✅ Force deleted ${oldSessions.docs.length} sessions!");
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Force deleted ${oldSessions.docs.length} sessions!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      DebugLogger.log("ℹ️ No sessions older than 1 hour found");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('No sessions old enough (1h+)'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                    
                                    DebugLogger.log("🔥 === FORCE DELETE TEST FINISHED ===");
                                    
                                  } catch (e) {
                                    DebugLogger.log("❌ Force delete failed: $e");
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text("Force Delete", style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 8.h),
                        
                        // Nuclear option
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                DebugLogger.log("💥 === DELETING ALL SESSIONS ===");
                                
                                final allSessions = await FirebaseFirestore.instance
                                    .collection('swipeSessions')
                                    .get();
                                
                                DebugLogger.log("📊 Found ${allSessions.docs.length} total sessions to delete");
                                
                                if (allSessions.docs.isNotEmpty) {
                                  final batch = FirebaseFirestore.instance.batch();
                                  
                                  for (final doc in allSessions.docs) {
                                    batch.delete(doc.reference);
                                  }
                                  
                                  await batch.commit();
                                  DebugLogger.log("💥 DELETED ALL ${allSessions.docs.length} SESSIONS!");
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('DELETED ALL ${allSessions.docs.length} sessions!'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                
                              } catch (e) {
                                DebugLogger.log("❌ Delete all failed: $e");
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                            child: Text("🚨 DELETE ALL SESSIONS", style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                          ),
                        ),

                        SizedBox(height: 8.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                DebugLogger.log("🧪 === TESTING INVITATION FLOW ===");
                                
                                final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                if (currentUserId == null) {
                                  DebugLogger.log("❌ No current user");
                                  return;
                                }
                                
                                final invitationsSnapshot = await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUserId)
                                    .collection('pending_invitations')
                                    .get();
                                
                                DebugLogger.log("📨 Found ${invitationsSnapshot.docs.length} pending invitations");
                                
                                if (invitationsSnapshot.docs.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('No pending invitations to test'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                final firstInvite = invitationsSnapshot.docs.first;
                                final inviteData = firstInvite.data();
                                
                                DebugLogger.log("🎯 Testing invitation: ${firstInvite.id}");
                                DebugLogger.log("   From: ${inviteData['fromUserName']}");
                                DebugLogger.log("   Session: ${inviteData['sessionId']}");
                                
                                final session = await SessionService.acceptInvitation(
                                  inviteData['sessionId'],
                                  widget.currentUser.name,
                                );
                                
                                if (session != null) {
                                  DebugLogger.log("✅ Successfully accepted invitation!");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('✅ Invitation test successful!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  DebugLogger.log("❌ Failed to accept invitation");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('❌ Invitation test failed'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                
                              } catch (e) {
                                DebugLogger.log("❌ Invitation test failed: $e");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('❌ Test failed: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: Text("🧪 Test Accept Invitation", style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                          ),
                        ),

                        SizedBox(height: 8.h),
                        
                        SizedBox(height: 8.h),
                        Text(
                          "⚠️ Debug only - check console for logs",
                          style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF121212),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Avatar
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE5A00D),
                  const Color(0xFFFF8A00),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  blurRadius: 20.r,
                  spreadRadius: 2.r,
                ),
              ],
            ),
            child: Center(
              child: Text(
                _profile.name.isNotEmpty ? _profile.name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Name and Edit Button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _profile.name.isNotEmpty ? _profile.name : 'Your Name',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              IconButton(
                onPressed: _showEditNameDialog,
                icon: Icon(
                  Icons.edit,
                  color: const Color(0xFFE5A00D),
                  size: 20.sp,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          // Member Since
          Text(
            'Member since January 2025',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final Map<String, int> genreCount = {};
    for (final movie in _profile.likedMovies) {
      for (final genre in movie.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }
    final topGenre = genreCount.entries.isNotEmpty 
        ? genreCount.entries.reduce((a, b) => a.value > b.value ? a : b).key
        : 'None';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Movie Stats',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        Row(
          children: [
            Expanded(
              child: _buildInteractiveStatCard(
                'Movies Liked',
                _profile.likedMovieIds.length.toString(),
                Icons.favorite,
                Colors.red,
                _navigateToLikedMovies, // Updated to use new navigation
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildInteractiveStatCard(
                'Matches',
                _profile.matchHistory.length.toString(),
                Icons.movie_filter,
                Colors.green,
                _navigateToMatches,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 12.h),
        
        Row(
          children: [
            Expanded(
              child: _buildInteractiveStatCard(
                'Top Genre',
                topGenre,
                Icons.category,
                const Color(0xFFE5A00D),
                () => _showGenreAnalytics(genreCount),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildInteractiveStatCard(
                'Preferences',
                _profile.preferredGenres.length.toString(),
                Icons.tune,
                Colors.purple,
                _showPreferencesEditor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractiveStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'TAP TO VIEW',
                style: TextStyle(
                  color: color,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _buildSettingsTile(
          title: 'Reset Preferences',
          subtitle: 'Clear your genres and vibes to start fresh',
          icon: Icons.refresh,
          onTap: _showResetPreferencesDialog,
        ),
      ],
    );
  }



  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 16.h),

        _buildCreateTestUsersButton(),
        
        _buildSettingsTile(
          title: 'Profile Information',
          subtitle: 'Edit your name and details',
          icon: Icons.person,
          onTap: _showEditNameDialog,
        ),
        
        _buildSettingsTile(
          title: 'Reset Profile',
          subtitle: 'Reset your profile for testing',
          icon: Icons.restore,
          onTap: _showResetProfileDialog,
        ),
      ],
    );
  }
  

  Widget _buildAppSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _buildSettingsTile(
          title: 'Help & Support',
          subtitle: 'Get help using the app',
          icon: Icons.help_outline,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support coming soon')),
            );
          },
        ),
        
        _buildSettingsTile(
          title: 'About',
          subtitle: 'App version and information',
          icon: Icons.info_outline,
          onTap: _showAboutDialog,
        ),
        
        // Testing Panel Section
        SizedBox(height: 24.h),
        
        Text(
          'Testing',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        SizedBox(height: 24.h),
        
        _buildSettingsTile(
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          icon: Icons.logout,
          onTap: _showLogoutConfirmation,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDestructive 
                        ? Colors.red.withValues(alpha: 0.2)
                        : const Color(0xFFE5A00D).withValues(alpha: 0.2),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : const Color(0xFFE5A00D),
                    size: 20.sp,
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? Colors.red : Colors.white,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation and Interactive Methods
  void _navigateToMatches() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchesScreen(
          currentUser: _profile,
          onProfileUpdate: (updatedProfile) {
            setState(() {
              _profile = updatedProfile;
            });
          },
        ),
      ),
    );
  }

  void _navigateToLikedMovies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LikedMoviesScreen(
          currentUser: _profile,
          onProfileUpdate: (updatedProfile) {
            setState(() {
              _profile = updatedProfile;
            });
          },
        ),
      ),
    );
  }

  void _showPreferencesEditor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Text(
                      'Movie Preferences',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Genres Section
                      Text(
                        'Favorite Genres',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      if (_profile.preferredGenres.isEmpty)
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'No genres selected yet. Complete onboarding to set your preferences.',
                            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _profile.preferredGenres.map((genre) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: const Color(0xFFE5A00D), width: 1.w),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: const Color(0xFFE5A00D),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                      
                      SizedBox(height: 24.h),
                      
                      // Vibes Section
                      Text(
                        'Preferred Vibes',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      
                      if (_profile.preferredVibes.isEmpty)
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'No vibes selected yet. Complete onboarding to set your preferences.',
                            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _profile.preferredVibes.map((vibe) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: Colors.purple, width: 1.w),
                            ),
                            child: Text(
                              vibe,
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                      
                      SizedBox(height: 32.h),
                      
                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _showResetPreferencesDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Reset Preferences',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenreAnalytics(Map<String, int> genreCount) {
    if (genreCount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Like some movies first to see your genre breakdown!')),
      );
      return;
    }

    final sortedGenres = genreCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, color: const Color(0xFFE5A00D), size: 24.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Your Genre Breakdown',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                    ),
                  ],
                ),
              ),
              
              // Genre bars
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: sortedGenres.length,
                  itemBuilder: (context, index) {
                    final entry = sortedGenres[index];
                    final percentage = (entry.value / _profile.likedMovies.length * 100).round();
                    final colors = [
                      const Color(0xFFE5A00D), Colors.red, Colors.blue, Colors.green, 
                      Colors.purple, Colors.orange, Colors.teal, Colors.pink,
                    ];
                    final color = colors[index % colors.length];
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${entry.value} movies ($percentage%)',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            height: 8.h,
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percentage / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Reset Preferences',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          'This will clear all your genre and vibe preferences. You can set them again by going through onboarding or the matcher screen.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedProfile = _profile.copyWith(
                preferredGenres: <String>{},
                preferredVibes: <String>{},
              );
              await _updateProfile(updatedProfile);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Reset', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }
  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _profile.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Edit Name',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.white30, fontSize: 16.sp),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(color: const Color(0xFFE5A00D), width: 2.w),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedProfile = _profile.copyWith(name: nameController.text.trim());
              await _updateProfile(updatedProfile);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A00D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Save', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTestUsersButton() {
  return ElevatedButton(
    onPressed: () async {
      final testUsers = [
        {
          'uid': 'alice_demo_123',
          'name': 'Alice Johnson',
          'preferredGenres': ['Action', 'Comedy'],
          'preferredVibes': ['Feel-good', 'Exciting'],
          'likedMovieIds': ['movie1', 'movie2'],
          'friendIds': [],
          'hasCompletedOnboarding': true,
          'genreScores': {'Action': 8.0, 'Comedy': 7.5},
          'vibeScores': {'Feel-good': 9.0},
        },
        {
          'uid': 'bob_demo_456',
          'name': 'Bob Smith',
          'preferredGenres': ['Drama', 'Thriller'],
          'preferredVibes': ['Dark', 'Mysterious'],
          'likedMovieIds': ['movie3', 'movie4'],
          'friendIds': [],
          'hasCompletedOnboarding': true,
          'genreScores': {'Drama': 9.0, 'Thriller': 8.5},
          'vibeScores': {'Dark': 8.0},
        },
        {
          'uid': 'carol_demo_789',
          'name': 'Carol Williams',
          'preferredGenres': ['Romance', 'Comedy'],
          'preferredVibes': ['Heartwarming', 'Feel-good'],
          'likedMovieIds': ['movie5', 'movie6'],
          'friendIds': [],
          'hasCompletedOnboarding': true,
          'genreScores': {'Romance': 9.5, 'Comedy': 8.0},
          'vibeScores': {'Heartwarming': 9.0},
        },
      ];

      for (final userData in testUsers) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userData['uid'] as String)
            .set(userData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test users created! You can now search for Alice, Bob, or Carol')),
      );
    },
    child: const Text('Create Test Users'),
  );
}
  // Dialog Methods

  void _showResetProfileDialog() {
    showDialog(
      context: context,
      builder: (_) => ProfileResetDialog(
        currentUser: _profile,
        onProfileReset: _refreshProfile,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'About QueueTogether',
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'Find movies to watch together with friends and family. Swipe, match, and discover your next favorite film!',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: const Color(0xFFE5A00D), fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  // Keep your existing logout functionality
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          "Sign Out",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          "Are you sure you want to sign out? You'll need to log back in to access your profile.",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(
              "Sign Out",
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }
}