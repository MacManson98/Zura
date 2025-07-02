// mood_based_learning_engine.dart
// Drop-in replacement that uses the EnhancedMoodEngine
// This maintains the same interface as your original file

import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/debug_loader.dart';
import 'mood_engine.dart';

// Re-export the enums and classes from enhanced engine
export 'mood_engine.dart' show CurrentMood, SessionContext, EnhancedMoodEngine;

class MoodBasedLearningEngine {
  
  /// Main mood session generator - uses enhanced engine
  static Future<List<Movie>> generateMoodBasedSession({
    required UserProfile user,
    required List<Movie> movieDatabase,
    required SessionContext sessionContext,
    required Set<String> seenMovieIds,
    required Set<String> sessionPassedMovieIds,
    int sessionSize = 30,
  }) async {
    DebugLogger.log("🎭 Generating enhanced mood session: ${sessionContext.moods.displayName}");
    
    // Use the enhanced filtering system
    final moodFilteredMovies = EnhancedMoodEngine.filterByMoodCriteria(
      movieDatabase, 
      sessionContext.moods, 
      seenMovieIds, 
      sessionPassedMovieIds
    );
    
    if (moodFilteredMovies.isEmpty) {
      DebugLogger.log("⚠️ No movies found for mood, using fallback");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    final result = _sortAndScoreMovies(moodFilteredMovies, sessionContext.moods, user, sessionSize);
    
    DebugLogger.log("🎬 Generated ${result.length} enhanced mood movies");
    DebugLogger.log("   Sample: ${result.take(3).map((m) => m.title).join(', ')}");
    
    return result;
  }
  
  /// Blended mood session generator
  static Future<List<Movie>> generateBlendedMoodSession({
    required UserProfile user,
    required List<Movie> movieDatabase,
    required List<CurrentMood> selectedMoods,
    required Set<String> seenMovieIds,
    required Set<String> sessionPassedMovieIds,
    int sessionSize = 30,
  }) async {
    DebugLogger.log("🎭 Generating enhanced blended mood session for: ${selectedMoods.map((m) => m.displayName).join(' + ')}");
    
    final blendedMovies = _filterForBlendedMoods(
      movieDatabase,
      selectedMoods,
      seenMovieIds,
      sessionPassedMovieIds,
    );
    
    if (blendedMovies.isEmpty) {
      DebugLogger.log("⚠️ No movies found for blended moods, using fallback");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    // For blended moods, use first mood's criteria for scoring
    final result = _sortAndScoreMovies(blendedMovies, selectedMoods.first, user, sessionSize);
    
    DebugLogger.log("🎬 Generated ${result.length} enhanced blended mood movies");
    return result;
  }
  
  /// Group session generator
  static Future<List<Movie>> generateGroupSession({
    required List<UserProfile> groupMembers,
    required List<Movie> movieDatabase,
    required SessionContext sessionContext,
    required Set<String> seenMovieIds,
    int sessionSize = 25,
  }) async {
    DebugLogger.log("👥 Generating enhanced shared mood pool for ${groupMembers.length} people: ${sessionContext.moods.displayName}");
    
    // Use enhanced filtering
    final moodFilteredMovies = EnhancedMoodEngine.filterByMoodCriteria(
      movieDatabase, 
      sessionContext.moods, 
      seenMovieIds, 
      <String>{}
    );
    
    if (moodFilteredMovies.isEmpty) {
      DebugLogger.log("⚠️ No movies found for group mood, using fallback");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    final sharedPool = _sortForGroupCompatibility(moodFilteredMovies, groupMembers, sessionSize);
    
    DebugLogger.log("🎬 Generated ${sharedPool.length} enhanced shared movies for group");
    DebugLogger.log("   Everyone will see: ${sharedPool.take(3).map((m) => m.title).join(', ')}");
    
    return sharedPool;
  }
  
  // ========================================
  // ENHANCED BLENDED MOOD FILTERING
  // ========================================
  
  static List<Movie> _filterForBlendedMoods(
    List<Movie> movieDatabase,
    List<CurrentMood> selectedMoods,
    Set<String> seenMovieIds,
    Set<String> sessionPassedMovieIds,
  ) {
    final blendedMovies = <Movie>[];
    final excludedMovieIds = <String>{};
    excludedMovieIds.addAll(seenMovieIds);
    excludedMovieIds.addAll(sessionPassedMovieIds);
    
    for (final movie in movieDatabase) {
      if (excludedMovieIds.contains(movie.id)) continue;
      
      // Movie must match at least one of the selected moods using enhanced logic
      final matchesAnyMood = selectedMoods.any((mood) => 
          _isMovieValidForMood(movie, mood));
      
      if (matchesAnyMood) {
        blendedMovies.add(movie);
      }
    }
    
    return blendedMovies;
  }
  
  /// Helper method to check if movie matches mood (wrapper for enhanced engine)
  static bool _isMovieValidForMood(Movie movie, CurrentMood mood) {
    // Use the enhanced engine's public method
    final movieGenres = movie.genres.map((g) => g.toLowerCase()).toSet();
    final movieTags = movie.tags.map((t) => t.toLowerCase()).toSet();
    
    // Check anti-pattern exclusions first
    final excludedGenres = EnhancedMoodEngine.MOOD_EXCLUSIONS[mood];
    if (excludedGenres != null) {
      for (final excludedGenre in excludedGenres) {
        if (movieGenres.contains(excludedGenre.toLowerCase())) {
          return false; // This movie is excluded from this mood
        }
      }
    }
    
    // For Tier 3 moods, check exemplar list using movie title
    if (mood == CurrentMood.mindBending || mood == CurrentMood.twistEnding || mood == CurrentMood.cultClassic) {
      String? moodType;
      switch (mood) {
        case CurrentMood.mindBending:
          moodType = 'mind_bending';
          break;
        case CurrentMood.twistEnding:
          moodType = 'twist_ending';
          break;
        case CurrentMood.cultClassic:
          moodType = 'cult_classic';
          break;
        default:
          break;
      }
      
      if (moodType != null && EnhancedMoodEngine.isExemplarMovieByTitle(movie.title, moodType)) {
        return true; // Exemplar movies always match
      }
    }
    
    // Basic quality and safety checks
    final rating = movie.rating ?? 0;
    final voteCount = movie.voteCount ?? 0;
    if (voteCount < 10 && rating < 5.0) return false;
    
    // Basic mood matching logic (simplified version)
    switch (mood) {
      case CurrentMood.familyFun:
        return movieGenres.contains('family') || movieGenres.contains('animation');
      case CurrentMood.pureComedy:
        return movieGenres.contains('comedy') && movieTags.any((tag) => tag.contains('funny'));
      case CurrentMood.epicAction:
        return movieGenres.contains('action') && movieTags.any((tag) => tag.contains('action-packed'));
      case CurrentMood.scaryAndSuspenseful:
        return movieGenres.contains('horror') || 
               (movieGenres.contains('thriller') && movieTags.any((tag) => tag.contains('scary')));
      case CurrentMood.romantic:
        return movieGenres.contains('romance');
      case CurrentMood.sciFiFuture:
        return movieGenres.contains('science fiction');
      default:
        // For other moods, use basic genre matching
        return mood.preferredGenres.any((g) => movieGenres.contains(g.toLowerCase()));
    }
  }
  
  // ========================================
  // SORTING AND SCORING (PRESERVED FROM ORIGINAL)
  // ========================================
  
  static List<Movie> _sortAndScoreMovies(List<Movie> movies, CurrentMood mood, UserProfile user, int sessionSize) {
    final scoredMovies = movies.map((movie) {
      double score = 0.0;
      
      // Base quality score
      score += (movie.rating ?? 0) * 10;
      score += (movie.voteCount ?? 0) / 1000;
      
      // Mood alignment score
      final movieGenres = movie.genres.map((g) => g.toLowerCase()).toSet();
      final moodGenres = mood.preferredGenres.map((g) => g.toLowerCase()).toSet();
      final genreOverlap = movieGenres.intersection(moodGenres).length;
      score += genreOverlap * 20;
      
      // Tag alignment score
      final movieTags = movie.tags.map((t) => t.toLowerCase()).toSet();
      final moodTags = mood.preferredVibes.map((v) => v.toLowerCase()).toSet();
      final tagOverlap = movieTags.intersection(moodTags).length;
      score += tagOverlap * 15;
      
      // User preference alignment based on liked movies
      try {
        final userGenres = _getUserPreferredGenres(user);
        if (userGenres.any((g) => movieGenres.contains(g.toLowerCase()))) {
          score += 10;
        }
      } catch (e) {
        // If user preferences not available, skip this scoring
      }
      
      // Recency bonus for newer movies
      final releaseYear = _extractYear(movie.releaseDate);
      if (releaseYear != null && releaseYear > 2010) {
        score += (releaseYear - 2010) * 0.5;
      }
      
      return MapEntry(movie, score);
    }).toList();
    
    // Sort by score (highest first)
    scoredMovies.sort((a, b) => b.value.compareTo(a.value));
    
    // Return top movies
    return scoredMovies
        .take(sessionSize)
        .map((entry) => entry.key)
        .toList();
  }
  
  static List<Movie> _sortForGroupCompatibility(List<Movie> movies, List<UserProfile> groupMembers, int sessionSize) {
    // For group sessions, prioritize movies that appeal to multiple members
    final scoredMovies = movies.map((movie) {
      double groupScore = 0.0;
      
      // Base quality
      groupScore += (movie.rating ?? 0) * 10;
      groupScore += (movie.voteCount ?? 0) / 1000;
      
      // Count how many group members would like this movie
      final movieGenres = movie.genres.map((g) => g.toLowerCase()).toSet();
      for (final member in groupMembers) {
        try {
          final memberGenres = _getUserPreferredGenres(member);
          final overlap = movieGenres.intersection(memberGenres.map((g) => g.toLowerCase()).toSet()).length;
          if (overlap > 0) {
            groupScore += 15; // Bonus for each member who might like it
          }
        } catch (e) {
          // If member preferences not available, give small bonus for popular genres
          if (movieGenres.contains('adventure') || movieGenres.contains('comedy')) {
            groupScore += 5;
          }
        }
      }
      
      // Prefer movies that are broadly appealing
      if (movieGenres.contains('adventure') || movieGenres.contains('comedy')) {
        groupScore += 5;
      }
      
      return MapEntry(movie, groupScore);
    }).toList();
    
    scoredMovies.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredMovies
        .take(sessionSize)
        .map((entry) => entry.key)
        .toList();
  }
  
  static List<Movie> _getFallbackMovies(List<Movie> movieDatabase, Set<String> seenMovieIds, int count) {
    // Fallback: Return popular, high-rated movies not yet seen
    final fallbackMovies = movieDatabase
        .where((movie) => !seenMovieIds.contains(movie.id))
        .where((movie) => (movie.rating ?? 0) > 6.5)
        .where((movie) => (movie.voteCount ?? 0) > 100)
        .toList();
    
    // Sort by rating and popularity
    fallbackMovies.sort((a, b) {
      final scoreA = (a.rating ?? 0) + (a.voteCount ?? 0) / 10000;
      final scoreB = (b.rating ?? 0) + (b.voteCount ?? 0) / 10000;
      return scoreB.compareTo(scoreA);
    });
    
    DebugLogger.log("🔄 Using ${fallbackMovies.length} fallback movies");
    return fallbackMovies.take(count).toList();
  }
  
  // ========================================
  // HELPER FUNCTIONS
  // ========================================
  
  /// Get user preferred genres based on their actual liked movies
  static List<String> _getUserPreferredGenres(UserProfile user) {
    // Extract genres from user's liked movies
    final genreCount = <String, int>{};
    
    for (final movie in user.likedMovies) {
      for (final genre in movie.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }
    
    // Return top genres (at least 2 occurrences)
    return genreCount.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList();
  }
  
  static int? _extractYear(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return int.parse(dateString.substring(0, 4));
    } catch (e) {
      return null;
    }
  }
}