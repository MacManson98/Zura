import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/debug_loader.dart';

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
  
  /// Main mood session generator - completely redesigned
  static Future<List<Movie>> generateMoodBasedSession({
    required UserProfile user,
    required List<Movie> movieDatabase,
    required SessionContext sessionContext,
    required Set<String> seenMovieIds,
    required Set<String> sessionPassedMovieIds,
    int sessionSize = 30,
  }) async {
    DebugLogger.log("🎭 Generating mood session: ${sessionContext.moods.displayName}");
    
    final moodFilteredMovies = _filterByMoodCriteria(
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
    
    DebugLogger.log("🎬 Generated ${result.length} mood movies");
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
    DebugLogger.log("🎭 Generating blended mood session for: ${selectedMoods.map((m) => m.displayName).join(' + ')}");
    
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
    
    DebugLogger.log("🎬 Generated ${result.length} blended mood movies");
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
    DebugLogger.log("👥 Generating shared mood pool for ${groupMembers.length} people: ${sessionContext.moods.displayName}");
    
    final moodFilteredMovies = _filterByMoodCriteria(
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
    
    DebugLogger.log("🎬 Generated ${sharedPool.length} shared movies for group");
    DebugLogger.log("   Everyone will see: ${sharedPool.take(3).map((m) => m.title).join(', ')}");
    
    return sharedPool;
  }
  
  /// REDESIGNED: Ultra-specific mood filtering that gives users what they expect
  static List<Movie> _filterByMoodCriteria(
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

      if (_isMoviePerfectForMood(movie, mood)) {
        moodMovies.add(movie);
      }
    }

    DebugLogger.log("✅ Found ${moodMovies.length} movies matching mood: ${mood.displayName}");
    return moodMovies;
  }
  
  /// COMPLETELY NEW: Each mood has custom logic for perfect matching
  static bool _isMoviePerfectForMood(Movie movie, CurrentMood mood) {
    final movieGenres = movie.genres.map((g) => g.toLowerCase()).toSet();
    final movieTags = movie.tags.map((t) => t.toLowerCase()).toSet();
    
    switch (mood) {
      case CurrentMood.pureComedy:
        return _isPureComedy(movie, movieGenres, movieTags);
        
      case CurrentMood.epicAction:
        return _isEpicAction(movie, movieGenres, movieTags);
        
      case CurrentMood.scaryAndSuspenseful:
        return _isScaryAndSuspenseful(movie, movieGenres, movieTags);
        
      case CurrentMood.romantic:
        return _isRomantic(movie, movieGenres, movieTags);
        
      case CurrentMood.mindBending:
        return _isMindBending(movie, movieGenres, movieTags);
        
      case CurrentMood.emotionalDrama:
        return _isEmotionalDrama(movie, movieGenres, movieTags);
        
      case CurrentMood.trueStories:
        return _isTrueStory(movie, movieGenres, movieTags);
        
      case CurrentMood.mysteryCrime:
        return _isMysteryOrCrime(movie, movieGenres, movieTags);
        
      case CurrentMood.adventureFantasy:
        return _isAdventureFantasy(movie, movieGenres, movieTags);
        
      case CurrentMood.musicalDance:
        return _isMusicalDance(movie, movieGenres, movieTags);
        
      case CurrentMood.familyFun:
        return _isFamilyFun(movie, movieGenres, movieTags);
        
      case CurrentMood.sciFiFuture:
        return _isSciFiFuture(movie, movieGenres, movieTags);
        
      case CurrentMood.worldCinema:
        return _isWorldCinema(movie, movieGenres, movieTags);
        
      case CurrentMood.cultClassic:
        return _isCultClassic(movie, movieGenres, movieTags);
        
      case CurrentMood.twistEnding:
        return _isTwistEnding(movie, movieGenres, movieTags);
        
      case CurrentMood.highStakes:
        return _isHighStakes(movie, movieGenres, movieTags);
    }
  }
  
  // ========================================
  // MOOD-SPECIFIC MATCHING FUNCTIONS
  // Each function defines what users expect for that mood
  // ========================================
  
  static bool _isPureComedy(Movie movie, Set<String> genres, Set<String> tags) {
    // Must have Comedy genre AND funny indicators
    if (!genres.contains('comedy')) return false;
    
    // Look for comedy-specific tags from TMDB
    final comedyTags = ['funny', 'hilarious', 'witty', 'humorous', 'comedic', 'light-hearted'];
    final hasComedyTag = tags.any((tag) => comedyTags.any((comedyTag) => tag.contains(comedyTag)));
    
    // Exclude dark comedies unless they have strong funny indicators
    if (tags.contains('dark comedy') || tags.contains('black comedy')) {
      return hasComedyTag; // Only include if explicitly funny
    }
    
    return hasComedyTag || genres.contains('comedy');
  }
  
  static bool _isEpicAction(Movie movie, Set<String> genres, Set<String> tags) {
    // Must have Action genre AND action-specific indicators
    if (!genres.contains('action')) return false;
    
    // Look for action-specific TMDB tags
    final actionTags = ['action-packed', 'combat', 'fighting', 'explosion', 'chase', 'shootout', 'martial arts', 'gunfight'];
    final hasActionTag = tags.any((tag) => actionTags.any((actionTag) => tag.contains(actionTag)));
    
    // Or high stakes indicators
    final stakeTags = ['high stakes', 'intense', 'adrenaline', 'explosive'];
    final hasStakeTag = tags.any((tag) => stakeTags.any((stakeTag) => tag.contains(stakeTag)));
    
    return hasActionTag || hasStakeTag;
  }
  
  static bool _isScaryAndSuspenseful(Movie movie, Set<String> genres, Set<String> tags) {
    // Must have Horror or Thriller genre
    if (!genres.contains('horror') && !genres.contains('thriller')) return false;
    
    // Look for scary/suspense indicators
    final scaryTags = ['scary', 'terrifying', 'frightening', 'suspenseful', 'creepy', 'dark', 'supernatural', 'ghost', 'demon', 'murder'];
    final hasScaryTag = tags.any((tag) => scaryTags.any((scaryTag) => tag.contains(scaryTag)));
    
    // Horror movies are automatically scary
    if (genres.contains('horror')) return true;
    
    // Thrillers need scary indicators
    return hasScaryTag;
  }
  
  static bool _isRomantic(Movie movie, Set<String> genres, Set<String> tags) {
    // Romance genre OR romantic indicators
    if (genres.contains('romance')) return true;
    
    // Look for romantic TMDB tags
    final romanticTags = ['romantic', 'love story', 'love triangle', 'wedding', 'marriage', 'relationship'];
    return tags.any((tag) => romanticTags.any((romTag) => tag.contains(romTag)));
  }
  
  static bool _isMindBending(Movie movie, Set<String> genres, Set<String> tags) {
    // Needs specific mind-bending indicators, not just genre
    final mindBendingTags = [
      'mind-bending', 'psychological', 'complex narrative', 'non linear', 'time travel', 
      'alternate reality', 'memory loss', 'unreliable narrator', 'twist', 'cerebral'
    ];
    
    final hasMindBendingTag = tags.any((tag) => 
        mindBendingTags.any((mbTag) => tag.contains(mbTag)));
    
    // Must have the right genre AND mind-bending indicators
    final rightGenres = genres.contains('sci-fi') || genres.contains('thriller') || genres.contains('mystery');
    return rightGenres && hasMindBendingTag;
  }
  
  static bool _isEmotionalDrama(Movie movie, Set<String> genres, Set<String> tags) {
    // Must have Drama genre
    if (!genres.contains('drama')) return false;
    
    // Look for emotional indicators
    final emotionalTags = ['emotional', 'heartwarming', 'moving', 'touching', 'tearjerker', 'inspiring'];
    return tags.any((tag) => emotionalTags.any((emTag) => tag.contains(emTag)));
  }
  
  static bool _isTrueStory(Movie movie, Set<String> genres, Set<String> tags) {
    // Biography/Documentary genres are automatic
    if (genres.contains('biography') || genres.contains('documentary')) return true;
    
    // Or explicit true story indicators
    final trueStoryTags = ['based on true story', 'biographical', 'real events', 'true story', 'memoir', 'real person'];
    return tags.any((tag) => trueStoryTags.any((tsTag) => tag.contains(tsTag)));
  }
  
  static bool _isMysteryOrCrime(Movie movie, Set<String> genres, Set<String> tags) {
    // Crime or Mystery genre
    if (genres.contains('crime') || genres.contains('mystery')) return true;
    
    // Or crime/mystery indicators
    final crimeTags = ['detective', 'investigation', 'murder', 'police', 'fbi', 'criminal', 'heist'];
    return tags.any((tag) => crimeTags.any((crimeTag) => tag.contains(crimeTag)));
  }
  
  static bool _isAdventureFantasy(Movie movie, Set<String> genres, Set<String> tags) {
    // Adventure, Fantasy, or Sci-Fi genres
    if (genres.contains('adventure') || genres.contains('fantasy') || genres.contains('sci-fi')) return true;
    
    // Or epic/fantasy indicators
    final epicTags = ['epic', 'magical', 'quest', 'journey', 'fantasy', 'otherworldly'];
    return tags.any((tag) => epicTags.any((epicTag) => tag.contains(epicTag)));
  }
  
  static bool _isMusicalDance(Movie movie, Set<String> genres, Set<String> tags) {
    // Musical genre or music-related tags
    if (genres.contains('musical') || genres.contains('music')) return true;
    
    final musicalTags = ['musical', 'dance', 'singing', 'song', 'concert'];
    return tags.any((tag) => musicalTags.any((musTag) => tag.contains(musTag)));
  }
  
  static bool _isFamilyFun(Movie movie, Set<String> genres, Set<String> tags) {
    // Family or Animation genres
    if (genres.contains('family') || genres.contains('animation')) return true;
    
    // Or family-friendly indicators
    final familyTags = ['family-friendly', 'kids', 'wholesome', 'children'];
    return tags.any((tag) => familyTags.any((famTag) => tag.contains(famTag)));
  }
  
  static bool _isSciFiFuture(Movie movie, Set<String> genres, Set<String> tags) {
    // Sci-Fi genre OR sci-fi specific indicators
    if (genres.contains('science fiction') || genres.contains('sci-fi')) return true;
    
    final scifiTags = ['futuristic', 'space', 'alien', 'robot', 'artificial intelligence', 'technology', 'spacecraft'];
    return tags.any((tag) => scifiTags.any((scifiTag) => tag.contains(scifiTag)));
  }
  
  static bool _isWorldCinema(Movie movie, Set<String> genres, Set<String> tags) {
    // Foreign genre OR international indicators
    if (genres.contains('foreign')) return true;
    
    // Look for international/cultural tags
    final worldTags = ['international', 'cultural', 'subtitled', 'foreign language'];
    return tags.any((tag) => worldTags.any((worldTag) => tag.contains(worldTag)));
  }
  
  static bool _isCultClassic(Movie movie, Set<String> genres, Set<String> tags) {
    // Look for cult-specific indicators
    final cultTags = ['cult classic', 'cult film', 'underground', 'weird', 'quirky', 'offbeat', 'bizarre', 'campy'];
    return tags.any((tag) => cultTags.any((cultTag) => tag.contains(cultTag)));
  }
  
  static bool _isTwistEnding(Movie movie, Set<String> genres, Set<String> tags) {
    // Must have right genre AND twist indicators
    final rightGenres = genres.contains('thriller') || genres.contains('mystery') || genres.contains('drama');
    if (!rightGenres) return false;
    
    final twistTags = ['plot twist', 'twist ending', 'surprise ending', 'shocking', 'unexpected', 'revelation'];
    return tags.any((tag) => twistTags.any((twistTag) => tag.contains(twistTag)));
  }
  
  static bool _isHighStakes(Movie movie, Set<String> genres, Set<String> tags) {
    // Must have action/thriller genre
    if (!genres.contains('action') && !genres.contains('thriller') && !genres.contains('crime')) return false;
    
    // Look for high stakes indicators
    final stakesTags = ['high stakes', 'urgent', 'time-sensitive', 'race against time', 'countdown', 'bomb', 'hostage', 'rescue'];
    return tags.any((tag) => stakesTags.any((stakesTag) => tag.contains(stakesTag)));
  }
  
  // ========================================
  // FILTERING AND SCORING FUNCTIONS
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
      if (!_meetsQualityThreshold(movie)) continue;
      if (!_isSfwMovie(movie)) continue;
      
      // Movie must match at least one of the selected moods
      final matchesAnyMood = selectedMoods.any((mood) => _isMoviePerfectForMood(movie, mood));
      
      if (matchesAnyMood) {
        blendedMovies.add(movie);
      }
    }
    
    return blendedMovies;
  }
  
  static List<Movie> _sortAndScoreMovies(List<Movie> movies, CurrentMood mood, UserProfile user, int sessionSize) {
    final scoredMovies = movies.map((movie) {
      double score = 0.0;
      
      // Base quality score
      score += (movie.rating ?? 0) + (movie.voteCount ?? 0) / 10000;
      
      // Mood-specific scoring bonuses
      score += _getMoodSpecificScore(movie, mood);
      
      // User preference bonuses
      if (user.preferredGenres.isNotEmpty) {
        final userGenreMatches = movie.genres.where((g) => user.preferredGenres.contains(g)).length;
        score += userGenreMatches * 1.0;
      }
      
      if (user.preferredVibes.isNotEmpty) {
        final userVibeMatches = movie.tags.where((t) => user.preferredVibes.contains(t)).length;
        score += userVibeMatches * 0.5;
      }
      
      return MapEntry(movie, score);
    }).toList();
    
    scoredMovies.sort((a, b) => b.value.compareTo(a.value));
    final result = scoredMovies.take(sessionSize).map((entry) => entry.key).toList();
    result.shuffle(); // Keep variety
    return result;
  }
  
  static double _getMoodSpecificScore(Movie movie, CurrentMood mood) {
    final movieTags = movie.tags.map((t) => t.toLowerCase()).toSet();
    double score = 0.0;
    
    // Give bonus points for mood-specific excellence
    switch (mood) {
      case CurrentMood.pureComedy:
        if (movieTags.contains('hilarious')) score += 2.0;
        if (movieTags.contains('funny')) score += 1.0;
        break;
        
      case CurrentMood.epicAction:
        if (movieTags.contains('action-packed')) score += 2.0;
        if (movieTags.contains('explosive')) score += 1.5;
        break;
        
      case CurrentMood.scaryAndSuspenseful:
        if (movieTags.contains('terrifying')) score += 2.0;
        if (movieTags.contains('scary')) score += 1.0;
        break;
        
      case CurrentMood.mindBending:
        if (movieTags.contains('mind-bending')) score += 2.0;
        if (movieTags.contains('psychological')) score += 1.5;
        break;
        
      case CurrentMood.trueStories:
        if (movieTags.contains('based on true story')) score += 2.0;
        if (movieTags.contains('biographical')) score += 1.5;
        break;
        
      default:
        // Generic mood matching bonus
        final hasStrongMoodMatch = mood.preferredVibes.any((vibe) => 
            movieTags.contains(vibe.toLowerCase()));
        if (hasStrongMoodMatch) score += 1.0;
    }
    
    return score;
  }
  
  static List<Movie> _sortForGroupCompatibility(List<Movie> movies, List<UserProfile> groupMembers, int sessionSize) {
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
      
      score += (movie.rating ?? 0) + (movie.voteCount ?? 0) / 10000;
      
      for (final genre in movie.genres) {
        final popularity = groupGenres[genre] ?? 0;
        score += popularity * 1.0;
      }
      
      for (final tag in movie.tags) {
        final popularity = groupVibes[tag] ?? 0;
        score += popularity * 0.5;
      }
      
      return MapEntry(movie, score);
    }).toList();
    
    scoredMovies.sort((a, b) => b.value.compareTo(a.value));
    return scoredMovies.take(sessionSize).map((entry) => entry.key).toList();
  }
  
  // ========================================
  // HELPER FUNCTIONS
  // ========================================
  
  static bool _meetsQualityThreshold(Movie movie) {
    return movie.posterUrl.isNotEmpty &&
           movie.rating != null &&
           movie.rating! >= 4.5 &&
           movie.voteCount != null &&
           movie.voteCount! >= 500;
  }
  
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

  // Public helper methods
  static bool meetsQualityThreshold(Movie movie) {
    return _meetsQualityThreshold(movie);
  }

  static bool isSfwMovie(Movie movie) {
    return _isSfwMovie(movie);
  }
}