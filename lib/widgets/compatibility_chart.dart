// File: lib/widgets/compatibility_chart.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../movie.dart';

class CompatibilityChart extends StatelessWidget {
  final UserProfile currentUser;
  final UserProfile friend;
  final List<Movie> sharedLikes;
  
  const CompatibilityChart({
    Key? key,
    required this.currentUser,
    required this.friend,
    required this.sharedLikes,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Calculate genre compatibility
    final Map<String, double> genreCompatibility = _calculateGenreCompatibility();
    final List<MapEntry<String, double>> sortedGenres = genreCompatibility.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      color: const Color(0xFF1F1F1F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Taste overlap section
            const Text(
              "Genre Compatibility",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Genre bars
            ...sortedGenres.take(5).map((entry) => _buildGenreBar(entry.key, entry.value)),
            
            const SizedBox(height: 20),
            
            // Movie preferences section
            const Text(
              "Movie Preferences",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPreferenceComparison(),
          ],
        ),
      ),
    );
  }
  
  Map<String, double> _calculateGenreCompatibility() {
    final Map<String, double> compatibility = {};
    
    // Get all unique genres from both users
    final Set<String> allGenres = {...currentUser.preferredGenres, ...friend.preferredGenres};
    
    for (final genre in allGenres) {
      final bool userLikes = currentUser.preferredGenres.contains(genre);
      final bool friendLikes = friend.preferredGenres.contains(genre);
      
      if (userLikes && friendLikes) {
        // Both like the genre
        compatibility[genre] = 1.0;
      } else if (userLikes || friendLikes) {
        // Only one likes the genre
        compatibility[genre] = 0.5;
      } else {
        // Nobody likes the genre (shouldn't happen with this logic)
        compatibility[genre] = 0.0;
      }
    }
    
    return compatibility;
  }
  
  Widget _buildGenreBar(String genre, double compatibility) {
    final Color barColor = _getCompatibilityColor(compatibility);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                genre,
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                "${(compatibility * 100).toInt()}%",
                style: TextStyle(
                  color: barColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: compatibility,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreferenceComparison() {
    final int totalUserLikes = currentUser.likedMovies.length;
    final int totalFriendLikes = friend.likedMovies.length;
    final int sharedCount = sharedLikes.length;
    
    return Row(
      children: [
        // Your likes
        Expanded(
          child: _buildPreferenceColumn(
            "Your Likes",
            totalUserLikes,
            Colors.blue,
          ),
        ),
        
        // Shared likes
        Expanded(
          child: _buildPreferenceColumn(
            "Shared",
            sharedCount,
            Colors.green,
          ),
        ),
        
        // Friend likes
        Expanded(
          child: _buildPreferenceColumn(
            "${friend.name}'s Likes",
            totalFriendLikes,
            Colors.orange,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreferenceColumn(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Fill bar
              FractionallySizedBox(
                heightFactor: count > 0 ? count / 20 : 0.05, // Scale to max of 20 movies
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Color _getCompatibilityColor(double compatibility) {
    final int score = (compatibility * 100).toInt();
    
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.amber;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }
}