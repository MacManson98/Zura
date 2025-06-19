// File: lib/utils/mood_based_learning_engine.dart
// CLEAN: Pure mood-based filtering with no personalization

import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/debug_loader.dart';

// Mood-based session management
enum CurrentMood {
  perfectForMe('Perfect For Me', '🎯', [], []), // Reserved for future feature
  perfectForUs('Perfect For Us', '🤝', [], []), // Reserved for future feature
  trueStory('True Stories', '📖', ['Biography', 'History', 'Drama', 'Documentary'], ['Based on a True Story', 'Real Events', 'True Story']),
  emotional('Deep & Emotional', '💭', ['Drama', 'Romance'], ['Emotional', 'Heartwarming', 'Moving']),
  thoughtful('Mind-Bending', '🤔', ['Drama', 'Sci-Fi', 'Mystery', 'Thriller'], ['Mind-Bending', 'Complex', 'Thought-Provoking', 'Twist']),
  lighthearted('Laid-Back & Fun', '🎉', ['Family', 'Animation', 'Comedy', 'TV Movie'], ['Comfort', 'Peaceful', 'Wholesome', 'Cozy', 'Funny', 'Silly', 'Upbeat']),
  scary('Thrills & Chills', '😱', ['Horror', 'Thriller'], ['Scary', 'Suspenseful', 'Dark']),
  romantic('Love Stories', '💕', ['Romance'], ['Romantic', 'Sweet', 'Heartwarming']),
  adventurous('Epic Adventure', '🗺️', ['Adventure', 'Fantasy', 'Action'], ['Epic', 'Action-Packed', 'Journey']);

  const CurrentMood(this.displayName, this.emoji, this.preferredGenres, this.preferredVibes);
  
  final String displayName;
  final String emoji;
  final List<String> preferredGenres;
  final List<String> preferredVibes;
  
