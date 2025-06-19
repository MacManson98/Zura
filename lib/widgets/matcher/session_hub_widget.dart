import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../models/user_profile.dart';
import '../../models/matching_models.dart';
import '../../models/session_models.dart';
import '../../utils/completed_session.dart';
import '../../utils/unified_session_manager.dart';
import '../../utils/debug_loader.dart';
import '../../utils/session_manager.dart';
import '../../movie.dart';
import '../../utils/movie_loader.dart';
import '../../screens/session_detail_screen.dart';
import 'session_controls_widget.dart';
import 'dart:async';
import 'dart:math' as math;

class SessionHubWidget extends StatefulWidget {
  final MatchingMode currentMode;
  final bool isInCollaborativeMode;
  final UserProfile? selectedFriend;
  final List<UserProfile> selectedGroup;
  final bool isWaitingForFriend;
  final SwipeSession? currentSession;
  final UserProfile currentUser;

  final bool hasStartedSession;
  final List<UserProfile> friendIds;
  final VoidCallback onEndSession;
  final VoidCallback onStartPopularMovies;
  final VoidCallback onShowMoodPicker;
  final Function(List<UserProfile>) onGroupSelected;
  final void Function(SwipeSession) onSessionCreated;
  final bool Function() canStartSession;
  final String Function(Duration) formatDuration;

