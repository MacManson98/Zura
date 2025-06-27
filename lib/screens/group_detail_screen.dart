// File: lib/screens/group_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/friend_group.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import 'matcher_screen.dart';
import '../utils/themed_notifications.dart';
import '../services/friendship_service.dart';
import '../services/group_invitation_service.dart';
import '../services/group_service.dart';
import 'movie_detail_screen.dart';
import '../utils/movie_loader.dart';

class GroupDetailScreen extends StatefulWidget {
  final FriendGroup group;
  final UserProfile currentUser;
  final List<Movie> allMovies;
  final VoidCallback? onGroupUpdated;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.currentUser,
    required this.allMovies,
    required this.onGroupUpdated,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _isLoading = false;
  Set<Movie> _recommendedMovies = {};
  List<UserProfile> _userFriends = [];
  bool _isLoadingFriends = false;
  List<Movie> _groupMatches = [];
  bool _isLoadingMatches = false;

  @override
  void initState() {
    super.initState();
    _loadGroupRecommendations();
    _loadUserFriends();
    _loadGroupMatches();
  }

  Future<void> _loadGroupRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("🎯 Loading group recommendations for: ${widget.group.name}");
      print("👥 Group members: ${widget.group.members.length}");
      
      // Analyze what the group collectively likes
      final Map<String, int> movieLikeCount = {};
      final Set<String> allSeenMovies = {};
      final Map<String, int> genrePreferences = {};
      final Map<String, int> vibePreferences = {};
      
      for (final member in widget.group.members) {
        print("📊 Analyzing member: ${member.name}");
        print("   Liked movies: ${member.likedMovieIds.length}");
        print("   Preferred genres: ${member.preferredGenres}");
        print("   Preferred vibes: ${member.preferredVibes}");
        
        // Count movie likes
        for (final movieId in member.likedMovieIds) {
          movieLikeCount[movieId] = (movieLikeCount[movieId] ?? 0) + 1;
        }
        
        // Track all seen movies (liked + passed)
        allSeenMovies.addAll(member.likedMovieIds);
        allSeenMovies.addAll(member.passedMovieIds);
        
        // Count genre preferences
        for (final genre in member.preferredGenres) {
          genrePreferences[genre] = (genrePreferences[genre] ?? 0) + 1;
        }
        
        // Count vibe preferences
        for (final vibe in member.preferredVibes) {
          vibePreferences[vibe] = (vibePreferences[vibe] ?? 0) + 1;
        }
      }
      
      print("🎬 Total unique movies seen by group: ${allSeenMovies.length}");
      print("📈 Top genres: ${genrePreferences.entries.where((e) => e.value >= 2).map((e) => '${e.key} (${e.value})').join(', ')}");
      
      // Find movies liked by multiple group members (group favorites)
      final groupFavorites = widget.allMovies.where((movie) {
        final likeCount = movieLikeCount[movie.id] ?? 0;
        return likeCount >= 2; // Liked by at least 2 people
      }).toList();
      
      print("⭐ Group favorites: ${groupFavorites.length} movies");
      
      // Generate smart recommendations
      final recommendations = <Movie, double>{};
      
      // Strategy 1: Find movies similar to group favorites
      for (final favoriteMovie in groupFavorites) {
        final similarMovies = _findSimilarMovies(favoriteMovie, widget.allMovies, allSeenMovies);
        
        for (final similarMovie in similarMovies) {
          final score = _calculateSimilarityScore(
            favoriteMovie, 
            similarMovie, 
            genrePreferences,
            vibePreferences,
            movieLikeCount[favoriteMovie.id] ?? 1,
          );
          
          // Keep the highest score for each movie
          if (!recommendations.containsKey(similarMovie) || 
              recommendations[similarMovie]! < score) {
            recommendations[similarMovie] = score;
          }
        }
      }
      
      print("🔍 Found ${recommendations.length} similar movie recommendations");
      