  // Helper to check if this is a profile-based mood (reserved for future)
  bool get isProfileBased => this == CurrentMood.perfectForMe || this == CurrentMood.perfectForUs;
}

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
  
  /// Pure mood-based session generation
  static Future<List<Movie>> generateMoodBasedSession({
    required UserProfile user,
    required List<Movie> movieDatabase,
    required SessionContext sessionContext,
    required Set<String> seenMovieIds,
    required Set<String> sessionPassedMovieIds,
    int sessionSize = 30,
  }) async {
    // Handle profile-based moods (reserved for future feature)
    if (sessionContext.moods == CurrentMood.perfectForMe || 
        sessionContext.moods == CurrentMood.perfectForUs) {
      DebugLogger.log("⚠️ Profile-based moods not yet implemented");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    DebugLogger.log("🎭 Generating mood session: ${sessionContext.moods.displayName}");
    DebugLogger.log("   Target genres: ${sessionContext.moods.preferredGenres}");
    DebugLogger.log("   Target vibes: ${sessionContext.moods.preferredVibes}");
    
    // Step 1: Filter by mood
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
    
    // Step 2: Sort by quality (no personalization)
    final result = _sortByQuality(moodFilteredMovies, sessionSize);
    
    DebugLogger.log("🎬 Generated ${result.length} mood movies");
    DebugLogger.log("   Sample: ${result.take(3).map((m) => m.title).join(', ')}");
    
    return result;
  }
  
  /// Group sessions: Create ONE shared pool for all participants
  static Future<List<Movie>> generateGroupSession({
    required List<UserProfile> groupMembers,
    required List<Movie> movieDatabase,
    required SessionContext sessionContext,
    required Set<String> seenMovieIds,
    int sessionSize = 25,
  }) async {
    // Handle "Perfect For Us" mood (reserved for future feature)
    if (sessionContext.moods == CurrentMood.perfectForUs) {
      DebugLogger.log("⚠️ Perfect For Us not yet implemented");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    DebugLogger.log("👥 Generating shared mood pool for ${groupMembers.length} people: ${sessionContext.moods.displayName}");
    
    // Step 1: Filter by mood (same for everyone)
    final moodFilteredMovies = _filterByMood(
      movieDatabase, 
      sessionContext.moods, 
      seenMovieIds, 
      <String>{} // No session passed movies for group sessions
    );
    
    if (moodFilteredMovies.isEmpty) {
      DebugLogger.log("⚠️ No movies found for group mood, using fallback");
      return _getFallbackMovies(movieDatabase, seenMovieIds, sessionSize);
    }
    
    // Step 2: Create shared pool focusing on quality
    final sharedPool = _createSharedPool(moodFilteredMovies, sessionSize);
    
    DebugLogger.log("🎬 Generated ${sharedPool.length} shared movies for group");
    DebugLogger.log("   Everyone will see: ${sharedPool.take(3).map((m) => m.title).join(', ')}");
    
    return sharedPool;
  }
  
  /// Filter movies by mood criteria
  static List<Movie> _filterByMood(
    List<Movie> movieDatabase, 
    CurrentMood mood, 
    Set<String> seenMovieIds, 
    Set<String> sessionPassedMovieIds
  ) {
    final moodMovies = <Movie>[];
    final targetGenres = mood.preferredGenres.toSet();
    final targetVibes = mood.preferredVibes.toSet();
    
    final excludedMovieIds = <String>{};
    excludedMovieIds.addAll(seenMovieIds);
    excludedMovieIds.addAll(sessionPassedMovieIds);

    final disqualifyingTagsPerMood = {
      'Laid-Back & Fun': {
        'Disturbing',
        'Dark',
        'Mind-Bending',
        'Twisty',
        'Grim',
        'Sad',
        'Philosophical',
        'Traumatic',
        'Violent',
        'War',
        'Tragic',
        'Horror',
        'Slow Burn',
        'Emotional',
        'Trauma',
        'Gory',
        'Grief',
        'Serious',
        'Heavy',
        'Depressing',
        'Romantic Drama',
        'Melancholy',
        'Cerebral',
        'Slasher',
      },
      'Deep & Emotional': {
        'Twisty',
        'Action-Packed',
        'Violent',
        'Gory',
        'Disturbing',
        'Supernatural',
        'Slasher',
        'Fantasy',
        'Abstract',
        'High Stakes',
        'Fast-Paced',
        'Experimental',
        'Over-Stylized',
        'Weird',
        'Silly',
        'Parody',
        'Horror',
        'Dark Comedy',
        'Stalker',
        'Cynical Humor',
        'Cringe',
        'Uncomfortable',
        'Obsession',
        'Psychological Comedy'
      },
      'Mind-Bending': {
        'Silly',
        'Wholesome',
        'Light-Hearted',
        'Family-Friendly',
        'Romantic Comedy',
        'Slapstick',
        'Simple',
        'Straightforward',
        'Comfort',
        'Cozy',
        'Heartwarming',
        'Musical',
        'Kids',
        'Rewatchable',
        'Uplifting',
        'Cheesy',
        'Predictable'
      },
      'Thrills & Chills': {
        'Comfort',
        'Cozy',
        'Peaceful',
        'Wholesome',
        'Heartwarming',
        'Feel-Good',
        'Romantic',
        'Light-Hearted',
        'Family-Friendly',
        'Animation',
        'Musical',
        'Funny',
        'Silly',
        'Uplifting',
        'Easy Watch',
        'Kids',
        'Rewatchable',
        'Cheesy'
      },
      'Love Stories': {
        'Horror',
        'Violent',
        'Dark',
        'Disturbing',
        'Mind-Bending',
        'Surrealism',
        'Twisty',
        'Sci-Fi/Techy',
        'War',
        'Crime',
        'Gory',
        'Slasher',
        'Supernatural',
        'Abstract',
        'High Stakes',
        'Action-Packed',
        'Cynical',
        'Unromantic',
        'Grim',
        'Trauma',
        'Philosophical',
        'Experimental'
      },
      'Epic Adventure': {
        'Romantic',
        'Heartwarming',
        'Wholesome',
        'Cozy',
        'Light-Hearted',
        'Slow Burn',
        'Philosophical',
        'Abstract',
        'Surrealism',
        'Emotional',
        'Musical',
        'Family-Friendly',
        'Slice of Life',
        'Peaceful',
        'Minimalist',
        'Feel-Good',
        'Domestic',
        'Cerebral',
        'Comedy-Driven',
        'Sad',
        'Tragic'
      },
      'True Stories': {
        'Sci-Fi/Techy',
        'Fantasy',
        'Supernatural',
        'Mind-Bending',
        'Surrealism',
        'Magical',
        'Alien',
        'Time Travel',
        'Multiverse',
        'Mythical',
        'Epic Fantasy',
        'Superhero',
        'Paranormal',
        'Witchcraft',
        'Space',
        'Cyberpunk',
        'Monster',
        'Fictional',
        'Made Up',
        'Alternate Reality',
        'Dystopian'
      }
    };

    final disqualifyingTags = disqualifyingTagsPerMood[mood.displayName] ?? {};

    for (final movie in movieDatabase) {
      if (excludedMovieIds.contains(movie.id)) continue;
      if (!_meetsQualityThreshold(movie)) continue;
      if (!_isSfwMovie(movie)) continue;

      // Runtime check (only for Laid-Back & Fun)
      if (mood.displayName == 'Laid-Back & Fun' && movie.runtime != null && movie.runtime! > 130) continue;

      // Disqualifying tags check
      final hasConflictTag = movie.tags.any((tag) => disqualifyingTags.contains(tag));
      if (hasConflictTag) continue;

      // Must match genre OR vibe
      final hasGenreMatch = movie.genres.any((g) => targetGenres.contains(g));
      final hasVibeMatch = movie.tags.any((v) => targetVibes.contains(v));

      if (hasGenreMatch || hasVibeMatch) {
        moodMovies.add(movie);
      }
    }

    DebugLogger.log("✅ Found ${moodMovies.length} movies matching mood: ${mood.displayName}");
    return moodMovies;
  }
  
  /// Sort movies by quality (no personalization)
  static List<Movie> _sortByQuality(List<Movie> movies, int sessionSize) {
    movies.sort((a, b) {
      final scoreA = (a.rating ?? 0) + (a.voteCount ?? 0) / 10000;
      final scoreB = (b.rating ?? 0) + (b.voteCount ?? 0) / 10000;
      return scoreB.compareTo(scoreA);
    });
    
    final result = movies.take(sessionSize).toList();
    result.shuffle(); // Add variety
    return result;
  }
  
  /// Create shared pool for groups (everyone gets same movies)
  static List<Movie> _createSharedPool(List<Movie> movies, int sessionSize) {
    movies.sort((a, b) {
      final scoreA = (a.rating ?? 0) + (a.voteCount ?? 0) / 10000;
      final scoreB = (b.rating ?? 0) + (b.voteCount ?? 0) / 10000;
      return scoreB.compareTo(scoreA);
    });
    
    // DON'T shuffle for groups - everyone needs same order
    return movies.take(sessionSize).toList();
  }
  
  /// Generate session for blended moods
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
        
    // Filter movies that match any of the blended criteria
    final blendedMovies = <Movie>[];
    final excludedMovieIds = <String>{};
    excludedMovieIds.addAll(seenMovieIds);
    excludedMovieIds.addAll(sessionPassedMovieIds);
    
    for (final movie in movieDatabase) {
      if (excludedMovieIds.contains(movie.id)) continue;
      if (!_meetsQualityThreshold(movie)) continue;
      if (!_isSfwMovie(movie)) continue;
      
      final hasGenreMatch = movie.genres.any((g) => allPreferredGenres.contains(g));
      final hasVibeMatch = movie.tags.any((v) => allPreferredVibes.contains(v));
      
      if (hasGenreMatch || hasVibeMatch) {
        blendedMovies.add(movie);
      }
    }
    
    // Sort by quality
    final result = _sortByQuality(blendedMovies, sessionSize);
    
    DebugLogger.log("🎬 Generated ${result.length} blended mood movies");
    return result;
  }
  
  // HELPER METHODS
  
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
  
  static bool _meetsQualityThreshold(Movie movie) {
    return movie.posterUrl.isNotEmpty &&
           movie.rating != null &&
           movie.rating! >= 5.0 &&
           movie.voteCount != null &&
           movie.voteCount! >= 1000;
  }
  
  static bool _isSfwMovie(Movie movie) {
    final bannedKeywords = ['porn', 'erotic', 'xxx', 'adult', 'sex', 'nude', 'strip'];
    final lcTitle = movie.title.toLowerCase();
    final lcOverview = movie.overview.toLowerCase();
    return !bannedKeywords.any((kw) => lcTitle.contains(kw) || lcOverview.contains(kw));
  }

  // Public helper methods for external use
  static bool meetsQualityThreshold(Movie movie) {
    return _meetsQualityThreshold(movie);
  }

  static bool isSfwMovie(Movie movie) {
    return _isSfwMovie(movie);
  }
}