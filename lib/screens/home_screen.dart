import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import 'dart:math';
import 'movie_detail_screen.dart';
import '../utils/film_identity_generator.dart';
import '../utils/moodboard_filter.dart';
import '../utils/debug_loader.dart';
import 'matches_screen.dart';
import 'liked_movies_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserProfile profile;
  final List<Movie> movies;
  final VoidCallback? onNavigateToMatches;
  final VoidCallback? onNavigateToMatcher;
  final VoidCallback? onNavigateToFriends;
  final VoidCallback? onNavigateToNotifications;
  final Function(UserProfile)? onProfileUpdate;

  const HomeScreen({
    super.key,
    required this.profile,
    required this.movies,
    this.onNavigateToMatches,
    this.onNavigateToMatcher,
    this.onNavigateToFriends,
    this.onNavigateToNotifications,
    this.onProfileUpdate,
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
  
  final int _notificationCount = 3; // Mock notification count
  final int _friendsOnline = 6; // Mock friends online

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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
                
                // Enhanced Quick Actions
                _buildEnhancedQuickActions(),
                SizedBox(height: 24.h),
                
                // Film Identity Section
                if (topGenres.isNotEmpty || topVibes.isNotEmpty) ...[
                  _buildFilmIdentitySection(topGenres, topVibes),
                  SizedBox(height: 24.h),
                ],
                
                // Friend Activity Feed
                _buildFriendActivityFeed(),
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
                  
                  // Actions
                  Row(
                    children: [
                      // Search Button
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(
                          Icons.search,
                          color: Colors.white70,
                          size: 20.sp,
                        ),
                      ),
                      
                      SizedBox(width: 12.w),
                      
                      // Notifications with Badge
                      GestureDetector(
                        onTap: widget.onNavigateToNotifications,
                        child: Stack(
                          children: [
                            Container(
                              width: 40.w,
                              height: 40.w,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1F1F),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Icon(
                                Icons.notifications_outlined,
                                color: Colors.white70,
                                size: 20.sp,
                              ),
                            ),
                            if (_notificationCount > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 16.w,
                                  height: 16.w,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _notificationCount.toString(),
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
            '$_friendsOnline',
            'Friends Online',
            Colors.green,
            Icons.people,
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

  Widget _buildEnhancedQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16.h),
        
        // Primary action - Start Swiping (matches your session controls styling)
        _buildActionButton(
          onTap: widget.onNavigateToMatcher ?? () {},
          icon: Icons.swipe_right,
          label: "Start Swiping",
          subtitle: "Discover new movies",
          isPrimary: true,
        ),
        
        SizedBox(height: 12.h),
        
        // Secondary actions row
        Row(
          children: [
            Expanded(
              child: _buildSecondaryActionCard(
                title: 'My Matches',
                subtitle: '${widget.profile.matchHistory.length} found',
                icon: Icons.people,
                onTap: _navigateToMatches,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildSecondaryActionCard(
                title: 'My Likes',
                subtitle: '${widget.profile.likedMovieIds.length} found',
                icon: Icons.favorite,
                onTap: _navigateToLikedMovies,
              ),
            ),
          ],
        ),
      ],
    );
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

  Widget _buildFriendActivityFeed() {
    final mockActivities = [
      {'name': 'Sarah', 'action': 'found a match', 'movie': 'Dune: Part Two', 'time': '2m ago'},
      {'name': 'Mike', 'action': 'started swiping', 'movie': 'The Batman', 'time': '5m ago'},
      {'name': 'Movie Squad', 'action': 'needs your vote', 'movie': '3 matches pending', 'time': '8m ago'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Friend Activity',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            GestureDetector(
              onTap: widget.onNavigateToFriends,
              child: Container(
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
                    Text(
                      'View All',
                      style: TextStyle(
                        color: const Color(0xFFE5A00D),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: const Color(0xFFE5A00D),
                      size: 12.sp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        ...mockActivities.map((activity) => Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: const Color(0xFFE5A00D),
                child: Text(
                  activity['name']![0],
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '${activity['name']} ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          TextSpan(
                            text: activity['action'],
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${activity['movie']} • ${activity['time']}',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFFE5A00D),
                  size: 12.sp,
                ),
              ),
            ],
          ),
        )).toList(),
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