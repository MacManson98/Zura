// File: lib/screens/home_screen.dart - Enhanced Version
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import '../screens/liked_movies_screen.dart';
import '../screens/matches_screen.dart';
import '../utils/completed_session.dart';
import 'dart:math';

import '../utils/debug_loader.dart';
import '../utils/movie_loader.dart';
import '../utils/tmdb_api.dart';
import 'movie_detail_screen.dart';
import 'trending_movies_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  final List<Movie> movies;
  final VoidCallback? onNavigateToMatches;
  final VoidCallback? onNavigateToMatcher;
  final VoidCallback? onNavigateToFriends;
  final VoidCallback? onNavigateToNotifications;
  final Function(UserProfile)? onProfileUpdate;
  final VoidCallback? onNavigateToSoloMatcher;
  final VoidCallback? onNavigateToFriendMatcher;
  final VoidCallback? onNavigateToGroupMatcher;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.movies,
    this.onNavigateToMatches,
    this.onNavigateToMatcher,
    this.onNavigateToFriends,
    this.onNavigateToNotifications,
    this.onProfileUpdate,
    this.onNavigateToSoloMatcher,
    this.onNavigateToFriendMatcher,
    this.onNavigateToGroupMatcher,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  
  // Simple state - no complex provider needed
  Movie? _randomPick;
  bool _isLoadingRandom = false;
  late AnimationController _randomButtonController;
  late Animation<double> _randomButtonAnimation;
  int _actualMatchCount = 0;
  List<Movie> _completeMovieDatabase = [];
  List<Movie> _trendingMovies = [];
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print('🏠 Enhanced HomeScreen: initState called');
      print('🏠 Profile: ${widget.profile.name}');
      print('🏠 Movies count: ${widget.movies.length}');
    }
    
    // Simple animation setup
    _randomButtonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _randomButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _randomButtonController,
      curve: Curves.elasticOut,
    ));
    _loadSessionBasedMatches();
    _loadTrendingMovies();
    _loadCompleteMovieDatabase();
  }

  @override
  void dispose() {
    _randomButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('🏠 Enhanced HomeScreen: build called');
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              
              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.h),
                      
                      // Quick Stats
                      _buildQuickStats(),
                      SizedBox(height: 24.h),

                      // Mode Selection
                      _buildModeSelection(),
                      SizedBox(height: 24.h),
                      
                      // Film Identity (NEW)
                      if (_hasFilmIdentity()) ...[
                        _buildFilmIdentity(),
                        SizedBox(height: 24.h),
                      ],
                      
                      // Random Movie Picker (ENHANCED)
                      _buildRandomMoviePicker(),
                      SizedBox(height: 24.h),
                      
                      // Recommended Movies (NEW)
                      _buildRecommendedMovies(),
                      SizedBox(height: 24.h),
                      
                      // Trending Movies
                      _buildTrendingMovies(),
                      
                      // Bottom padding for nav bar
                      SizedBox(height: 100.h),
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

  Future<void> _loadCompleteMovieDatabase() async {
    _completeMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
    if (mounted){
    setState(() {});
    }
  }

  Future<void> _loadSessionBasedMatches() async {
    try {
      if (kDebugMode) {
        print("🔍 Loading session-based matches for HomeScreen...");
      }
      final allSessions = await widget.profile.getAllSessionsForDisplay();
      
      int totalMatches = 0;
      for (final session in allSessions) {
        if (session.type != SessionType.solo) {
          totalMatches += session.matchedMovieIds.length;
        }
      }
      
      if (kDebugMode) {
        print("📊 Total matches found across sessions: $totalMatches");
      }
      
      if (mounted) {
        setState(() {
          _actualMatchCount = totalMatches;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error loading session matches: $e");
      }
    }
  }

  void _navigateToLikedMovies() {
    if (kDebugMode) {
      print('📱 Navigating to Liked Movies');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LikedMoviesScreen(
          currentUser: widget.profile,
          onProfileUpdate: (updatedProfile) {
            widget.onProfileUpdate?.call(updatedProfile);
          },
        ),
      ),
    );
  }

  void _navigateToMatches() {
    if (kDebugMode) {
      print('📱 Navigating to Matches');
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchesScreen(
          currentUser: widget.profile,
          onProfileUpdate: (updatedProfile) {
            widget.onProfileUpdate?.call(updatedProfile);
          },
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: const LinearGradient(
                colors: [Color(0xFFE5A00D), Color(0xFFFF8A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                  blurRadius: 12.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.profile.name.isNotEmpty 
                  ? widget.profile.name[0].toUpperCase() 
                  : 'U',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 16.w),
          
          // Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, ${_getDisplayName()}! 👋',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Ready to discover something amazing?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1F1F1F),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Movies Liked - Clickable
          GestureDetector(
            onTap: _navigateToLikedMovies,
            child: _buildStatItem(
              '${widget.profile.likedMovieIds.length}',
              'Movies Liked',
              const Color(0xFFE5A00D),
              Icons.favorite,
            ),
          ),
          _buildStatDivider(),
          // Matches - Clickable (using your actual matches calculation)
          GestureDetector(
            onTap: _navigateToMatches,
            child: _buildStatItem(
              '$_actualMatchCount',
              'Matches',
              Colors.red,
              Icons.local_fire_department,
            ),
          ),
          _buildStatDivider(),
          // Friends - Clickable
          GestureDetector(
            onTap: _navigateToTrendingMovies,
            child: _buildStatItem(
              _isLoadingTrending 
                  ? '...' 
                  : '8', // Show fixed number since we show top 8
              'Trending Now',
              Colors.orange,
              Icons.whatshot,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildStatItem(String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: color.withValues(alpha: 0.4),
              width: 1.w,
            ),
          ),
          child: Icon(icon, color: color, size: 20.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1.w,
      height: 40.h,
      color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
    );
  }

  Widget _buildModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose how you watch',
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
              child: _buildModeCard(
                'Solo',
                'Your taste',
                Icons.person,
                const Color(0xFFE5A00D),
                () => widget.onNavigateToSoloMatcher?.call(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildModeCard(
                'Friend',
                'Match together',
                Icons.people,
                Colors.purple,
                () => widget.onNavigateToFriendMatcher?.call(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildModeCard(
                'Group',
                'Party mode',
                Icons.groups,
                Colors.indigo,
                () => widget.onNavigateToGroupMatcher?.call(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeCard(String title, String subtitle, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 28.sp, color: color),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Film Identity Section
  Widget _buildFilmIdentity() {
    final identity = _getFilmIdentity();
    final topGenres = _getTopGenres();
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'You\'re $identity!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            children: topGenres.map((genre) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                genre,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ENHANCED: Random Movie Picker with Animation
  Widget _buildRandomMoviePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feeling Adventurous?',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 16.h),
        AnimatedBuilder(
          animation: _randomButtonAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _randomButtonAnimation.value,
              child: GestureDetector(
                onTap: _generateRandomPick,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFE5A00D).withValues(alpha: 0.3),
                        Colors.orange.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          _isLoadingRandom ? Icons.hourglass_empty : Icons.casino,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoadingRandom ? "Finding your film..." : "Random Film",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Let us surprise you with something great",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (_randomPick != null) ...[
          SizedBox(height: 16.h),
          _buildRandomPickResult(),
        ],
      ],
    );
  }

  Widget _buildRandomPickResult() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1F1F1F),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.network(
              _randomPick!.posterUrl,
              width: 60.w,
              height: 90.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60.w,
                height: 90.h,
                color: Colors.grey[800],
                child: Icon(Icons.movie, size: 30.sp, color: Colors.white30),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _randomPick!.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8.h),
                Text(
                  _randomPick!.genres.take(2).join(' • '),
                  style: TextStyle(
                    color: const Color(0xFFE5A00D),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: const Color(0xFFE5A00D),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Recommended Movies
  Widget _buildRecommendedMovies() {
    final recommendations = _getRecommendedMovies();
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink(); // Don't show section if empty
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recommended for You',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                  width: 1.w,
                ),
              ),
              child: Text(
                'Based on your likes',
                style: TextStyle(
                  color: const Color(0xFFE5A00D),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final movie = recommendations[index];
              return Container(
                width: 120.w,
                margin: EdgeInsets.only(right: 12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showMovieDetails(movie),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: Image.network(
                              movie.posterUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFF2A2A2A),
                                child: Icon(Icons.movie, size: 40.sp, color: Colors.white30),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      movie.title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (movie.rating != null)
                      Text(
                        '⭐ ${movie.rating!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: const Color(0xFFE5A00D),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _loadTrendingMovies() async {
    if (mounted){
    setState(() => _isLoadingTrending = true);
    }
    try {
      final trending = await _getTrendingMovies();
      setState(() {
        _trendingMovies = trending;
        _isLoadingTrending = false;
      });
    } catch (e) {
      DebugLogger.log("❌ Error loading trending movies: $e");
      setState(() => _isLoadingTrending = false);
    }
  }

  Widget _buildTrendingMovies() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                      width: 1.w,
                    ),
                  ),
                  child: Icon(
                    Icons.trending_up,
                    color: const Color(0xFFE5A00D),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trending This Week',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Text(
                      _isLoadingTrending 
                          ? 'Loading from TMDB...'
                          : _trendingMovies.isEmpty
                              ? 'No trending movies found'
                              : 'Popular on TMDB',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLoadingTrending ? Icons.hourglass_empty : Icons.whatshot,
                    color: const Color(0xFFE5A00D),
                    size: 12.sp,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    _isLoadingTrending ? 'Loading' : 'Live',
                    style: TextStyle(
                      color: const Color(0xFFE5A00D),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        
        // Loading state
        if (_isLoadingTrending)
          GlassmorphicContainer(
            width: double.infinity,
            height: 120.h,
            borderRadius: 16,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFFE5A00D).withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    color: const Color(0xFFE5A00D),
                    strokeWidth: 2.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Loading trending from TMDB...',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          )
        // Empty state
        else if (_trendingMovies.isEmpty)
          GlassmorphicContainer(
            width: double.infinity,
            height: 120.h,
            borderRadius: 16,
            blur: 15,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.trending_down,
                  color: Colors.white30,
                  size: 32.sp,
                ),
                SizedBox(height: 8.h),
                Text(
                  'No trending movies available',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: _loadTrendingMovies,
                  child: Text(
                    'Tap to retry',
                    style: TextStyle(
                      color: const Color(0xFFE5A00D),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        // Trending movies list
        else ...[
          // Show top 3 trending movies
          ..._trendingMovies.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final movie = entry.value;
            final rank = index + 1;
            final stats = _getTrendingStats(movie, rank);
            
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1F1F1F),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: rank == 1 
                    ? const Color(0xFFE5A00D).withValues(alpha: 0.4)
                    : const Color(0xFFE5A00D).withValues(alpha: 0.2),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showMovieDetails(
                      context: context,
                      movie: movie,
                      currentUser: widget.profile,
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: rank == 1 
                                ? [const Color(0xFFE5A00D), Colors.orange.shade600]
                                : [Colors.grey[600]!, Colors.grey[700]!],
                            ),
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: (rank == 1 ? const Color(0xFFE5A00D) : Colors.grey[600]!)
                                    .withValues(alpha: 0.3),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        
                        // Movie poster
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            movie.posterUrl,
                            width: 50.w,
                            height: 75.h,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 50.w,
                              height: 75.h,
                              color: Colors.grey[800],
                              child: Icon(Icons.movie, size: 20.sp, color: Colors.white30),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        
                        // Movie info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                movie.title,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                movie.genres.take(2).join(' • '),
                                style: TextStyle(
                                  color: const Color(0xFFE5A00D),
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              
                              // Trending stats
                              Row(
                                children: [
                                  Icon(
                                    stats['trend'] == 'up' ? Icons.trending_up : Icons.whatshot,
                                    color: stats['trend'] == 'up' ? Colors.green : Colors.orange,
                                    size: 14.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${stats['views']} views',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 12.sp,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${stats['likes']}',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Action button
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                              width: 1.w,
                            ),
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: const Color(0xFFE5A00D),
                            size: 20.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          
          // "View all trending" button
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: _navigateToTrendingMovies,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All Trending',
                    style: TextStyle(
                      color: const Color(0xFFE5A00D),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xFFE5A00D),
                    size: 14.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showMovieDetails(Movie movie) {
    showMovieDetails(
      context: context,
      movie: movie,
      currentUser: widget.profile,
      onAddToFavorites: (movie) {
        if (kDebugMode) {
          print('➕ Adding movie to favorites: ${movie.title}');
        }
        // Add to user's liked movies
        final updatedProfile = widget.profile.copyWith(
          likedMovieIds: {...widget.profile.likedMovieIds, movie.id},
        );
        widget.onProfileUpdate?.call(updatedProfile);
      },
      onRemoveFromFavorites: (movie) {
        if (kDebugMode) {
          print('➖ Removing movie from favorites: ${movie.title}');
        }
        // Remove from user's liked movies
        final updatedLikedIds = widget.profile.likedMovieIds.where((id) => id != movie.id).toList();
        final updatedProfile = widget.profile.copyWith(
          likedMovieIds: updatedLikedIds.toSet(),
        );
        widget.onProfileUpdate?.call(updatedProfile);
      },
      isInFavorites: widget.profile.likedMovieIds.contains(movie.id),
    );
  }

  // LOGIC METHODS (from your original HomeScreen)
  
  Future<void> _generateRandomPick() async {
    if (_isLoadingRandom || widget.movies.isEmpty) return;

    setState(() => _isLoadingRandom = true);
    _randomButtonController.forward().then((_) => _randomButtonController.reverse());
    
    await Future.delayed(const Duration(milliseconds: 600));

    final random = Random();
    List<Movie> availableMovies = widget.movies.where((movie) => 
        !widget.profile.likedMovies.contains(movie)).toList();
    if (availableMovies.isEmpty) availableMovies = widget.movies;

    setState(() {
      _randomPick = availableMovies[random.nextInt(availableMovies.length)];
      _isLoadingRandom = false;
    });
  }

  List<Movie> _getRecommendedMovies() {
    try {
      if (widget.profile.likedMovies.isEmpty) {
        // If no liked movies yet, return high-quality movies
        final highQuality = widget.movies.where((movie) => 
          (movie.rating ?? 0.0) >= 7.5
        ).toList();
        highQuality.shuffle();
        return highQuality.take(6).toList();
      }

      // Extract genres from liked movies
      final likedGenres = <String, int>{};
      for (final movie in widget.profile.likedMovies) {
        for (final genre in movie.genres) {
          likedGenres[genre] = (likedGenres[genre] ?? 0) + 1;
        }
      }

      // Find movies in your preferred genres that you haven't liked yet
      final recommendations = widget.movies.where((movie) {
        // Skip if already liked
        if (widget.profile.likedMovies.contains(movie)) return false;
        
        // Check if movie has genres you like
        final hasPreferredGenre = movie.genres.any((genre) => 
          likedGenres.containsKey(genre)
        );
        
        // Only include good quality movies
        final isGoodQuality = (movie.rating ?? 0.0) >= 6.5;
        
        return hasPreferredGenre && isGoodQuality;
      }).toList();

      // Score based on how much you like each genre
      recommendations.sort((a, b) {
        double scoreA = 0;
        double scoreB = 0;
        
        for (final genre in a.genres) {
          scoreA += likedGenres[genre] ?? 0;
        }
        for (final genre in b.genres) {
          scoreB += likedGenres[genre] ?? 0;
        }
        
        return scoreB.compareTo(scoreA);
      });

      if (kDebugMode) {
        print('🎯 Generated ${recommendations.length} recommendations based on ${likedGenres.length} preferred genres');
      }

      return recommendations.take(6).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error generating recommendations: $e');
      }
      return [];
    }
  }

  Future<List<Movie>> _getTrendingMovies() async {
    try {
      DebugLogger.log("🔥 Loading trending movies from TMDB + local database...");
      
      // Step 1: Get trending movie IDs from TMDB API
      final trendingIds = await TMDBApi.getTrendingMovieIds(timeWindow: 'week');
      DebugLogger.log("📋 Got ${trendingIds.length} trending IDs from TMDB: ${trendingIds.take(5)}");
      
      if (trendingIds.isEmpty) {
        DebugLogger.log("⚠️ No trending IDs from TMDB, using fallback");
        return _getFallbackTrendingMovies();
      }
      
      // Step 2: Load your complete local movie database
      final localMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      DebugLogger.log("💾 Local database loaded: ${localMovieDatabase.length} movies");
      
      if (localMovieDatabase.isEmpty) {
        DebugLogger.log("⚠️ Local database is empty, using widget.movies as fallback");
        return _getFallbackTrendingMovies();
      }
      
      // Step 3: Find trending movies in your local database (preserving TMDB order)
      final trendingMovies = <Movie>[];
          int foundCount = 0;
          int notFoundCount = 0;
          
          for (final trendingId in trendingIds) {
            // Find movie in local database by ID
            final foundMovie = localMovieDatabase.cast<Movie?>().firstWhere(
              (movie) => movie?.id == trendingId,
              orElse: () => null,
            );
            
            if (foundMovie != null && !widget.profile.likedMovies.contains(foundMovie)) {
              trendingMovies.add(foundMovie);
              foundCount++;
              DebugLogger.log("✅ Found trending movie: ${foundMovie.title} (ID: $trendingId)");
            } else {
              notFoundCount++;
              if (notFoundCount <= 3) { // Only log first few misses to avoid spam
                DebugLogger.log("❌ Trending movie ID $trendingId not found in local database");
              }
            }
            
            // Stop when we have enough movies
            if (trendingMovies.length >= 8) break;
          }
          
          DebugLogger.log("📊 Trending results: Found $foundCount, Not found $notFoundCount");
          
      // Step 4: If we don't have enough trending matches, fill with high-quality local movies
      if (trendingMovies.length < 3) {
        DebugLogger.log("⚠️ Only found ${trendingMovies.length} trending movies, adding high-quality local movies");
        final fallbackMovies = MovieDatabaseLoader.getHighQualityMovies(
          localMovieDatabase,
          minRating: 7.0,
          minVotes: 500,
          limit: 8 - trendingMovies.length,
        );
        
        // Add fallback movies that aren't already in trending and user hasn't liked
        for (final movie in fallbackMovies) {
          if (!trendingMovies.contains(movie) && 
              !widget.profile.likedMovies.contains(movie) &&
              trendingMovies.length < 8) {
            trendingMovies.add(movie);
          }
        }
      }
      
      DebugLogger.log("🎬 Final trending list: ${trendingMovies.length} movies");
      DebugLogger.log("🎭 Sample: ${trendingMovies.take(3).map((m) => m.title).join(', ')}");
      
      return trendingMovies;
      
    } catch (e) {
      DebugLogger.log("❌ Error loading trending movies: $e");
      return _getFallbackTrendingMovies();
    }
  }

  List<Movie> _getFallbackTrendingMovies() {
    try {
      // Use complete movie database if available
      final movies = _completeMovieDatabase.isNotEmpty ? _completeMovieDatabase : widget.movies;
      
      if (movies.isEmpty) {
        DebugLogger.log("⚠️ No movies available for fallback trending");
        return [];
      }
      
      // Use MovieDatabaseLoader to get high-quality movies
      final highQualityMovies = MovieDatabaseLoader.getHighQualityMovies(
        movies,
        minRating: 7.0,
        minVotes: 500,
        limit: 20,
      );
      
      // Filter out already liked movies
      final candidateMovies = highQualityMovies.where((movie) =>
        !widget.profile.likedMovies.contains(movie)
      ).toList();
      
      // Shuffle for variety
      final now = DateTime.now();
      candidateMovies.shuffle(Random(now.day + now.month));
      
      DebugLogger.log("🔄 Fallback trending: ${candidateMovies.length} high-quality movies");
      return candidateMovies.take(8).toList();
      
    } catch (e) {
      DebugLogger.log("❌ Error in fallback trending: $e");
      return [];
    }
  }

  Map<String, dynamic> _getTrendingStats(Movie movie, int rank) {
    final random = Random(movie.title.hashCode + rank);
    final baseViews = 800 - (rank * 50); // Higher rank = more views
    final views = baseViews + random.nextInt(300);
    final likes = (views * 0.12).round() + random.nextInt(40);
    final trend = rank <= 3 ? "hot" : (random.nextBool() ? "up" : "stable");
    
    return {
      'views': views,
      'likes': likes,
      'trend': trend,
    };
  }


  void _navigateToTrendingMovies() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrendingMoviesScreen(
          currentUser: widget.profile,
          onProfileUpdate: (updatedProfile) {
            widget.onProfileUpdate?.call(updatedProfile);
          },
        ),
      ),
    );
  }

  bool _hasFilmIdentity() {
    return widget.profile.genreScores.isNotEmpty || widget.profile.vibeScores.isNotEmpty;
  }

  String _getFilmIdentity() {
    final topGenre = _getTopGenres().isNotEmpty ? _getTopGenres().first : '';
    final topVibe = _getTopVibes().isNotEmpty ? _getTopVibes().first : '';
    
    if (topGenre.isNotEmpty && topVibe.isNotEmpty) {
      return 'a $topGenre $topVibe Explorer';
    } else if (topGenre.isNotEmpty) {
      return 'a $topGenre Enthusiast';
    } else if (topVibe.isNotEmpty) {
      return 'a $topVibe Movie Lover';
    }
    return 'a Movie Explorer';
  }

  List<String> _getTopGenres() {
    final sorted = widget.profile.genreScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((e) => e.key).toList();
  }

  List<String> _getTopVibes() {
    final sorted = widget.profile.vibeScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(2).map((e) => e.key).toList();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
  }

  String _getDisplayName() {
    if (widget.profile.name.isEmpty) return 'there';
    return widget.profile.name.split(' ')[0];
  }
}