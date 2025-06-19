// File: lib/data/movie_json_loader.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../movie.dart';
import '../utils/debug_loader.dart';

class MovieJsonLoader {
  static Future<List<Movie>> loadOnboardingMovies() async {
    try {
      // Load the JSON file from assets
      final String jsonString = await rootBundle.loadString('lib/data/popular_movies_data.json');
      
      // Parse the JSON
      final List<dynamic> jsonList = json.decode(jsonString);
      
      // Convert JSON to Movie objects using the existing fromJson method
      final List<Movie> movies = jsonList.map((jsonMovie) {
        return Movie.fromJson(jsonMovie);
      }).toList();
      
      DebugLogger.log('✅ Loaded ${movies.length} movies from JSON file');
      return movies;
      
    } catch (e) {
      DebugLogger.log('❌ Error loading movies from JSON: $e');
      return [];
    }
  }
}