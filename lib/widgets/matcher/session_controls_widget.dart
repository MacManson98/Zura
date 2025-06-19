import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../models/user_profile.dart';
import '../../models/session_models.dart';
import '../../utils/session_manager.dart';
import '../../widgets/session_invitation_widget.dart';
import '../../models/matching_models.dart';
import '../group_selection_widget.dart';

class SessionControlsWidget extends StatelessWidget {
  final MatchingMode currentMode;
  final bool hasStartedSession;
  final UserProfile? selectedFriend;
  final List<UserProfile> selectedGroup;
  final UserProfile currentUser;
  final List<UserProfile> friendIds;
  
  // Callback functions
  final VoidCallback onEndSession;
  final VoidCallback onStartPopularMovies;
  final VoidCallback onShowMoodPicker;
  final Function(List<UserProfile>) onGroupSelected;
  final void Function(SwipeSession) onSessionCreated;
  
  // Helper functions
  final bool Function() canStartSession;
  final String Function(Duration) formatDuration;

  const SessionControlsWidget({
    super.key,
    required this.currentMode,
    required this.hasStartedSession,
    required this.selectedFriend,
    required this.selectedGroup,
    required this.currentUser,
    required this.friendIds,
    required this.onEndSession,
    required this.onStartPopularMovies,
    required this.onShowMoodPicker,
    required this.onGroupSelected,
    required this.onSessionCreated,
    required this.canStartSession,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        children: [
          // Show active session status if session is running
          if (hasStartedSession && SessionManager.hasActiveSession) ...[
            GlassmorphicContainer(
              width: double.infinity,
              height: 90.h,
              borderRadius: 20,
              blur: 15,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withValues(alpha: 0.2),
                  Colors.blue.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    // Session status icon
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade600],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8.r,
                            spreadRadius: 1.r,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.timer,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                    
                    SizedBox(width: 16.w),
                    
                    // Session info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Session Active",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12.sp,
                                color: Colors.green.shade300,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "Duration: ${formatDuration(SessionManager.currentSessionDuration ?? Duration.zero)}",
                                style: TextStyle(
                                  color: Colors.green.shade300,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // End session button
                    GestureDetector(
                      onTap: onEndSession,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.withValues(alpha: 0.2),
                              Colors.orange.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5),
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          "End Session",
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
          
          // Solo Mode: Just choose mood (simplified) - GOLDEN
          if (currentMode == MatchingMode.solo) ...[
            GlassmorphicContainer(
              width: double.infinity,
              height: 60.h,
              borderRadius: 20,
              blur: 15,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: canStartSession() 
                    ? [
                        const Color(0xFFE5A00D).withValues(alpha: 0.3),
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ]
                    : [
                        Colors.grey.withValues(alpha: 0.2),
                        Colors.grey.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                      ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: canStartSession()
                    ? [
                        const Color(0xFFE5A00D).withValues(alpha: 0.6),
                        Colors.white.withValues(alpha: 0.2),
                      ]
                    : [
                        Colors.grey.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.1),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canStartSession() ? onShowMoodPicker : null,
                  borderRadius: BorderRadius.circular(20.r),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            gradient: canStartSession() 
                                ? LinearGradient(
                                    colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                                  )
                                : null,
                            color: canStartSession() ? null : Colors.grey[700],
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.mood,
                            color: canStartSession() ? Colors.white : Colors.grey[400],
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          "Choose Your Mood",
                          style: TextStyle(
                            color: canStartSession() ? Colors.white : Colors.grey[400],
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Friend Mode: Show invite options prominently - GOLDEN
          if (currentMode == MatchingMode.friend) ...[
            if (selectedFriend != null) ...[
              // Friend is selected - show friend info card - GOLDEN
              GlassmorphicContainer(
                width: double.infinity,
                height: 80.h,
                borderRadius: 20,
                blur: 15,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Row(
                    children: [
                      // Friend avatar - GOLDEN
                      Container(
                        width: 50.w,
                        height: 50.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFE5A00D), Colors.orange],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            selectedFriend!.name[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ready to match with ${selectedFriend!.name}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              "Find movies you'll both enjoy",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              
              // Single button: Choose mood for friend matching - GOLDEN
              GlassmorphicContainer(
                width: double.infinity,
                height: 50.h,
                borderRadius: 18,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onShowMoodPicker,
                    borderRadius: BorderRadius.circular(18.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mood, color: const Color(0xFFE5A00D), size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "Choose Mood",
                          style: TextStyle(
                            color: const Color(0xFFE5A00D),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // No friend selected - show invite button - GOLDEN
              GlassmorphicContainer(
                width: double.infinity,
                height: 60.h,
                borderRadius: 20,
                blur: 15,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showFriendSelector(context),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFFE5A00D), Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.person_add,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            "Invite Friend",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],

          // Group Mode: Show group creation options - GOLDEN
          if (currentMode == MatchingMode.group) ...[
            if (selectedGroup.isNotEmpty) ...[
              // Group selected - show group info card - GOLDEN
              GlassmorphicContainer(
                width: double.infinity,
                height: 70.h,
                borderRadius: 20,
                blur: 15,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFE5A00D), Colors.orange],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(Icons.groups, color: Colors.white, size: 18.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          "Group: You + ${selectedGroup.map((f) => f.name).join(', ')}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showGroupSelectionDialog(context),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.edit, color: Colors.white, size: 16.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              
              // Single button: Choose mood for group matching - GOLDEN
              GlassmorphicContainer(
                width: double.infinity,
                height: 50.h,
                borderRadius: 18,
                blur: 10,
                alignment: Alignment.center,
                border: 1,
                linearGradient: LinearGradient(
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onShowMoodPicker,
                    borderRadius: BorderRadius.circular(18.r),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mood, color: const Color(0xFFE5A00D), size: 18.sp),
                        SizedBox(width: 8.w),
                        Text(
                          "Choose Mood",
                          style: TextStyle(
                            color: const Color(0xFFE5A00D),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // No group selected - GOLDEN
              GlassmorphicContainer(
                width: double.infinity,
                height: 60.h,
                borderRadius: 20,
                blur: 15,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    Colors.orange.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D).withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showGroupSelectionDialog(context),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [const Color(0xFFE5A00D), Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(
                              Icons.groups,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            "Select Group",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _showFriendSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FriendInviteDialog(
        currentUser: currentUser,
        friendIds: friendIds,
        onSessionCreated: onSessionCreated,
      ),
    );
  }

  void _showGroupSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => GroupSelectionWidget(
        currentUser: currentUser,
        friendIds: friendIds,
        onGroupSelected: onGroupSelected,
        onSessionCreated: onSessionCreated,
      ),
    );
  }
}