// Updated Mood Engine Testing Script for the NEW redesigned engine
// Save as: test_mood_engine.dart
// Run with: dart test_mood_engine.dart

import 'dart:io';
import 'dart:convert';

// Simple Movie class for testing
class Movie {
  final String id;
  final String title;
  final String overview;
  final List<String> genres;
  final List<String> tags;
  final double? rating;
  final int? voteCount;
  final String posterUrl;

  Movie({
    required this.id,
    required this.title,
    required this.overview,
    required this.genres,
    required this.tags,
    this.rating,
    this.voteCount,
    this.posterUrl = '',
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      overview: json['overview']?.toString() ?? '',
      genres: _safeListFromJson(json['genres']),
      tags: _safeListFromJson(json['tags']),
      rating: json['rating']?.toDouble(),
      voteCount: json['voteCount']?.toInt(),
      posterUrl: json['posterUrl']?.toString() ?? '',
    );
  }

  static List<String> _safeListFromJson(dynamic jsonList) {
    if (jsonList == null) return [];
    if (jsonList is List) {
      return jsonList.map((item) => item.toString()).toList();
    }
    return [];
  }
}

// CurrentMood enum
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

// NEW REDESIGNED MOOD MATCHING LOGIC
class MoodTester {
  
  /// Main mood matching function using the NEW logic
  static bool matchesMoodCriteria(Movie movie, CurrentMood mood) {
    return _isMoviePerfectForMood(movie, mood);
  }
  
  /// NEW: Each mood has custom logic for perfect matching
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
  // ========================================
  
  static bool _isPureComedy(Movie movie, Set<String> genres, Set<String> tags) {
    if (!genres.contains('comedy')) return false;
    
    final comedyTags = ['funny', 'hilarious', 'witty', 'humorous', 'comedic', 'light-hearted'];
    final hasComedyTag = tags.any((tag) => comedyTags.any((comedyTag) => tag.contains(comedyTag)));
    
    if (tags.contains('dark comedy') || tags.contains('black comedy')) {
      return hasComedyTag;
    }
    
    return hasComedyTag || genres.contains('comedy');
  }
  
  static bool _isEpicAction(Movie movie, Set<String> genres, Set<String> tags) {
    if (!genres.contains('action')) return false;
    
    final actionTags = ['action-packed', 'combat', 'fighting', 'explosion', 'chase', 'shootout', 'martial arts', 'gunfight'];
    final hasActionTag = tags.any((tag) => actionTags.any((actionTag) => tag.contains(actionTag)));
    
    final stakeTags = ['high stakes', 'intense', 'adrenaline', 'explosive'];
    final hasStakeTag = tags.any((tag) => stakeTags.any((stakeTag) => tag.contains(stakeTag)));
    
    return hasActionTag || hasStakeTag;
  }
  
  static bool _isScaryAndSuspenseful(Movie movie, Set<String> genres, Set<String> tags) {
    if (!genres.contains('horror') && !genres.contains('thriller')) return false;
    
    final scaryTags = ['scary', 'terrifying', 'frightening', 'suspenseful', 'creepy', 'dark', 'supernatural', 'ghost', 'demon', 'murder'];
    final hasScaryTag = tags.any((tag) => scaryTags.any((scaryTag) => tag.contains(scaryTag)));
    
    if (genres.contains('horror')) return true;
    
    return hasScaryTag;
  }
  
  static bool _isRomantic(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('romance')) return true;
    
