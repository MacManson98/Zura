import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/debug_loader.dart';

/// Recommends movies for a single user based on their genre and vibe scores.
List<Movie> recommendForUser(UserProfile user, List<Movie> allMovies, {int max = 100}) {
  final scored = <Movie, double>{};

  for (final movie in allMovies) {
    double score = 0;

    for (final genre in movie.genres) {
      score += user.genreScores[genre] ?? 0;
    }

    for (final vibe in movie.tags) {
      score += user.vibeScores[vibe] ?? 0;
    }

    // Small base score to introduce variety
    score += 1;

    scored[movie] = score;
    DebugLogger.log('🎯 ${movie.title} → $score');
  }

  final sorted = scored.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.map((e) => e.key).take(max).toList();
}

/// Generates a combined session pool for two users (e.g., friend match).
List<Movie> generateSessionPoolForPair({
  required UserProfile userA,
  required UserProfile userB,
  required List<Movie> allMovies,
  int perUser = 100,
}) {
  final listA = recommendForUser(userA, allMovies, max: perUser);
  final listB = recommendForUser(userB, allMovies, max: perUser);

  final combined = {...listA, ...listB}.toList();
  combined.shuffle();

  return combined;
}

/// Generates a combined session pool for multiple users (e.g., group match).
List<Movie> generateSessionPoolForUsers({
  required List<UserProfile> users,
  required List<Movie> allMovies,
  int perUser = 50,
}) {
  final Set<Movie> allRecommendations = {};

  for (final user in users) {
    final recs = recommendForUser(user, allMovies, max: perUser);
    allRecommendations.addAll(recs);
  }

  final list = allRecommendations.toList()..shuffle();
  return list;
}
