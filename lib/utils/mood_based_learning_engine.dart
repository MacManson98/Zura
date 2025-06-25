// File: lib/utils/mood_based_learning_engine.dart
// CLEAN: Pure mood-based filtering with no personalization

import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/debug_loader.dart';

// Mood-based session management - Updated 10 distinct moods
enum CurrentMood {
  pureComedy('Pure Comedy', '😂', ['Comedy'], ['Funny', 'Silly', 'Upbeat', 'Light-Hearted', 'Hilarious', 'Witty']),
  epicAction('Epic Action', '💥', ['Action'], ['Action-Packed', 'High Stakes', 'Fast-Paced', 'Adrenaline', 'Intense', 'Explosive']),
  scaryAndSuspenseful('Scary & Suspenseful', '😱', ['Horror', 'Thriller'], ['Scary', 'Suspenseful', 'Dark', 'Creepy', 'Terrifying', 'Spine-Chilling']),
  romantic('Romantic', '💕', ['Romance'], ['Romantic', 'Sweet', 'Heartwarming', 'Love Story', 'Passionate', 'Tender']),
  mindBending('Mind-Bending', '🤔', ['Drama', 'Sci-Fi', 'Mystery', 'Thriller'], ['Mind-Bending', 'Complex', 'Thought-Provoking', 'Twist', 'Cerebral', 'Psychological']),
  emotionalDrama('Emotional Drama', '💭', ['Drama'], ['Emotional', 'Heartwarming', 'Moving', 'Deep', 'Touching', 'Meaningful']),
  trueStories('True Stories', '📖', ['Biography', 'History', 'Drama', 'Documentary'], ['Based on a True Story', 'Real Events', 'True Story', 'Historical', 'Biographical']),
  mysteryCrime('Mystery & Crime', '🔍', ['Crime', 'Mystery', 'Thriller'], ['Mystery', 'Crime', 'Investigation', 'Detective', 'Intrigue', 'Puzzle']),
  adventureFantasy('Adventure & Fantasy', '🗺️', ['Adventure', 'Fantasy', 'Sci-Fi'], ['Epic', 'Adventure', 'Journey', 'Fantasy', 'Magical', 'Otherworldly']),
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

