import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import 'dart:math';
import 'movie_detail_screen.dart';
import '../utils/film_identity_generator.dart';
import '../utils/moodboard_filter.dart';
import '../utils/debug_loader.dart';
import 'matches_screen.dart';
import 'liked_movies_screen.dart';
import '../utils/movie_loader.dart';
import '../utils/tmdb_api.dart';
import 'trending_movies_screen';
import '../models/matching_models.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  final List<Movie> movies;
  final VoidCallback? onNavigateToMatches;
  final VoidCallback? onNavigateToMatcher;
  final VoidCallback? onNavigateToFriends;
  final VoidCallback? onNavigateToNotifications;
  final Function(UserProfile)? onProfileUpdate;

  // NEW: Add specific mode callbacks
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

class _HomeScreenState extends State<HomeScreen> 
    with TickerProviderStateMixin {
  Movie? _randomPick;
  bool _isLoadingRandom = false;
  
  // Animation controllers - properly initialized
  AnimationController? _randomButtonController;
  AnimationController? _floatingController;
  AnimationController? _fadeController;
  
  Animation<double>? _randomButtonAnimation;
  Animation<double>? _floatingAnimation;
  Animation<double>? _fadeAnimation;

  List<Movie> _completeMovieDatabase = [];
  List<Movie> _trendingMovies = [];
  bool _isLoadingTrending = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCompleteMovieDatabase();
    _loadTrendingMovies();
  }

  Future<void> _loadTrendingMovies() async {
    setState(() => _isLoadingTrending = true);
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

  void _initializeAnimations() {
    try {
      _randomButtonController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      _floatingController = AnimationController(
        duration: const Duration(seconds: 4),
        vsync: this,
      );
      
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );

      _randomButtonAnimation = Tween<double>(
        begin: 1.0,
        end: 1.05,
      ).animate(CurvedAnimation(
        parent: _randomButtonController!,
        curve: Curves.elasticOut,
      ));

      _floatingAnimation = Tween<double>(
        begin: -10.0,
        end: 10.0,
      ).animate(CurvedAnimation(
        parent: _floatingController!,
        curve: Curves.easeInOut,
      ));

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _fadeController!,
        curve: Curves.easeOut,
      ));

      // Start animations
      _floatingController?.repeat(reverse: true);
      _fadeController?.forward();
    } catch (e) {
      DebugLogger.log('Animation initialization error: $e');
    }
  }

  @override
  void dispose() {
    _randomButtonController?.dispose();
    _floatingController?.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  Future<void> _loadCompleteMovieDatabase() async {
    _completeMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
    setState(() {});
  }

  Future<void> _generateRandomPick() async {
    if (_isLoadingRandom || widget.movies.isEmpty) return;

    setState(() => _isLoadingRandom = true);
    _randomButtonController?.forward().then((_) => _randomButtonController?.reverse());
    await Future.delayed(const Duration(milliseconds: 600));

    final random = Random();
    List<Movie> availableMovies = widget.movies.where((movie) => 
        !widget.profile.likedMovies.contains(movie)).toList();
    if (availableMovies.isEmpty) availableMovies = widget.movies;

    _randomPick = availableMovies[random.nextInt(availableMovies.length)];
    setState(() => _isLoadingRandom = false);
  }

  List<Movie> _getRecommendedMovies() {
    final recs = widget.movies.where((movie) =>
      movie.genres.any(widget.profile.preferredGenres.contains) &&
      !widget.profile.likedMovies.contains(movie)).toList();
    recs.shuffle();
    return recs.take(6).toList();
  }

  List<Movie> _getTopPicksThisWeek() {
    final seed = DateTime.now().day + DateTime.now().month;
    final picks = List<Movie>.from(widget.movies)..shuffle(Random(seed));
    return picks.take(8).toList();
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

// Update your fallback method to use MovieDatabaseLoader:
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

  // Update your _getTrendingStats method to be more realistic:
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

  // Add this method to handle navigation to trending screen:
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 18) return "Good afternoon";
    return "Good evening";
  }

  String _getArticle(String identity) {
    final vowelSounds = ['a', 'e', 'i', 'o', 'u'];
    final firstLetter = identity.toLowerCase().substring(0, 1);
    return vowelSounds.contains(firstLetter) ? 'an' : 'a';
  }

  String _getFilmIdentityTitle() {
    final genreTop = _getTop(widget.profile.genreScores);
    final vibeTop = _getTop(widget.profile.vibeScores);
    var identity = getFilmIdentity(genreTop, vibeTop);
    
    if (identity == "Movie Explorer" && genreTop.isNotEmpty) {
      identity = getFilmIdentity(genreTop, "Any");
      if (identity == "Movie Explorer" && vibeTop.isNotEmpty) {
        identity = getFilmIdentity("Any", vibeTop);
      }
    }
    
    return identity.isEmpty ? "Movie Explorer" : identity;
  }

  String _getTop(Map<String, double> scores) {
    if (scores.isEmpty) return "";
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    final filtered = sorted.where((entry) => 
      !moodboardBlacklist.contains(entry.key.toLowerCase())
    ).toList();
    
    return filtered.isEmpty ? "" : filtered.first.key;
  }

  List<String> _getTopMoodboardItems(Map<String, double> scores, int count) {
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    final filtered = sorted.where((entry) => 
      !moodboardBlacklist.contains(entry.key.toLowerCase())
    ).toList();
    
    return filtered.take(count).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recommendedMovies = _getRecommendedMovies();
    final topPicks = _getTopPicksThisWeek();
    final topGenres = _getTopMoodboardItems(widget.profile.genreScores, 2);
    final topVibes = _getTopMoodboardItems(widget.profile.vibeScores, 2);
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Animated background elements
          _buildFloatingBackground(),
          
          // Main content
          SafeArea(
            child: _fadeAnimation != null 
              ? FadeTransition(
                  opacity: _fadeAnimation!,
                  child: _buildMainContent(recommendedMovies, topPicks, topGenres, topVibes),
                )
              : _buildMainContent(recommendedMovies, topPicks, topGenres, topVibes),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(List<Movie> recommendedMovies, List<Movie> topPicks, 
                          List<String> topGenres, List<String> topVibes) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern Header
        _buildModernHeader(),
        
        // Main Content
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                
                // Quick Stats Dashboard
                _buildQuickStats(),
                SizedBox(height: 24.h),

                //Qucik Access Carousel
                _buildSwipingModeCarousel(),
                SizedBox(height: 24.h,),
                // Enhanced Quick Actions
                _buildEnhancedQuickActions(),
                SizedBox(height: 24.h),
                
                // Film Identity Section
                if (topGenres.isNotEmpty || topVibes.isNotEmpty) ...[
                  _buildFilmIdentitySection(topGenres, topVibes),
                  SizedBox(height: 24.h),
                ],
                
                // Trending This Week (REPLACED Friend Activity)
                _buildTrendingThisWeek(),
                SizedBox(height: 24.h),
                
                // Enhanced Random Film Section
                _buildEnhancedRandomSection(),
                SizedBox(height: 24.h),
                
                // Vertical Discovery Feed
                if (topPicks.isNotEmpty) ...[
                  _buildVerticalDiscoveryFeed(topPicks),
                  SizedBox(height: 24.h),
                ],
                
                // Stats Section
                if (widget.profile.likedMovies.isNotEmpty) ...[
                  _buildEnhancedStatsSection(),
                  SizedBox(height: 24.h),
                ],
                
                // Recommendations
                if (recommendedMovies.isNotEmpty) ...[
                  _buildHorizontalRecommendations(recommendedMovies),
                  SizedBox(height: 24.h),
                ],
                
                // Bottom padding for nav bar
                SizedBox(height: 100.h),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          if (_floatingAnimation != null)
            AnimatedBuilder(
              animation: _floatingAnimation!,
              builder: (context, child) {
                return Positioned(
                  top: 100.h + _floatingAnimation!.value,
                  right: -100.w,
                  child: Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE5A00D).withValues(alpha: 0.08),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          if (_floatingAnimation != null)
            AnimatedBuilder(
              animation: _floatingAnimation!,
              builder: (context, child) {
                return Positioned(
                  bottom: 200.h - _floatingAnimation!.value,
                  left: -100.w,
                  child: Container(
                    width: 250.w,
                    height: 250.w,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE5A00D).withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF121212),
      surfaceTintColor: const Color(0xFF121212),
      shadowColor: Colors.transparent,
      pinned: false,
      floating: true,
      snap: true,
      elevation: 0,
      expandedHeight: 140.h,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  // Profile Avatar with Online Status
                  Stack(
                    children: [
                      Container(
                        width: 50.w,
                        height: 50.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE5A00D), Color(0xFFFF8A00)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.r),
                          child: Center(
                            child: Text(
                              widget.profile.name.isNotEmpty 
                                ? widget.profile.name[0].toUpperCase() 
                                : 'U',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF121212), width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // Greeting and Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_getGreeting()}, ${widget.profile.name.isNotEmpty ? widget.profile.name.split(' ')[0] : 'there'}! 👋',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Ready to discover something amazing?',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '${widget.profile.likedMovieIds.length}',
            'Movies Liked',
            const Color(0xFFE5A00D),
            Icons.favorite,
          ),
          _buildStatDivider(),
          _buildStatItem(
            '${widget.profile.matchHistory.length}',
            'Matches',
            Colors.red,
            Icons.local_fire_department,
          ),
          _buildStatDivider(),
          _buildStatItem(
          _isLoadingTrending 
              ? '...' 
              : '${_trendingMovies.length}', // ✅ Use the state variable instead
            'Trending Now',
            Colors.orange,
            Icons.whatshot,
          ),
        ],
      ),
    );
  }

    void _navigateToMatches() {
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

    void _navigateToLikedMovies() {
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

  Widget _buildStatItem(String value, String label, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
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
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildSwipingModeCarousel() {
    final PageController _pageController = PageController(viewportFraction: 0.85);

    final List<Map<String, dynamic>> swipingModes = [
      {
        'title': 'Solo',
        'subtitle': 'Your taste',
        'icon': Icons.person,
        'gradient': const LinearGradient(colors: [Color(0xFFE5A00D), Color(0xFFFF8A00)]),
        'onTap': () => _navigateToMatcher(MatchingMode.solo),
      },
      {
        'title': 'Friend',
        'subtitle': 'Match together',
        'icon': Icons.people,
        'gradient': LinearGradient(colors: [Colors.purple.shade600, Colors.purple.shade800]),
        'onTap': () => _navigateToMatcher(MatchingMode.friend),
      },
      {
        'title': 'Group',
        'subtitle': 'Party mode',
        'icon': Icons.groups,
        'gradient': LinearGradient(colors: [Colors.indigo.shade600, Colors.indigo.shade800]),
        'onTap': () => _navigateToMatcher(MatchingMode.group),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Text(
                      textAlign: TextAlign.center,
          'Choose how you watch',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 180.h,
          child: PageView.builder(
            controller: _pageController,
            itemCount: swipingModes.length,
            itemBuilder: (context, index) {
              final item = swipingModes[index];

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = ((1 - (value.abs() * 0.2)).clamp(0.8, 1.0)).toDouble();
                    }
                  return Transform.scale(
                    scale: value,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: GestureDetector(
                        onTap: item['onTap'],
                        child: Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            gradient: item['gradient'],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item['icon'], size: 42.sp, color: Colors.white),
                              SizedBox(height: 16.h),
                              Text(
                                item['title'],
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                item['subtitle'],
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: 12.h),
        Center(
          child: SmoothPageIndicator(
            controller: _pageController,
            count: swipingModes.length,
            effect: ExpandingDotsEffect(
              dotHeight: 6.h,
              dotWidth: 6.h,
              activeDotColor: Colors.white,
              dotColor: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildEnhancedQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            SizedBox(height: 20.h),
            
            // Quick access section header
            Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildSecondaryActionCard(
                    title: 'My Matches',
                    subtitle: '${widget.profile.matchHistory.length} found',
                    icon: Icons.favorite,
                    onTap: _navigateToMatches,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildSecondaryActionCard(
                    title: 'My Likes',
                    subtitle: '${widget.profile.likedMovieIds.length} movies',
                    icon: Icons.thumb_up,
                    onTap: _navigateToLikedMovies,
                  ),
                ),
              ],
            ),
          ],
    );
  }

  void _navigateToMatcher(MatchingMode mode) {
    switch (mode) {
      case MatchingMode.solo:
        widget.onNavigateToSoloMatcher?.call();
        break;
      case MatchingMode.friend:
        widget.onNavigateToFriendMatcher?.call();
        break;
      case MatchingMode.group:
        widget.onNavigateToGroupMatcher?.call();
        break;
    }
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: isPrimary 
            ? const LinearGradient(
                colors: [Color(0xFFE5A00D), Color(0xFFFF8A00)],
              )
            : null,
          color: isPrimary ? null : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16.r),
          border: isPrimary ? null : Border.all(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isPrimary 
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFE5A00D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : const Color(0xFFE5A00D),
                size: 20.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isPrimary ? Colors.white : Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isPrimary ? Colors.white.withValues(alpha: 0.8) : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: isPrimary ? Colors.white : Colors.white54,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFFE5A00D),
              size: 24.sp,
            ),
            SizedBox(height: 12.h),
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
                fontSize: 11.sp,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilmIdentitySection(List<String> topGenres, List<String> topVibes) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
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
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.psychology,
                  color: const Color(0xFFE5A00D),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You\'re ${_getArticle(_getFilmIdentityTitle())} ${_getFilmIdentityTitle()}!',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Based on your taste profile',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [...topGenres, ...topVibes].take(3).map((tag) => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: const Color(0xFFE5A00D),
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

  // NEW: Trending This Week section (replaces friend activity)
  Widget _buildTrendingThisWeek() {
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
                    borderRadius: BorderRadius.circular(8.r),
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
                color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
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
          Container(
            height: 120.h,
            child: Center(
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
            ),
          )
        // Empty state
        else if (_trendingMovies.isEmpty)
          Container(
            height: 120.h,
            child: Center(
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
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(12.r),
                border: rank == 1 ? Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  width: 1.w,
                ) : null,
              ),
              child: GestureDetector(
                onTap: () {
                  showMovieDetails(
                    context: context,
                    movie: movie,
                    currentUser: widget.profile,
                  );
                },
                child: Row(
                  children: [
                    // Rank badge
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: rank == 1 
                          ? const Color(0xFFE5A00D) 
                          : rank == 2 
                            ? Colors.grey[600]
                            : Colors.grey[700],
                        borderRadius: BorderRadius.circular(8.r),
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
                        color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
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
                borderRadius: BorderRadius.circular(8.r),
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

  Widget _buildEnhancedRandomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feeling Adventurous?',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        _randomButtonAnimation != null 
          ? AnimatedBuilder(
              animation: _randomButtonAnimation!,
              builder: (context, child) {
                return Transform.scale(
                  scale: _randomButtonAnimation!.value,
                  child: _buildRandomButton(),
                );
              },
            )
          : _buildRandomButton(),
        if (_randomPick != null) ...[
          SizedBox(height: 16.h),
          _buildRandomPickResult(),
        ],
      ],
    );
  }

  Widget _buildRandomButton() {
    return _buildActionButton(
      onTap: _generateRandomPick,
      icon: _isLoadingRandom ? Icons.hourglass_empty : Icons.casino,
      label: _isLoadingRandom ? "Finding your film..." : "Random Film",
      subtitle: "Let us surprise you with something great",
      isPrimary: true,
    );
  }

  Widget _buildRandomPickResult() {
    return GestureDetector(
      onTap: () {
        showMovieDetails(
          context: context,
          movie: _randomPick!,
          currentUser: widget.profile,
        );
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
            width: 1.w,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
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
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
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
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.play_arrow,
                color: const Color(0xFFE5A00D),
                size: 24.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDiscoveryFeed(List<Movie> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Selected Just For You!',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${movies.length} picks',
                style: TextStyle(
                  color: const Color(0xFFE5A00D),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        
        // Enhanced movie grid with better cards
        SizedBox(
          height: 240.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.only(right: 16.w),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () => showMovieDetails(
                  context: context,
                  movie: movie,
                  currentUser: widget.profile,
                ),
                child: Container(
                  width: 140.w,
                  margin: EdgeInsets.only(right: 16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Stack(
                            children: [
                              Image.network(
                                movie.posterUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[800],
                                  child: Icon(Icons.movie, size: 40.sp, color: Colors.white30),
                                ),
                              ),
                              // Gradient overlay for better text readability
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 60.h,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.8),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Movie title overlay
                              Positioned(
                                bottom: 8.h,
                                left: 8.w,
                                right: 8.w,
                                child: Text(
                                  movie.title,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
      ],
    );
  }

  Widget _buildEnhancedStatsSection() {
    final topGenres = <String, int>{};
    for (final movie in widget.profile.likedMovies) {
      for (final genre in movie.genres) {
        topGenres[genre] = (topGenres[genre] ?? 0) + 1;
      }
    }
    
    final sortedGenres = topGenres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Taste',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEnhancedStatItem('Movies Liked', widget.profile.likedMovies.length.toString()),
              _buildEnhancedStatItem('Top Genre', sortedGenres.isNotEmpty ? sortedGenres.first.key : 'None'),
              _buildEnhancedStatItem('Matches', widget.profile.matchHistory.length.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE5A00D),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHorizontalRecommendations(List<Movie> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 200.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () {
                  showMovieDetails(
                    context: context,
                    movie: movie,
                    currentUser: widget.profile,
                  );
                },
                child: Container(
                  width: 120.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            movie.posterUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[800],
                              child: Icon(Icons.movie, size: 40.sp, color: Colors.white30),
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}