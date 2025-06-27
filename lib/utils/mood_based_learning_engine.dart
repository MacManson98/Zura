// File: lib/utils/mood_based_learning_engine.dart
// MINIMAL IMPROVEMENTS: Same API, better internal logic, removed redundancies

import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/debug_loader.dart';

// Same mood enum - no changes
enum CurrentMood {
  pureComedy('Pure Comedy', '😂', ['Comedy'], ['Funny', 'Silly', 'Upbeat', 'Light-Hearted', 'Hilarious', 'Witty']),
  epicAction('Epic Action', '💥', ['Action'], ['Action-Packed', 'High Stakes', 'Fast-Paced', 'Adrenaline', 'Intense', 'Explosive']),
  scaryAndSuspenseful('Fear & Suspense', '😱', ['Horror', 'Thriller'], ['Scary', 'Suspenseful', 'Dark', 'Creepy', 'Terrifying', 'Spine-Chilling']),
  romantic('Romantic', '💕', ['Romance'], ['Romantic', 'Sweet', 'Heartwarming', 'Love Story', 'Passionate', 'Tender']),
  mindBending('Mind-Bending', '🤔', ['Drama', 'Sci-Fi', 'Mystery', 'Thriller'], ['Mind-Bending', 'Complex', 'Thought-Provoking', 'Twist', 'Cerebral', 'Psychological']),
  emotionalDrama('Emotional Drama', '💭', ['Drama'], ['Emotional', 'Heartwarming', 'Moving', 'Deep', 'Touching', 'Meaningful']),
  trueStories('True Stories', '📖', ['Biography', 'History', 'Drama', 'Documentary'], ['Based on a True Story', 'Real Events', 'True Story', 'Historical', 'Biographical']),
  mysteryCrime('Mystery & Crime', '🔍', ['Crime', 'Mystery', 'Thriller'], ['Mystery', 'Crime', 'Investigation', 'Detective', 'Intrigue', 'Puzzle']),
  adventureFantasy('Epic Worlds', '🗺️', ['Adventure', 'Fantasy', 'Sci-Fi'], ['Epic', 'Adventure', 'Journey', 'Fantasy', 'Magical', 'Otherworldly']),
  musicalDance('Musical & Dance', '🎵', ['Musical'], ['Uplifting', 'Musical', 'Dance']),
  familyFun('Family Fun', '👨‍👩‍👧‍👦', ['Family', 'Animation'], ['Family-Friendly', 'Kids', 'Wholesome']),
  sciFiFuture('Sci-Fi & Future', '🚀', ['Sci-Fi'], ['Futuristic', 'Space', 'Technology']),
  worldCinema('World Cinema', '🌍', ['Foreign', 'Drama'], ['International', 'Cultural', 'Subtitled']),
  cultClassic('Cult Classic', '🎞️', ['Drama', 'Comedy', 'Horror'], ['Cult Classic', 'Underground', 'Retro', 'Campy', 'Weird', 'Quirky', 'B-Movie', 'Niche']),
  twistEnding('Twist Ending', '🔄', ['Thriller', 'Mystery', 'Drama'], ['Plot Twist', 'Surprise Ending', 'Shocking', 'Mind-Bending', 'Unexpected', 'Psychological']),
  highStakes('High Stakes', '🧨', ['Action', 'Thriller', 'Crime'], ['Tension', 'Urgent', 'Unrelenting', 'Time-Sensitive', 'Race Against Time', 'Explosive']);

  const CurrentMood(this.displayName, this.emoji, this.preferredGenres, this.preferredVibes);
  
  final String displayName;
  final String emoji;
  final List<String> preferredGenres;
  final List<String> preferredVibes;
}

// Same SessionContext - no changes
class SessionContext {
  final CurrentMood moods;
  final DateTime startTime;
  final List<String> groupMemberIds;
  
