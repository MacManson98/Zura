import '../models/friend_group.dart';
import '../movie.dart';

class SimpleGroupRecommendations {
  
  /// Generate simple, smart recommendations for a group
  static List<Movie> generateRecommendations({
    required FriendGroup group,
    required List<Movie> allMovies,
    int maxRecommendations = 12,
  }) {
    
    // 1. Get all movies the group has collectively liked
    final Map<String, int> movieLikeCount = {};
    final Set<String> allSeenMovies = {};
    final Map<String, int> genrePreferences = {};
    
    // Analyze what the group likes
    for (final member in group.members) {
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
    }
    
    // 2. Find the group's favorite movies (liked by multiple people)
    final groupFavorites = allMovies.where((movie) {
      final likeCount = movieLikeCount[movie.id] ?? 0;
      return likeCount >= 2; // Liked by at least 2 people
    }).toList();
    
    // 3. Find similar movies to what the group likes
    final recommendations = <Movie, double>{};
    
    for (final favoriteMovie in groupFavorites) {
      final similarMovies = _findSimilarMovies(favoriteMovie, allMovies, allSeenMovies);
      
      for (final similarMovie in similarMovies) {
        final score = _calculateSimilarityScore(
          favoriteMovie, 
          similarMovie, 
          genrePreferences,
          movieLikeCount[favoriteMovie.id] ?? 1,
        );
        
        // Keep the highest score for each movie
        if (!recommendations.containsKey(similarMovie) || 
            recommendations[similarMovie]! < score) {
          recommendations[similarMovie] = score;
        }
      }
    }
    
    // 4. If we don't have enough recommendations, add some high-rated movies in preferred genres
    if (recommendations.length < maxRecommendations) {
      final additionalMovies = _findHighRatedInPreferredGenres(
        allMovies, 
        genrePreferences, 
        allSeenMovies,
        maxRecommendations - recommendations.length,
      );
      
      for (final movie in additionalMovies) {
        if (!recommendations.containsKey(movie)) {
          recommendations[movie] = _calculateGenreScore(movie, genrePreferences);
        }
      }
    }
    
    // 5. Sort by score and return top recommendations
    final sortedRecommendations = recommendations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedRecommendations
        .take(maxRecommendations)
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Find movies similar to a given movie
  static List<Movie> _findSimilarMovies(
    Movie favoriteMovie, 
    List<Movie> allMovies, 
    Set<String> seenMovies,
  ) {
    return allMovies.where((movie) {
      // Skip if already seen
      if (seenMovies.contains(movie.id) || movie.id == favoriteMovie.id) {
        return false;
      }
      
      // Must be decent quality (handle null rating)
      final movieRating = movie.rating ?? 0.0;
      if (movieRating < 6.5) return false;
      
      // Must share at least one genre
      final sharedGenres = movie.genres.toSet().intersection(favoriteMovie.genres.toSet());
      if (sharedGenres.isEmpty) return false;
      
      return true;
    }).toList();
  }
  
  /// Calculate how similar two movies are
  static double _calculateSimilarityScore(
    Movie favoriteMovie,
    Movie candidateMovie,
    Map<String, int> genrePreferences,
    int favoriteMovieLikes,
  ) {
    double score = 0;
    
    // Base score from rating (handle null rating)
    final candidateRating = candidateMovie.rating ?? 7.0; // Default to decent rating if null
    score += candidateRating * 2;
    
    // Bonus for shared genres
    final sharedGenres = candidateMovie.genres.toSet().intersection(favoriteMovie.genres.toSet());
    score += sharedGenres.length * 5;
    
    // Bonus for popular genres in the group
    for (final genre in candidateMovie.genres) {
      final genrePopularity = genrePreferences[genre] ?? 0;
      score += genrePopularity * 2;
    }
    
    // Bonus based on how much the group liked the reference movie
    score += favoriteMovieLikes * 3;
    
    return score;
  }
  
  /// Find high-rated movies in the group's preferred genres
  static List<Movie> _findHighRatedInPreferredGenres(
    List<Movie> allMovies,
    Map<String, int> genrePreferences,
    Set<String> seenMovies,
    int count,
  ) {
    if (genrePreferences.isEmpty) return [];
    
    // Get the most popular genres
    final popularGenres = genrePreferences.entries
        .where((entry) => entry.value >= 2) // Liked by at least 2 people
        .map((entry) => entry.key)
        .toSet();
    
    if (popularGenres.isEmpty) return [];
    
    final candidates = allMovies.where((movie) {
      if (seenMovies.contains(movie.id)) return false;
      
      // Handle null rating
      final movieRating = movie.rating ?? 0.0;
      if (movieRating < 7.5) return false; // High quality only
      
      return movie.genres.any((genre) => popularGenres.contains(genre));
    }).toList();
    
    // Sort by rating (handle null ratings)
    candidates.sort((a, b) {
      final aRating = a.rating ?? 0.0;
      final bRating = b.rating ?? 0.0;
      return bRating.compareTo(aRating);
    });
    
    return candidates.take(count).toList();
  }
  
  /// Calculate score based on genre preferences
  static double _calculateGenreScore(Movie movie, Map<String, int> genrePreferences) {
    // Handle null rating
    final movieRating = movie.rating ?? 7.0; // Default to decent rating if null
    double score = movieRating * 2;
    
    for (final genre in movie.genres) {
      final genrePopularity = genrePreferences[genre] ?? 0;
      score += genrePopularity * 3;
    }
    
    return score;
  }
  
  /// Get a simple explanation for why a movie was recommended
  static String getRecommendationReason(
    Movie movie, 
    FriendGroup group, 
    List<Movie> allMovies,
  ) {
    // Find which group favorites are similar to this movie
    final Map<String, int> movieLikeCount = {};
    for (final member in group.members) {
      for (final movieId in member.likedMovieIds) {
        movieLikeCount[movieId] = (movieLikeCount[movieId] ?? 0) + 1;
      }
    }
    
    final groupFavorites = allMovies.where((m) {
      final likeCount = movieLikeCount[m.id] ?? 0;
      return likeCount >= 2;
    }).toList();
    
    // Find the most similar favorite movie
    Movie? mostSimilar;
    int maxSharedGenres = 0;
    
    for (final favorite in groupFavorites) {
      final sharedGenres = movie.genres.toSet().intersection(favorite.genres.toSet());
      if (sharedGenres.length > maxSharedGenres) {
        maxSharedGenres = sharedGenres.length;
        mostSimilar = favorite;
      }
    }
    
    if (mostSimilar != null) {
      return "Because you loved ${mostSimilar.title}";
    }
    
    // Fallback to genre-based reason
    final popularGenres = <String, int>{};
    for (final member in group.members) {
      for (final genre in member.preferredGenres) {
        popularGenres[genre] = (popularGenres[genre] ?? 0) + 1;
      }
    }
    
    final moviePreferredGenres = movie.genres.where((genre) => 
        (popularGenres[genre] ?? 0) >= 2).toList();
    
    if (moviePreferredGenres.isNotEmpty) {
      return "Great ${moviePreferredGenres.first.toLowerCase()} movie";
    }
    
    return "Highly rated and worth watching";
  }
}