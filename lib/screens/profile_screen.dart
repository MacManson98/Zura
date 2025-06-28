import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../utils/completed_session.dart';
import '../utils/themed_notifications.dart';
import '../utils/user_profile_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/auth/login_screen.dart';
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
    _loadSessionBasedMatches(); // Fix matches count on load
  }

  // ✅ FIX: Load and count matches from all sessions properly
  Future<void> _loadSessionBasedMatches() async {
    try {
      DebugLogger.log("🔍 Loading session-based matches...");
      final allSessions = await _profile.getAllSessionsForDisplay();
      
      int totalMatches = 0;
      for (final session in allSessions) {
        if (session.type != SessionType.solo) {
          totalMatches += session.matchedMovieIds.length;
        }
      }
      
      DebugLogger.log("📊 Total matches found across sessions: $totalMatches");
      DebugLogger.log("📊 Profile.totalMatches getter returns: ${_profile.totalMatches}");
      
      if (mounted) {
        setState(() {
          // Trigger UI update to reflect correct count
        });
      }
    } catch (e) {
      DebugLogger.log("❌ Error loading session matches: $e");
    }
  }

  Future<void> _updateProfile(UserProfile updatedProfile) async {
    try {
      await UserProfileStorage.saveProfile(updatedProfile);
      setState(() {
        _profile = updatedProfile;
      });
      
      ThemedNotifications.showSuccess(context, 'Profile updated successfully', icon: "✅");
    } catch (e) {
      ThemedNotifications.showError(context, 'Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF121212),
              const Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Header Section
                _buildProfileHeader(),
                
                SizedBox(height: 24.h),
                
                // Stats Section with enhanced details
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildStatsSection(),
                ),
                
                SizedBox(height: 32.h),
                
                // Customization Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildCustomizationSection(),
                ),
                
                SizedBox(height: 32.h),
                
                // Account Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildAccountSection(),
                ),
                
                SizedBox(height: 32.h),
                
                // App Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildAppSection(),
                ),
                
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      margin: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1F1F1F),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar with enhanced styling
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
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                  blurRadius: 20.r,
                  spreadRadius: 4.r,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
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
                _profile.name.isNotEmpty ? _profile.name : 'No Name Set',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 12.w),
              GestureDetector(
                onTap: _showEditNameDialog,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: const Color(0xFFE5A00D),
                    size: 16.sp,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            _profile.email,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    // ✅ FIX: Calculate genre stats properly
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
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
                _navigateToLikedMovies,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildInteractiveStatCard(
                'Matches',
                '${_profile.totalMatches}', // ✅ FIX: Show session type info
                Icons.movie_filter,
                Colors.green,
                _navigateToMatches,
                subtitle: _getMatchesSubtitle(),
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
                'Sessions',
                _profile.totalSessions.toString(),
                Icons.history,
                Colors.purple,
                () => _showSessionHistory(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ NEW: Get subtitle for matches card showing session types
  String _getMatchesSubtitle() {
    final collaborativeSessions = _profile.sessionHistory
        .where((s) => s.type != SessionType.solo && s.matchedMovieIds.isNotEmpty)
        .toList();
    
    if (collaborativeSessions.isEmpty) return "Tap to find matches";
    
    final friendSessions = collaborativeSessions.where((s) => s.type == SessionType.friend).length;
    final groupSessions = collaborativeSessions.where((s) => s.type == SessionType.group).length;
    
    if (friendSessions > 0 && groupSessions > 0) {
      return "$friendSessions friend, $groupSessions group";
    } else if (friendSessions > 0) {
      return "$friendSessions friend session${friendSessions == 1 ? '' : 's'}";
    } else if (groupSessions > 0) {
      return "$groupSessions group session${groupSessions == 1 ? '' : 's'}";
    }
    
    return "From collaborative sessions";
  }

  Widget _buildInteractiveStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap, {String? subtitle}) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, animationValue, child) {
          return Transform.scale(
            scale: 0.95 + (animationValue * 0.05),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.1),
                    color.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
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
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24.sp,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  SizedBox(height: 8.h),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'TAP TO VIEW',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ NEW: Enhanced customization section
  Widget _buildCustomizationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customize Your Experience',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _buildSettingsTile(
          title: 'Movie Preferences',
          subtitle: 'Set your favorite genres and vibes',
          icon: Icons.tune,
          color: const Color(0xFFE5A00D),
          onTap: _showPreferencesEditor,
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'Notification Settings',
          subtitle: 'Manage your app notifications',
          icon: Icons.notifications,
          color: Colors.blue,
          onTap: _showNotificationSettings,
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'Display Options',
          subtitle: 'Theme and appearance settings',
          icon: Icons.palette,
          color: Colors.purple,
          onTap: _showDisplaySettings,
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'Privacy Settings',
          subtitle: 'Control your data and visibility',
          icon: Icons.privacy_tip,
          color: Colors.teal,
          onTap: _showPrivacySettings,
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _buildSettingsTile(
          title: 'Profile Information',
          subtitle: 'Edit your name and details',
          icon: Icons.person,
          color: const Color(0xFFE5A00D),
          onTap: _showEditNameDialog,
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'Friends & Groups',
          subtitle: 'Manage your connections',
          icon: Icons.group,
          color: Colors.green,
          onTap: _showFriendsAndGroups,
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'Data & Storage',
          subtitle: 'Manage app data and cache',
          icon: Icons.storage,
          color: Colors.orange,
          onTap: _showDataSettings,
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
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _buildSettingsTile(
          title: 'Help & Support',
          subtitle: 'Get help using the app',
          icon: Icons.help_outline,
          color: Colors.blue,
          onTap: () {
            ThemedNotifications.showInfo(context, 'Help & Support coming soon', icon: "🚧");
          },
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'About',
          subtitle: 'App version and information',
          icon: Icons.info_outline,
          color: Colors.teal,
          onTap: _showAboutDialog,
        ),
        
        SizedBox(height: 16.h),
        
        _buildSettingsTile(
          title: 'Sign Out',
          subtitle: 'Sign out of your account',
          icon: Icons.logout,
          color: Colors.red,
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
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.only(bottom: 4.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A2A2A),
              const Color(0xFF1F1F1F),
            ],
          ),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDestructive 
                ? Colors.red.withValues(alpha: 0.3)
                : color.withValues(alpha: 0.2),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4.r,
              offset: Offset(0, 1.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                icon,
                color: color,
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
                      fontSize: 13.sp,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.4),
              size: 20.sp,
            ),
          ],
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
    // For now, show a placeholder dialog until preferences editor is implemented
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Movie Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Advanced preferences editor coming soon!',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              'For now, you can set preferences by going through the matcher screens.',
              style: TextStyle(color: Colors.white60, fontSize: 12.sp),
              textAlign: TextAlign.center,
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

  void _showGenreAnalytics(Map<String, int> genreCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Your Genre Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (genreCount.isEmpty)
                Text(
                  'No genre data available. Like some movies to see your preferences!',
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                )
              else
                // Fix: Create the widget list first, then spread it
                ..._buildGenreWidgets(genreCount)
            ],
          ),
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

  // Helper method to build genre widgets
  List<Widget> _buildGenreWidgets(Map<String, int> genreCount) {
    final sortedEntries = genreCount.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(5).map((entry) => Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            entry.key,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
          Text(
            '${entry.value} movies',
            style: TextStyle(color: const Color(0xFFE5A00D), fontSize: 14.sp),
          ),
        ],
      ),
    )).toList();
  }

  // ✅ NEW: Show session history
  void _showSessionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Your Session History',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300.h,
          child: _profile.sessionHistory.isEmpty
              ? Center(
                  child: Text(
                    'No sessions yet. Start swiping to build your history!',
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: _profile.sessionHistory.length,
                  itemBuilder: (context, index) {
                    final session = _profile.sessionHistory[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                session.type == SessionType.solo 
                                    ? Icons.person 
                                    : session.type == SessionType.friend 
                                        ? Icons.people 
                                        : Icons.group,
                                color: const Color(0xFFE5A00D),
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                session.type.name.toUpperCase(),
                                style: TextStyle(
                                  color: const Color(0xFFE5A00D),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          if (session.type != SessionType.solo)
                            Text(
                              'With: ${session.getOtherParticipantsDisplay(_profile.name)}',
                              style: TextStyle(color: Colors.white, fontSize: 13.sp),
                            ),
                          Text(
                            'Matches: ${session.matchedMovieIds.length}',
                            style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

  // ✅ NEW: Customization methods
  void _showNotificationSettings() {
    ThemedNotifications.showInfo(context, 'Notification settings coming soon', icon: "🔔");
  }

  void _showDisplaySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Display Options',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleOption(
              'Dark Mode',
              'Use dark theme throughout the app',
              true, // Always true for now
              (value) {
                ThemedNotifications.showInfo(context, 'Theme switching coming soon', icon: "🎨");
              },
            ),
            SizedBox(height: 16.h),
            _buildToggleOption(
              'Show Animations',
              'Enable smooth transitions and effects',
              true,
              (value) {
                ThemedNotifications.showInfo(context, 'Animation controls coming soon', icon: "✨");
              },
            ),
            SizedBox(height: 16.h),
            _buildToggleOption(
              'Compact View',
              'Show more content in lists',
              false,
              (value) {
                ThemedNotifications.showInfo(context, 'View options coming soon', icon: "📋");
              },
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

  void _showPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Privacy Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildToggleOption(
              'Profile Visibility',
              'Allow friends to see your profile',
              true,
              (value) {
                ThemedNotifications.showInfo(context, 'Privacy controls coming soon', icon: "🔒");
              },
            ),
            SizedBox(height: 16.h),
            _buildToggleOption(
              'Activity Status',
              'Show when you\'re online',
              false,
              (value) {
                ThemedNotifications.showInfo(context, 'Status controls coming soon', icon: "🟢");
              },
            ),
            SizedBox(height: 16.h),
            _buildToggleOption(
              'Data Analytics',
              'Help improve the app with usage data',
              true,
              (value) {
                ThemedNotifications.showInfo(context, 'Analytics settings coming soon', icon: "📊");
              },
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

  void _showFriendsAndGroups() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Friends & Groups',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Friends: ${_profile.friendIds.length}',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Groups: ${_profile.groupIds.length}',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            SizedBox(height: 16.h),
            Text(
              'Friend and group management features are coming soon!',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              textAlign: TextAlign.center,
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

  void _showDataSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Data & Storage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cached Movies: ${_profile.likedMovies.length}',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Session History: ${_profile.sessionHistory.length} sessions',
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showClearCacheConfirmation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: BorderSide(color: Colors.orange, width: 1.w),
                  ),
                ),
                child: Text(
                  'Clear Movie Cache',
                  style: TextStyle(color: Colors.orange, fontSize: 14.sp),
                ),
              ),
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

  Widget _buildToggleOption(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFFE5A00D),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  void _showClearCacheConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.orange.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Clear Movie Cache',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will clear cached movie data but keep your likes and session history. The app will re-download movie details as needed.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ElevatedButton(
              onPressed: () async {
                // Clear movie cache but keep IDs
                final clearedProfile = _profile.copyWith();
                // Reset cached movies but keep the IDs
                clearedProfile.likedMovies = {};
                
                await _updateProfile(clearedProfile);
                Navigator.pop(context);
                ThemedNotifications.showSuccess(context, 'Movie cache cleared', icon: "🗑️");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('Clear Cache', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
            ),
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
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Edit Profile Name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: const Color(0xFFE5A00D)),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  final updatedProfile = _profile.copyWith(name: newName);
                  await _updateProfile(updatedProfile);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('Save', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'About QueueTogether',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
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
            SizedBox(height: 16.h),
            Text(
              '© 2024 QueueTogether',
              style: TextStyle(color: Colors.white54, fontSize: 12.sp),
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

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.red.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  ThemedNotifications.showError(context, 'Error signing out: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
            ),
          ),
        ],
      ),
    );
  }
}