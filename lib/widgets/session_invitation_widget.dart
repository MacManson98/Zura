// File: lib/widgets/session_invitation_widget.dart
// Part 1: Imports and main SessionInvitationWidget class

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:share_plus/share_plus.dart';
import '../models/session_models.dart';
import '../services/session_service.dart';
import '../models/user_profile.dart';
import '../utils/mood_based_learning_engine.dart';
import 'mood_selection_widget.dart';

class SessionInvitationWidget extends StatefulWidget {
  final UserProfile currentUser;
  final List<UserProfile> friendIds;
  final Function(SwipeSession session) onSessionCreated;

  const SessionInvitationWidget({
    super.key,
    required this.currentUser,
    required this.friendIds,
    required this.onSessionCreated,
  });

  @override
  State<SessionInvitationWidget> createState() => _SessionInvitationWidgetState();
}

class _SessionInvitationWidgetState extends State<SessionInvitationWidget> {
  bool _isCreatingSession = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF161616),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 24.h),
          
          // Header with icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                      blurRadius: 12.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.movie_filter,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Swipe Together",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    "Find movies you'll both love",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 32.h),
          
          // Primary action button
          _buildPrimaryInviteButton(),
          
          SizedBox(height: 24.h),
          
          // Divider
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Text(
                  "OR",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24.h),
          
          // Secondary options
          Row(
            children: [
              Expanded(
                child: _buildSecondaryOption(
                  icon: Icons.person_add_outlined,
                  title: "Invite Friend",
                  subtitle: "Pick 1 friend & mood",
                  onTap: _showFriendSelector,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSecondaryOption(
                  icon: Icons.login,
                  title: "Join Session",
                  subtitle: "Enter code",
                  onTap: _showJoinSessionDialog,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
  // Part 2: Build methods for buttons and UI components

  Widget _buildPrimaryInviteButton() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 64.h,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          const Color(0xFFE5A00D).withValues(alpha: 0.9),
          Colors.orange.shade600.withValues(alpha: 0.9),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFFE5A00D),
          Colors.orange.shade600,
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCreatingSession ? null : _createAndShareSession,
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isCreatingSession)
                  SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.share,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                SizedBox(width: 12.w),
                Text(
                  _isCreatingSession ? "Creating Session..." : "Create & Share Code",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 100.h,
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.04),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isCreatingSession ? null : onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFFE5A00D),
                    size: 24.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  // Part 3: Session creation and mood selection methods

  // Create session with mood selection dialog
  Future<void> _createAndShareSession() async {
    setState(() => _isCreatingSession = true);
    
    try {
      final selectedMood = await _showMoodSelectionDialog();
      
      if (selectedMood == null) {
        setState(() => _isCreatingSession = false);
        return;
      }
      
      final session = await SessionService.createSession(
        hostName: widget.currentUser.name,
        inviteType: InvitationType.code,
        selectedMood: selectedMood,
      );
      
      if (mounted) {
        widget.onSessionCreated(session);
        _showShareOptionsDialog(session.sessionCode!, selectedMood);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingSession = false);
    }
  }

  Future<CurrentMood?> _showMoodSelectionDialog() async {
    CurrentMood? selectedMood;
    
    await showDialog<CurrentMood>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 500.h,
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            colors: [
              const Color(0xFF1F1F1F).withValues(alpha: 0.9),
              const Color(0xFF121212).withValues(alpha: 0.9),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.mood, color: const Color(0xFFE5A00D), size: 24.sp),
                    SizedBox(width: 12.w),
                    Text(
                      "Choose Session Mood",
                      style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                Text(
                  "Pick the vibe for this session. Your friend will see your choice when they join.",
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 20.h),
                
                // Mood options
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: CurrentMood.values
                          .where((mood) => mood != CurrentMood.perfectForMe)
                          .map((mood) => Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            child: GlassmorphicContainer(
                              width: double.infinity,
                              height: 60.h,
                              borderRadius: 12,
                              blur: 10,
                              alignment: Alignment.centerLeft,
                              border: 1,
                              linearGradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.05),
                                  Colors.white.withValues(alpha: 0.02),
                                ],
                              ),
                              borderGradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.1),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    selectedMood = mood;
                                    Navigator.of(context).pop(mood);
                                  },
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.r),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                          child: Text(mood.emoji, style: TextStyle(fontSize: 20.sp)),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                mood.displayName,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                "Great for collaborative sessions",
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                  fontSize: 12.sp,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.white30,
                                          size: 16.sp,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ).toList(),
                    ),
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: Colors.white30),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    
    return selectedMood;
  }
  // Part 4: Share options and join session dialog methods

  void _showShareOptionsDialog(String sessionCode, CurrentMood selectedMood) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 450.h,
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 2,
          linearGradient: LinearGradient(
            colors: [
              const Color(0xFF1F1F1F).withValues(alpha: 0.9),
              const Color(0xFF121212).withValues(alpha: 0.9),
            ],
          ),
          borderGradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24.r),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.celebration, color: const Color(0xFFE5A00D), size: 24.sp),
                    SizedBox(width: 12.w),
                    Text(
                      "Session Ready!",
                      style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                
                SizedBox(height: 20.h),
                
                // Mood display
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Text(selectedMood.emoji, style: TextStyle(fontSize: 24.sp)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${selectedMood.displayName} Session",
                              style: TextStyle(
                                color: const Color(0xFFE5A00D),
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "You set the mood for this session",
                              style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                Text(
                  "Share this code with your friend:",
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                
                SizedBox(height: 16.h),
                
                // Session code
                Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFE5A00D).withValues(alpha: 0.2),
                        Colors.orange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFE5A00D), width: 2.w),
                  ),
                  child: Column(
                    children: [
                      Text(
                        sessionCode,
                        style: TextStyle(
                          color: const Color(0xFFE5A00D),
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6.w,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "6-digit session code",
                        style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24.h),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: sessionCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied! Send it to your friend'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: Icon(Icons.copy, size: 18.sp, color: const Color(0xFFE5A00D)),
                        label: Text(
                          "Copy Code",
                          style: TextStyle(color: const Color(0xFFE5A00D), fontSize: 13.sp),
                        ),
                        style: TextButton.styleFrom(
                          side: BorderSide(color: const Color(0xFFE5A00D)),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Share.share(
                            'Join my ${selectedMood.displayName} movie session! ${selectedMood.emoji}\n\nCode: $sessionCode\n\nWe\'ll find movies that match this vibe together! 🎬',
                          );
                        },
                        icon: Icon(Icons.share, size: 18.sp, color: Colors.white),
                        label: Text(
                          "Share",
                          style: TextStyle(fontSize: 13.sp, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A00D),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                // Status
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12.w,
                        height: 12.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.w,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Waiting for friend to join...",
                        style: TextStyle(color: Colors.blue, fontSize: 12.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Done button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        side: BorderSide(color: Colors.white30),
                      ),
                    ),
                    child: Text(
                      "Got it!",
                      style: TextStyle(color: const Color(0xFFE5A00D), fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFriendSelector() {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => FriendInviteDialog(
        currentUser: widget.currentUser,
        friendIds: widget.friendIds,
        onSessionCreated: widget.onSessionCreated,
      ),
    );
  }
  // Part 5: Join session dialog and start of FriendInviteDialog class

  void _showJoinSessionDialog() {
    Navigator.of(context).pop();
    final codeController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 300.h,
            borderRadius: 24,
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              colors: [
                const Color(0xFF1F1F1F).withValues(alpha: 0.9),
                const Color(0xFF121212).withValues(alpha: 0.9),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.2),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  Text(
                    "Join Friend's Session",
                    style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  Text(
                    "Enter the 6-digit code your friend shared:",
                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  TextField(
                    controller: codeController,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      letterSpacing: 4.w,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: TextStyle(
                        color: Colors.white30,
                        letterSpacing: 4.w,
                        fontWeight: FontWeight.bold,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: const Color(0xFFE5A00D), width: 2.w),
                      ),
                      counterText: "",
                      contentPadding: EdgeInsets.symmetric(vertical: 20.h),
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isJoining ? null : () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              side: BorderSide(color: Colors.white30),
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isJoining || codeController.text.length != 6
                              ? null
                              : () async {
                                  setState(() => isJoining = true);
                                  
                                  try {
                                    final session = await SessionService.joinSessionByCode(
                                      codeController.text,
                                      widget.currentUser.name,
                                    );
                                    
                                    if (session != null) {
                                      Navigator.of(context).pop();
                                      widget.onSessionCreated(session);
                                      
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Successfully joined session!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Session not found. Check the code and try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to join: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() => isJoining = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE5A00D),
                            disabledBackgroundColor: Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: isJoining
                              ? SizedBox(
                                  width: 16.w,
                                  height: 16.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  "Join Session",
                                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced Friend invite dialog with single friend selection and improved styling
class FriendInviteDialog extends StatefulWidget {
  final UserProfile currentUser;
  final List<UserProfile> friendIds;
  final Function(SwipeSession session) onSessionCreated;

  const FriendInviteDialog({
    super.key,
    required this.currentUser,
    required this.friendIds,
    required this.onSessionCreated,
  });

  @override
  State<FriendInviteDialog> createState() => _FriendInviteDialogState();
}

class _FriendInviteDialogState extends State<FriendInviteDialog> {
  String? selectedFriendId; // Changed to single selection
  bool isCreatingSession = false;
  bool _showMoodSelection = false;
  CurrentMood? _selectedMood;

  // Part 6: FriendInviteDialog build method

  @override
  Widget build(BuildContext context) {
    if (_showMoodSelection) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              MoodSelectionWidget(
                onMoodsSelected: _onMoodsSelected,
                isGroupMode: false, // Changed to false since it's 1-on-1
                groupSize: 2, // Always 2 for friend mode
              ),
              Positioned(
                top: 16.h,
                left: 16.w,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showMoodSelection = false;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 500.h,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F1F1F).withValues(alpha: 0.95),
            const Color(0xFF161616).withValues(alpha: 0.95),
            const Color(0xFF121212).withValues(alpha: 0.95),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.8),
            Colors.orange.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          spreadRadius: 2.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_add,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Invite Friend",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              if (widget.friendIds.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Icon(
                            Icons.people_outline,
                            size: 48.sp,
                            color: Colors.white30,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          "No Friends Yet",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "Add friends to start swiping together!",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14.sp,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Friends selection header
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      color: const Color(0xFFE5A00D),
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Select a Friend",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        "${widget.friendIds.length} available",
                        style: TextStyle(
                          color: const Color(0xFFE5A00D),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16.h),
                
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.friendIds.length,
                    itemBuilder: (context, index) {
                      final friend = widget.friendIds[index];
                      final isSelected = selectedFriendId == friend.uid;
                      
                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: 72.h,
                          borderRadius: 16,
                          blur: 10,
                          alignment: Alignment.centerLeft,
                          border: 2,
                          linearGradient: LinearGradient(
                            colors: isSelected
                                ? [
                                    const Color(0xFFE5A00D).withValues(alpha: 0.3),
                                    const Color(0xFFE5A00D).withValues(alpha: 0.15),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.08),
                                    Colors.white.withValues(alpha: 0.04),
                                  ],
                          ),
                          borderGradient: LinearGradient(
                            colors: isSelected
                                ? [
                                    const Color(0xFFE5A00D).withValues(alpha: 0.8),
                                    const Color(0xFFE5A00D).withValues(alpha: 0.6),
                                  ]
                                : [
                                    Colors.white.withValues(alpha: 0.15),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: isCreatingSession
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedFriendId = isSelected ? null : friend.uid;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(16.r),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  children: [
                                    // Friend avatar with enhanced styling
                                    Container(
                                      width: 48.w,
                                      height: 48.h,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isSelected
                                              ? [const Color(0xFFE5A00D), Colors.orange.shade600]
                                              : [Colors.grey[700]!, Colors.grey[800]!],
                                        ),
                                        borderRadius: BorderRadius.circular(14.r),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                                                  blurRadius: 8.r,
                                                  spreadRadius: 1.r,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : "?",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    SizedBox(width: 16.w),
                                    
                                    // Friend info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            friend.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                        ],
                                      ),
                                    ),
                                    
                                    SizedBox(width: 12.w),
                                    
                                    // Selection indicator
                                    Container(
                                      padding: EdgeInsets.all(8.w),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFE5A00D).withValues(alpha: 0.2)
                                            : Colors.white.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                        color: isSelected ? const Color(0xFFE5A00D) : Colors.white60,
                                        size: 24.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Part 7: Final part of FriendInviteDialog with confirmation, buttons and methods

                if (selectedFriendId != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE5A00D).withValues(alpha: 0.2),
                          const Color(0xFFE5A00D).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFFE5A00D).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: const Color(0xFFE5A00D),
                          size: 20.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "Ready to invite ${widget.friendIds.firstWhere((f) => f.uid == selectedFriendId).name}",
                            style: TextStyle(
                              color: const Color(0xFFE5A00D),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
              
              SizedBox(height: 20.h),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: isCreatingSession ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (widget.friendIds.isNotEmpty) ...[
                    SizedBox(width: 16.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isCreatingSession || selectedFriendId == null
                            ? null
                            : () {
                                setState(() {
                                  _showMoodSelection = true;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A00D),
                          disabledBackgroundColor: Colors.grey[700],
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: isCreatingSession
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.mood, color: Colors.white, size: 18.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Pick Mood",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMoodsSelected(List<CurrentMood> moods) {
    setState(() {
      _selectedMood = moods.isNotEmpty ? moods.first : null;
      _showMoodSelection = false;
    });
    
    if (_selectedMood != null) {
      _sendInvitation();
    }
  }

  Future<void> _sendInvitation() async {
    if (_selectedMood == null || selectedFriendId == null) return;
    
    setState(() => isCreatingSession = true);
    
    try {
      final session = await SessionService.createSession(
        hostName: widget.currentUser.name,
        inviteType: InvitationType.friend,
        selectedMood: _selectedMood,
      );
      
      final friend = widget.friendIds.firstWhere((f) => f.uid == selectedFriendId);
      await SessionService.inviteFriend(
        sessionId: session.sessionId,
        friendId: selectedFriendId!,
        friendName: friend.name,
        selectedMood: _selectedMood,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSessionCreated(session);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedMood!.displayName} session invitation sent to ${friend.name}!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isCreatingSession = false);
    }
  }
}