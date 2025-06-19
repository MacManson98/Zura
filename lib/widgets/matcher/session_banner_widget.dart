import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../movie.dart';
import '../../models/session_models.dart';
import '../../models/user_profile.dart';
import '../../models/matching_models.dart';
import '../../utils/mood_based_learning_engine.dart';
import '../../utils/session_manager.dart';
import '../../utils/user_profile_storage.dart';
import '../../utils/debug_loader.dart';
import '../../services/session_service.dart';
import '../../utils/unified_session_manager.dart';
import '../../utils/completed_session.dart';

class SessionBannerWidget extends StatelessWidget {
  final bool showMoodSelectionModal;
  final List<CurrentMood> selectedMoods;
  final bool isInCollaborativeMode;
  final bool isReadyToSwipe;
  final SwipeSession? currentSession;
  final UserProfile currentUser;

  // Callback functions
  final VoidCallback onShowMoodSelection;
  final VoidCallback onRequestMoodChange;
  final VoidCallback onRefreshMood;
  final Function(Map<String, dynamic>) onUpdateState; // For state updates
  final Function(String) onShowSnackBar; // For showing snack bars

  const SessionBannerWidget({
    super.key,
    required this.showMoodSelectionModal,
    required this.selectedMoods,
    required this.isInCollaborativeMode,
    required this.isReadyToSwipe,
    required this.currentSession,
    required this.currentUser,
    required this.onShowMoodSelection,
    required this.onRequestMoodChange,
    required this.onRefreshMood,
    required this.onUpdateState,
    required this.onShowSnackBar,
  });

