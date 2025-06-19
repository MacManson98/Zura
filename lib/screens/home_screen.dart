import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import 'dart:math';
import 'movie_detail_screen.dart';
import '../utils/film_identity_generator.dart';
import '../utils/moodboard_filter.dart';
import '../utils/debug_loader.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  final List<Movie> movies;
  final VoidCallback? onNavigateToMatches;
  final VoidCallback? onNavigateToMatcher;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.movies,
    this.onNavigateToMatches,
    this.onNavigateToMatcher,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Movie? _randomPick;
  bool _isLoadingRandom = false;
  late AnimationController _randomButtonController;
  late Animation<double> _randomButtonAnimation;

  @override
  void initState() {
    super.initState();

    _randomButtonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _randomButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _randomButtonController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _randomButtonController.dispose();
    super.dispose();
  }

  Future<void> _generateRandomPick() async {
    if (_isLoadingRandom || widget.movies.isEmpty) return;

    setState(() => _isLoadingRandom = true);
    _randomButtonController.forward().then((_) => _randomButtonController.reverse());
    await Future.delayed(const Duration(milliseconds: 600));

    final random = Random();
    List<Movie> availableMovies = widget.movies.where((movie) => !widget.profile.likedMovies.contains(movie)).toList();
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
    return picks.take(6).toList();
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
    
    // Debug: DebugLogger.log what we're getting
    DebugLogger.log('Debug - genreTop: $genreTop, vibeTop: $vibeTop, identity: $identity');
    
    // If we get the default, try some fallback logic
    if (identity == "Movie Explorer" && genreTop.isNotEmpty) {
      // Try with just the genre
      identity = getFilmIdentity(genreTop, "Any");
      if (identity == "Movie Explorer" && vibeTop.isNotEmpty) {
        // Try with just the vibe
        identity = getFilmIdentity("Any", vibeTop);
      }
    }
    
    return identity.isEmpty ? "Movie Explorer" : identity;
  }

  String _getTop(Map<String, double> scores) {
    if (scores.isEmpty) return "";
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    // Filter out blacklisted items for identity generation too
    final filtered = sorted.where((entry) => 
      !moodboardBlacklist.contains(entry.key.toLowerCase())
    ).toList();
    
    return filtered.isEmpty ? "" : filtered.first.key;
  }

  List<String> _getTopMoodboardItems(Map<String, double> scores, int count) {
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    // Filter out blacklisted items
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
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header that hides when scrolling
            SliverAppBar(
              automaticallyImplyLeading: false,
              backgroundColor: const Color(0xFF121212),
              surfaceTintColor: const Color(0xFF121212),
              shadowColor: Colors.transparent,
              pinned: false,
              floating: true,
              snap: true,
              elevation: 0,
              expandedHeight: 120.h,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: const Color(0xFF121212),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hey ${widget.profile.name.isNotEmpty ? widget.profile.name.split(' ')[0] : 'there'}! 👋',
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'What are we watching today?',
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
              ),
            ),
            
            // Main Content
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // Remove this extra SizedBox(height: 8.h), - it's redundant
                    
                    // Enhanced Film Identity Section
                    if (topGenres.isNotEmpty || topVibes.isNotEmpty) ...[
                      Container(
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
                            
                            // Enhanced moodboard with better styling - limit to 3 total items
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
                                    width: 1.w,
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
                      ),
                      SizedBox(height: 32.h),
                    ],

                    // Enhanced Top Picks Section
                    if (topPicks.isNotEmpty) ...[
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
                              '${topPicks.length} picks',
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
                          itemCount: topPicks.length,
                          itemBuilder: (context, index) {
                            final movie = topPicks[index];
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
                      SizedBox(height: 32.h),
                    ],
                    
                    // Interactive Random Film Button
                    _buildRandomFilmSection(),
                    
                    SizedBox(height: 32.h),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    
                    SizedBox(height: 32.h),
                    
                    // Your Stats (if user has activity)
                    if (widget.profile.likedMovies.isNotEmpty) ...[
                      _buildStatsSection(),
                      SizedBox(height: 32.h),
                    ],
                    
                    // Recommendations
                    if (recommendedMovies.isNotEmpty) ...[
                      _buildRecommendationsSection(recommendedMovies),
                      SizedBox(height: 32.h),
                    ],
                    
                    // Bottom padding for nav bar
                    SizedBox(height: 80.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomFilmSection() {
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
        
        // Random Film Button
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE5A00D),
                        Color(0xFFFF8A00),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isLoadingRandom) ...[
                        SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Finding your film...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.casino,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Random Film',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        
        // Show random pick result
        if (_randomPick != null) ...[
          SizedBox(height: 16.h),
          GestureDetector(
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
                  SizedBox(width: 12.w),
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
                        SizedBox(height: 4.h),
                        Text(
                          _randomPick!.genres.take(2).join(' • '),
                          style: TextStyle(
                            color: const Color(0xFFE5A00D),
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
        ],
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Start Swiping',
                subtitle: 'Find new movies',
                icon: Icons.swipe,
                onTap: widget.onNavigateToMatcher ?? () {},
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildActionCard(
                title: 'My Movies',
                subtitle: '${widget.profile.likedMovieIds.length} liked',
                icon: Icons.favorite,
                onTap: widget.onNavigateToMatches ?? () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
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
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final topGenres = <String, int>{};
    for (final movie in widget.profile.likedMovies) {
      for (final genre in movie.genres) {
        topGenres[genre] = (topGenres[genre] ?? 0) + 1;
      }
    }
    
    final sortedGenres = topGenres.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
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
        
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Movies Liked', widget.profile.likedMovies.length.toString()),
                  _buildStatItem('Top Genre', sortedGenres.isNotEmpty ? sortedGenres.first.key : 'None'),
                  _buildStatItem('Matches', widget.profile.matchHistory.length.toString()),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
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

  Widget _buildRecommendationsSection(List<Movie> movies) {
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