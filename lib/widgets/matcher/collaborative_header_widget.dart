import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../models/session_models.dart';
import '../../models/user_profile.dart';
import '../../models/matching_models.dart';
import '../../utils/mood_based_learning_engine.dart';
import '../../services/session_service.dart';
import '../../utils/debug_loader.dart';
import '../../movie.dart';
import '../../utils/themed_notifications.dart';

class CollaborativeHeaderWidget extends StatelessWidget {
  final bool isInCollaborativeMode;
  final SwipeSession? currentSession;
  final bool isReadyToSwipe;
  final bool isWaitingForFriend;
  final UserProfile currentUser;
  final List<CurrentMood> selectedMoods;
  
  // Callback functions
  final VoidCallback onRequestMoodChange;
  final Function(Map<String, dynamic>) onUpdateState;

  const CollaborativeHeaderWidget({
    super.key,
    required this.isInCollaborativeMode,
    required this.currentSession,
    required this.isReadyToSwipe,
    required this.isWaitingForFriend,
    required this.currentUser,
    required this.selectedMoods,
    required this.onRequestMoodChange,
    required this.onUpdateState,
  });

  @override
  Widget build(BuildContext context) {
    if (!isInCollaborativeMode || currentSession == null) {
      return const SizedBox.shrink();
    }
    
    // If we're ready to swipe, don't show this header (mood banner will show instead)
    if (isReadyToSwipe) {
      return const SizedBox.shrink();
    }

    final actuallyWaiting = currentSession!.status == SessionStatus.created;
    if (isReadyToSwipe && !actuallyWaiting) {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100.h,
        borderRadius: 20,
        blur: 15,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.2),
            const Color(0xFFB8860B).withValues(alpha: 0.15),
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
          child: Column(
            children: [
              // Main session info row
              Row(
                children: [
                  // Session status icon
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE5A00D),
                          const Color(0xFFB8860B),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      actuallyWaiting ? Icons.hourglass_empty : Icons.people,
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
                          actuallyWaiting ? "Waiting for friend..." : "Swiping together!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        if (currentSession!.sessionCode != null)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              "Code: ${currentSession!.sessionCode}",
                              style: TextStyle(
                                color: const Color(0xFFE5A00D),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (currentSession!.participantNames.length > 1) ...[
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 12.sp,
                                color: Colors.white60,
                              ),
                              SizedBox(width: 4.w),
                              Expanded(
                                child: Text(
                                  "With: ${currentSession!.participantNames.where((name) => name != currentUser.name).join(', ')}",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Action buttons column
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Change Vibe button (only show if session has started and mood is selected)
                      if (selectedMoods.isNotEmpty || currentSession!.hasMoodSelected)
                        GestureDetector(
                          onTap: onRequestMoodChange,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.mood, color: Colors.orange, size: 16.sp),
                                SizedBox(width: 6.w),
                                Text(
                                  "Change Vibe",
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      SizedBox(height: 8.h),
                      
                      // End Session button
                      GestureDetector(
                        onTap: () => _showEndSessionDialog(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.withValues(alpha: 0.2),
                                Colors.red.withValues(alpha: 0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.5),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.close, color: Colors.red, size: 16.sp),
                              SizedBox(width: 6.w),
                              Text(
                                "End Session",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEndSessionDialog(BuildContext context) {
    final friendNames = currentSession?.participantNames
        .where((name) => name != currentUser.name)
        .join(", ") ?? "your friend";
        
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          "End Session for Everyone?",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to end this collaborative session? This will end the session for both you and $friendNames.",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _endCollaborativeSession(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text("End for Everyone"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endCollaborativeSession(BuildContext context) async {
    if (currentSession == null) return;
    
    try {
      // Cancel the session on Firebase for all participants
      await SessionService.cancelSession(
        currentSession!.sessionId,
        cancelledBy: currentUser.name,
      );

      if (!context.mounted) return;
      
      // Reset all collaborative state
      onUpdateState({
        'currentSession': null,
        'isWaitingForFriend': false,
        'isInCollaborativeMode': false,
        'currentMode': MatchingMode.solo,
        'isReadyToSwipe': false,
        'isLoadingSession': false,
        'hasStartedSession': false,
        'sessionPool': <Movie>[],
        'currentSessionMovieIds': <String>{},
        'selectedMoods': <CurrentMood>[],
        'currentSessionContext': null,
        'sessionPassedMovieIds': <String>{},
        'swipeCount': 0,
        'selectedFriend': null,
        'selectedGroup': <UserProfile>[],
        'groupLikes': <String, Set<String>>{},
      });

      if (!context.mounted) return;
      
      // Show success message
      ThemedNotifications.showInfo(context, 'Session ended for everyone', icon: "🚪");
      
      DebugLogger.log("✅ Collaborative session ended successfully");
      
    } catch (e) {
      DebugLogger.log("❌ Error ending collaborative session: $e");
      ThemedNotifications.showError(context, 'Failed to end session');
    }
  }
}