    final romanticTags = ['romantic', 'love story', 'love triangle', 'wedding', 'marriage', 'relationship'];
    return tags.any((tag) => romanticTags.any((romTag) => tag.contains(romTag)));
  }
  
  static bool _isMindBending(Movie movie, Set<String> genres, Set<String> tags) {
    final mindBendingTags = [
      'mind-bending', 'psychological', 'complex narrative', 'non linear', 'time travel', 
      'alternate reality', 'memory loss', 'unreliable narrator', 'twist', 'cerebral'
    ];
    
    final hasMindBendingTag = tags.any((tag) => 
        mindBendingTags.any((mbTag) => tag.contains(mbTag)));
    
    final rightGenres = genres.contains('sci-fi') || genres.contains('thriller') || genres.contains('mystery') || genres.contains('science fiction');
    return rightGenres && hasMindBendingTag;
  }
  
  static bool _isEmotionalDrama(Movie movie, Set<String> genres, Set<String> tags) {
    if (!genres.contains('drama')) return false;
    
    final emotionalTags = ['emotional', 'heartwarming', 'moving', 'touching', 'tearjerker', 'inspiring'];
    return tags.any((tag) => emotionalTags.any((emTag) => tag.contains(emTag)));
  }
  
  static bool _isTrueStory(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('biography') || genres.contains('documentary')) return true;
    
    final trueStoryTags = ['based on true story', 'biographical', 'real events', 'true story', 'memoir', 'real person'];
    return tags.any((tag) => trueStoryTags.any((tsTag) => tag.contains(tsTag)));
  }
  
  static bool _isMysteryOrCrime(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('crime') || genres.contains('mystery')) return true;
    
    final crimeTags = ['detective', 'investigation', 'murder', 'police', 'fbi', 'criminal', 'heist'];
    return tags.any((tag) => crimeTags.any((crimeTag) => tag.contains(crimeTag)));
  }
  
  static bool _isAdventureFantasy(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('adventure') || genres.contains('fantasy') || genres.contains('sci-fi') || genres.contains('science fiction')) return true;
    
    final epicTags = ['epic', 'magical', 'quest', 'journey', 'fantasy', 'otherworldly'];
    return tags.any((tag) => epicTags.any((epicTag) => tag.contains(epicTag)));
  }
  
  static bool _isMusicalDance(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('musical') || genres.contains('music')) return true;
    
    final musicalTags = ['musical', 'dance', 'singing', 'song', 'concert'];
    return tags.any((tag) => musicalTags.any((musTag) => tag.contains(musTag)));
  }
  
  static bool _isFamilyFun(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('family') || genres.contains('animation')) return true;
    
    final familyTags = ['family-friendly', 'kids', 'wholesome', 'children'];
    return tags.any((tag) => familyTags.any((famTag) => tag.contains(famTag)));
  }
  
  static bool _isSciFiFuture(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('science fiction') || genres.contains('sci-fi')) return true;
    
    final scifiTags = ['futuristic', 'space', 'alien', 'robot', 'artificial intelligence', 'technology', 'spacecraft'];
    return tags.any((tag) => scifiTags.any((scifiTag) => tag.contains(scifiTag)));
  }
  
  static bool _isWorldCinema(Movie movie, Set<String> genres, Set<String> tags) {
    if (genres.contains('foreign')) return true;
    
    final worldTags = ['international', 'cultural', 'subtitled', 'foreign language'];
    return tags.any((tag) => worldTags.any((worldTag) => tag.contains(worldTag)));
  }
  
  static bool _isCultClassic(Movie movie, Set<String> genres, Set<String> tags) {
    final cultTags = ['cult classic', 'cult film', 'underground', 'weird', 'quirky', 'offbeat', 'bizarre', 'campy'];
    return tags.any((tag) => cultTags.any((cultTag) => tag.contains(cultTag)));
  }
  
  static bool _isTwistEnding(Movie movie, Set<String> genres, Set<String> tags) {
    final rightGenres = genres.contains('thriller') || genres.contains('mystery') || genres.contains('drama');
    if (!rightGenres) return false;
    
    final twistTags = ['plot twist', 'twist ending', 'surprise ending', 'shocking', 'unexpected', 'revelation'];
    return tags.any((tag) => twistTags.any((twistTag) => tag.contains(twistTag)));
  }
  
  static bool _isHighStakes(Movie movie, Set<String> genres, Set<String> tags) {
    if (!genres.contains('action') && !genres.contains('thriller') && !genres.contains('crime')) return false;
    
    final stakesTags = ['high stakes', 'urgent', 'time-sensitive', 'race against time', 'countdown', 'bomb', 'hostage', 'rescue'];
    return tags.any((tag) => stakesTags.any((stakesTag) => tag.contains(stakesTag)));
  }

  static bool _meetsQualityThreshold(Movie movie) {
    return movie.posterUrl.isNotEmpty &&
           movie.rating != null &&
           movie.rating! >= 4.5 &&
           movie.voteCount != null &&
           movie.voteCount! >= 500;
  }
}

