// Updated Test Script for STRICT Mood Engine
// Save as: test_strict_mood_engine.dart
// Run with: dart test_strict_mood_engine.dart

import 'dart:io';
import 'dart:convert';
import 'package:Zura/utils/debug_loader.dart';

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

// CurrentMood enum (same as in your engine)
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

// STRICT Mood Matching Logic (mirrors your new engine)
class StrictMoodTester {
  
  /// Test both strict and relaxed matching
  static MatchResult testMoodMatching(Movie movie, CurrentMood mood) {
    final isStrictMatch = _isMovieStrictMatchForMood(movie, mood);
    final isRelaxedMatch = _isMovieRelaxedMatchForMood(movie, mood);
    
    return MatchResult(
      isStrictMatch: isStrictMatch,
      isRelaxedMatch: isRelaxedMatch,
      meetsQuality: _meetsQualityThreshold(movie),
    );
  }
  
  /// STRICT matching - requires both genre AND specific vibe indicators
  static bool _isMovieStrictMatchForMood(Movie movie, CurrentMood mood) {
    final movieGenres = movie.genres.map((g) => g.toLowerCase().trim()).toSet();
    final movieTags = movie.tags.map((t) => t.toLowerCase().trim()).toSet();
    
    // Global exclusions first
    if (_hasGlobalExclusions(movie, mood, movieGenres, movieTags)) return false;
    
    switch (mood) {
      case CurrentMood.pureComedy:
        // Must be Comedy genre AND have funny indicators AND not be dark/action heavy
        if (!movieGenres.contains('comedy')) return false;
        if (_isActionHeavyMovie(movieGenres, movieTags)) return false;
        final comedyVibes = ['funny', 'hilarious', 'witty', 'humorous', 'comedic', 'light-hearted', 'silly'];
        return _hasExactVibeMatch(movieTags, comedyVibes);
        
      case CurrentMood.epicAction:
        // Must be Action genre AND have action indicators AND not be primarily comedy/family
        if (!movieGenres.contains('action')) return false;
        if (_isPrimarilyComedyOrFamily(movieGenres, movieTags)) return false;
        final actionVibes = ['action-packed', 'combat', 'fighting', 'explosive', 'intense', 'adrenaline'];
        return _hasExactVibeMatch(movieTags, actionVibes);
        
      case CurrentMood.scaryAndSuspenseful:
        // Must be Horror or Thriller AND have scary indicators
        if (!movieGenres.contains('horror') && !movieGenres.contains('thriller')) return false;
        final scaryVibes = ['scary', 'terrifying', 'frightening', 'suspenseful', 'creepy', 'spine-chilling'];
        return _hasExactVibeMatch(movieTags, scaryVibes) || movieGenres.contains('horror');
        
      case CurrentMood.romantic:
        // Must be Romance genre OR have EXPLICIT romantic indicators (not action movies with romance tags)
        if (movieGenres.contains('romance')) return true;
        if (_isActionHeavyMovie(movieGenres, movieTags)) return false;
        final romanticVibes = ['love story', 'passionate', 'tender', 'sweet'];
        final explicitRomantic = ['romantic comedy', 'romantic drama', 'love triangle', 'wedding'];
        return _hasExactVibeMatch(movieTags, romanticVibes) || _hasExactVibeMatch(movieTags, explicitRomantic);
        
      case CurrentMood.mindBending:
        // Must have specific genres AND explicit mind-bending indicators
        final rightGenres = movieGenres.any((g) => ['drama', 'sci-fi', 'science fiction', 'mystery', 'thriller'].contains(g));
        if (!rightGenres) return false;
        final mindVibes = ['mind-bending', 'psychological thriller', 'cerebral', 'thought-provoking'];
        final twistVibes = ['plot twist', 'twist ending', 'non-linear', 'unreliable narrator'];
        return _hasExactVibeMatch(movieTags, mindVibes) || _hasExactVibeMatch(movieTags, twistVibes);
        
      case CurrentMood.emotionalDrama:
        // Must be Drama AND have emotional indicators
        if (!movieGenres.contains('drama')) return false;
        final emotionalVibes = ['emotional', 'heartwarming', 'moving', 'touching', 'meaningful', 'tearjerker'];
        return _hasExactVibeMatch(movieTags, emotionalVibes);
        
      case CurrentMood.trueStories:
        // Must have biographical genres OR very explicit true story indicators
        if (movieGenres.any((g) => ['biography', 'documentary', 'history'].contains(g))) return true;
        final trueVibes = ['based on true story', 'based on a true story', 'biographical', 'true story'];
        return _hasExactVibeMatch(movieTags, trueVibes);
        
      case CurrentMood.mysteryCrime:
        // Must be Crime/Mystery/Thriller AND have investigation indicators
        if (!movieGenres.any((g) => ['crime', 'mystery', 'thriller'].contains(g))) return false;
        final crimeVibes = ['detective', 'investigation', 'murder mystery', 'crime solving', 'police procedural'];
        final criminalVibes = ['heist', 'organized crime', 'criminal', 'mafia', 'gangster'];
        return _hasExactVibeMatch(movieTags, crimeVibes) || _hasExactVibeMatch(movieTags, criminalVibes);
        
      case CurrentMood.adventureFantasy:
        // Must have adventure/fantasy genres AND epic indicators
        if (!movieGenres.any((g) => ['adventure', 'fantasy', 'sci-fi', 'science fiction'].contains(g))) return false;
        final epicVibes = ['epic', 'quest', 'journey', 'magical', 'otherworldly', 'mythical'];
        return _hasExactVibeMatch(movieTags, epicVibes);
        
      case CurrentMood.musicalDance:
        // Must be Musical genre OR have explicit music indicators
        if (movieGenres.any((g) => ['musical', 'music'].contains(g))) return true;
        final musicVibes = ['musical', 'dance', 'singing', 'song', 'concert', 'broadway'];
        return _hasExactVibeMatch(movieTags, musicVibes);
        
      case CurrentMood.familyFun:
        // Must be Family/Animation OR have family indicators
        if (movieGenres.any((g) => ['family', 'animation'].contains(g))) return true;
        final familyVibes = ['family-friendly', 'kids', 'wholesome', 'children'];
        return _hasExactVibeMatch(movieTags, familyVibes);
        
      case CurrentMood.sciFiFuture:
        // Must be Sci-Fi AND have futuristic indicators
        if (!movieGenres.any((g) => ['sci-fi', 'science fiction'].contains(g))) return false;
        final scifiVibes = ['futuristic', 'space', 'alien', 'robot', 'artificial intelligence', 'cyberpunk', 'dystopian'];
        return _hasExactVibeMatch(movieTags, scifiVibes);
        
      case CurrentMood.worldCinema:
        // Must be Foreign OR have explicit foreign film indicators
        if (movieGenres.contains('foreign')) return true;
        final worldVibes = ['subtitled', 'foreign language', 'international film', 'world cinema'];
        return _hasExactVibeMatch(movieTags, worldVibes);
        
      case CurrentMood.cultClassic:
        // Must have explicit cult indicators (not generic "underground")
        final cultVibes = ['cult classic', 'cult film', 'cult following', 'midnight movie', 'b-movie', 'campy', 'weird', 'bizarre'];
        return _hasExactVibeMatch(movieTags, cultVibes);
        
      case CurrentMood.twistEnding:
        // Must have right genres AND explicit twist indicators
        if (!movieGenres.any((g) => ['thriller', 'mystery', 'drama'].contains(g))) return false;
        final twistVibes = ['plot twist', 'twist ending', 'surprise ending', 'shocking ending', 'unexpected ending'];
        return _hasExactVibeMatch(movieTags, twistVibes);
        
      case CurrentMood.highStakes:
        // Must have action/thriller genres AND explicit stakes indicators
        if (!movieGenres.any((g) => ['action', 'thriller', 'crime'].contains(g))) return false;
        final stakesVibes = ['high stakes', 'race against time', 'time-sensitive', 'countdown', 'urgent', 'life or death'];
        return _hasExactVibeMatch(movieTags, stakesVibes);
    }
  }
  