  SessionContext({
    required this.moods,
    required this.groupMemberIds,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();
}

class MoodBasedLearningEngine {
  
  /// ✨ IMPROVED: Same method signature, better internal logic
  static Future<List<Movie>> generateMoodBasedSession({
    required UserProfile user,
    required List<Movie> movieDatabase,
    required SessionContext sessionContext,
    required Set<String> seenMovieIds,
    required Set<String> sessionPassedMovieIds,
    int sessionSize = 30,
  }) async {
    DebugLogger.log("🎭 Generating mood session: ${sessionContext.moods.displayName}");
    DebugLogger.log("   Target genres: ${sessionContext.moods.preferredGenres}");
    DebugLogger.log("   Target vibes: ${sessionContext.moods.preferredVibes}");
    
    // Step 1: Filter by mood (improved but same logic)
    final moodFilteredMovies = _filterByMood(
      movieDatabase, 
      sessionContext.moods, 
      seenMovieIds, 
      sessionPassedMovieIds
    );
    
    if (moodFilteredMovies.isEmpty) {
      DebugLogger.log("⚠️ No movies found for mood, using fallback");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    // Step 2: ✨ IMPROVED: Better scoring that considers user preferences when available
    final result = _sortWithSmartScoring(moodFilteredMovies, user, sessionSize);
    
    DebugLogger.log("🎬 Generated ${result.length} mood movies");
    DebugLogger.log("   Sample: ${result.take(3).map((m) => m.title).join(', ')}");
    
    return result;
  }
  
  /// ✨ IMPROVED: Same method signature, better group balancing
  static Future<List<Movie>> generateGroupSession({
    required List<UserProfile> groupMembers,
    required List<Movie> movieDatabase,
    required SessionContext sessionContext,
    required Set<String> seenMovieIds,
    int sessionSize = 25,
  }) async {
    DebugLogger.log("👥 Generating shared mood pool for ${groupMembers.length} people: ${sessionContext.moods.displayName}");
    
    // Step 1: Filter by mood (same as before)
    final moodFilteredMovies = _filterByMood(
      movieDatabase, 
      sessionContext.moods, 
      seenMovieIds, 
      <String>{}
    );
    
    if (moodFilteredMovies.isEmpty) {
      DebugLogger.log("⚠️ No movies found for group mood, using fallback");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    // Step 2: ✨ IMPROVED: Consider group preferences when available
    final sharedPool = _sortForGroupCompatibility(moodFilteredMovies, groupMembers, sessionSize);
    
    DebugLogger.log("🎬 Generated ${sharedPool.length} shared movies for group");
    DebugLogger.log("   Everyone will see: ${sharedPool.take(3).map((m) => m.title).join(', ')}");
    
    return sharedPool;
  }
  
  /// ✨ IMPROVED: Same method signature, better blending logic
  static Future<List<Movie>> generateBlendedMoodSession({
    required UserProfile user,
    required List<Movie> movieDatabase,
    required List<CurrentMood> selectedMoods,
    required Set<String> seenMovieIds,
    required Set<String> sessionPassedMovieIds,
    int sessionSize = 30,
  }) async {
    DebugLogger.log("🎭 Generating blended mood session for: ${selectedMoods.map((m) => m.displayName).join(' + ')}");
    
    // Combine all preferred genres and vibes from selected moods
    final Set<String> allPreferredGenres = {};
    final Set<String> allPreferredVibes = {};
    
    for (final mood in selectedMoods) {
      allPreferredGenres.addAll(mood.preferredGenres);
      allPreferredVibes.addAll(mood.preferredVibes);
    }
    
    DebugLogger.log("   Combined genres: ${allPreferredGenres.join(', ')}");
    DebugLogger.log("   Combined vibes: ${allPreferredVibes.join(', ')}");
        
    // ✨ IMPROVED: Better filtering for blended moods
    final blendedMovies = _filterForBlendedMoods(
      movieDatabase,
      allPreferredGenres,
      allPreferredVibes,
      seenMovieIds,
      sessionPassedMovieIds,
    );
    
    if (blendedMovies.isEmpty) {
      DebugLogger.log("⚠️ No movies found for blended moods, using fallback");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    // ✨ IMPROVED: Better scoring for blended results
    final result = _sortWithSmartScoring(blendedMovies, user, sessionSize);
    
    DebugLogger.log("🎬 Generated ${result.length} blended mood movies");
    return result;
  }
  
  /// ✨ IMPROVED: Better movie filtering with enhanced mood matching
  static List<Movie> _filterByMood(
    List<Movie> movieDatabase, 
    CurrentMood mood, 
    Set<String> seenMovieIds, 
    Set<String> sessionPassedMovieIds
  ) {
    final moodMovies = <Movie>[];
    final excludedMovieIds = <String>{};
    excludedMovieIds.addAll(seenMovieIds);
    excludedMovieIds.addAll(sessionPassedMovieIds);

    for (final movie in movieDatabase) {
      if (excludedMovieIds.contains(movie.id)) continue;
      if (!_meetsQualityThreshold(movie)) continue;
      if (!_isSfwMovie(movie)) continue;

      if (_matchesMoodCriteria(movie, mood)) {
        moodMovies.add(movie);
      }
    }

    DebugLogger.log("✅ Found ${moodMovies.length} movies matching mood: ${mood.displayName}");
    return moodMovies;
  }

  /// ✨ IMPROVED: Enhanced mood matching with better coverage
  static bool _matchesMoodCriteria(Movie movie, CurrentMood mood) {
    final movieGenres = movie.genres.map((g) => g.toLowerCase()).toSet();
    final movieTags = movie.tags.map((t) => t.toLowerCase()).toSet();

    // Direct genre match
    final hasDirectGenreMatch = mood.preferredGenres.any((moodGenre) => 
        movieGenres.contains(moodGenre.toLowerCase()));
    
    // ✨ IMPROVED: Better vibe matching
    final hasVibeMatch = _checkVibeMatch(movieTags, mood.preferredVibes);
    
    // Special cases for specific moods (improved)
    switch (mood) {
      case CurrentMood.musicalDance:
        final hasMusicalGenre = movieGenres.contains('music');
        final hasMusicalTag = movieTags.any((tag) => 
            tag.contains('musical') || tag.contains('music') || tag.contains('dance'));
        return hasMusicalGenre || hasMusicalTag;
        
      case CurrentMood.cultClassic:
        final cultKeywords = ['cult', 'underground', 'retro', 'campy', 'weird', 'quirky', 'b-movie', 'niche'];
        final hasCultVibe = movieTags.any((tag) => 
            cultKeywords.any((keyword) => tag.contains(keyword)));
        return hasDirectGenreMatch || hasVibeMatch || hasCultVibe;
        
      default:
        return hasDirectGenreMatch || hasVibeMatch;
    }
  }
  
  /// ✨ NEW: Better vibe matching that catches more relevant movies
  static bool _checkVibeMatch(Set<String> movieTags, List<String> moodVibes) {
    for (final moodVibe in moodVibes) {
      final vibeLower = moodVibe.toLowerCase();
      
      // Exact match
      if (movieTags.any((tag) => tag.contains(vibeLower))) {
        return true;
      }
      
      // Word-by-word matching for multi-word vibes
      final vibeWords = vibeLower.split(' ').where((w) => w.length > 3);
      if (vibeWords.any((word) => 
          movieTags.any((tag) => tag.contains(word)))) {
        return true;
      }
    }
    return false;
  }
  
  /// ✨ NEW: Better filtering for blended moods
  static List<Movie> _filterForBlendedMoods(
    List<Movie> movieDatabase,
    Set<String> allPreferredGenres,
    Set<String> allPreferredVibes,
    Set<String> seenMovieIds,
    Set<String> sessionPassedMovieIds,
  ) {
    final blendedMovies = <Movie>[];
    final excludedMovieIds = <String>{};
    excludedMovieIds.addAll(seenMovieIds);
    excludedMovieIds.addAll(sessionPassedMovieIds);
    
    for (final movie in movieDatabase) {
      if (excludedMovieIds.contains(movie.id)) continue;
      if (!_meetsQualityThreshold(movie)) continue;
      if (!_isSfwMovie(movie)) continue;
      
      final hasGenreMatch = movie.genres.any((g) => allPreferredGenres.contains(g));
      final hasVibeMatch = _checkVibeMatch(movie.tags.map((t) => t.toLowerCase()).toSet(), allPreferredVibes.toList());
      
      if (hasGenreMatch || hasVibeMatch) {
        blendedMovies.add(movie);
      }
    }
    
    return blendedMovies;
  }
  
  /// ✨ IMPROVED: Smart scoring that considers user preferences when available
  static List<Movie> _sortWithSmartScoring(List<Movie> movies, UserProfile user, int sessionSize) {
    final scoredMovies = movies.map((movie) {
      double score = 0.0;
      
      // Base quality score (unchanged)
      score += (movie.rating ?? 0) + (movie.voteCount ?? 0) / 10000;
      
      // ✨ IMPROVEMENT: Gentle personalization boost when user has preferences
      if (user.preferredGenres.isNotEmpty) {
        final userGenreMatches = movie.genres.where((g) => user.preferredGenres.contains(g)).length;
        score += userGenreMatches * 1.0; // Modest boost
      }
      
      if (user.preferredVibes.isNotEmpty) {
        final userVibeMatches = movie.tags.where((t) => user.preferredVibes.contains(t)).length;
        score += userVibeMatches * 0.5; // Gentle boost
      }
      
      return MapEntry(movie, score);
    }).toList();
    
    scoredMovies.sort((a, b) => b.value.compareTo(a.value));
    final result = scoredMovies.take(sessionSize).map((entry) => entry.key).toList();
    result.shuffle(); // Keep variety
    return result;
  }
  
  /// ✨ IMPROVED: Group sorting that considers group preferences
  static List<Movie> _sortForGroupCompatibility(List<Movie> movies, List<UserProfile> groupMembers, int sessionSize) {
    // Analyze group preferences
    final groupGenres = <String, int>{};
    final groupVibes = <String, int>{};
    
    for (final member in groupMembers) {
      for (final genre in member.preferredGenres) {
        groupGenres[genre] = (groupGenres[genre] ?? 0) + 1;
      }
      for (final vibe in member.preferredVibes) {
        groupVibes[vibe] = (groupVibes[vibe] ?? 0) + 1;
      }
    }
    
    final scoredMovies = movies.map((movie) {
      double score = 0.0;
      
      // Base quality score
      score += (movie.rating ?? 0) + (movie.voteCount ?? 0) / 10000;
      
      // Group preference scoring
      for (final genre in movie.genres) {
        final popularity = groupGenres[genre] ?? 0;
        score += popularity * 1.0; // More members like this genre = higher score
      }
      
      for (final tag in movie.tags) {
        final popularity = groupVibes[tag] ?? 0;
        score += popularity * 0.5;
      }
      
      return MapEntry(movie, score);
    }).toList();
    
    scoredMovies.sort((a, b) => b.value.compareTo(a.value));
    // Don't shuffle for groups - consistent experience
    return scoredMovies.take(sessionSize).map((entry) => entry.key).toList();
  }
  
  // ✨ IMPROVED: Better quality threshold
  static bool _meetsQualityThreshold(Movie movie) {
    return movie.posterUrl.isNotEmpty &&
           movie.rating != null &&
           movie.rating! >= 4.5 && // Slightly more permissive
           movie.voteCount != null &&
           movie.voteCount! >= 500; // Lower threshold for more variety
  }
  
  // Same helper methods (unchanged)
  static List<Movie> _getFallbackMovies(List<Movie> movieDatabase, Set<String> excludedMovieIds, int count) {
    final fallbackMovies = movieDatabase
        .where((movie) => 
            !excludedMovieIds.contains(movie.id) && 
            _meetsQualityThreshold(movie) && 
            _isSfwMovie(movie))
        .toList();
    
    fallbackMovies.shuffle();
    return fallbackMovies.take(count).toList();
  }
  
  static bool _isSfwMovie(Movie movie) {
    final bannedKeywords = ['porn', 'erotic', 'xxx', 'adult', 'sex', 'nude', 'strip'];
    final lcTitle = movie.title.toLowerCase();
    final lcOverview = movie.overview.toLowerCase();
    return !bannedKeywords.any((kw) => lcTitle.contains(kw) || lcOverview.contains(kw));
  }

  // Public helper methods (unchanged)
  static bool meetsQualityThreshold(Movie movie) {
    return _meetsQualityThreshold(movie);
  }

  static bool isSfwMovie(Movie movie) {
    return _isSfwMovie(movie);
  }
}