import '/movie.dart';
import '../utils/completed_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../utils/user_profile_storage.dart';

class MovieLike {
  final String movieId;
  final DateTime likedAt;
  final String sessionType; // "solo", "friend", "group"
  
  MovieLike({
    required this.movieId, 
    required this.likedAt, 
    required this.sessionType
  });
  
  factory MovieLike.fromJson(Map<String, dynamic> json) {
    return MovieLike(
      movieId: json['movieId'],
      likedAt: DateTime.parse(json['likedAt']),
      sessionType: json['sessionType'] ?? 'solo',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'movieId': movieId,
      'likedAt': likedAt.toIso8601String(),
      'sessionType': sessionType,
    };
  }
}

class UserProfile {
  String uid;
  String name;
  Set<String> likedMovieIds;
  Set<String> matchedMovieIds;
  List<CompletedSession> sessionHistory;
  List<Map<String, dynamic>> matchHistory;
  final List<String> friendIds;
  final List<String> groupIds;
  List<MovieLike> recentLikes;
  List<String> recentLikedMovieIds;
  DateTime lastActivityDate;
  Set<String> passedMovieIds;
  bool hasSeenMatcher = false;

  // ✅ SMART SOLUTION: In-memory cache for Movie objects (not persisted)
  // This gives us the performance benefits without storage bloat
  Set<Movie> _cachedLikedMovies = <Movie>{};
  Set<Movie> _cachedMatchedMovies = <Movie>{};
  
  // ✅ PERFORMANCE: Track what's in cache to avoid duplicate loading
  Set<String> _cachedLikedMovieIds = <String>{};
  Set<String> _cachedMatchedMovieIds = <String>{};

  UserProfile({
    required this.uid,
    this.name = '',
    this.friendIds = const [],
    this.groupIds = const [],
    required this.likedMovieIds,
    required this.matchedMovieIds,
    required this.matchHistory,
    this.hasSeenMatcher = false,
    List<String>? recentLikedMovieIds,
    DateTime? lastActivityDate,
    Set<String>? passedMovieIds,
    List<MovieLike>? recentLikes,
    this.sessionHistory = const [],
    Set<String>? preferredGenres,
    Set<String>? preferredVibes,
    Set<String>? blockedGenres, 
    Set<String>? blockedAttributes,
    Set<Movie>? likedMovies,
    Set<Movie>? matchedMovies,
    Map<String, double>? genreScores,
    Map<String, double>? vibeScores,
    })  : recentLikedMovieIds = recentLikedMovieIds ?? [],
        lastActivityDate = lastActivityDate ?? DateTime.now(),
        passedMovieIds = passedMovieIds ?? {},
        recentLikes = recentLikes ?? [];

  // ✅ SMART GETTERS: Return cached movies + lazy load missing ones
  Set<Movie> get likedMovies {
    // Return what we have in cache - UI can request loading of missing ones separately
    return Set.from(_cachedLikedMovies);
  }
  
  Set<Movie> get matchedMovies {
    // Return what we have in cache - UI can request loading of missing ones separately  
    return Set.from(_cachedMatchedMovies);
  }

  // ✅ EFFICIENT: Add movies to both cache and IDs
  void addLikedMovie(Movie movie) {
    likedMovieIds.add(movie.id);
    _cachedLikedMovies.add(movie);
    _cachedLikedMovieIds.add(movie.id);
  }
  
  void addMatchedMovie(Movie movie) {
    matchedMovieIds.add(movie.id);
    _cachedMatchedMovies.add(movie);
    _cachedMatchedMovieIds.add(movie.id);
  }

  // ✅ BULK LOADING: Load missing movies into cache
  void loadMoviesIntoCache(List<Movie> movies) {
    for (final movie in movies) {
      // Add to liked cache if ID is in likedMovieIds but not yet cached
      if (likedMovieIds.contains(movie.id) && !_cachedLikedMovieIds.contains(movie.id)) {
        _cachedLikedMovies.add(movie);
        _cachedLikedMovieIds.add(movie.id);
      }
      
      // Add to matched cache if ID is in matchedMovieIds but not yet cached
      if (matchedMovieIds.contains(movie.id) && !_cachedMatchedMovieIds.contains(movie.id)) {
        _cachedMatchedMovies.add(movie);
        _cachedMatchedMovieIds.add(movie.id);
      }
    }
  }

  // ✅ CACHE MANAGEMENT: Get IDs that need loading
  Set<String> getMissingLikedMovieIds() {
    return likedMovieIds.difference(_cachedLikedMovieIds);
  }
  
  Set<String> getMissingMatchedMovieIds() {
    return matchedMovieIds.difference(_cachedMatchedMovieIds);
  }

  // ✅ SETTERS: Clear both cache and IDs (for reset functionality)
  set likedMovies(Set<Movie> value) {
    _cachedLikedMovies = Set.from(value);
    _cachedLikedMovieIds = value.map((movie) => movie.id).toSet();
    likedMovieIds = Set.from(_cachedLikedMovieIds);
  }
  