  /// Simple mood matching: Genre first, then tag filtering
  static bool _matchesMoodCriteria(Movie movie, CurrentMood mood) {
    final movieGenres = movie.genres.map((g) => g.toLowerCase()).toSet();
    final movieTags = movie.tags.map((t) => t.toLowerCase()).toSet();

    switch (mood) {
      case CurrentMood.musicalDance:
      // 🎵 CORRECTED: Look for "Music" genre OR "musical" tag
      final hasMusicalGenre = movieGenres.contains('music'); // Changed from 'musical' to 'music'
      final hasMusicalTag = movieTags.contains('musical');   // Added tag check
      
      if (!hasMusicalGenre && !hasMusicalTag) {
        return false;
      }
      
      // Exclude obvious non-musicals (refinement)
      final badTags = {'horror', 'thriller', 'war', 'crime', 'dark', 'violent'};
      return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.pureComedy:
        // 😂 Must have Comedy genre, exclude dramatic/serious content
        if (!movieGenres.contains('comedy')) return false;
        
        final badTags = {'horror', 'thriller', 'war', 'crime', 'dramatic', 'serious', 'sad'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.romantic:
        // 💕 Must have Romance genre, exclude violent/scary content
        if (!movieGenres.contains('romance')) return false;
        
        final badTags = {'horror', 'violent', 'war', 'crime', 'scary', 'dark'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.scaryAndSuspenseful:
        // 😱 Must have Horror OR Thriller genre, exclude feel-good content
        if (!movieGenres.any((g) => ['horror', 'thriller'].contains(g))) return false;
        
        final badTags = {'comedy', 'funny', 'feel-good', 'wholesome', 'family-friendly', 'romantic'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.epicAction:
        // 💥 Must have Action genre, exclude slow/peaceful content
        if (!movieGenres.contains('action')) return false;
        
        final badTags = {'slow', 'peaceful', 'romantic', 'cozy', 'gentle', 'contemplative'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.mindBending:
        // 🤔 Thriller, Mystery, or Sci-Fi + complex tags
        if (!movieGenres.any((g) => ['thriller', 'mystery', 'sci-fi'].contains(g))) return false;
        
        // Must have complexity indicators
        final complexTags = {'mind-bending', 'complex', 'psychological', 'cerebral', 'thought-provoking'};
        if (!movieTags.any((tag) => complexTags.contains(tag))) return false;
        
        final badTags = {'simple', 'family-friendly', 'comedy', 'feel-good'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.emotionalDrama:
        // 💭 Must have Drama genre + emotional tags
        if (!movieGenres.contains('drama')) return false;
        
        final emotionalTags = {'emotional', 'touching', 'moving', 'heartwarming', 'meaningful'};
        if (!movieTags.any((tag) => emotionalTags.contains(tag))) return false;
        
        final badTags = {'comedy', 'action', 'silly', 'superficial'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.trueStories:
        // 📖 Biography, History, Documentary OR true story tags
        final trueGenres = movieGenres.any((g) => ['biography', 'history', 'documentary'].contains(g));
        final trueTags = movieTags.any((tag) => ['true story', 'based on', 'real events', 'biographical'].contains(tag));
        
        if (!trueGenres && !trueTags) return false;
        
        final badTags = {'sci-fi', 'fantasy', 'supernatural', 'fictional'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.mysteryCrime:
        // 🔍 Crime, Mystery, or Thriller + investigation tags
        if (!movieGenres.any((g) => ['crime', 'mystery', 'thriller'].contains(g))) return false;
        
        final investigationTags = {'mystery', 'crime', 'detective', 'investigation'};
        return movieTags.any((tag) => investigationTags.contains(tag));

      case CurrentMood.adventureFantasy:
        // 🗺️ Adventure, Fantasy, or Sci-Fi genres
        return movieGenres.any((g) => ['adventure', 'fantasy', 'sci-fi'].contains(g));

      case CurrentMood.familyFun:
        // 👨‍👩‍👧‍👦 Family or Animation genre, exclude mature content
        if (!movieGenres.any((g) => ['family', 'animation'].contains(g))) return false;
        
        final badTags = {'horror', 'violent', 'adult', 'mature', 'scary'};
        return !movieTags.any((tag) => badTags.contains(tag));

      case CurrentMood.sciFiFuture:
        // 🚀 Must have Sci-Fi genre
        return movieGenres.contains('sci-fi');

      case CurrentMood.worldCinema:
        // 🌍 Foreign genre OR international tags
        final worldGenres = movieGenres.contains('foreign');
        final worldTags = movieTags.any((tag) => ['international', 'foreign', 'subtitled'].contains(tag));
        
        return worldGenres || worldTags;

      case CurrentMood.twistEnding:
        // 🔄 Thriller, Mystery, or Drama genres with twist-related tags
        if (!movieGenres.any((g) => ['thriller', 'mystery', 'drama'].contains(g))) return false;

        final twistTags = {'twist', 'plot twist', 'unexpected', 'surprise ending', 'mind-bending', 'shock'};
        return movieTags.any((tag) => twistTags.contains(tag));

      case CurrentMood.cultClassic:
        // 🎞️ Look for tags that signify cult status or niche appeal
        final cultTags = {
          'cult classic', 'underground', 'b-movie', 'retro', 'iconic', 'campy', 'midnight', 'niche', 'weird', 'quirky'
        };
        return movieTags.any((tag) => cultTags.contains(tag));

      case CurrentMood.highStakes:
        // 🎞️ Look for tags that signify cult status or niche appeal
        final highStakesTags = {
          'Tension', 'Urgent', 'Unrelenting', 'Time-Sensitive', 'Race Against Time', 'Explosive', 'High Stakes', 'taking a risk'
        };
        return movieTags.any((tag) => highStakesTags.contains(tag));
    }
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