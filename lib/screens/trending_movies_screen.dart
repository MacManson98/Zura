import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import '../utils/tmdb_api.dart';
import '../utils/movie_loader.dart';
import '../utils/debug_loader.dart';
import 'movie_detail_screen.dart';
import 'dart:math';

class TrendingMoviesScreen extends StatefulWidget {
  final UserProfile currentUser;
  final Function(UserProfile)? onProfileUpdate;

  const TrendingMoviesScreen({
    super.key,
    required this.currentUser,
    this.onProfileUpdate,
  });

  @override
  State<TrendingMoviesScreen> createState() => _TrendingMoviesScreenState();
}

class _TrendingMoviesScreenState extends State<TrendingMoviesScreen>
    with TickerProviderStateMixin {
  List<Movie> _trendingMovies = [];
  bool _isLoading = true;
  String _selectedTimeWindow = 'week';
  AnimationController? _refreshController;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadTrendingMovies();
  }

  @override
  void dispose() {
    _refreshController?.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingMovies() async {
    setState(() => _isLoading = true);
    
    try {
      DebugLogger.log("🔥 Loading trending movies for timeWindow: $_selectedTimeWindow");
      
      // Step 1: Get trending movie IDs from TMDB
      final trendingIds = await TMDBApi.getTrendingMovieIds(timeWindow: _selectedTimeWindow);
      DebugLogger.log("📋 Got ${trendingIds.length} trending IDs from TMDB");
      
      if (trendingIds.isEmpty) {
        DebugLogger.log("⚠️ No trending IDs from TMDB");
        setState(() {
          _trendingMovies = [];
          _isLoading = false;
        });
        return;
      }
      
      // Step 2: Load local movie database
      final localMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      DebugLogger.log("💾 Local database has ${localMovieDatabase.length} movies");
      
      if (localMovieDatabase.isEmpty) {
        DebugLogger.log("⚠️ Local database is empty");
        setState(() {
          _trendingMovies = [];
          _isLoading = false;
        });
        return;
      }
      
      // Step 3: Find matching movies in local database (preserving TMDB trending order)
      final matchingMovies = <Movie>[];
      int foundCount = 0;
      int notFoundCount = 0;
      
      for (final trendingId in trendingIds) {
        // Find movie in local database by ID
        final foundMovie = localMovieDatabase.cast<Movie?>().firstWhere(
          (movie) => movie?.id == trendingId,
          orElse: () => null,
        );
        
        if (foundMovie != null && !widget.currentUser.likedMovies.contains(foundMovie)) {
          matchingMovies.add(foundMovie);
          foundCount++;
        } else {
          notFoundCount++;
        }
      }
      
      DebugLogger.log("📊 Trending screen results: Found $foundCount, Not found $notFoundCount");
      DebugLogger.log("✅ Found ${matchingMovies.length} trending movies in local database");
      
      setState(() {
        _trendingMovies = matchingMovies;
        _isLoading = false;
      });
      
    } catch (e) {
      DebugLogger.log("❌ Error loading trending movies: $e");
      setState(() {
        _trendingMovies = [];
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getTrendingStats(Movie movie, int rank) {
    final random = Random(movie.title.hashCode + rank);
    final baseViews = 500 - (rank * 20); // Higher rank = more views
    final views = baseViews + random.nextInt(200);
    final likes = (views * 0.1).round() + random.nextInt(50);
    final trend = rank <= 3 ? "hot" : (random.nextBool() ? "up" : "stable");
    
    return {
      'views': views,
      'likes': likes,
      'trend': trend,
    };
  }

  Future<void> _refreshTrending() async {
    _refreshController?.forward().then((_) => _refreshController?.reverse());
    await _loadTrendingMovies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Trending Movies',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: _refreshController != null
                ? AnimatedBuilder(
                    animation: _refreshController!,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshController!.value * 2 * 3.14159,
                        child: const Icon(Icons.refresh, color: Color(0xFFE5A00D)),
                      );
                    },
                  )
                : const Icon(Icons.refresh, color: Color(0xFFE5A00D)),
            onPressed: _refreshTrending,
          ),
        ],
      ),
      body: Column(
        children: [
          // Time Window Selector
          _buildTimeWindowSelector(),
          
          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _trendingMovies.isEmpty
                    ? _buildEmptyState()
                    : _buildTrendingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeWindowSelector() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          _buildTimeWindowButton('day', 'Today'),
          _buildTimeWindowButton('week', 'This Week'),
        ],
      ),
    );
  }

  Widget _buildTimeWindowButton(String value, String label) {
    final isSelected = _selectedTimeWindow == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedTimeWindow != value) {
            setState(() => _selectedTimeWindow = value);
            _loadTrendingMovies();
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE5A00D) : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFFE5A00D),
            strokeWidth: 3.w,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading trending movies...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_down,
            size: 64.sp,
            color: Colors.white30,
          ),
          SizedBox(height: 16.h),
          Text(
            'No trending movies found',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try refreshing or check back later',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _refreshTrending,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A00D),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Refresh',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: _trendingMovies.length,
      itemBuilder: (context, index) {
        final movie = _trendingMovies[index];
        final rank = index + 1;
        final stats = _getTrendingStats(movie, rank);
        
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12.r),
            border: rank <= 3 ? Border.all(
              color: rank == 1 
                  ? const Color(0xFFE5A00D)
                  : rank == 2 
                      ? Colors.grey[400]!
                      : Colors.grey[600]!,
              width: 2.w,
            ) : null,
          ),
          child: GestureDetector(
            onTap: () {
              showMovieDetails(
                context: context,
                movie: movie,
                currentUser: widget.currentUser,
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
                            ? Colors.grey[400]
                            : rank == 3
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
                SizedBox(width: 12.w),
                
                // Movie info - wrapped in flexible
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      if (movie.genres.isNotEmpty)
                        Text(
                          movie.genres.take(2).join(' • '),
                          style: TextStyle(
                            color: const Color(0xFFE5A00D),
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      SizedBox(height: 6.h),
                      
                      // Trending stats - simplified
                      Row(
                        children: [
                          Icon(
                            stats['trend'] == 'hot' 
                                ? Icons.whatshot
                                : stats['trend'] == 'up'
                                    ? Icons.trending_up
                                    : Icons.trending_flat,
                            color: stats['trend'] == 'hot' 
                                ? Colors.orange
                                : stats['trend'] == 'up'
                                    ? Colors.green
                                    : Colors.grey,
                            size: 12.sp,
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              '${stats['views']} • ❤️${stats['likes']}${movie.rating != null ? ' • ⭐${movie.rating!.toStringAsFixed(1)}' : ''}',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 10.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}