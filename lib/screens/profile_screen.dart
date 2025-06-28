import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
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
    _loadSessionBasedMatches();
  }

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
            padding: EdgeInsets.only(
              // ✅ FIXED: Proper bottom padding calculation for custom navigation bar
              bottom: 120.h, // Increased to ensure no overlap with navigation bar
            ),
            child: Column(
              children: [
                // Header Section
                _buildProfileHeader(),
                
                SizedBox(height: 24.h),
                
                // Stats Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildStatsSection(),
                ),
                
                SizedBox(height: 32.h),
                
                // Account Settings Section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildAccountSection(),
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
      padding: EdgeInsets.all(20.w),
      margin: EdgeInsets.all(20.w),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 180.h, // ✅ FIXED: Reduced height to prevent overflow
        borderRadius: 20,
        blur: 15,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.15),
            Colors.orange.shade600.withValues(alpha: 0.1),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.6),
            Colors.orange.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w), // ✅ FIXED: Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // ✅ FIXED: Center content
            children: [
              // Profile Avatar
              Container(
                width: 80.w, // ✅ FIXED: Reduced size
                height: 80.w,
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
                      blurRadius: 15.r, // ✅ FIXED: Reduced blur
                      spreadRadius: 2.r,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _profile.name.isNotEmpty ? _profile.name[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 28.sp, // ✅ FIXED: Reduced font size
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 12.h), // ✅ FIXED: Reduced spacing
              
              // Name and Edit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible( // ✅ FIXED: Made text flexible
                    child: Text(
                      _profile.name.isNotEmpty ? _profile.name : 'No Name Set',
                      style: TextStyle(
                        fontSize: 20.sp, // ✅ FIXED: Reduced font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  GestureDetector(
                    onTap: _showEditNameDialog,
                    child: Container(
                      padding: EdgeInsets.all(6.w), // ✅ FIXED: Reduced padding
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                          width: 1.w,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: const Color(0xFFE5A00D),
                        size: 14.sp, // ✅ FIXED: Reduced icon size
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 6.h), // ✅ FIXED: Reduced spacing
              
              Flexible( // ✅ FIXED: Made email flexible
                child: Text(
                  _profile.email,
                  style: TextStyle(
                    fontSize: 14.sp, // ✅ FIXED: Reduced font size
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    // Calculate genre stats
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
              child: _buildStatCard(
                'Movies Liked',
                _profile.likedMovieIds.length.toString(),
                Icons.favorite,
                Colors.red,
                _navigateToLikedMovies,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
                'Matches',
                '${_profile.totalMatches}',
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
              child: _buildStatCard(
                'Top Genre',
                topGenre,
                Icons.category,
                const Color(0xFFE5A00D),
                () => _showGenreAnalytics(genreCount),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatCard(
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 130.h, // ✅ FIXED: Reduced height to prevent overflow
        borderRadius: 16,
        blur: 10,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.6),
            color.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.w), // ✅ FIXED: Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.w), // ✅ FIXED: Reduced padding
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20.sp, // ✅ FIXED: Reduced icon size
                ),
              ),
              
              SizedBox(height: 6.h), // ✅ FIXED: Reduced spacing
              
              Text(
                value,
                style: TextStyle(
                  fontSize: 18.sp, // ✅ FIXED: Reduced font size
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 2.h), // ✅ FIXED: Reduced spacing
              
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp, // ✅ FIXED: Reduced font size
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 4.h), // ✅ FIXED: Reduced spacing
              
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), // ✅ FIXED: Reduced padding
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'TAP TO VIEW',
                  style: TextStyle(
                    fontSize: 7.sp, // ✅ FIXED: Reduced font size
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _buildSettingsTile(
          title: 'Change Name',
          subtitle: 'Update your display name',
          icon: Icons.person,
          color: const Color(0xFFE5A00D),
          onTap: _showEditNameDialog,
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'Change Email',
          subtitle: 'Update your email address',
          icon: Icons.email,
          color: Colors.blue,
          onTap: _showChangeEmailDialog,
        ),
        
        SizedBox(height: 8.h),
        
        _buildSettingsTile(
          title: 'Change Password',
          subtitle: 'Update your password',
          icon: Icons.lock,
          color: Colors.green,
          onTap: _showChangePasswordDialog,
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
        margin: EdgeInsets.only(bottom: 4.h),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 70.h, // ✅ FIXED: Slightly reduced height
          borderRadius: 12,
          blur: 10,
          alignment: Alignment.centerLeft,
          border: 1,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDestructive 
                ? [
                    Colors.red.withValues(alpha: 0.1),
                    Colors.red.withValues(alpha: 0.05),
                  ]
                : [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                  ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDestructive 
                ? [
                    Colors.red.withValues(alpha: 0.6),
                    Colors.red.withValues(alpha: 0.3),
                  ]
                : [
                    color.withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.2),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.all(14.w), // ✅ FIXED: Slightly reduced padding
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w), // ✅ FIXED: Reduced padding
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18.sp, // ✅ FIXED: Reduced icon size
                  ),
                ),
                
                SizedBox(width: 14.w), // ✅ FIXED: Reduced spacing
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15.sp, // ✅ FIXED: Reduced font size
                          fontWeight: FontWeight.w600,
                          color: isDestructive ? Colors.red : Colors.white,
                        ),
                      ),
                      SizedBox(height: 1.h), // ✅ FIXED: Reduced spacing
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.sp, // ✅ FIXED: Reduced font size
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 18.sp, // ✅ FIXED: Reduced icon size
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Navigation Methods
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

  // Dialog Methods
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
          'Change Name',
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
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final updatedProfile = _profile.copyWith(name: newName);
                await _updateProfile(updatedProfile);
                Navigator.pop(context);
              }
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

  void _showChangeEmailDialog() {
    final emailController = TextEditingController(text: _profile.email);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.blue.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Change Email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'Enter new email',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.h),
            Text(
              'You will need to verify your new email address.',
              style: TextStyle(color: Colors.white60, fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newEmail = emailController.text.trim();
              if (newEmail.isNotEmpty && newEmail.contains('@')) {
                try {
                  await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(newEmail);
                  final updatedProfile = _profile.copyWith(email: newEmail);
                  await _updateProfile(updatedProfile);
                  Navigator.pop(context);
                  ThemedNotifications.showSuccess(context, 'Email updated successfully', icon: "📧");
                } catch (e) {
                  ThemedNotifications.showError(context, 'Error updating email: ${e.toString()}');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Update', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: Colors.green.withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'Current password',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: newPasswordController,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'New password',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: confirmPasswordController,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green.withValues(alpha: 0.3)),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54, fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPassword = currentPasswordController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();
              
              if (newPassword != confirmPassword) {
                ThemedNotifications.showError(context, 'New passwords do not match');
                return;
              }
              
              if (newPassword.length < 6) {
                ThemedNotifications.showError(context, 'Password must be at least 6 characters');
                return;
              }
              
              try {
                final user = FirebaseAuth.instance.currentUser;
                final credential = EmailAuthProvider.credential(
                  email: user!.email!,
                  password: currentPassword,
                );
                
                await user.reauthenticateWithCredential(credential);
                await user.updatePassword(newPassword);
                
                Navigator.pop(context);
                ThemedNotifications.showSuccess(context, 'Password updated successfully', icon: "🔒");
              } catch (e) {
                ThemedNotifications.showError(context, 'Error updating password: ${e.toString()}');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Update', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
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
          ElevatedButton(
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
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
          ),
        ],
      ),
    );
  }

  // Simple popup methods for stats
  void _showGenreAnalytics(Map<String, int> genreCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Your Top Genres', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        content: genreCount.isEmpty
            ? Text('Like some movies to see your genre preferences!', 
                style: TextStyle(color: Colors.white70, fontSize: 14.sp))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: () {
                  final sortedEntries = genreCount.entries.toList();
                  sortedEntries.sort((a, b) => b.value.compareTo(a.value));
                  return sortedEntries
                      .take(5)
                      .map((entry) => Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: TextStyle(color: Colors.white, fontSize: 14.sp)),
                            Text('${entry.value} movies', 
                              style: TextStyle(color: const Color(0xFFE5A00D), fontSize: 14.sp)),
                          ],
                        ),
                      ))
                      .toList();
                }(),
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

  void _showSessionHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Session History', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        content: SizedBox(
          width: double.maxFinite,
          height: 200.h,
          child: _profile.sessionHistory.isEmpty
              ? Center(
                  child: Text('No sessions yet. Start swiping to build your history!',
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
                          Text(
                            session.type.name.toUpperCase(),
                            style: TextStyle(
                              color: const Color(0xFFE5A00D),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
}