  /// Helper: Check for exact vibe matches (not partial contains)
  static bool _hasExactVibeMatch(Set<String> movieTags, List<String> targetVibes) {
    for (final vibe in targetVibes) {
      for (final tag in movieTags) {
        // Exact match or vibe is contained as a complete word/phrase
        if (tag == vibe || tag.contains(' $vibe ') || tag.startsWith('$vibe ') || tag.endsWith(' $vibe')) {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Helper: Global exclusions to prevent cross-contamination
  static bool _hasGlobalExclusions(Movie movie, CurrentMood mood, Set<String> movieGenres, Set<String> movieTags) {
    // Prevent family movies from appearing in inappropriate moods
    if (movieGenres.contains('family') || movieGenres.contains('animation')) {
      if ([CurrentMood.scaryAndSuspenseful, CurrentMood.mysteryCrime].contains(mood)) {
        return true;
      }
    }
    
    // Prevent action movies from dominating non-action moods
    if (_isActionHeavyMovie(movieGenres, movieTags)) {
      if ([CurrentMood.emotionalDrama, CurrentMood.trueStories].contains(mood)) {
        // Only allow if they have very strong indicators for the target mood
        return !_hasStrongMoodIndicators(movieTags, mood);
      }
    }
    
    return false;
  }
  
  /// Helper: Detect action-heavy movies
  static bool _isActionHeavyMovie(Set<String> movieGenres, Set<String> movieTags) {
    if (!movieGenres.contains('action')) return false;
    final actionIndicators = ['action-packed', 'combat', 'fighting', 'explosive', 'shootout'];
    return movieTags.any((tag) => actionIndicators.any((indicator) => tag.contains(indicator)));
  }
  
  /// Helper: Detect primarily comedy/family movies
  static bool _isPrimarilyComedyOrFamily(Set<String> movieGenres, Set<String> movieTags) {
    // If it has family/animation genres, it's primarily family
    if (movieGenres.any((g) => ['family', 'animation'].contains(g))) return true;
    
    // If it has comedy genre AND comedy tags, it's primarily comedy
    if (movieGenres.contains('comedy')) {
      final comedyTags = ['funny', 'hilarious', 'witty', 'comedic'];
      return movieTags.any((tag) => comedyTags.any((comedy) => tag.contains(comedy)));
    }
    
    return false;
  }
  
  /// Helper: Check for strong mood indicators
  static bool _hasStrongMoodIndicators(Set<String> movieTags, CurrentMood mood) {
    switch (mood) {
      case CurrentMood.emotionalDrama:
        final strongEmotional = ['tearjerker', 'heartbreaking', 'deeply moving', 'emotionally powerful'];
        return _hasExactVibeMatch(movieTags, strongEmotional);
      case CurrentMood.trueStories:
        final strongTrue = ['based on true story', 'biographical', 'documentary style'];
        return _hasExactVibeMatch(movieTags, strongTrue);
      default:
        return false;
    }
  }
  
  /// RELAXED matching - genre requirements only (as fallback)
  static bool _isMovieRelaxedMatchForMood(Movie movie, CurrentMood mood) {
    final movieGenres = movie.genres.map((g) => g.toLowerCase().trim()).toSet();
    
    switch (mood) {
      case CurrentMood.pureComedy:
        return movieGenres.contains('comedy');
        
      case CurrentMood.epicAction:
        return movieGenres.contains('action');
        
      case CurrentMood.scaryAndSuspenseful:
        return movieGenres.contains('horror') || movieGenres.contains('thriller');
        
      case CurrentMood.romantic:
        return movieGenres.contains('romance');
        
      case CurrentMood.mindBending:
        return movieGenres.any((g) => ['drama', 'sci-fi', 'science fiction', 'mystery', 'thriller'].contains(g));
        
      case CurrentMood.emotionalDrama:
        return movieGenres.contains('drama');
        
      case CurrentMood.trueStories:
        return movieGenres.any((g) => ['biography', 'documentary', 'history', 'drama'].contains(g));
        
      case CurrentMood.mysteryCrime:
        return movieGenres.any((g) => ['crime', 'mystery', 'thriller'].contains(g));
        
      case CurrentMood.adventureFantasy:
        return movieGenres.any((g) => ['adventure', 'fantasy', 'sci-fi', 'science fiction'].contains(g));
        
      case CurrentMood.musicalDance:
        return movieGenres.any((g) => ['musical', 'music'].contains(g));
        
      case CurrentMood.familyFun:
        return movieGenres.any((g) => ['family', 'animation'].contains(g));
        
      case CurrentMood.sciFiFuture:
        return movieGenres.any((g) => ['sci-fi', 'science fiction'].contains(g));
        
      case CurrentMood.worldCinema:
        return movieGenres.contains('foreign');
        
      case CurrentMood.cultClassic:
        return movieGenres.any((g) => ['drama', 'comedy', 'horror'].contains(g));
        
      case CurrentMood.twistEnding:
        return movieGenres.any((g) => ['thriller', 'mystery', 'drama'].contains(g));
        
      case CurrentMood.highStakes:
        return movieGenres.any((g) => ['action', 'thriller', 'crime'].contains(g));
    }
  }

  static bool _meetsQualityThreshold(Movie movie) {
    return movie.posterUrl.isNotEmpty &&
           movie.rating != null &&
           movie.rating! >= 4.5 &&
           movie.voteCount != null &&
           movie.voteCount! >= 500;
  }
}

class MatchResult {
  final bool isStrictMatch;
  final bool isRelaxedMatch;
  final bool meetsQuality;
  
  MatchResult({
    required this.isStrictMatch,
    required this.isRelaxedMatch,
    required this.meetsQuality,
  });
  
  String get status {
    if (isStrictMatch && meetsQuality) return '✅ PERFECT';
    if (isStrictMatch && !meetsQuality) return '🟡 STRICT (Low Quality)';
    if (isRelaxedMatch && meetsQuality) return '🟠 RELAXED';
    if (isRelaxedMatch && !meetsQuality) return '🔴 RELAXED (Low Quality)';
    return '❌ NO MATCH';
  }
}

// Main testing function
void main() async {
  DebugLogger.log('🎬 STRICT Mood Engine Tester Starting...\n');
  
  // Ask for path to movies.json
  DebugLogger.log('Enter the path to your movies.json file:');
  DebugLogger.log('(or press Enter for default: ./assets/movies.json)');
  final input = stdin.readLineSync();
  final filePath = input?.trim().isEmpty == true ? './assets/movies.json' : input!.trim();
  
  try {
    // Load movies
    DebugLogger.log('\n📚 Loading movies from: $filePath');
    final file = File(filePath);
    if (!file.existsSync()) {
      DebugLogger.log('❌ File not found: $filePath');
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
    
    DebugLogger.log('✅ Loaded ${movies.length} movies (skipped $skipped invalid entries)\n');
    
    // Test each mood with STRICT and RELAXED matching
    DebugLogger.log('🎭 Testing STRICT vs RELAXED Mood Matching...\n');
    DebugLogger.log('=' * 90);
    
    for (final mood in CurrentMood.values) {
      DebugLogger.log('\n${mood.emoji} ${mood.displayName.toUpperCase()}');
      DebugLogger.log('Target Genres: ${mood.preferredGenres.join(', ')}');
      DebugLogger.log('Target Vibes: ${mood.preferredVibes.join(', ')}');
      DebugLogger.log('-' * 80);
      
      final strictMatches = <Movie>[];
      final relaxedMatches = <Movie>[];
      final qualityStrictMatches = <Movie>[];
      final qualityRelaxedMatches = <Movie>[];
      
      for (final movie in movies) {
        final result = StrictMoodTester.testMoodMatching(movie, mood);
        
        if (result.isStrictMatch) {
          strictMatches.add(movie);
          if (result.meetsQuality) qualityStrictMatches.add(movie);
        } else if (result.isRelaxedMatch) {
          relaxedMatches.add(movie);
          if (result.meetsQuality) qualityRelaxedMatches.add(movie);
        }
      }
      
      DebugLogger.log('📊 MATCH SUMMARY:');
      DebugLogger.log('   🟢 Strict Matches: ${strictMatches.length} (${qualityStrictMatches.length} high quality)');
      DebugLogger.log('   🟡 Relaxed Only: ${relaxedMatches.length} (${qualityRelaxedMatches.length} high quality)');
      DebugLogger.log('   🎯 Users will see: ${qualityStrictMatches.length} strict + ${qualityRelaxedMatches.length} relaxed fallback');
      
      // Show top matches from each category
      if (qualityStrictMatches.isNotEmpty) {
        DebugLogger.log('\n🏆 TOP STRICT MATCHES (what users will see first):');
        final topStrict = qualityStrictMatches.take(5).toList();
        for (int i = 0; i < topStrict.length; i++) {
          final movie = topStrict[i];
          DebugLogger.log('   ${i + 1}. ${movie.title} (${movie.rating ?? 'N/A'}) ✅');
          DebugLogger.log('      Genres: ${movie.genres.join(', ')}');
          final relevantTags = movie.tags.where((tag) => 
              mood.preferredVibes.any((vibe) => tag.toLowerCase().contains(vibe.toLowerCase()))).take(3);
          if (relevantTags.isNotEmpty) {
            DebugLogger.log('      Mood Tags: ${relevantTags.join(', ')}');
          }
        }
      }
      
      if (qualityRelaxedMatches.isNotEmpty && qualityStrictMatches.length < 5) {
        DebugLogger.log('\n🟡 TOP RELAXED FALLBACK MATCHES:');
        final topRelaxed = qualityRelaxedMatches.take(3).toList();
        for (int i = 0; i < topRelaxed.length; i++) {
          final movie = topRelaxed[i];
          DebugLogger.log('   ${i + 1}. ${movie.title} (${movie.rating ?? 'N/A'}) 🟡');
          DebugLogger.log('      Genres: ${movie.genres.join(', ')}');
          DebugLogger.log('      Tags: ${movie.tags.take(3).join(', ')}');
        }
      }
      
      DebugLogger.log('=' * 90);
    }
    
    // Ask for detailed analysis
    DebugLogger.log('\n🔍 Want detailed analysis of a specific mood?');
    DebugLogger.log('Enter mood name (or press Enter to skip):');
    final moodInput = stdin.readLineSync()?.trim().toLowerCase();
    
    if (moodInput != null && moodInput.isNotEmpty) {
      final selectedMood = CurrentMood.values.where((mood) => 
          mood.displayName.toLowerCase().contains(moodInput)).firstOrNull;
      
      if (selectedMood != null) {
        _detailedMoodAnalysis(movies, selectedMood);
      } else {
        DebugLogger.log('❌ Mood not found. Available moods:');
        for (final mood in CurrentMood.values) {
          DebugLogger.log('   - ${mood.displayName}');
        }
      }
    }
    
  } catch (e) {
    DebugLogger.log('❌ Error: $e');
  }
}

void _detailedMoodAnalysis(List<Movie> movies, CurrentMood mood) {
  DebugLogger.log('\n🔍 DETAILED ANALYSIS: ${mood.displayName}');
  DebugLogger.log('=' * 90);
  
  final strictResults = <Movie, MatchResult>{};
  final relaxedResults = <Movie, MatchResult>{};
  final rejectedResults = <Movie, MatchResult>{};
  
  for (final movie in movies) {
    final result = StrictMoodTester.testMoodMatching(movie, mood);
    
    if (result.isStrictMatch && result.meetsQuality) {
      strictResults[movie] = result;
    } else if (result.isRelaxedMatch && result.meetsQuality) {
      relaxedResults[movie] = result;
    } else if (result.isStrictMatch || result.isRelaxedMatch) {
      rejectedResults[movie] = result;
    }
  }
  
  DebugLogger.log('📊 DETAILED BREAKDOWN:');
  DebugLogger.log('   ✅ Strict Quality Matches: ${strictResults.length}');
  DebugLogger.log('   🟡 Relaxed Quality Matches: ${relaxedResults.length}');
  DebugLogger.log('   ❌ Rejected (Poor Quality): ${rejectedResults.length}');
  
  void _printMovieDetails(Movie movie, MatchResult result) {
    DebugLogger.log('   Title: ${movie.title}');
    DebugLogger.log('   Status: ${result.status}');
    DebugLogger.log('   Rating: ${movie.rating ?? 'N/A'} | Votes: ${movie.voteCount ?? 'N/A'}');
    DebugLogger.log('   Genres: ${movie.genres.join(', ')}');
    DebugLogger.log('   Tags: ${movie.tags.join(', ')}');
    if (movie.overview.isNotEmpty && movie.overview.length > 100) {
      DebugLogger.log('   Overview: ${movie.overview.substring(0, 100)}...');
    }
    DebugLogger.log('');
  }
  
  if (strictResults.isNotEmpty) {
    DebugLogger.log('\n✅ STRICT QUALITY MATCHES (Perfect for this mood):');
    var count = 0;
    for (final entry in strictResults.entries) {
      if (count >= 10) break;
      DebugLogger.log('\n${count + 1}.');
      _printMovieDetails(entry.key, entry.value);
      count++;
    }
  }
  
  if (relaxedResults.isNotEmpty && relaxedResults.length <= 10) {
    DebugLogger.log('\n🟡 RELAXED QUALITY MATCHES (Fallback options):');
    var count = 0;
    for (final entry in relaxedResults.entries) {
      if (count >= 5) break;
      DebugLogger.log('\n${count + 1}.');
      _printMovieDetails(entry.key, entry.value);
      count++;
    }
  }
  
  if (rejectedResults.isNotEmpty && rejectedResults.length <= 5) {
    DebugLogger.log('\n❌ REJECTED MATCHES (Low quality but genre/tag match):');
    var count = 0;
    for (final entry in rejectedResults.entries) {
      if (count >= 3) break;
      DebugLogger.log('\n${count + 1}.');
      _printMovieDetails(entry.key, entry.value);
      count++;
    }
  }
}

extension ListExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}