  @override
  Widget build(BuildContext context) {
    // Smart banner logic - decides which banner to show
    if (showMoodSelectionModal) {
      return const SizedBox.shrink();
    }
    
    // Show mood banner for mood-based sessions OR collaborative sessions
    if (selectedMoods.isNotEmpty) {
      return _buildMoodBanner(context);
    }
    
    // Show popular movies banner
    if (isReadyToSwipe && selectedMoods.isEmpty) {
      return _buildPopularMoviesBanner(context);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildPopularMoviesBanner(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.8),
            const Color(0xFFB8860B).withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
            blurRadius: 4.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // Popular movies emoji
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                "🔥",
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
            SizedBox(width: 10.w),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Popular Movies",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    "Trending movies everyone's watching",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.sp,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Try different button
            GestureDetector(
              onTap: onShowMoodSelection,
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.w),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.mood,
                  color: Colors.white,
                  size: 16.sp,
                ),
              ),
            ),
            
            // Add spacing between buttons
            SizedBox(width: 8.w),
            
            // Add End Session button for popular movies
            GestureDetector(
              onTap: () {
                _showEndSessionConfirmation(context);
              },
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.withValues(alpha: 0.8), width: 1.w),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red.withValues(alpha: 0.9),
                  size: 16.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndSessionConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "End Session?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          SessionManager.hasActiveSession 
              ? "Are you sure you want to end your current session? Your progress will be saved."
              : "Are you sure you want to exit this movie selection?",
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog first
              _handleEndSession(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("End Session"),
          ),
        ],
      ),
    );
  }

  void _showCollaborativeEndSessionConfirmation(BuildContext context) {
    final friendNames = currentSession?.participantNames
        .where((name) => name != currentUser.name)
        .join(", ") ?? "your friend";
        
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "End Session for Everyone?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
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
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog first
              await _cancelSessionForBoth(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("End for Everyone"),
          ),
        ],
      ),
    );
  }

  void _handleEndSession(BuildContext context) async {
    // If there's an active session, end it properly first (but don't show summary)
    if (SessionManager.hasActiveSession) {
      final completedSession = SessionManager.endSession();
      if (completedSession != null) {
        currentUser.addCompletedSession(completedSession);
        await UserProfileStorage.saveProfile(currentUser);
        
        // Save to Firestore
        try {
          await FirebaseFirestore.instance.collection('swipeSessions').add({
            ...completedSession.toJson(),
            'participantIds': [currentUser.uid],
            'createdAt': FieldValue.serverTimestamp(),
          });
          DebugLogger.log("✅ Session ended and saved to Firestore");
        } catch (e) {
          DebugLogger.log("⚠️ Error saving session to Firestore: $e");
        }
      }
    }
    
    // ALWAYS reset the UI state completely
    onUpdateState({
      'isReadyToSwipe': false,
      'isLoadingSession': false,
      'hasStartedSession': false,
      'sessionPool': <Movie>[],
      'currentSessionMovieIds': <String>{},
      'selectedMoods': <CurrentMood>[],
      'currentSessionContext': null,
      'sessionPassedMovieIds': <String>{},
      'swipeCount': 0,
    });
    
    // Show confirmation that session was ended
    onShowSnackBar('Session ended');
  }

  Future<void> _cancelSessionForBoth(BuildContext context) async {
    if (currentSession == null) return;
    
    try {
      // Cancel the session on Firebase for all participants
      await SessionService.cancelSession(
        currentSession!.sessionId,
        cancelledBy: currentUser.name,
      );
      
      // Use the safer ending method
      await _endCollaborativeSessionWithReset(context);
      
      onShowSnackBar('Session ended for everyone');
    } catch (e) {
      DebugLogger.log("❌ Error ending collaborative session: $e");
      onShowSnackBar('Failed to end session');
    }
  }

  Future<void> _endCollaborativeSessionWithReset(BuildContext context) async {
    // Clear from unified session manager
    UnifiedSessionManager.clearActiveCollaborativeSession();
    
    // Properly end the collaborative session in Firestore
    if (currentSession != null) {
      try {
        await UnifiedSessionManager.endSessionProperly(
          sessionType: currentSession!.participantNames.length > 2 
              ? SessionType.group 
              : SessionType.friend,
          sessionId: currentSession!.sessionId,
          userProfile: currentUser,
        );
      } catch (e) {
        DebugLogger.log("❌ Error ending session properly: $e");
      }
    }
    
    // Reset UI state
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
    
    DebugLogger.log("✅ Collaborative session ended and UI reset");
  }

  Widget _buildMoodBanner(BuildContext context) {
    String moodText;
    String moodEmoji;
    
    if (selectedMoods.length == 1) {
      moodText = "${selectedMoods.first.displayName} vibes";
      moodEmoji = selectedMoods.first.emoji;
    } else {
      moodText = "Blended vibes: ${selectedMoods.map((m) => m.displayName).take(2).join(' + ')}${selectedMoods.length > 2 ? ' +${selectedMoods.length - 2}' : ''}";
      moodEmoji = selectedMoods.take(3).map((m) => m.emoji).join();
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.9),
            const Color(0xFFB8860B).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
            blurRadius: 4.r,
            offset: Offset(0, 1.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            // Compact mood emoji
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                moodEmoji,
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
            SizedBox(width: 10.w),
            
            // Compact mood text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moodText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    isInCollaborativeMode ? "Swiping together with this mood" : "Finding perfect movies",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.sp,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action buttons
            if (isInCollaborativeMode) ...[
              // Change Vibe button
              GestureDetector(
                onTap: onRequestMoodChange,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.w),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.mood,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              
              // End Session button
              GestureDetector(
                onTap: () {
                  _showCollaborativeEndSessionConfirmation(context);
                },
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.withValues(alpha: 0.8), width: 1.w),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red.withValues(alpha: 0.9),
                    size: 16.sp,
                  ),
                ),
              ),
            ] else ...[
              // Solo mode - just refresh button
              GestureDetector(
                onTap: onRefreshMood,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.w),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
              
              SizedBox(width: 8.w),
              
              // End Session button for solo mode
              GestureDetector(
                onTap: () {
                  _showEndSessionConfirmation(context);
                },
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.withValues(alpha: 0.8), width: 1.w),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.red.withValues(alpha: 0.9),
                    size: 16.sp,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}