  set matchedMovies(Set<Movie> value) {
    _cachedMatchedMovies = Set.from(value);
    _cachedMatchedMovieIds = value.map((movie) => movie.id).toSet();
    matchedMovieIds = Set.from(_cachedMatchedMovieIds);
  }

  void addCompletedSession(CompletedSession session) {
    sessionHistory.insert(0, session);
    if (sessionHistory.length > 50) {
      sessionHistory = sessionHistory.take(50).toList();
    }
  }

  // Get recent solo sessions
  List<CompletedSession> get recentSoloSessions {
    return sessionHistory
        .where((session) => session.type == SessionType.solo)
        .take(10)
        .toList();
  }

  // Get recent collaborative sessions
  List<CompletedSession> get recentCollaborativeSessions {
    return sessionHistory
        .where((session) => session.type != SessionType.solo)
        .take(10)
        .toList();
  }

  // Get sessions from last 7 days
  List<CompletedSession> get recentSessions {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return sessionHistory
        .where((session) => session.startTime.isAfter(weekAgo))
        .toList();
  }

  // Session statistics
  int get totalSessions => sessionHistory.length;
  
  int get totalMatches => sessionHistory
      .map((session) => session.matchedMovieIds.length)
      .fold(0, (sum, matches) => sum + matches);
  
  int get totalLikedFromSessions => sessionHistory
      .map((session) => session.likedMovieIds.length)
      .fold(0, (sum, likes) => sum + likes);

  Future<List<CompletedSession>> loadCollaborativeSessions(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('swipeSessions')
        .where('hostId', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();

    return snapshot.docs.map((doc) {
      return CompletedSession.fromFirestore(doc.id, doc.data());
    }).toList();
  }

  factory UserProfile.empty() {
    return UserProfile(
      uid: '',
      name: '',
      friendIds: const [],
      groupIds: const [],
      likedMovieIds: {},
      matchedMovieIds: {},
      matchHistory: [],
      recentLikedMovieIds: [],
      passedMovieIds: {},
      recentLikes: [],
    );
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    List<String>? friendIds,
    List<String>? groupIds,
    Set<String>? likedMovieIds,
    Set<String>? favouriteMovieIds,
    Set<String>? matchedMovieIds,
    List<Map<String, dynamic>>? matchHistory,
    bool? hasSeenMatcher,
    List<String>? recentLikedMovieIds,
    DateTime? lastActivityDate,
    Set<String>? passedMovieIds,
    List<MovieLike>? recentLikes,
    List<CompletedSession>? sessionHistory,
    // Compatibility: Ignore these old parameters for now
    Set<String>? preferredGenres,
    Set<String>? preferredVibes,
    Set<String>? blockedGenres,
    Set<String>? blockedAttributes,
    Set<Movie>? likedMovies,
    Set<Movie>? matchedMovies,
    Map<String, double>? genreScores,
    Map<String, double>? vibeScores,
  }) {
    final newProfile = UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      friendIds: friendIds ?? this.friendIds,
      groupIds: groupIds ?? this.groupIds,
      likedMovieIds: likedMovieIds ?? this.likedMovieIds,
      matchedMovieIds: matchedMovieIds ?? this.matchedMovieIds,
      matchHistory: matchHistory ?? this.matchHistory,
      hasSeenMatcher: hasSeenMatcher ?? this.hasSeenMatcher,
      recentLikedMovieIds: recentLikedMovieIds ?? this.recentLikedMovieIds,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      passedMovieIds: passedMovieIds ?? this.passedMovieIds,
      recentLikes: recentLikes ?? this.recentLikes,
      sessionHistory: sessionHistory ?? this.sessionHistory,
    );
    
    // ✅ IMPORTANT: Preserve cache when copying
    newProfile._cachedLikedMovies = Set.from(_cachedLikedMovies);
    newProfile._cachedMatchedMovies = Set.from(_cachedMatchedMovies);
    newProfile._cachedLikedMovieIds = Set.from(_cachedLikedMovieIds);
    newProfile._cachedMatchedMovieIds = Set.from(_cachedMatchedMovieIds);
    
