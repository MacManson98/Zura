import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../movie.dart';
import '../../models/user_profile.dart';
import '../../models/matching_models.dart';
import '../../models/session_models.dart';
import '../../utils/session_manager.dart';
import '../../utils/debug_loader.dart';
import '../../utils/user_profile_storage.dart';
import '../../utils/mood_engine.dart';
import '../../services/session_service.dart';
import '../../screens/movie_detail_screen.dart';
import '../../utils/themed_notifications.dart';

class MainContentWidget extends StatelessWidget {
  // State variables
  final bool hasStartedSession;
  final List<Movie> sessionPool;
  final MatchingMode currentMode;
  final UserProfile? selectedFriend;
  final bool isInCollaborativeMode;
  final UserProfile currentUser;
  final List<UserProfile> friendIds;
  final List<UserProfile> selectedGroup;
  final SwipeSession? currentSession;
  final SessionContext? currentSessionContext;
  final List<CurrentMood> selectedMoods;
  final Set<String> sessionPassedMovieIds;
  final Set<String> currentSessionMovieIds;
  final int swipeCount;
  final List<Movie> movieDatabase;
  final bool isRefreshingPool;
  final List<Movie> basePool;
  final List<Movie> dynamicPool;
  final Map<String, Set<String>> groupLikes;

  // Callback functions for state changes
  final VoidCallback onStartPopularMovies;
  final VoidCallback onShowMoodPicker;
  final Function(MatchingMode) onSwitchMode;
  final VoidCallback onInitializeApp;
  final Function(Movie) onShowMatchCelebration;
  final Function(Movie) onLikeMovie;
  final Function(Movie) onPassMovie;
  final VoidCallback onRefreshPoolIfNeeded;
  final Function(String, List<String>) onAddMoreMoviesToSession;
  final Function(UserProfile) onSelectFriend;
  final VoidCallback onAdaptSessionPool;
  final Function(Map<String, dynamic>) onUpdateState; // Generic state updater

  const MainContentWidget({
    super.key,
    required this.hasStartedSession,
    required this.sessionPool,
    required this.currentMode,
    required this.selectedFriend,
    required this.isInCollaborativeMode,
    required this.currentUser,
    required this.friendIds,
    required this.selectedGroup,
    required this.currentSession,
    required this.currentSessionContext,
    required this.selectedMoods,
    required this.sessionPassedMovieIds,
    required this.currentSessionMovieIds,
    required this.swipeCount,
    required this.movieDatabase,
    required this.isRefreshingPool,
    required this.basePool,
    required this.dynamicPool,
    required this.groupLikes,
    required this.onStartPopularMovies,
    required this.onShowMoodPicker,
    required this.onSwitchMode,
    required this.onInitializeApp,
    required this.onShowMatchCelebration,
    required this.onLikeMovie,
    required this.onPassMovie,
    required this.onRefreshPoolIfNeeded,
    required this.onAddMoreMoviesToSession,
    required this.onSelectFriend,
    required this.onAdaptSessionPool,
    required this.onUpdateState,
  });

  @override
  Widget build(BuildContext context) {
    DebugLogger.log("🔍 DEBUG: _buildMainContent called");
    DebugLogger.log("🔍 DEBUG: hasStartedSession: $hasStartedSession");
    DebugLogger.log("🔍 DEBUG: SessionManager.hasActiveSession: ${SessionManager.hasActiveSession}");
    DebugLogger.log("🔍 DEBUG: sessionPool.length: ${sessionPool.length}");
    
    // FIRST: Check for session end - MOST IMPORTANT
    if (hasStartedSession && !SessionManager.hasActiveSession && !isInCollaborativeMode) {
      DebugLogger.log("🔍 DEBUG: Session ended externally - showing session ended screen");
      return _buildSessionEndedScreen(context);
    }
    
    if (currentMode == MatchingMode.friend && selectedFriend == null && !isInCollaborativeMode) {
      return _buildSelectFriendScreen(context);
    }

    if (sessionPool.isEmpty) {
      return _buildEmptyState(context);
    }

    return _buildSwipeInterface(context);
  }