// Main testing function
void main() async {
  print('🎬 NEW Mood Engine Tester Starting...\n');
  
  // Ask for path to movies.json
  print('Enter the path to your movies.json file:');
  print('(or press Enter for default: ./assets/movies.json)');
  final input = stdin.readLineSync();
  final filePath = input?.trim().isEmpty == true ? './assets/movies.json' : input!.trim();
  
  try {
    // Load movies
    print('\n📚 Loading movies from: $filePath');
    final file = File(filePath);
    if (!file.existsSync()) {
      print('❌ File not found: $filePath');
      return;
    }
    
    final jsonString = await file.readAsString();
    final List<dynamic> jsonList = json.decode(jsonString);
    
    final movies = <Movie>[];
    int skipped = 0;
    
    for (final movieJson in jsonList) {
      try {
        final movie = Movie.fromJson(movieJson);
        if (movie.title.isNotEmpty && movie.genres.isNotEmpty) {
          movies.add(movie);
        } else {
          skipped++;
        }
      } catch (e) {
        skipped++;
      }
    }
    
    print('✅ Loaded ${movies.length} movies (skipped $skipped invalid entries)\n');
    
    // Test each mood
    print('🎭 Testing NEW Mood Matching Logic...\n');
    print('=' * 80);
    
    for (final mood in CurrentMood.values) {
      print('\n${mood.emoji} ${mood.displayName.toUpperCase()}');
      print('Target Genres: ${mood.preferredGenres.join(', ')}');
      print('Target Vibes: ${mood.preferredVibes.join(', ')}');
      print('-' * 60);
      
      final matchedMovies = <Movie>[];
      
      for (final movie in movies) {
        if (!MoodTester._meetsQualityThreshold(movie)) continue;
        
        if (MoodTester.matchesMoodCriteria(movie, mood)) {
          matchedMovies.add(movie);
        }
      }
      
      print('📊 Total Matches: ${matchedMovies.length}');
      
      // Show top 10 matches
      final topMatches = matchedMovies.take(10).toList();
      if (topMatches.isNotEmpty) {
        print('\n🏆 Top Matches:');
        for (int i = 0; i < topMatches.length; i++) {
          final movie = topMatches[i];
          print('   ${i + 1}. ${movie.title} (${movie.rating ?? 'N/A'})');
          print('      Genres: ${movie.genres.join(', ')}');
          if (movie.tags.isNotEmpty) {
            final relevantTags = movie.tags.take(5).join(', ');
            print('      Tags: $relevantTags${movie.tags.length > 5 ? '...' : ''}');
          }
        }
      }
      
      print('=' * 80);
    }
    
    // Ask if user wants detailed analysis of a specific mood
    print('\n🔍 Want detailed analysis of a specific mood?');
    print('Enter mood name (or press Enter to skip):');
    final moodInput = stdin.readLineSync()?.trim().toLowerCase();
    
    if (moodInput != null && moodInput.isNotEmpty) {
      final selectedMood = CurrentMood.values.where((mood) => 
          mood.displayName.toLowerCase().contains(moodInput)).firstOrNull;
      
      if (selectedMood != null) {
        _detailedMoodAnalysis(movies, selectedMood);
      } else {
        print('❌ Mood not found. Available moods:');
        for (final mood in CurrentMood.values) {
          print('   - ${mood.displayName}');
        }
      }
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}

void _detailedMoodAnalysis(List<Movie> movies, CurrentMood mood) {
  print('\n🔍 DETAILED ANALYSIS: ${mood.displayName}');
  print('=' * 80);
  
  var allMatches = <Movie>[];
  final rejectedByQuality = <Movie>[];
  
  for (final movie in movies) {
    if (MoodTester.matchesMoodCriteria(movie, mood)) {
      if (MoodTester._meetsQualityThreshold(movie)) {
        allMatches.add(movie);
      } else {
        rejectedByQuality.add(movie);
      }
    }
  }
  
  print('📊 MATCH BREAKDOWN:');
  print('   Total Matches: ${allMatches.length}');
  print('   Rejected by Quality: ${rejectedByQuality.length}');
  
  if (allMatches.length > 20) {
    print('\n⚠️  Large result set (${allMatches.length} movies)');
    print('Showing top 20 matches sorted by rating...');
    allMatches.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    allMatches = allMatches.take(20).toList();
  }
  
  print('\n📝 DETAILED MATCHES:');
  for (int i = 0; i < allMatches.length; i++) {
    final movie = allMatches[i];
    
    print('\n${i + 1}. ${movie.title}');
    print('   Rating: ${movie.rating ?? 'N/A'} | Votes: ${movie.voteCount ?? 'N/A'}');
    print('   Genres: ${movie.genres.join(', ')}');
    print('   Tags: ${movie.tags.join(', ')}');
    
    if (movie.overview.isNotEmpty && movie.overview.length > 100) {
      print('   Overview: ${movie.overview.substring(0, 100)}...');
    } else if (movie.overview.isNotEmpty) {
      print('   Overview: ${movie.overview}');
    }
  }
  
  if (rejectedByQuality.isNotEmpty && rejectedByQuality.length <= 10) {
    print('\n🚫 REJECTED BY QUALITY THRESHOLD:');
    for (final movie in rejectedByQuality.take(10)) {
      print('   - ${movie.title} (Rating: ${movie.rating ?? 'N/A'}, Votes: ${movie.voteCount ?? 'N/A'})');
    }
  }
}

extension ListExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}