    return newProfile;
  }

  Map<String, dynamic> toJson() {
    // ✅ EFFICIENT: Only persist IDs, not Movie objects
    return {
      'uid': uid,
      'name': name,
      'friendIds': friendIds,
      'groupIds': groupIds,
      'likedMovieIds': likedMovieIds.toList(),
      'matchedMovieIds': matchedMovieIds.toList(),
      
      // ✅ OPTIMIZED: Store only essential match data, not full movie objects
      'matchHistory': matchHistory.map((match) => {
        'movieId': match['movieId'],
        'matchDate': match['matchDate'],
        'username': match['username'],
        'watched': match['watched'] ?? false,
        'archived': match['archived'] ?? false,
        'archivedDate': match['archivedDate'],
        'groupName': match['groupName'],
        // Remove 'movie' object - fetch details when needed
      }).toList(),
      
      'hasSeenMatcher': hasSeenMatcher,
      'recentLikedMovieIds': recentLikedMovieIds,
      'lastActivityDate': lastActivityDate.toIso8601String(),
      'passedMovieIds': passedMovieIds.toList(),
      'recentLikes': recentLikes.map((like) => like.toJson()).toList(),
      'sessionHistory': sessionHistory.map((session) => session.toJson()).toList(),
      
      // ✅ NOTE: _cachedLikedMovies and _cachedMatchedMovies are NOT persisted
      // They will be rebuilt from IDs when the profile is loaded
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      friendIds: List<String>.from(json['friendIds'] ?? []),
      groupIds: List<String>.from(json['groupIds'] ??[]),
      likedMovieIds: Set<String>.from(json['likedMovieIds'] ?? []),
      matchedMovieIds: Set<String>.from(json['matchedMovieIds'] ?? []),
      matchHistory: (json['matchHistory'] as List<dynamic>? ?? [])
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(),
      hasSeenMatcher: json['hasSeenMatcher'] ?? false,
      recentLikedMovieIds: List<String>.from(json['recentLikedMovieIds'] ?? []),
      lastActivityDate: json['lastActivityDate'] != null 
          ? DateTime.parse(json['lastActivityDate'])
          : DateTime.now(),
      passedMovieIds: Set<String>.from(json['passedMovieIds'] ?? []),
      recentLikes: (json['recentLikes'] as List<dynamic>?)
        ?.map((item) => MovieLike.fromJson(item as Map<String, dynamic>))
        .toList() ?? [],
      sessionHistory: (json['sessionHistory'] as List<dynamic>?)
          ?.map((sessionJson) => CompletedSession.fromJson(sessionJson))
          .toList() ?? [],
      
      // 🔄 COMPATIBILITY: Ignore old format data gracefully
      // These fields existed in old profiles but are no longer stored
      preferredGenres: null, // Ignored
      preferredVibes: null,  // Ignored  
      blockedGenres: null,   // Ignored
      blockedAttributes: null, // Ignored
      likedMovies: null,     // Ignored - use likedMovieIds instead
      matchedMovies: null,   // Ignored - use matchedMovieIds instead
      genreScores: null,     // Ignored for now
      vibeScores: null,      // Ignored for now
    );
    // ✅ NOTE: Cache starts empty and gets populated as movies are loaded
  }

  // Helper methods
  bool isMemberOfGroup(String groupId) => groupIds.contains(groupId);
  int get groupCount => groupIds.length;
  bool get hasGroups => groupIds.isNotEmpty;

  // Add/remove group methods
  UserProfile addToGroup(String groupId) {
    if (groupIds.contains(groupId)) return this;
    return copyWith(groupIds: [...groupIds, groupId]);
  }

  UserProfile removeFromGroup(String groupId) {
    final newGroupIds = groupIds.where((id) => id != groupId).toList();
    return copyWith(groupIds: newGroupIds);
  }
  
  bool isFriendsWith(String userId) => friendIds.contains(userId);
  int get friendCount => friendIds.length;
  bool get hasFriends => friendIds.isNotEmpty;

  void removeDuplicateSessions() {
    final seen = <String>{};
    final uniqueSessions = <CompletedSession>[];
    
    for (final session in sessionHistory) {
      if (!seen.contains(session.id)) {
        seen.add(session.id);
        uniqueSessions.add(session);
      }
    }
    
    if (uniqueSessions.length != sessionHistory.length) {
      print("🧹 Cleaned up ${sessionHistory.length - uniqueSessions.length} duplicate sessions");
      sessionHistory = uniqueSessions;
    }
  }

  // 🆕 Method 2: Get all sessions for display (combines local solo + firestore collaborative)
  Future<List<CompletedSession>> getAllSessionsForDisplay() async {
    final soloSessions = sessionHistory
        .where((session) => session.type == SessionType.solo)
        .toList();
    
    try {
      final uid = this.uid;
      final userService = UserService(); // You'll need to import this
      final collaborativeSessions = await userService.loadCollaborativeSessionsForDisplay(uid);
      
      // Combine and sort by date
      final allSessions = [...soloSessions, ...collaborativeSessions];
      allSessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      return allSessions;
    } catch (e) {
      print("Error loading collaborative sessions: $e");
      return soloSessions; // Fallback to solo sessions only
    }
  }

  // 🆕 Method 3: Delete session from appropriate storage
  Future<void> deleteSession(CompletedSession session) async {
    if (session.type == SessionType.solo) {
      // Remove from local storage
      sessionHistory.removeWhere((s) => s.id == session.id);
      await UserProfileStorage.saveProfile(this);
    } else {
      // Remove from Firestore
      try {
        await FirebaseFirestore.instance
            .collection('swipeSessions')
            .doc(session.id)
            .delete();
      } catch (e) {
        print("Error deleting collaborative session: $e");
      }
    }
  }

  // ✅ COMPATIBILITY: Temporary getters for existing code
  // These provide backwards compatibility while you migrate your UI code
  
  // Empty sets/maps for now since mood system doesn't use these
  Set<String> get preferredGenres => <String>{};
  Set<String> get preferredVibes => <String>{};
  Set<String> get blockedGenres => <String>{};
  Set<String> get blockedAttributes => <String>{};
  Map<String, double> get genreScores => <String, double>{};
  Map<String, double> get vibeScores => <String, double>{};
}