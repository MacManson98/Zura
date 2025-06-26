import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import '../services/friendship_service.dart';
import '../widgets/compatibility_chart.dart';
import '../services/recommendation_service.dart';
import '../utils/movie_loader.dart';
import 'matcher_screen.dart';
import '../utils/themed_notifications.dart';

class FriendProfileScreen extends StatefulWidget {
  final UserProfile currentUser;
  final UserProfile friend;
  final List<Movie> allMovies;

  const FriendProfileScreen({
    super.key,
    required this.currentUser,
    required this.friend,
    required this.allMovies,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late List<Movie> _sharedLikes;
  late List<Movie> _recommendedMovies;
  List<Movie> _matchedMovies = []; // Initialize with empty list instead of late
  late Map<String, int> _genreOverlap;
  int _sharedMovieCount = 0;
  int _matchesCount = 0;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _analyzeProfiles();
  }

  void _analyzeProfiles() async {
    setState(() {
      _isLoading = true;
    });
    
    // DEBUG: Print the data we're working with
    print("=== FRIEND PROFILE DEBUG ===");
    print("Current user: ${widget.currentUser.name}");
    print("Friend: ${widget.friend.name}");
    print("Current user liked movies: ${widget.currentUser.likedMovies.length}");
    print("Friend liked movies: ${widget.friend.likedMovies.length}");
    print("Current user preferred genres: ${widget.currentUser.preferredGenres}");
    print("Friend preferred genres: ${widget.friend.preferredGenres}");
    print("Current user preferred vibes: ${widget.currentUser.preferredVibes}");
    print("Friend preferred vibes: ${widget.friend.preferredVibes}");
    print("Total movies available: ${widget.allMovies.length}");
    
    // Additional debug info
    print("Friend UID: ${widget.friend.uid}");
    print("Friend likedMovieIds: ${widget.friend.likedMovieIds}");
    
    // Find shared liked movies (use MovieDatabaseLoader to get actual movie objects)
    final currentUserMovieIds = widget.currentUser.likedMovieIds;
    final friendMovieIds = widget.friend.likedMovieIds;
    final sharedMovieIds = currentUserMovieIds.intersection(friendMovieIds);
    
    print("Current user movie IDs: $currentUserMovieIds");
    print("Friend movie IDs: $friendMovieIds");  
    print("Shared movie IDs: $sharedMovieIds");
    
    // Load the full movie database to find shared movies
    print("📚 Loading movie database to find shared movies...");
    try {
      final fullMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      print("📊 Movie database loaded: ${fullMovieDatabase.length} movies");
      
      if (fullMovieDatabase.isNotEmpty) {
        // Debug: Check first few movies in database
        print("🔍 First 3 movies in database:");
        for (int i = 0; i < fullMovieDatabase.length && i < 3; i++) {
          print("   Movie ID: ${fullMovieDatabase[i].id}, Title: ${fullMovieDatabase[i].title}");
        }
        
        // Debug: Check if any of our shared IDs exist in database
        print("🔍 Looking for shared movie IDs: $sharedMovieIds");
        final foundIds = <String>[];
        for (final movie in fullMovieDatabase) {
          if (sharedMovieIds.contains(int.tryParse(movie.id))) {
            foundIds.add(movie.id);
          }
        }
        print("🔍 Found ${foundIds.length} matching IDs in database: $foundIds");
        
        // Find actual movie objects for shared IDs
        _sharedLikes = [];
        
        for (final sharedId in sharedMovieIds) {
          final movie = fullMovieDatabase.firstWhere(
            (movie) {
              try {
                return movie.id == sharedId.toString();
              } catch (e) {
                return false;
              }
            },
            orElse: () => Movie(
              id: '-1',
              title: '',
              overview: '',
              genres: [],
              tags: [],
              posterUrl: '',
              cast: [],
            ),
          );
          
          if (movie.id != '-1') {
            _sharedLikes.add(movie);
            print("✅ Found shared movie: ${movie.title} (ID: ${movie.id})");
          } else {
            print("❌ Could not find movie with ID: $sharedId");
          }
        }
        
        print("📊 Successfully loaded ${_sharedLikes.length} shared movie objects");
      } else {
        print("❌ Movie database is empty");
        _sharedLikes = [];
      }
    } catch (e) {
      print("❌ Error loading movie database: $e");
      _sharedLikes = [];
    }
    
    // Store the actual shared count (use the movie IDs count as the authoritative number)
    _sharedMovieCount = sharedMovieIds.length;
    
    print("Shared movies found: ${_sharedLikes.length}");
    
    // Load matches between current user and friend
    print("📅 Loading match history between users...");
    await _loadMatchHistory();
    
    // Calculate genre overlap (handle empty preferences)
    _genreOverlap = {};
    
    // Count genres from current user
    final currentGenres = widget.currentUser.preferredGenres;
    for (var genre in currentGenres) {
      _genreOverlap[genre] = (_genreOverlap[genre] ?? 0) + 1;
    }
    
    // Count genres from friend
    final friendGenres = widget.friend.preferredGenres;
    for (var genre in friendGenres) {
      _genreOverlap[genre] = (_genreOverlap[genre] ?? 0) + 1;
    }
    
    // Find movies both might enjoy (simple recommendation logic)
    final Set<String> combinedGenres = {...currentGenres, ...friendGenres};
    final Set<String> combinedVibes = {...widget.currentUser.preferredVibes, ...widget.friend.preferredVibes};
    
    // Generate movie recommendations using the smart recommendation service
    _recommendedMovies = await RecommendationService.getRecommendationsForPair(
      user1: widget.currentUser,
      user2: widget.friend,
      allMovies: widget.allMovies,
      maxRecommendations: 10,
    );
    
    print("Combined genres: $combinedGenres");
    print("Combined vibes: $combinedVibes");
    print("Recommended movies found: ${_recommendedMovies.length}");
    
    // Try to load fresh data from Firestore to check what's actually saved
    try {
      final freshDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.friend.uid)
          .get();
      
      if (freshDoc.exists) {
        final freshData = freshDoc.data()!;
        print("=== FRESH FIRESTORE DATA ===");
        print("Fresh name: ${freshData['name']}");
        print("Fresh likedMovieIds: ${freshData['likedMovieIds']}");
        print("Fresh preferredGenres: ${freshData['preferredGenres']}");
        print("Fresh preferredVibes: ${freshData['preferredVibes']}");
      } else {
        print("❌ Friend document doesn't exist in Firestore!");
      }
    } catch (e) {
      print("❌ Error loading fresh data: $e");
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMatchHistory() async {
    try {
      // Get matches from the current user's match history
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();
      
      if (!userDoc.exists) {
        print("❌ Current user document not found");
        _matchedMovies = [];
        _matchesCount = 0;
        return;
      }
      
      final userData = userDoc.data()!;
      final matchHistory = userData['matchHistory'] as List<dynamic>? ?? [];
      
      print("📊 Found ${matchHistory.length} total matches in user history");
      
      // Filter matches that include both users
      final collaborativeMatches = matchHistory.where((match) {
        final username = match['username'] as String? ?? '';
        final currentUserName = widget.currentUser.name;
        final friendName = widget.friend.name;
        
        // Check if both users are mentioned in the username field
        return username.contains(currentUserName) && username.contains(friendName);
      }).toList();
      
      print("📅 Found ${collaborativeMatches.length} collaborative matches");
      
      _matchesCount = collaborativeMatches.length;
      
      // Load full movie database to get movie details
      final fullMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      
      if (fullMovieDatabase.isNotEmpty && collaborativeMatches.isNotEmpty) {
        _matchedMovies = [];
        
        for (final match in collaborativeMatches) {
          final movieId = match['movieId'] as String? ?? '';
          
          final movie = fullMovieDatabase.firstWhere(
            (movie) => movie.id == movieId,
            orElse: () => Movie(
              id: '-1',
              title: '',
              overview: '',
              genres: [],
              tags: [],
              posterUrl: '',
              cast: [],
            ),
          );
          
          if (movie.id != '-1') {
            _matchedMovies.add(movie);
            print("✅ Found matched movie: ${movie.title} (ID: ${movie.id})");
          }
        }
        
        // Sort by match date (most recent first)
        final matchesWithDates = collaborativeMatches.map((match) {
          final movieId = match['movieId'] as String? ?? '';
          final movie = _matchedMovies.firstWhere(
            (m) => m.id == movieId,
            orElse: () => Movie(
              id: '-1', 
              title: '', 
              overview: '', 
              genres: [], 
              tags: [], 
              posterUrl: '', 
              cast: []
            ),
          );
          return {
            'movie': movie,
            'date': match['matchDate'] as Timestamp?,
            'watched': match['watched'] as bool? ?? false,
          };
        }).where((item) {
          final movie = item['movie'] as Movie?;
          return movie != null && movie.id != '-1';
        }).toList();
        
        matchesWithDates.sort((a, b) {
          final aDate = a['date'] as Timestamp?;
          final bDate = b['date'] as Timestamp?;
          if (aDate == null || bDate == null) return 0;
          return bDate.compareTo(aDate); // Most recent first
        });
        
        _matchedMovies = matchesWithDates
            .map((item) => item['movie'] as Movie)
            .where((movie) => movie.id != '-1')
            .toList();
        
        print("📊 Successfully loaded ${_matchedMovies.length} matched movie objects");
      } else {
        _matchedMovies = [];
      }
      
    } catch (e) {
      print("❌ Error loading match history: $e");
      _matchedMovies = [];
      _matchesCount = 0;
    }
  }
  
  // Calculate overall compatibility score
  double get _compatibilityScore {
    // Count shared genres (handle empty preferences)
    int sharedGenres = 0;
    for (var entry in _genreOverlap.entries) {
      if (entry.value > 1) sharedGenres++;
    }
    
    // Count shared vibes (handle empty preferences)
    final currentVibes = widget.currentUser.preferredVibes;
    final friendVibes = widget.friend.preferredVibes;
    int sharedVibes = currentVibes.intersection(friendVibes).length;
    
    // Calculate percentages
    final currentGenres = widget.currentUser.preferredGenres;
    final friendGenresSet = widget.friend.preferredGenres;
    
    double genrePercentage = currentGenres.isEmpty || friendGenresSet.isEmpty ? 0 :
        sharedGenres / 
        (currentGenres.length + friendGenresSet.length - sharedGenres);
    
    double vibePercentage = currentVibes.isEmpty || friendVibes.isEmpty ? 0 :
        sharedVibes / 
        (currentVibes.length + friendVibes.length - sharedVibes);
    
    // Calculate shared likes percentage using movie IDs
    double sharedLikesPercentage = 0;
    final currentMovieIds = widget.currentUser.likedMovieIds;
    final friendMovieIds = widget.friend.likedMovieIds;
    
    if (currentMovieIds.isNotEmpty || friendMovieIds.isNotEmpty) {
      final sharedCount = currentMovieIds.intersection(friendMovieIds).length;
      sharedLikesPercentage = sharedCount == 0 ? 0 : 
          sharedCount / (currentMovieIds.length + friendMovieIds.length - sharedCount);
    }
    
    // Weighted average (likes count more)
    return (genrePercentage * 0.3 + vibePercentage * 0.3 + sharedLikesPercentage * 0.4) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF121212),
              const Color(0xFF121212),
              const Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(),
              
              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: GlassmorphicContainer(
                          width: 80.w,
                          height: 80.h,
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
                          child: CircularProgressIndicator(
                            color: const Color(0xFFE5A00D),
                            strokeWidth: 2.w,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Friend profile card with compatibility
                            _buildProfileCard(),
                            
                            SizedBox(height: 20.h),
                            
                            // Match button
                            _buildMatchButton(),
                            
                            SizedBox(height: 24.h),
                            
                            // Matches section
                            _buildMatchesSection(),
                            
                            SizedBox(height: 24.h),
                            
                            // Compatibility breakdown
                            _buildCompatibilitySection(),
                            
                            SizedBox(height: 24.h),
                            
                            // Movie recommendations section
                            _buildRecommendationsSection(),
                            
                            SizedBox(height: 24.h),
                            
                            // Shared liked movies section
                            _buildSharedLikesSection(),
                            
                            SizedBox(height: 80.h), // Bottom padding
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

  Widget _buildMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.movie_creation_outlined,
              color: Colors.green,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "Your Matches Together",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_matchesCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  "$_matchesCount",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        
        SizedBox(height: 12.h),
        
        _matchedMovies.isEmpty
            ? _buildEmptyState(
                _matchesCount > 0 
                    ? "Found $_matchesCount matches!\nLoading movie details..."
                    : "No matches yet. Start a session together!",
                _matchesCount > 0 ? Icons.movie : Icons.movie_creation_outlined,
              )
            : _buildMatchesCarousel(_matchedMovies),
      ],
    );
  }

  Widget _buildMatchesCarousel(List<Movie> movies) {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _buildMatchMovieCard(movie, index);
        },
      ),
    );
  }

  Widget _buildMatchMovieCard(Movie movie, int index) {
    // Note: In a real implementation, you'd want to store match dates with movies
    // For now, showing relative time based on index
    final daysAgo = index; // Placeholder - you'd get this from match data
    final dateText = daysAgo == 0 ? "Today" : 
                     daysAgo == 1 ? "Yesterday" : 
                     "$daysAgo days ago";
    
    return Container(
      width: 120.w,
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      child: GestureDetector(
        onTap: () => _showMovieDetails(movie),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                // Movie poster
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2A2A2A),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white30,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              movie.title,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Match date overlay at top
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      dateText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50.h,
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
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.r,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Tap indicator
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF1F1F1F),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
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
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          
          SizedBox(width: 8.w),
          
          // Friend avatar
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE5A00D),
                  Colors.orange.shade600,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  blurRadius: 6.r,
                  spreadRadius: 1.r,
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.friend.name.isNotEmpty ? widget.friend.name[0].toUpperCase() : "?",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12.w),
          
          Expanded(
            child: Text(
              widget.friend.name,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: 24.sp,
            ),
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text(
                      'Remove Friend',
                      style: TextStyle(color: Colors.red, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'remove') {
                _showRemoveFriendDialog();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final compatibilityScore = _compatibilityScore.round();
    
    // Determine compatibility level and color
    String compatibilityLevel;
    Color compatibilityColor;
    
    if (compatibilityScore >= 80) {
      compatibilityLevel = "Excellent";
      compatibilityColor = Colors.green;
    } else if (compatibilityScore >= 60) {
      compatibilityLevel = "Good";
      compatibilityColor = Colors.lightGreen;
    } else if (compatibilityScore >= 40) {
      compatibilityLevel = "Moderate";
      compatibilityColor = Colors.amber;
    } else if (compatibilityScore >= 20) {
      compatibilityLevel = "Fair";
      compatibilityColor = Colors.orange;
    } else {
      compatibilityLevel = "Poor";
      compatibilityColor = Colors.red;
    }
    
    return Container(
      padding: EdgeInsets.all(18.w),
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
          color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
          BoxShadow(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Friend avatar (larger)
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFE5A00D),
                      Colors.orange.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                      blurRadius: 12.r,
                      spreadRadius: 2.r,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.friend.name.isNotEmpty ? widget.friend.name[0].toUpperCase() : "?",
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 18.w),
              
              // Compatibility info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Movie Compatibility",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: 6.h),
                    
                    Row(
                      children: [
                        // Compatibility percentage
                        Text(
                          "$compatibilityScore%",
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: compatibilityColor,
                          ),
                        ),
                        
                        SizedBox(width: 10.w),
                        
                        // Compatibility level
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: compatibilityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: compatibilityColor.withValues(alpha: 0.5),
                              width: 1.w,
                            ),
                          ),
                          child: Text(
                            compatibilityLevel,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: compatibilityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20.h),
          
          // Shared likes stats
          Row(
            children: [
              Expanded(
                child: _buildStatColumn("Matches", _matchesCount),
              ),
              Expanded(
                child: _buildStatColumn("Shared\nLikes", _sharedMovieCount),
              ),
              Expanded(
                child: _buildStatColumn("Recommended\nMovies", _recommendedMovies.length),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE5A00D),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMatchButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatcherScreen(
                  sessionId: sessionId,
                  allMovies: widget.allMovies,
                  currentUser: widget.currentUser,
                  friendIds: [widget.friend],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.movie_filter, color: Colors.white, size: 20.sp),
                SizedBox(width: 10.w),
                Text(
                  "Start Movie Matching",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompatibilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Compatibility Breakdown",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 12.h),
        
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A2A2A),
                const Color(0xFF1F1F1F),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
              width: 1.w,
            ),
          ),
          child: CompatibilityChart(
            currentUser: widget.currentUser,
            friend: widget.friend,
            sharedLikes: _sharedLikes,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.recommend,
              color: const Color(0xFFE5A00D),
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "Movies You Might Both Enjoy",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_recommendedMovies.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  "${_recommendedMovies.length}",
                  style: TextStyle(
                    color: const Color(0xFFE5A00D),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        
        SizedBox(height: 12.h),
        
        _recommendedMovies.isEmpty
            ? _buildEmptyState(
                "Like more movies to get recommendations!",
                Icons.thumb_up_outlined,
              )
            : _buildMoviesCarousel(_recommendedMovies),
      ],
    );
  }

  Widget _buildSharedLikesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.favorite,
              color: Colors.red,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "Movies You Both Liked",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_sharedMovieCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.5),
                    width: 1.w,
                  ),
                ),
                child: Text(
                  "$_sharedMovieCount",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        
        SizedBox(height: 12.h),
        
        // Show different states based on what we have
        _buildSharedLikesContent(),
      ],
    );
  }

  Widget _buildSharedLikesContent() {
    // If we have movie objects, show them
    if (_sharedLikes.isNotEmpty) {
      return _buildMoviesCarousel(_sharedLikes);
    }
    
    // If we have shared IDs but no movie objects, show debug info
    if (_sharedMovieCount > 0) {
      return _buildEmptyStateWithCount(
        "You both liked $_sharedMovieCount movies!\nTrouble loading movie details...\nCheck debug logs for details.",
        Icons.movie,
      );
    }
    
    // No shared movies at all
    return _buildEmptyState(
      "No shared likes yet. Start matching!",
      Icons.movie_filter_outlined,
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return GlassmorphicContainer(
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
            icon,
            color: Colors.white30,
            size: 40.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.sp,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithCount(String message, IconData icon) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120.h,
      borderRadius: 16,
      blur: 15,
      alignment: Alignment.center,
      border: 1,
      linearGradient: LinearGradient(
        colors: [
          const Color(0xFFE5A00D).withValues(alpha: 0.15),
          const Color(0xFFE5A00D).withValues(alpha: 0.08),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          const Color(0xFFE5A00D).withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFFE5A00D),
            size: 40.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMoviesCarousel(List<Movie> movies) {
    return SizedBox(
      height: 180.h, // Slightly smaller height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _buildCarouselMovieCard(movie, index);
        },
      ),
    );
  }

  Widget _buildCarouselMovieCard(Movie movie, int index) {
    return Container(
      width: 120.w, // Fixed width for each card
      margin: EdgeInsets.symmetric(horizontal: 6.w),
      child: GestureDetector(
        onTap: () => _showMovieDetails(movie),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8.r,
                offset: Offset(0, 3.h),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                // Movie poster
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2A2A2A),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white30,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              movie.title,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 50.h,
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
                    child: Padding(
                      padding: EdgeInsets.all(8.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            movie.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.r,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (movie.genres.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              movie.genres.first,
                              style: TextStyle(
                                color: const Color(0xFFE5A00D),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.r,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Tap indicator
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMovieDetails(Movie movie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A2A2A),
                const Color(0xFF1F1F1F),
              ],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            border: Border.all(
              color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
              width: 1.w,
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              
              // Movie details content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        movie.genres.join(' • '),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: const Color(0xFFE5A00D),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      if (movie.tags.isNotEmpty) ...[
                        Text(
                          'Vibes',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Wrap(
                          spacing: 8.w,
                          runSpacing: 4.h,
                          children: movie.tags.map((tag) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.purple.withValues(alpha: 0.5), width: 1.w),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 12.sp,
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
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

  void _showRemoveFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            width: 1.w,
          ),
        ),
        title: Text(
          "Remove Friend",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to remove ${widget.friend.name} from your friends?",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red, Colors.red.shade600],
              ),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ElevatedButton(
              onPressed: () async {
                // Close the dialog immediately
                Navigator.of(context).pop();
                
                try {
                  // Actually remove the friend
                  await FriendshipService.removeFriend(
                    userId: widget.currentUser.uid,
                    friendId: widget.friend.uid,
                  );
                  
                  // Show success message and go back
                  if (mounted) {
                    ThemedNotifications.showSuccess(
                      context, 
                      '${widget.friend.name} removed from friends',
                      icon: "👋"
                    );
                    
                    // Go back to friends list
                    Navigator.of(context).pop();
                  }
                  
                } catch (e) {
                  // Show error message
                  if (mounted) {
                    ThemedNotifications.showError(context, 'Error removing friend: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                "Remove",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}