  const SessionHubWidget({
    super.key,
    required this.currentMode,
    required this.isInCollaborativeMode,
    required this.selectedFriend,
    required this.selectedGroup,
    required this.isWaitingForFriend,
    required this.currentSession,
    required this.currentUser,

    required this.hasStartedSession,
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
  State<SessionHubWidget> createState() => _SessionHubWidgetState();
}

class _SessionHubWidgetState extends State<SessionHubWidget> {
  List<CompletedSession> _allDisplaySessions = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadSessionHistory(); // Load once on init
  }

  @override
  void didUpdateWidget(SessionHubWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Only refresh when user returns from swiping
    if (oldWidget.isInCollaborativeMode && !widget.isInCollaborativeMode) {
      DebugLogger.log("🔄 User returned from collaborative session - refreshing");
      _loadSessionHistory();
    }
  }

  Future<void> _loadSessionHistory() async {
    if (_isLoadingHistory) return;
    
    setState(() => _isLoadingHistory = true);
    
    try {
      final allSessions = await UnifiedSessionManager.getAllSessionsForDisplay(widget.currentUser);
      
      if (mounted) {
        setState(() {
          _allDisplaySessions = allSessions;
        });
        
        // Load matched movies from sessions
        await _loadMatchedMoviesFromSessions(allSessions);
        
        DebugLogger.log("✅ SessionHub: Loaded ${allSessions.length} sessions");
      }
      
    } catch (e) {
      DebugLogger.log("❌ SessionHub: Error loading session history: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _loadMatchedMoviesFromSessions(List<CompletedSession> sessions) async {
    try {
      // Get all movie IDs from all sessions
      final Set<String> allMovieIds = {};
      
      for (final session in sessions) {
        allMovieIds.addAll(session.matchedMovieIds);
        allMovieIds.addAll(session.likedMovieIds);
      }
      
      if (allMovieIds.isEmpty) {
        DebugLogger.log("📝 No movie IDs found in sessions");
        return;
      }
      
      DebugLogger.log("🔍 Found ${allMovieIds.length} unique movie IDs across all sessions");
      
      // Try to find movies in existing collections first
      final List<Movie> foundMovies = [];
      final Set<String> missingMovieIds = {};
      
      for (final movieId in allMovieIds) {
        Movie? foundMovie;
        
        // Try likedMovies first
        try {
          foundMovie = widget.currentUser.likedMovies.firstWhere(
            (movie) => movie.id == movieId,
          );
          DebugLogger.log("✅ Found movie in likedMovies: ${foundMovie.title}");
        } catch (e) {
          // Try matchedMovies
          try {
            foundMovie = widget.currentUser.matchedMovies.firstWhere(
              (movie) => movie.id == movieId,
            );
            DebugLogger.log("✅ Found movie in matchedMovies: ${foundMovie.title}");
          } catch (e) {
            // Movie not found in either collection
            missingMovieIds.add(movieId);
            DebugLogger.log("⚠️ Movie ID $movieId not found in user collections");
          }
        }
        
        if (foundMovie != null) {
          foundMovies.add(foundMovie);
        }
      }
      
      // Load missing movies from database if needed
      if (missingMovieIds.isNotEmpty) {
        DebugLogger.log("🔄 Loading ${missingMovieIds.length} missing movies from database...");
        await _loadMissingMoviesFromDatabase(missingMovieIds, foundMovies);
      }
      
      // Update movie collections
      if (mounted && foundMovies.isNotEmpty) {
        setState(() {
          widget.currentUser.loadMoviesIntoCache(foundMovies);
        });
        
        DebugLogger.log("✅ Updated movie collections: ${foundMovies.length} movies total");
      }
      
    } catch (e) {
      DebugLogger.log("❌ Error loading movies from sessions: $e");
    }
  }

  Future<void> _loadMissingMoviesFromDatabase(Set<String> missingMovieIds, List<Movie> foundMovies) async {
    try {
      // Load the movie database
      final movieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      
      for (final movieId in missingMovieIds) {
        try {
          final movie = movieDatabase.firstWhere((m) => m.id == movieId);
          foundMovies.add(movie);
          DebugLogger.log("✅ Loaded missing movie from database: ${movie.title}");
        } catch (e) {
          DebugLogger.log("⚠️ Movie ID $movieId not found in movie database - skipping");
        }
      }
    } catch (e) {
      DebugLogger.log("❌ Error loading movie database: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show collaborative waiting screen if in collaborative mode
    if (widget.isInCollaborativeMode) {
      return _buildCollaborativeWaitingScreen();
    }
    
    // Show session history based on current mode
    return _buildSessionHistoryView();
  }

  Widget _buildSessionHistoryView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ ADD: SessionControlsWidget at the top of scrollable content
          SessionControlsWidget(
            currentMode: widget.currentMode,
            hasStartedSession: widget.hasStartedSession,
            selectedFriend: widget.selectedFriend,
            selectedGroup: widget.selectedGroup,
            currentUser: widget.currentUser,
            friendIds: widget.friendIds,
            onEndSession: widget.onEndSession,
            onStartPopularMovies: widget.onStartPopularMovies,
            onShowMoodPicker: widget.onShowMoodPicker,
            onGroupSelected: widget.onGroupSelected,
            onSessionCreated: widget.onSessionCreated,
            canStartSession: widget.canStartSession,
            formatDuration: widget.formatDuration,
          ),
          
          SizedBox(height: 24.h),
          
          // ✅ THEN: Show loading state or session history
          if (_isLoadingHistory)
            _buildLoadingState()
          else
            _buildModeSpecificHistory(),
        ],
      ),
    );
  }

  Widget _buildModeSpecificHistory() {
    switch (widget.currentMode) {
      case MatchingMode.solo:
        return _buildSoloHistory();
      case MatchingMode.friend:
        return _buildFriendHistory();
      case MatchingMode.group:
        return _buildGroupHistory();
    }
  }

  Widget _buildSoloHistory() {
    final soloSessions = _allDisplaySessions
        .where((s) => s.type == SessionType.solo)
        .toList();
    
    if (soloSessions.isEmpty) {
      return _buildEmptyHistoryState();
    }

    // Group sessions by time periods for better organization
    final groupedSessions = _groupSessionsByTime(soloSessions);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        _buildSectionHeader("Your Recent Sessions", soloSessions.length),
        SizedBox(height: 16.h),
        
        // Time-grouped sessions with accordions
        ...groupedSessions.entries.map((entry) {
          if (entry.value.isEmpty) return SizedBox.shrink();
          return _buildTimeGroupAccordion(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildFriendHistory() {
    final friendSessions = _allDisplaySessions
        .where((s) => s.type != SessionType.solo && s.participantNames.length == 2)
        .toList();
    
    if (friendSessions.isEmpty) {
      return _buildEmptyHistoryState();
    }

    // Group by friend
    final sessionsByFriend = <String, List<CompletedSession>>{};
    for (final session in friendSessions) {
      final friendName = session.getOtherParticipantsDisplay(widget.currentUser.name);
      sessionsByFriend[friendName] = [...(sessionsByFriend[friendName] ?? []), session];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Friend Sessions", friendSessions.length),
        SizedBox(height: 16.h),
        
        ...sessionsByFriend.entries.map((entry) {
          return _buildFriendGroupAccordion(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildGroupHistory() {
    final groupSessions = _allDisplaySessions
        .where((s) => s.type != SessionType.solo && s.participantNames.length >= 3)
        .toList();
    
    if (groupSessions.isEmpty) {
      return _buildEmptyHistoryState();
    }

    // Group by group participants
    final sessionsByGroup = <String, List<CompletedSession>>{};
    for (final session in groupSessions) {
      final groupKey = session.groupName ?? session.getOtherParticipantsDisplay(widget.currentUser.name);
      sessionsByGroup[groupKey] = [...(sessionsByGroup[groupKey] ?? []), session];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Group Sessions", groupSessions.length),
        SizedBox(height: 16.h),
        
        ...sessionsByGroup.entries.map((entry) {
          return _buildGroupAccordion(entry.key, entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Color(0xFFE5A00D).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Color(0xFFE5A00D),
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, List<CompletedSession>> _groupSessionsByTime(List<CompletedSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));
    final thisWeek = today.subtract(Duration(days: 7));

    final Map<String, List<CompletedSession>> grouped = {
      'Earlier Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      if (sessionDate.isAtSameMomentAs(today)) {
        grouped['Earlier Today']!.add(session);
      } else if (sessionDate.isAtSameMomentAs(yesterday)) {
        grouped['Yesterday']!.add(session);
      } else if (session.startTime.isAfter(thisWeek)) {
        grouped['This Week']!.add(session);
      } else {
        grouped['Earlier']!.add(session);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    
    return grouped;
  }

  Widget _buildTimeGroupAccordion(String timeLabel, List<CompletedSession> sessions) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              timeLabel,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Color(0xFFE5A00D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                sessions.length.toString(),
                style: TextStyle(
                  color: Color(0xFFE5A00D),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        iconColor: Colors.white60,
        collapsedIconColor: Colors.white60,
        initiallyExpanded: timeLabel == 'Earlier Today',
        children: sessions.map((session) => _buildSessionCard(session)).toList(),
      ),
    );
  }

  Widget _buildFriendGroupAccordion(String friendName, List<CompletedSession> sessions) {
    final totalMatches = sessions.fold(0, (sum, s) => sum + s.matchedMovieIds.length);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFE5A00D), Colors.orange]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  friendName[0].toUpperCase(),
                  style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                friendName,
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "$totalMatches matches",
              style: TextStyle(color: Color(0xFFE5A00D), fontSize: 12.sp),
            ),
          ],
        ),
        iconColor: Colors.white60,
        collapsedIconColor: Colors.white60,
        initiallyExpanded: false,
        children: sessions.map((session) => _buildSessionCard(session)).toList(),
      ),
    );
  }

  Widget _buildGroupAccordion(String groupName, List<CompletedSession> sessions) {
    final totalMatches = sessions.fold(0, (sum, s) => sum + s.matchedMovieIds.length);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              width: 30.w,
              height: 30.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFFE5A00D), Colors.orange]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.groups, color: Colors.white, size: 16.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                groupName,
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "$totalMatches matches",
              style: TextStyle(color: Color(0xFFE5A00D), fontSize: 12.sp),
            ),
          ],
        ),
        iconColor: Colors.white60,
        collapsedIconColor: Colors.white60,
        initiallyExpanded: false,
        children: sessions.map((session) => _buildSessionCard(session)).toList(),
      ),
    );
  }

  Widget _buildSessionCard(CompletedSession session) {
    final isActive = session.id.startsWith("active_");
    final isSolo = session.type == SessionType.solo;
    
    // Determine relevant movie IDs and count
    late final List<String> relevantMovieIds;
    if (isActive && session.id.startsWith("active_collaborative_")) {
      relevantMovieIds = session.matchedMovieIds;
    } else if (isSolo) {
      if (isActive) {
        relevantMovieIds = session.likedMovieIds;
      } else {
        relevantMovieIds = widget.currentUser.recentLikes
          .where((like) =>
            like.likedAt.isAfter(session.startTime) &&
            like.likedAt.isBefore(session.endTime))
          .map((like) => like.movieId)
          .toList();
      }
    } else {
      relevantMovieIds = session.matchedMovieIds;
    }

    final movieCount = relevantMovieIds.length;
    
    // Get preview movies for display
    final previewMovies = relevantMovieIds.take(4).map((movieId) {
      Movie? movie;
      try {
        movie = widget.currentUser.likedMovies.firstWhere((m) => m.id == movieId);
      } catch (e) {
        try {
          movie = widget.currentUser.matchedMovies.firstWhere((m) => m.id == movieId);
        } catch (e) {
          return null;
        }
      }
      return movie;
    }).where((movie) => movie != null).cast<Movie>().toList();

    final isCollaborativeSession = isActive && session.id.startsWith("active_collaborative_") || !isSolo;
    final countLabel = isCollaborativeSession
        ? (movieCount == 1 ? 'match' : 'matches')
        : (movieCount == 1 ? 'pick' : 'picks');

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: GestureDetector(
        onTap: () => _openSessionDetail(session),
        onLongPress: () => _showSessionMenu(session),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: movieCount > 0 ? 170.h : 120.h,
          borderRadius: 20,
          blur: 15,
          alignment: Alignment.centerLeft,
          border: 2,
          linearGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isActive
                ? [
                    Colors.green.withValues(alpha: 0.2),
                    Colors.green.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.05),
                  ]
                : [
                    const Color(0xFFB8860B).withValues(alpha: 0.2), // Golden brown
                    const Color(0xFF8B7D3A).withValues(alpha: 0.15), // Darker golden
                    Colors.white.withValues(alpha: 0.05),
                  ],
          ),
          borderGradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (isActive 
                  ? Colors.green 
                  : const Color(0xFFE5A00D)).withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.2),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                // Left side: Session info + movie posters
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Session type icon and title
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isActive 
                                    ? [Colors.green, Colors.green.shade600]
                                    : [const Color(0xFFE5A00D), Colors.orange],
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive ? Colors.green : const Color(0xFFE5A00D))
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8.r,
                                  spreadRadius: 1.r,
                                ),
                              ],
                            ),
                            child: Icon(
                              isActive 
                                  ? Icons.play_circle_filled 
                                  : isSolo 
                                      ? Icons.person 
                                      : Icons.people,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                          
                          SizedBox(width: 16.w),
                          
                          // Title and status
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        isActive 
                                            ? (isSolo ? "Current Solo Session" : "Current Group Session")
                                            : _generateSessionTitle(session),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(8.r),
                                        ),
                                        child: Text(
                                          "LIVE",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                
                                SizedBox(height: 4.h),
                                
                                // Time and participant info
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12.sp,
                                      color: Colors.white60,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      isActive 
                                          ? "In progress..." 
                                          : _formatRelativeDate(session.startTime),
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    if (!isSolo && session.participantNames.isNotEmpty) ...[
                                      SizedBox(width: 12.w),
                                      Icon(
                                        Icons.people_outline,
                                        size: 12.sp,
                                        color: Colors.white60,
                                      ),
                                      SizedBox(width: 4.w),
                                      Expanded(
                                        child: Text(
                                          session.groupName != null && session.groupName!.isNotEmpty 
                                              ? session.groupName!
                                              : session.getOtherParticipantsDisplay(widget.currentUser.name),
                                          style: TextStyle(
                                            color: Colors.blue.shade300,
                                            fontSize: 12.sp,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      // Movie posters (if movies exist)
                      if (movieCount > 0) ...[
                        SizedBox(height: 16.h),
                        
                        Container(
                          width: double.infinity,
                          child: Center(
                            child: Container(
                              width: movieCount >= 3 
                                  ? (3 * 40.w) + (2 * 35.w) + 40.w
                                  : movieCount == 2 
                                      ? (2 * 40.w) + (1 * 35.w)
                                      : 40.w,
                              height: 50.h,
                              child: Stack(
                                children: [
                                  ...previewMovies.take(3).toList().asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final movie = entry.value;
                                    return Positioned(
                                      left: index * 35.w,
                                      child: Container(
                                        width: 40.w,
                                        height: 50.h,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.r),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            width: 1.w,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(7.r),
                                          child: movie.posterUrl.isNotEmpty 
                                              ? Image.network(
                                                  movie.posterUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: Colors.grey[800],
                                                    child: Icon(
                                                      Icons.movie,
                                                      size: 16.sp,
                                                      color: Colors.white30,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  color: Colors.grey[800],
                                                  child: Icon(
                                                    Icons.movie,
                                                    size: 16.sp,
                                                    color: Colors.white30,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  
                                  // Placeholder icons for missing movies
                                  ...List.generate(
                                      (3 - previewMovies.length > 0) ? math.min(3 - previewMovies.length, movieCount - previewMovies.length) : 0,
                                    (index) {
                                      final position = previewMovies.length + index;
                                      if (position >= 3) return Container();
                                      
                                      return Positioned(
                                        left: position * 35.w,
                                        child: Container(
                                          width: 40.w,
                                          height: 50.h,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[800],
                                            borderRadius: BorderRadius.circular(8.r),
                                            border: Border.all(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              width: 1.w,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.movie,
                                            size: 16.sp,
                                            color: Colors.white30,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  // "+X more" badge
                                  if (movieCount > 3)
                                    Positioned(
                                      left: 3 * 35.w,
                                      child: Container(
                                        width: 40.w,
                                        height: 50.h,
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(8.r),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            width: 1.w,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            "+${movieCount - 3}",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(width: 16.w),
                
                // Right side: Action buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Movie count badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive 
                              ? [Colors.green, Colors.green.shade600]
                              : [const Color(0xFFE5A00D), Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                          "$movieCount $countLabel",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    // Action button
                    GestureDetector(
                      onTap: () => isActive 
                          ? _resumeSession(session)
                          : _openSessionDetail(session),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.play_arrow : Icons.arrow_forward,
                              size: 12.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              isActive ? "Resume" : "View",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
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
          ),
        ),
      ),
    );
  }

  void _resumeSession(CompletedSession session) {
    // TODO: Navigate back to matcher with session resume
    DebugLogger.log("🔄 Resume session: ${session.id}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resume session feature - connect to matcher'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openSessionDetail(CompletedSession session) {
    DebugLogger.log("👁️ Opening session detail: ${session.id}");
    
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionDetailScreen(
            session: session,
            currentUser: widget.currentUser,
            onStartNewSession: () {
              DebugLogger.log("🚀 Starting new session from detail screen");
              
              // Navigate back to the main screen (pop all routes until main)
              Navigator.of(context).popUntil((route) => route.isFirst);
              
              // Show success message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ready to start a new session!'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      DebugLogger.log("❌ Error navigating to session detail: $e");
      
      // Fallback: show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open session details. Please try again.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showSessionMenu(CompletedSession session) {
    final isActive = session.id.startsWith("active_");
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1F1F1F), Color(0xFF121212)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
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
            
            SizedBox(height: 20.h),
            
            Text(
              _generateSessionTitle(session),
              style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            
            SizedBox(height: 20.h),
            
            if (isActive) ...[
              _buildMenuOption(
                icon: Icons.play_arrow,
                title: "Resume Session",
                subtitle: "Continue where you left off",
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _resumeSession(session);
                },
              ),
              SizedBox(height: 12.h),
            ] else ...[
              _buildMenuOption(
                icon: Icons.visibility,
                title: "View Details",
                subtitle: "See full session summary",
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _openSessionDetail(session);
                },
              ),
              SizedBox(height: 12.h),
            ],
            
            _buildMenuOption(
              icon: Icons.delete,
              title: "Delete Session",
              subtitle: isActive ? "End and delete this session" : "Remove from history",
              color: Colors.red,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _deleteSession(session, isActive);
              },
            ),
            
            SizedBox(height: 20.h),
            
            // Cancel button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDestructive 
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isDestructive 
                ? Colors.red.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            
            SizedBox(width: 16.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive ? Colors.red : Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDestructive ? Colors.red.shade300 : Colors.white60,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: isDestructive ? Colors.red : Colors.white30,
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSession(CompletedSession session, bool isActive) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          isActive ? "Delete Active Session?" : "Delete Session?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          isActive 
              ? "This will end and permanently delete your current session. This action cannot be undone."
              : "This will permanently delete this session from your history. This action cannot be undone.",
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
              Navigator.of(context).pop();
              await _performSessionDeletion(session, isActive);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _performSessionDeletion(CompletedSession session, bool isActive) async {
    try {
      if (isActive) {
        // Handle active session deletion
        SessionManager.endSession();
        DebugLogger.log("✅ Active session ended without saving");
      } else {
        // Use unified session manager for proper deletion
        await UnifiedSessionManager.deleteSessionProperly(
          session: session,
          userProfile: widget.currentUser,
        );
      }

      // Refresh the session list
      await _loadSessionHistory();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Active session deleted' : 'Session deleted'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

    } catch (e) {
      DebugLogger.log("❌ Error deleting session: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete session: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildEmptyHistoryState() {
    return Container(
      width: double.infinity,
      // Add minimum height to ensure proper centering
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // ✅ ADD THIS
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ ADD THIS
        children: [
          Icon(
            Icons.history,
            size: 48.sp,
            color: Colors.white30,
          ),
          SizedBox(height: 16.h),
          Text(
            "No ${widget.currentMode.name} sessions yet",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center, // ✅ ADD THIS
          ),
          SizedBox(height: 8.h),
          Text(
            "Start your first session to see it here",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14.sp,
            ),
            textAlign: TextAlign.center, // ✅ ADD THIS
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFFE5A00D),
            strokeWidth: 2.w,
          ),
          SizedBox(height: 16.h),
          Text(
            "Loading your sessions...",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  // Keep the existing collaborative waiting screen
  Widget _buildCollaborativeWaitingScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated waiting indicator with glassmorphic design
            GlassmorphicContainer(
              width: 140.w,
              height: 140.h,
              borderRadius: 70,
              blur: 20,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A90E2).withValues(alpha: 0.2),
                  const Color(0xFF357ABD).withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF4A90E2).withValues(alpha: 0.6),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated circular progress
                  SizedBox(
                    width: 80.r,
                    height: 80.r,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
                      strokeWidth: 3.w,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  // Center icon
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFF4A90E2), const Color(0xFF357ABD)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people,
                      size: 24.sp,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 32.h),
            
            // Status text
            Text(
              widget.isWaitingForFriend 
                  ? "Waiting for your friend..."
                  : widget.currentSession != null && widget.currentSession!.moviePool.isEmpty
                    ? "Waiting for host to set up movies..."
                    : "Get ready to swipe!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16.h),
            
            // Subtitle with glassmorphic background
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.w,
                ),
              ),
              child: Text(
                widget.isWaitingForFriend 
                    ? "They'll join using your session code"
                    : "Choose your mood and start finding movies together!",
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14.sp,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Session code display if available
            if (widget.currentSession?.sessionCode != null) ...[
              SizedBox(height: 24.h),
              GlassmorphicContainer(
                width: double.infinity,
                height: 60.h,
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
                    const Color(0xFF4A90E2).withValues(alpha: 0.4),
                    Colors.white.withValues(alpha: 0.2),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    children: [
                      Text(
                        "Session Code",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.currentSession!.sessionCode!,
                        style: TextStyle(
                          color: const Color(0xFF4A90E2),
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _generateSessionTitle(CompletedSession session) {
    final isSolo = session.type == SessionType.solo;
    final movieCount = isSolo ? session.likedMovieIds.length : session.matchedMovieIds.length;
    
    if (session.id.startsWith("active_")) {
      return isSolo ? "Current Solo Session" : "Current Group Session";
    }
    
    if (movieCount == 0) {
      return isSolo ? "Quick Browse" : "Group Session";
    }
    
    if (isSolo) {
      final timeOfDay = session.startTime.hour;
      if (timeOfDay >= 18) {
        if (movieCount == 1) return "Evening Pick";
        if (movieCount <= 3) return "Night Browsing";
        return "Late Night Hunt";
      } else if (timeOfDay >= 12) {
        if (movieCount == 1) return "Afternoon Find";
        if (movieCount <= 3) return "Midday Picks";
        return "Afternoon Session";
      } else {
        if (movieCount == 1) return "Morning Discovery";
        if (movieCount <= 3) return "Morning Picks";
        return "Early Session";
      }
    } else {
      if (movieCount == 1) return "Perfect Match";
      if (movieCount <= 3) return "Group Consensus";
      if (movieCount <= 7) return "Movie Night Planning";
      return "Epic Group Session";
    }
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}