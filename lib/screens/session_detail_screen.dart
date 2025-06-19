// File: lib/screens/session_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/completed_session.dart';
import '../utils/debug_loader.dart';
import '../utils/movie_loader.dart';
import '../screens/watch_options_screen.dart';
import 'package:glassmorphism/glassmorphism.dart';

class SessionDetailScreen extends StatefulWidget {
  final CompletedSession session;
  final UserProfile currentUser;
  final VoidCallback? onStartNewSession;

  const SessionDetailScreen({
    super.key,
    required this.session,
    required this.currentUser,
    this.onStartNewSession,
  });

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> 
    with TickerProviderStateMixin {
  late PageController _pageController;
  late TabController _tabController;
  List<Movie> _sessionMovies = [];
  List<Movie> _matchedMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // Only create TabController for solo sessions that might need it in the future
    // For now, we're not using tabs for collaborative sessions
    _tabController = TabController(length: 1, vsync: this);
    
    _loadSessionMovies();
  }

  Future<void> _loadSessionMovies() async {
    try {
      final movieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      final isSolo = widget.session.type == SessionType.solo;
      
      if (isSolo) {
        // Solo session: load all liked movies
        final likedMovies = <Movie>[];
        for (final movieId in widget.session.likedMovieIds) {
          try {
            final movie = movieDatabase.firstWhere((m) => m.id == movieId);
            likedMovies.add(movie);
          } catch (e) {
            DebugLogger.log("⚠️ Could not find movie for ID: $movieId");
          }
        }
        _sessionMovies = likedMovies;
      } else {
        // Collaborative session: only load matched movies
        final matchedMovies = <Movie>[];
        
        // Load matched movies
        for (final movieId in widget.session.matchedMovieIds) {
          try {
            final movie = movieDatabase.firstWhere((m) => m.id == movieId);
            matchedMovies.add(movie);
          } catch (e) {
            DebugLogger.log("⚠️ Could not find matched movie for ID: $movieId");
          }
        }
        
        _matchedMovies = matchedMovies;
        _sessionMovies = matchedMovies; // Show matches by default
        
        // For collaborative sessions, we don't have individual user likes stored
        // so we'll just show matches. The tab system will be simplified.
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      DebugLogger.log("❌ Error loading session movies: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildGlassHeader() {
    final isSolo = widget.session.type == SessionType.solo;
    final timeAgo = _formatRelativeDate(widget.session.startTime);
    
    return GlassmorphicContainer(
      width: double.infinity,
      height: 130.h, // Reduced height
      borderRadius: 0,
      blur: 15,
      alignment: Alignment.bottomCenter,
      border: 0,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.05),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            children: [
              // Back button row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: GlassmorphicContainer(
                      width: 120.w,
                      height: 32.h,
                      borderRadius: 8,
                      blur: 4,
                      alignment: Alignment.center,
                      border: 1,
                      linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (isSolo ? Color(0xFFE5A00D) : Colors.blue).withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          (isSolo ? Color(0xFFE5A00D) : Colors.blue).withValues(alpha: 0.8),
                          Colors.white.withValues(alpha: 0.3),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_ios, color: Colors.white, size: 12.sp),
                          SizedBox(width: 2.w),
                          Text(
                            "Back to Sessions",
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
                  
                  Spacer(),
                  
                  // Session info
                  GlassmorphicContainer(
                    width: 120.w,
                    height: 32.h,
                    borderRadius: 16,
                    blur: 4,
                    alignment: Alignment.center,
                    border: 1,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (isSolo ? Color(0xFFE5A00D) : Colors.blue).withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        (isSolo ? Color(0xFFE5A00D) : Colors.blue).withValues(alpha: 0.8),
                        Colors.white.withValues(alpha: 0.3),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSolo ? Icons.person : Icons.people,
                          color: isSolo ? Color(0xFFE5A00D) : Colors.blue,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 6.h), // Reduced spacing
              
              // Session title
              Text(
                widget.session.funTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp, // Reduced font size
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (!isSolo)
                Text(
                  "With ${widget.session.participantNames.where((name) => name != "You").join(", ")}",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11.sp, // Reduced font size
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    final isSolo = widget.session.type == SessionType.solo;
    
    // For now, don't show tabs for collaborative sessions since we only have matches
    // In the future, we could track individual user likes per session to enable this
    if (isSolo) {
      return SizedBox(height: 8.h); // Small spacing for solo sessions
    }
    
    // Show session type indicator for collaborative sessions
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 45.h,
        borderRadius: 22,
        blur: 8,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.4),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, color: Colors.blue, size: 16.sp),
            SizedBox(width: 8.w),
            Text(
              "Matched Movies (${_matchedMovies.length})",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieGrid() {
    if (_sessionMovies.isEmpty) {
      return Container(
        height: 200.h,
        child: _buildEmptyState(),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 0.65, // Adjusted to prevent overflow
        ),
        itemCount: _sessionMovies.length,
        itemBuilder: (context, index) {
          final movie = _sessionMovies[index];
          return _buildMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () => _openWatchOptions(movie),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 16,
        blur: 8,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE5A00D).withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Column(
          children: [
            // Movie poster
            Expanded(
              flex: 5, // Increased poster area
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.all(8.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    children: [
                      Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[800],
                          child: Icon(Icons.movie, color: Colors.white30, size: 32.sp),
                        ),
                      ),
                      
                      // Rating overlay
                      if (movie.rating != null)
                        Positioned(
                          top: 8.h,
                          right: 8.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star, color: Color(0xFFE5A00D), size: 12.sp),
                                SizedBox(width: 2.w),
                                Text(
                                  movie.rating!.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // Tap indicator
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: Color(0xFFE5A00D).withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.play_arrow, color: Colors.white, size: 14.sp),
                                  SizedBox(width: 4.w),
                                  Text(
                                    "WATCH",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
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
            
            // Movie info - Reduced height
            Container(
              width: double.infinity,
              height: 50.h, // Fixed height to prevent overflow
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    movie.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (movie.releaseDate != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      _getYearFromDate(movie.releaseDate!),
                      style: TextStyle(
                        color: Color(0xFFE5A00D),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isSolo = widget.session.type == SessionType.solo;
    
    String title, subtitle;
    IconData icon;
    
    if (isSolo) {
      title = "No Movies Liked";
      subtitle = "You didn't like any movies in this session";
      icon = Icons.movie_outlined;
    } else {
      title = "No Matches";
      subtitle = "You and your friends didn't agree on any movies in this session";
      icon = Icons.sentiment_neutral;
    }
    
    return Container(
      height: 200.h, // Fixed height
      margin: EdgeInsets.all(32.w),
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48.sp, color: Colors.white30),
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Start new session button
          SizedBox(
            width: double.infinity,
            height: 50.h, // Reduced height
            child: ElevatedButton.icon(
              onPressed: widget.onStartNewSession,
              icon: Icon(Icons.add, size: 20.sp),
              label: Text(
                'Start New Session',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE5A00D),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 4,
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Session stats
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Session Stats",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Duration", _formatDuration(widget.session.duration)),
                    _buildStatItem("Total Swipes", "${widget.session.totalSwipes}"),
                    _buildStatItem(
                      widget.session.type == SessionType.solo ? "Liked" : "Matches", 
                      "${widget.session.type == SessionType.solo ? widget.session.likedMovieIds.length : widget.session.matchedMovieIds.length}",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Color(0xFFE5A00D),
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFE5A00D)),
              SizedBox(height: 16.h),
              Text(
                "Loading session details...",
                style: TextStyle(color: Colors.white70, fontSize: 16.sp),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // Glass header
          SliverToBoxAdapter(
            child: _buildGlassHeader(),
          ),
          
          // Tab section (for collaborative sessions)
          SliverToBoxAdapter(
            child: _buildTabSection(),
          ),
          
          // Movie grid
          SliverToBoxAdapter(
            child: _buildMovieGrid(),
          ),
          
          // Action buttons
          SliverToBoxAdapter(
            child: _buildActionButtons(),
          ),
          
          // Bottom padding to prevent overflow
          SliverToBoxAdapter(
            child: SizedBox(height: 60.h),
          ),
        ],
      ),
    );
  }

  // Helper methods
  void _openWatchOptions(Movie movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WatchOptionsScreen(
          movie: movie,
          currentUser: widget.currentUser,
          onContinueSession: () {
            Navigator.pop(context); // Close watch options
            if (widget.onStartNewSession != null) {
              widget.onStartNewSession!(); // Start new session
            }
          },
        ),
      ),
    );
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

  String _getYearFromDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.year.toString();
    } catch (e) {
      return dateString;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}