  Widget _buildSessionEndedScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80.sp, color: Colors.green),
          SizedBox(height: 24.h),
          Text("Session Ended", style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 16.h),
          Text("Your session has been completed successfully", style: TextStyle(color: Colors.grey[400], fontSize: 16.sp), textAlign: TextAlign.center),
          SizedBox(height: 32.h),
          
          SizedBox(
            width: 200.w,
            child: ElevatedButton.icon(
              onPressed: () {
                onUpdateState({
                  'hasStartedSession': false,
                  'isReadyToSwipe': false,
                  'selectedMoods': <CurrentMood>[],
                  'sessionPool': <Movie>[],
                  'currentSessionContext': null,
                });
                onStartPopularMovies();
              },
              icon: Icon(Icons.trending_up, size: 20.sp),
              label: Text("Popular Movies"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A00D),
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          SizedBox(
            width: 200.w,
            child: OutlinedButton.icon(
              onPressed: () {
                onUpdateState({
                  'hasStartedSession': false,
                  'isReadyToSwipe': false,
                  'selectedMoods': <CurrentMood>[],
                  'sessionPool': <Movie>[],
                  'currentSessionContext': null,
                });
                onShowMoodPicker();
              },
              icon: Icon(Icons.mood, size: 20.sp),
              label: Text("Choose Mood"),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFFE5A00D), width: 2.w),
                foregroundColor: const Color(0xFFE5A00D),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeInterface(BuildContext context) {
    return Padding(
      // 🔧 FIXED: Add proper padding to avoid floating nav bar overlap
      padding: EdgeInsets.only(
        left: 8.r,
        right: 8.r,
        top: 8.r,
        // ✅ CRITICAL: Account for floating nav bar
        // Nav bar: height 70.h + bottom position 25.h + extra spacing 16.h = 111.h total
        bottom: 111.h,
      ),
      child: Column(
        children: [
          Expanded(
            child: CardSwiper(
              cardsCount: sessionPool.length,
              numberOfCardsDisplayed: 1,
              onSwipe: (previousIndex, currentIndex, direction) => _onSwipe(context, previousIndex, currentIndex, direction),
              cardBuilder: (context, index, percentX, percentY) {
                if (index >= sessionPool.length) return const SizedBox.shrink();

                final movie = sessionPool[index];
                
                final leftIntensity = percentX < 0 ? (-percentX.toDouble()).clamp(0.0, 1.0) : 0.0;
                final rightIntensity = percentX > 0 ? percentX.toDouble().clamp(0.0, 1.0) : 0.0;
                
                return Container(
                  margin: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.yellow.shade800, width: 2.w),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: const Color(0xFF1A1A1A)),
                        
                        Column(
                          children: [
                            Expanded(
                              flex: 12,
                              child: Container(
                                width: double.infinity,
                                child: Image.network(
                                  movie.posterUrl,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[800],
                                      child: Icon(
                                        Icons.broken_image, 
                                        size: 100.sp, 
                                        color: Colors.white24
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w), // Slightly more padding
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    movie.title,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8.h), // More spacing
                                  Container(
                                    height: 36.h, // Slightly taller button
                                    child: ElevatedButton(
                                      onPressed: () => _showMovieDetailSheet(context, movie),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE5A00D),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18.r), // More rounded
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                                      ),
                                      child: Text(
                                        "View more",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (leftIntensity > 0)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.red.withAlpha((179 * leftIntensity).toInt()),
                                    Colors.red.withAlpha(0),
                                  ],
                                  stops: const [0.0, 0.3],
                                ),
                              ),
                            ),
                          ),
                          
                        if (rightIntensity > 0)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Colors.green.withAlpha((179 * rightIntensity).toInt()),
                                    Colors.green.withAlpha(0),
                                  ],
                                  stops: const [0.0, 0.3],
                                ),
                              ),
                            ),
                          ),
                        
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _showMovieDetailSheet(context, movie),
                              splashColor: Colors.white.withAlpha(26),
                              highlightColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 🔧 FIXED: Improved instruction text spacing and positioning
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
            child: Text(
              "Swipe left to pass, right to like",
              style: TextStyle(
                color: Colors.grey[400], 
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  bool _onSwipe(BuildContext context, int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    SessionManager.recordActivity();
    if (isInCollaborativeMode && currentSession != null) {
      return _onCollaborativeSwipe(context, previousIndex, currentIndex, direction);
    }
    
    if (previousIndex >= sessionPool.length) return false;
    
    final movie = sessionPool[previousIndex];
    onUpdateState({'swipeCount': swipeCount + 1});
    DebugLogger.log("🔢 Swipe count: ${swipeCount + 1}");
    
    final isLike = direction == CardSwiperDirection.right;
    
    // UNIFIED LEARNING: Light learning for all mood sessions
    if (currentSessionContext != null) {
      // Simple tracking only (no learning)
      if (isLike) {
        onUpdateState({
          'userLikedMovies': {...currentUser.likedMovies, movie},
          'userLikedMovieIds': [...currentUser.likedMovieIds, movie.id],
        });
      } else {
        onUpdateState({
          'userPassedMovieIds': {...currentUser.passedMovieIds, movie.id},
        });
      }
      
      if (isLike) {
        onLikeMovie(movie);
      } else {
        onPassMovie(movie);
        // For mood sessions, track passed movies to avoid showing again this session
        onUpdateState({
          'sessionPassedMovieIds': {...sessionPassedMovieIds, movie.id},
        });
      }
    } else {
      // For popular movies sessions (no mood context)
      if (isLike) {
        onLikeMovie(movie);
      } else {
        onUpdateState({
          'userPassedMovieIds': {...currentUser.passedMovieIds, movie.id},
        });
        onPassMovie(movie);
      }
    }
    
    // Check for group matches (simplified since everyone sees same movies)
    if (currentMode == MatchingMode.friend && isLike) {
      _checkForFriendMatch(movie);
    } else if (currentMode == MatchingMode.group && isLike) {
      _checkForGroupMatch(movie, isLike);
    }
    
    // Check if we're running low on movies
    if (currentIndex != null && currentIndex >= sessionPool.length - 5) {
      if (selectedMoods.isNotEmpty) {
        onRefreshPoolIfNeeded(); // Only for mood sessions
      } else if (isInCollaborativeMode) {
        // Handle collaborative session refresh
      }
      // For popular movies sessions, we don't refill - they're designed to be finite
    }
    
    return true;
  }

  void _checkForFriendMatch(Movie movie) {
    if (selectedFriend?.likedMovieIds.contains(movie.id) == true) {
      onShowMatchCelebration(movie);
    }
  }

  void _checkForGroupMatch(Movie movie, bool isLike) {
    if (!isLike) return;
    
    // Friend mode - simple 2-person matching (keep existing logic)
    if (currentMode == MatchingMode.friend && selectedFriend?.likedMovieIds.contains(movie.id) == true) {
      onShowMatchCelebration(movie);
      return;
    }
    
    // Group mode - handled by GroupMatchingHandler via MatcherGroupIntegration
    // The real group matching logic is now in matcher_screen.dart likeMovie() method
    // This method is only called for local/non-collaborative matching scenarios
    if (currentMode == MatchingMode.group && !isInCollaborativeMode) {
      // Local group mode (if you support it) - simplified logic for local-only groups
      final userGroupLikes = groupLikes[currentUser.name] ?? <String>{};
      userGroupLikes.add(movie.title);
      
      final everyone = [currentUser.name, ...selectedGroup.map((f) => f.name)];
      final allLiked = everyone.every((name) => groupLikes[name]?.contains(movie.title) == true);
      
      if (allLiked) {
        onShowMatchCelebration(movie);
      }
    }
    
    // Note: Collaborative group matching is handled in matcher_screen.dart via MatcherGroupIntegration
  }

  bool _onCollaborativeSwipe(BuildContext context, int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (currentSession == null || previousIndex >= sessionPool.length) return false;

    final movie = sessionPool[previousIndex];
    final isLike = direction == CardSwiperDirection.right;

    // Record swipe in Firebase
    SessionService.recordSwipe(
      sessionId: currentSession!.sessionId,
      movieId: movie.id,
      isLike: isLike,
    );

    // Update local user profile
    if (isLike) {
      onUpdateState({
        'userLikedMovies': {...currentUser.likedMovies, movie},
        'userLikedMovieIds': {...currentUser.likedMovieIds, movie.id},
      });
    } else {
      onUpdateState({
        'userPassedMovieIds': {...currentUser.passedMovieIds, movie.id},
        'sessionPassedMovieIds': {...sessionPassedMovieIds, movie.id},
      });
    }

    // Save profile
    UserProfileStorage.saveProfile(currentUser);

    // Note: Group matching for collaborative sessions is handled in matcher_screen.dart
    // via MatcherGroupIntegration.handleGroupLike() in the likeMovie() method
    
    // Check if running low on movies and add more
    if (currentIndex != null && currentIndex >= sessionPool.length - 5) {
      final isHost = currentSession!.hostId == currentUser.uid;
      if (isHost) {
        DebugLogger.log("🔄 HOST: Running low on movies, adding more...");
        onAddMoreMoviesToSession(currentSession!.sessionId, []);
      }
    }

    return true;
  }

  void _showMovieDetailSheet(BuildContext context, Movie movie) {
    final bool isInFavorites = currentUser.likedMovies.contains(movie);

    showMovieDetails(
      context: context,
      movie: movie,
      currentUser: currentUser,
      onAddToFavorites: isInFavorites ? null : (Movie movie) {
        onUpdateState({
          'userLikedMovies': [...currentUser.likedMovies, movie],
        });

        ThemedNotifications.showSuccess(context, '${movie.title} added to favorites', icon: "❤️");
      },
      onRemoveFromFavorites: isInFavorites ? (Movie movie) {
        onUpdateState({
          'userLikedMovies': {...currentUser.likedMovies}..remove(movie),
        });
        ThemedNotifications.showDecline(context, '${movie.title} removed from favorites', icon: "💔");
      } : null,
      onMarkAsWatched: currentMode == MatchingMode.friend || currentMode == MatchingMode.group
          ? (Movie movie) {
              ThemedNotifications.showSuccess(context, '${movie.title} marked as watched', icon: "✅");
            }
          : null,
      isInFavorites: isInFavorites,
    );
  }

  Widget _buildSelectFriendScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 80.sp,
              color: Colors.white30,
            ),
            SizedBox(height: 16.h),
            Text(
              "Choose a friend to start finding movies you both want to watch!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                _showFriendSelectionDialog(context);
              },
              icon: Icon(Icons.people, color: Colors.white, size: 20.sp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A00D),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                minimumSize: Size(200.w, 50.h),
              ),
              label: Text(
                "Select a Friend",
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "OR",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: () {
                onSwitchMode(MatchingMode.solo);
              },
              icon: Icon(Icons.movie, color: const Color(0xFFE5A00D), size: 20.sp),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: const Color(0xFFE5A00D), width: 1.w),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                minimumSize: Size(200.w, 50.h),
              ),
              label: Text(
                "Start Solo Swiping",
                style: TextStyle(color: const Color(0xFFE5A00D), fontSize: 16.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter,
              size: 80.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 24.h),
            Text(
              currentMode == MatchingMode.solo 
                  ? "No movies to swipe yet!" 
                  : "No movies to match yet!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Try selecting 'Popular Movies' or choose a mood to get started.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: onStartPopularMovies,
              icon: Icon(Icons.trending_up, color: Colors.white, size: 20.sp),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A00D),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              label: Text(
                "Load Popular Movies", 
                style: TextStyle(color: Colors.white, fontSize: 16.sp)
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFriendSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Select a Friend", 
          style: TextStyle(color: Colors.white, fontSize: 18.sp)
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: friendIds.isEmpty
              ? Center(
                  child: Text(
                    "You don't have any friends yet. Add some from the Friends tab!",
                    style: TextStyle(color: Colors.white70, fontSize: 15.sp),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: friendIds.length,
                  itemBuilder: (context, index) {
                    final friend = friendIds[index];
                    final isSelected = selectedFriend?.name == friend.name;
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey[800],
                        radius: 20.r,
                        child: Text(
                          friend.name.isNotEmpty ? friend.name[0].toUpperCase() : "?",
                          style: TextStyle(color: Colors.white, fontSize: 16.sp),
                        ),
                      ),
                      title: Text(
                        friend.name,
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ),
                      subtitle: Text(
                        "Genres: ${friend.preferredGenres.take(2).join(", ")}${friend.preferredGenres.length > 2 ? "..." : ""}",
                        style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: const Color(0xFFE5A00D), size: 24.sp)
                          : null,
                      selected: isSelected,
                      selectedTileColor: Colors.black26,
                      onTap: () {
                        Navigator.pop(context);
                        onSelectFriend(friend);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel", 
              style: TextStyle(color: Colors.white70, fontSize: 15.sp)
            ),
          ),
        ],
      ),
    );
  }
}