      // Strategy 2: Add high-rated movies in preferred genres/vibes
      if (recommendations.length < 12) {
        final additionalMovies = _findHighRatedInPreferences(
          widget.allMovies, 
          genrePreferences, 
          vibePreferences,
          allSeenMovies,
          12 - recommendations.length,
        );
        
        for (final movie in additionalMovies) {
          if (!recommendations.containsKey(movie)) {
            recommendations[movie] = _calculateGenreVibeScore(movie, genrePreferences, vibePreferences);
          }
        }
        
        print("➕ Added ${additionalMovies.length} genre/vibe-based recommendations");
      }
      
      // Strategy 3: If still not enough, add universally acclaimed movies
      if (recommendations.length < 8) {
        final acclaimedMovies = widget.allMovies.where((movie) {
          if (allSeenMovies.contains(movie.id)) return false;
          final rating = movie.rating ?? 0.0;
          return rating >= 8.0; // Highly rated movies
        }).toList()..sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
        
        for (final movie in acclaimedMovies.take(8 - recommendations.length)) {
          if (!recommendations.containsKey(movie)) {
            recommendations[movie] = (movie.rating ?? 0.0) * 2; // Base score on rating
          }
        }
        
        print("🏆 Added ${acclaimedMovies.take(8 - recommendations.length).length} acclaimed movies");
      }
      
      // Sort by score and get top recommendations
      final sortedRecommendations = recommendations.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final finalRecommendations = sortedRecommendations
          .take(12)
          .map((entry) => entry.key)
          .toList();
      
      print("✅ Final recommendations: ${finalRecommendations.length} movies");
      
      if (mounted) {
        setState(() {
          _recommendedMovies = finalRecommendations.take(10).toSet(); // Limit to 10 for UI
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print("❌ Error loading group recommendations: $e");
      if (mounted) {
        setState(() {
          _recommendedMovies = {};
          _isLoading = false;
        });
      }
    }
  }

  // Helper method: Find movies similar to a favorite
  List<Movie> _findSimilarMovies(
    Movie favoriteMovie, 
    List<Movie> allMovies, 
    Set<String> seenMovies,
  ) {
    return allMovies.where((movie) {
      // Skip if already seen
      if (seenMovies.contains(movie.id) || movie.id == favoriteMovie.id) {
        return false;
      }
      
      // Must be decent quality
      final movieRating = movie.rating ?? 0.0;
      if (movieRating < 6.5) return false;
      
      // Must share at least one genre
      final sharedGenres = movie.genres.toSet().intersection(favoriteMovie.genres.toSet());
      if (sharedGenres.isEmpty) return false;
      return true;
    }).toList();
  }

  // Helper method: Calculate similarity score
  double _calculateSimilarityScore(
    Movie favoriteMovie,
    Movie candidateMovie,
    Map<String, int> genrePreferences,
    Map<String, int> vibePreferences,
    int favoriteMovieLikes,
  ) {
    double score = 0;
    
    // Base score from rating
    final candidateRating = candidateMovie.rating ?? 7.0;
    score += candidateRating * 2;
    
    // Bonus for shared genres
    final sharedGenres = candidateMovie.genres.toSet().intersection(favoriteMovie.genres.toSet());
    score += sharedGenres.length * 5;
    
    // Bonus for shared vibes/tags
    final sharedVibes = candidateMovie.tags.toSet().intersection(favoriteMovie.tags.toSet());
    score += sharedVibes.length * 3;
    
    // Bonus for popular genres in the group
    for (final genre in candidateMovie.genres) {
      final genrePopularity = genrePreferences[genre] ?? 0;
      score += genrePopularity * 2;
    }
    
    // Bonus for popular vibes in the group
    for (final vibe in candidateMovie.tags) {
      final vibePopularity = vibePreferences[vibe] ?? 0;
      score += vibePopularity * 1.5;
    }
    
    // Bonus based on how much the group liked the reference movie
    score += favoriteMovieLikes * 3;
    
    return score;
  }

  // Helper method: Find high-rated movies in preferred genres/vibes
  List<Movie> _findHighRatedInPreferences(
    List<Movie> allMovies,
    Map<String, int> genrePreferences,
    Map<String, int> vibePreferences,
    Set<String> seenMovies,
    int count,
  ) {
    // Get popular preferences
    final popularGenres = genrePreferences.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toSet();
        
    final popularVibes = vibePreferences.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toSet();
    
    if (popularGenres.isEmpty && popularVibes.isEmpty) return [];
    
    final candidates = allMovies.where((movie) {
      if (seenMovies.contains(movie.id)) return false;
      
      final movieRating = movie.rating ?? 0.0;
      if (movieRating < 7.0) return false; // Good quality only
      
      final hasPreferredGenre = movie.genres.any((genre) => popularGenres.contains(genre));
      final hasPreferredVibe = movie.tags.any((vibe) => popularVibes.contains(vibe));
      
      return hasPreferredGenre || hasPreferredVibe;
    }).toList();
    
    // Sort by rating
    candidates.sort((a, b) {
      final aRating = a.rating ?? 0.0;
      final bRating = b.rating ?? 0.0;
      return bRating.compareTo(aRating);
    });
    
    return candidates.take(count).toList();
  }

  // Helper method: Calculate score based on genre/vibe preferences
  double _calculateGenreVibeScore(
    Movie movie, 
    Map<String, int> genrePreferences,
    Map<String, int> vibePreferences
  ) {
    final movieRating = movie.rating ?? 7.0;
    double score = movieRating * 2;
    
    for (final genre in movie.genres) {
      final genrePopularity = genrePreferences[genre] ?? 0;
      score += genrePopularity * 3;
    }
    
    for (final vibe in movie.tags) {
      final vibePopularity = vibePreferences[vibe] ?? 0;
      score += vibePopularity * 2;
    }
    
    return score;
  }

  void _startGroupMatching() {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatcherScreen(
          sessionId: sessionId,
          allMovies: widget.allMovies,
          currentUser: widget.currentUser,
          friendIds: widget.group.members,
        ),
      ),
    );
  }

  void _showManageMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildManageMembersSheet(),
    );
  }

  void _loadUserFriends() async {
    if (_isLoadingFriends) return;
    
    setState(() {
      _isLoadingFriends = true;
    });

    try {
      final friends = await FriendshipService.getFriends(widget.currentUser.uid);
      setState(() {
        _userFriends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFriends = false;
      });
      ThemedNotifications.showDecline(context, 'Failed to load friends', icon: "❌");
    }
  }

  // Show Add Members Dialog
  void _showAddMembersDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildAddMembersSheet(),
    );
  }

  Widget _buildAddMembersSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF161616),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  "Add Members",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Friends to invite
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Available Friends",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_isLoadingFriends)
                        SizedBox(
                          width: 16.w,
                          height: 16.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFFE5A00D),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Friends list
                  if (_userFriends.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _userFriends.length,
                        itemBuilder: (context, index) {
                          final friend = _userFriends[index];
                          final isAlreadyMember = widget.group.members.any((member) => member.uid == friend.uid);
                          
                          if (isAlreadyMember) return const SizedBox.shrink();
                          
                          return _buildMemberListItem(friend, false);
                        },
                      ),
                    ),
                  
                  // Empty state for friends
                  if (_userFriends.isEmpty && !_isLoadingFriends)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48.sp,
                              color: Colors.white24,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              "No friends to invite",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              "Add some friends first to invite them to groups",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Unified member list item builder
  Widget _buildMemberListItem(UserProfile member, bool isCurrentMember) {
    final bool isCurrentUser = member.uid == widget.currentUser.uid;
    final bool isCreator = member.uid == widget.group.creatorId;
    final bool canRemove = widget.group.isCreatedBy(widget.currentUser.uid) && 
                          !isCurrentUser && !isCreator && isCurrentMember;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 70.h,
        borderRadius: 16,
        blur: 10,
        alignment: Alignment.centerLeft,
        border: 1,
        linearGradient: LinearGradient(
          colors: isCurrentUser
              ? [
                  const Color(0xFFE5A00D).withValues(alpha: 0.15),
                  const Color(0xFFE5A00D).withValues(alpha: 0.05),
                ]
              : [
                  Colors.white.withValues(alpha: 0.05),
                  Colors.white.withValues(alpha: 0.02),
                ],
        ),
        borderGradient: LinearGradient(
          colors: isCurrentUser
              ? [
                  const Color(0xFFE5A00D).withValues(alpha: 0.6),
                  const Color(0xFFE5A00D).withValues(alpha: 0.3),
                ]
              : [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Member avatar
              Stack(
                children: [
                  Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isCreator 
                            ? [const Color(0xFFE5A00D), Colors.orange.shade600]
                            : [Colors.blue.shade400, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Center(
                      child: Text(
                        member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Creator crown
                  if (isCreator && isCurrentMember)
                    Positioned(
                      top: -2.h,
                      right: -2.w,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5A00D),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFF121212), width: 1.w),
                        ),
                        child: Icon(Icons.star, color: Colors.white, size: 10.sp),
                      ),
                    ),
                ],
              ),
              
              SizedBox(width: 12.w),
              
              // Member details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.name.isEmpty ? 'Unknown User' : member.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Status badges
                        if (isCurrentUser && isCurrentMember)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              "You",
                              style: TextStyle(
                                color: const Color(0xFFE5A00D),
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    SizedBox(height: 2.h),
                    
                    // Role indicator
                    Text(
                      isCurrentMember 
                          ? (isCreator ? 'Group Creator' : 'Member')
                          : 'Available to invite',
                      style: TextStyle(
                        color: isCurrentMember 
                            ? (isCreator ? const Color(0xFFE5A00D) : Colors.white54)
                            : Colors.green,
                        fontSize: 11.sp,
                        fontWeight: isCreator ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action button
              if (canRemove)
                GestureDetector(
                  onTap: () => _showRemoveMemberDialog(member),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      Icons.person_remove,
                      color: Colors.red,
                      size: 16.sp,
                    ),
                  ),
                )
              else if (!isCurrentMember)
                GestureDetector(
                  onTap: () => _inviteFriendToGroup(member),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE5A00D),
                          Colors.orange.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      "Invite",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGroupSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildGroupSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = widget.group.isCreatedBy(widget.currentUser.uid);
                    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          widget.group.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          // Obvious Settings Button
          Container(
            margin: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: _showGroupSettings,
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A00D)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group header card
                  _buildGroupHeaderCard(isCreator),
                  
                  SizedBox(height: 24.h),
                  
                  // Action buttons row
                  _buildActionButtonsRow(),
                  
                  SizedBox(height: 24.h),
                  
                  // Members section
                  _buildMembersSection(),
                  
                  SizedBox(height: 24.h),

                  //Group Matches Section
                  _buildGroupMatchesSection(),

                  SizedBox(height: 24.h),
                  
                  // Group recommendations section
                  _buildRecommendationsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupHeaderCard(bool isCreator) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150.h,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.centerLeft,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            // Enhanced group avatar
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                    blurRadius: 12.r,
                    spreadRadius: 2.r,
                  ),
                ],
              ),
              child: widget.group.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(
                        widget.group.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.group, color: Colors.white, size: 40);
                        },
                      ),
                    )
                  : const Icon(Icons.group, color: Colors.white, size: 40),
            ),
            
            SizedBox(width: 20.w),
            
            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.group.name,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  Text(
                    "Created by ${widget.group.createdBy}",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white60,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Stats row
                  Row(
                    children: [
                      _buildStatChip(
                        "${widget.group.members.length}",
                        "Members",
                        Icons.people,
                      ),
                      SizedBox(width: 12.w),
                      _buildStatChip(
                        "${widget.group.totalSessions}",
                        "Sessions",
                        Icons.movie_filter,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Group type badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: widget.group.isPrivate 
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: widget.group.isPrivate 
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.group.isPrivate ? Icons.lock : Icons.public,
                          size: 12.sp,
                          color: widget.group.isPrivate ? Colors.red : Colors.green,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          widget.group.isPrivate ? "Private" : "Public",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: widget.group.isPrivate ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: const Color(0xFFE5A00D)),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        // Start Matching Button
        Expanded(
          flex: 2,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 56.h,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              colors: [
                const Color(0xFFE5A00D).withValues(alpha: 0.9),
                Colors.orange.shade600.withValues(alpha: 0.9),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFFE5A00D),
                Colors.orange.shade600,
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startGroupMatching,
                borderRadius: BorderRadius.circular(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_filter,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Start Matching",
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
        ),
        
        SizedBox(width: 16.w),
        
        // Manage Members Button (formerly Invite)
        Expanded(
          flex: 1,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 56.h,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.2),
                Colors.blue.withValues(alpha: 0.1),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.6),
                Colors.blue.withValues(alpha: 0.3),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showManageMembers,
                borderRadius: BorderRadius.circular(16.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group,
                      color: Colors.blue,
                      size: 20.sp,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Manage",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Members",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${widget.group.members.length} people",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),
        
        // Enhanced Members list
        _buildEnhancedMembersList(),
      ],
    );
  }

  Widget _buildGroupMatchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Group Matches",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${_groupMatches.length} matches",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8.h),
        
        Text(
          "Movies this group has matched together",
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12.sp,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _isLoadingMatches
            ? _buildLoadingMatches()
            : _groupMatches.isEmpty
                ? _buildEmptyMatches()
                : _buildMatchesCarousel(),
      ],
    );
  }

  // 7. Add these supporting widgets:
  Widget _buildLoadingMatches() {
    return Container(
      height: 180.h,
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE5A00D),
          strokeWidth: 2.w,
        ),
      ),
    );
  }

  Widget _buildEmptyMatches() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.w,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            color: Colors.white30,
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            "No matches yet",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "Start matching together to see results here",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesCarousel() {
    return Container(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _groupMatches.length,
        itemBuilder: (context, index) {
          final movie = _groupMatches[index]; // ✅ use preloaded object

          return Container(
            width: 120.w,
            margin: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () {
                showMovieDetails(
                  context: context,
                  movie: movie,
                  currentUser: widget.currentUser,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          movie.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[800],
                            child: Center(
                              child: Icon(Icons.broken_image, color: Colors.white30, size: 24.sp),
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
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadGroupMatches() async {
    setState(() {
      _isLoadingMatches = true;
    });

    try {
      print("📅 Loading group matches for: ${widget.group.name}");
      
      // Get all group member UIDs
      final groupMemberIds = widget.group.members.map((member) => member.uid).toList();
      print("👥 Group members: ${groupMemberIds.length} (${groupMemberIds})");
      
      // Query swipeSessions collection for group sessions with these members
      final sessionsQuery = await FirebaseFirestore.instance
          .collection('swipeSessions')
          .where('status', isEqualTo: 'completed')
          .get();
      
      print("📊 Found ${sessionsQuery.docs.length} total completed sessions");
      
      // Filter for sessions that are GROUP sessions with these specific members
      final groupSessions = sessionsQuery.docs.where((doc) {
        final data = doc.data();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final sessionType = data['type'] ?? data['inviteType'];
        final sessionGroupId = data['groupId'];
        
        // Must meet these criteria:
        // 1. Be a group session (3+ participants OR explicitly marked as group type)
        // 2. Include members from this group
        // 3. Optionally match the groupId if available
        
        final isGroupSession = sessionType == 'group' || participantIds.length >= 3;
        final hasGroupMembers = participantIds.any((id) => groupMemberIds.contains(id));
        final matchesGroupId = sessionGroupId == null || sessionGroupId == widget.group.id;
        
        // For now, we'll include any group session that has members from this group
        // This is a bit loose, but should work for most cases
        final qualifies = isGroupSession && hasGroupMembers && matchesGroupId;
        
        if (qualifies) {
          print("✅ Valid group session: ${doc.id}");
          print("   Participants: ${participantIds.length} (${participantIds})");
          print("   Type: $sessionType, GroupId: $sessionGroupId");
        }
        
        return qualifies;
      }).toList();
      
      print("🎬 Found ${groupSessions.length} group sessions");
      
      // Extract all matched movie IDs from these group sessions
      final Set<String> allMatchedMovieIds = {};
      for (final sessionDoc in groupSessions) {
        final data = sessionDoc.data();
        final matches = List<String>.from(data['matches'] ?? []);
        allMatchedMovieIds.addAll(matches);
        print("📽️ Group session ${sessionDoc.id}: ${matches.length} matches");
      }
      
      print("🎬 Total unique group matches: ${allMatchedMovieIds.length}");
      
      // Load movie details from local database
      if (allMatchedMovieIds.isNotEmpty) {
        final fullMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
        final loadedMovies = <Movie>[];
        
        for (final movieId in allMatchedMovieIds) {
          try {
            final movie = fullMovieDatabase.firstWhere((m) => m.id == movieId);
            loadedMovies.add(movie);
            print("✅ Loaded group match movie: ${movie.title}");
          } catch (e) {
            print("❌ Could not find movie with ID: $movieId");
          }
        }
        
        setState(() {
          _groupMatches = loadedMovies;
          _isLoadingMatches = false;
        });
        
        print("📊 Successfully loaded ${loadedMovies.length} group match movie objects");
      } else {
        setState(() {
          _groupMatches = [];
          _isLoadingMatches = false;
        });
        print("ℹ️ No group matches found");
      }
      
    } catch (e) {
      print("❌ Error loading group matches: $e");
      setState(() {
        _groupMatches = [];
        _isLoadingMatches = false;
      });
    }
  }



  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommended For Group",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _recommendedMovies.isEmpty
            ? _buildEmptyRecommendations()
            : _buildRecommendationsGrid(),
      ],
    );
  }

  Widget _buildEnhancedMembersList() {
    return Column(
      children: widget.group.members.map((member) {
        final bool isCurrentUser = member.uid == widget.currentUser.uid;
        final bool isCreator = member.uid == widget.group.creatorId;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 70.h,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.centerLeft,
            border: 1,
            linearGradient: LinearGradient(
              colors: isCurrentUser
                  ? [
                      const Color(0xFFE5A00D).withValues(alpha: 0.15),
                      const Color(0xFFE5A00D).withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ],
            ),
            borderGradient: LinearGradient(
              colors: isCurrentUser
                  ? [
                      const Color(0xFFE5A00D).withValues(alpha: 0.6),
                      const Color(0xFFE5A00D).withValues(alpha: 0.3),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Enhanced member avatar
                  Stack(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCreator 
                                ? [const Color(0xFFE5A00D), Colors.orange.shade600]
                                : [Colors.blue.shade400, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Creator crown
                      if (isCreator)
                        Positioned(
                          top: -2.h,
                          right: -2.w,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A00D),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: const Color(0xFF121212), width: 1.w),
                            ),
                            child: Icon(Icons.star, color: Colors.white, size: 10.sp),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Member details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.name.isEmpty ? 'Unknown User' : member.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Status badges
                            if (isCurrentUser)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  "You",
                                  style: TextStyle(
                                    color: const Color(0xFFE5A00D),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        SizedBox(height: 2.h),
                        
                        // Role indicator
                        Text(
                          isCreator ? 'Group Creator' : 'Member',
                          style: TextStyle(
                            color: isCreator ? const Color(0xFFE5A00D) : Colors.white54,
                            fontSize: 11.sp,
                            fontWeight: isCreator ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Member actions for non-current users
                  if (!isCurrentUser && widget.group.isCreatedBy(widget.currentUser.uid))
                    GestureDetector(
                      onTap: () => _showMemberOptions(member),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white60,
                          size: 16.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.movie_outlined,
                size: 48.sp,
                color: Colors.white24,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "No recommendations yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Start matching with this group to get recommendations",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _recommendedMovies.length,
      itemBuilder: (context, index) {
        final movie = _recommendedMovies.elementAt(index);
        
        return GestureDetector(
          onTap: () {
            // Show movie details dialog
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Icon(Icons.broken_image, color: Colors.white30, size: 24.sp),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 4.h),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildManageMembersSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF161616),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Icon(Icons.group, color: Colors.blue, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  "Manage Members",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Text(
                  "${widget.group.members.length} members",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Add Members Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: GlassmorphicContainer(
              width: double.infinity,
              height: 56.h,
              borderRadius: 16,
              blur: 10,
              alignment: Alignment.center,
              border: 2,
              linearGradient: LinearGradient(
                colors: [
                  const Color(0xFFE5A00D).withValues(alpha: 0.9),
                  Colors.orange.shade600.withValues(alpha: 0.9),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  const Color(0xFFE5A00D),
                  Colors.orange.shade600,
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAddMembersDialog,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Add Members",
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
          ),
          
          SizedBox(height: 20.h),
          
          // Current Members List
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Members",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.group.members.length,
                      itemBuilder: (context, index) {
                        final member = widget.group.members[index];
                        return _buildMemberListItem(member, true);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Group Settings Bottom Sheet (keeping existing implementation)
  Widget _buildGroupSettingsSheet() {
    final isCreator = widget.group.isCreatedBy(widget.currentUser.uid);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF161616),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
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
            
            // Header
            Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  "Group Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Settings options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isCreator) ...[
                      // Edit Group
                      _buildSettingsOption(
                        icon: Icons.edit,
                        title: "Edit Group Info",
                        subtitle: "Change name, description, and privacy",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          ThemedNotifications.showInfo(context, 'Edit group coming soon!', icon: "🚧");
                        },
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      // Group Privacy
                      _buildSettingsOption(
                        icon: widget.group.isPrivate ? Icons.lock : Icons.public,
                        title: widget.group.isPrivate ? "Make Public" : "Make Private",
                        subtitle: widget.group.isPrivate 
                            ? "Allow anyone to discover and join"
                            : "Require invitations to join",
                        color: widget.group.isPrivate ? Colors.green : Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleGroupPrivacy();
                        },
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Danger zone separator
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1.h,
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              "DANGER ZONE",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.h,
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Delete Group (Creator only)
                      _buildSettingsOption(
                        icon: Icons.delete_forever,
                        title: "Delete Group",
                        subtitle: "Permanently delete this group and all data",
                        color: Colors.red,
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeleteGroup();
                        },
                      ),
                    ] else ...[
                      // Non-creator options
                      _buildSettingsOption(
                        icon: Icons.notifications,
                        title: "Notifications",
                        subtitle: "Manage group notification settings",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          ThemedNotifications.showInfo(context, 'Notification settings coming soon!', icon: "🚧");
                        },
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      _buildSettingsOption(
                        icon: Icons.report,
                        title: "Report Group",
                        subtitle: "Report inappropriate content or behavior",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          ThemedNotifications.showInfo(context, 'Report feature coming soon!', icon: "🚧");
                        },
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Leave Group
                      _buildSettingsOption(
                        icon: Icons.exit_to_app,
                        title: "Leave Group",
                        subtitle: "You can be re-invited by the group creator",
                        color: Colors.red,
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmLeaveGroup();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: Colors.white30),
                  ),
                ),
                child: Text(
                  "Close",
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 70.h,
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.centerLeft,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDestructive
            ? [
                Colors.red.withValues(alpha: 0.1),
                Colors.red.withValues(alpha: 0.05),
              ]
            : [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
      ),
      borderGradient: LinearGradient(
        colors: isDestructive
            ? [
                Colors.red.withValues(alpha: 0.3),
                Colors.red.withValues(alpha: 0.1),
              ]
            : [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
    );
  }

  void _inviteFriendToGroup(UserProfile friend) async {
    try {
      await GroupInvitationService().sendGroupInvitations(
        groupId: widget.group.id,
        groupName: widget.group.name,
        groupDescription: widget.group.description,
        groupImageUrl: widget.group.imageUrl,
        creator: widget.currentUser,
        invitees: [friend],
      );
      
      Navigator.pop(context); // Close add members sheet
      ThemedNotifications.showLike(context, 'Invitation sent to ${friend.name}!', icon: "📨");
    } catch (e) {
      ThemedNotifications.showDecline(context, 'Failed to send invitation: $e', icon: "❌");
    }
  }

  void _showRemoveMemberDialog(UserProfile member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Remove Member?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          "Are you sure you want to remove ${member.name} from this group?",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close manage members sheet
              
              try {
                // ✅ FIXED: Actually remove the member from the group
                await GroupService().removeMemberFromGroup(
                  groupId: widget.group.id,
                  memberIdToRemove: member.uid,
                );
                
                // ✅ FIXED: Update the local UI by removing from the current group object
                setState(() {
                  widget.group.members.removeWhere((m) => m.uid == member.uid);
                });
                
                // ✅ FIXED: Call the refresh callback
                if (widget.onGroupUpdated != null) {
                  widget.onGroupUpdated!();
                }
                
                ThemedNotifications.showDecline(context, '${member.name} removed from group', icon: "👋");
              } catch (e) {
                ThemedNotifications.showError(context, 'Failed to remove member: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              "Remove",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberOptions(UserProfile member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1F1F1F),
              const Color(0xFF121212),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              member.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 20.h),
            
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text("View Profile", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to member profile
              },
            ),
            
            ListTile(
              leading: Icon(Icons.message, color: Colors.green),
              title: Text("Send Message", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Open message dialog
              },
            ),
            
            if (widget.group.isCreatedBy(widget.currentUser.uid))
              ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text("Remove from Group", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveMember(member);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _toggleGroupPrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Change Group Privacy",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Privacy settings will be available soon!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: const Color(0xFFE5A00D))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Delete Group?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "This will permanently delete \"${widget.group.name}\" and remove all members.",
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "This action cannot be undone!",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                // ✅ FIXED: Actually delete the group from backend
                await GroupService().deleteGroup(widget.group.id, widget.currentUser.uid);
                
                Navigator.pop(context); // Go back to groups list
                
                // ✅ FIXED: Call the refresh callback
                if (widget.onGroupUpdated != null) {
                  widget.onGroupUpdated!();
                }
                
                ThemedNotifications.showDecline(context, 'Group "${widget.group.name}" deleted', icon: "🗑️");
              } catch (e) {
                ThemedNotifications.showError(context, 'Failed to delete group: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              "Delete Group",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Leave Group?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          "Are you sure you want to leave \"${widget.group.name}\"? You can be re-invited by the group creator.",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                await GroupService().leaveGroup(widget.group.id, widget.currentUser.uid);
                
                Navigator.pop(context); // Go back to friends screen
                
                // ✅ Call the refresh callback
                if (widget.onGroupUpdated != null) {
                  widget.onGroupUpdated!();
                }
                
                ThemedNotifications.showInfo(context, 'You left "${widget.group.name}"', icon: "🚪");
              } catch (e) {
                ThemedNotifications.showError(context, 'Failed to leave group: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(
              "Leave Group",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(UserProfile member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Remove Member?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          "Are you sure you want to remove ${member.name} from this group?",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                // ✅ FIXED: Actually remove the member from the group backend
                await GroupService().removeMemberFromGroup(
                  groupId: widget.group.id,
                  memberIdToRemove: member.uid,
                );
                
                // ✅ FIXED: Update the local UI by removing from the current group object
                setState(() {
                  widget.group.members.removeWhere((m) => m.uid == member.uid);
                });
                
                // ✅ FIXED: Call the refresh callback
                if (widget.onGroupUpdated != null) {
                  widget.onGroupUpdated!();
                }
                
                // Close the manage members sheet if it's open
                Navigator.pop(context);
                
                ThemedNotifications.showDecline(context, '${member.name} removed from group', icon: "👋");
              } catch (e) {
                ThemedNotifications.showError(context, 'Failed to remove member: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              "Remove",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}