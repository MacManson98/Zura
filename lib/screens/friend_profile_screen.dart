import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import '../widgets/compatibility_chart.dart';
import 'matcher_screen.dart';

class FriendProfileScreen extends StatefulWidget {
  final UserProfile currentUser;
  final UserProfile friend;
  final List<Movie> allMovies;

  const FriendProfileScreen({
    super.key,
    required this.currentUser,
    required this.friend,
    required this.allMovies,
  });

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  late List<Movie> _sharedLikes;
  late List<Movie> _recommendedMovies;
  late Map<String, int> _genreOverlap;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _analyzeProfiles();
  }

  void _analyzeProfiles() {
    setState(() {
      _isLoading = true;
    });
    
    // Find shared liked movies
    _sharedLikes = widget.currentUser.likedMovies
        .where((movie) => widget.friend.likedMovies.contains(movie))
        .toList();
    
    // Calculate genre overlap
    _genreOverlap = {};
    
    // Count genres from current user
    for (var genre in widget.currentUser.preferredGenres) {
      _genreOverlap[genre] = (_genreOverlap[genre] ?? 0) + 1;
    }
    
    // Count genres from friend
    for (var genre in widget.friend.preferredGenres) {
      _genreOverlap[genre] = (_genreOverlap[genre] ?? 0) + 1;
    }
    
    // Find movies both might enjoy (simple recommendation logic)
    final Set<String> combinedGenres = {...widget.currentUser.preferredGenres, ...widget.friend.preferredGenres};
    final Set<String> combinedVibes = {...widget.currentUser.preferredVibes, ...widget.friend.preferredVibes};
    
    // Generate movie recommendations based on shared preferences
    _recommendedMovies = widget.allMovies
        .where((movie) {
          // Count how many shared genres and vibes the movie matches
          int genreMatches = movie.genres
              .where((g) => combinedGenres.contains(g))
              .length;
              
          int vibeMatches = movie.tags
              .where((t) => combinedVibes.contains(t))
              .length;
              
          // Consider it a good recommendation if it matches at least one genre and vibe
          return genreMatches > 0 && vibeMatches > 0;
        })
        .where((movie) => 
            !widget.currentUser.likedMovies.contains(movie) ||
            !widget.friend.likedMovies.contains(movie))
        .toList();
    
    // Sort recommendations by how many genres/vibes they match
    _recommendedMovies.sort((a, b) {
      int aMatches = a.genres.where((g) => combinedGenres.contains(g)).length +
          a.tags.where((t) => combinedVibes.contains(t)).length;
          
      int bMatches = b.genres.where((g) => combinedGenres.contains(g)).length +
          b.tags.where((t) => combinedVibes.contains(t)).length;
          
      return bMatches.compareTo(aMatches); // Descending order
    });
    
    // Take only top 10 recommendations
    if (_recommendedMovies.length > 10) {
      _recommendedMovies = _recommendedMovies.sublist(0, 10);
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // Calculate overall compatibility score
  double get _compatibilityScore {
    // Count shared genres
    int sharedGenres = 0;
    for (var entry in _genreOverlap.entries) {
      if (entry.value > 1) sharedGenres++;
    }
    
    // Count shared vibes
    int sharedVibes = widget.currentUser.preferredVibes
        .intersection(widget.friend.preferredVibes)
        .length;
    
    // Calculate percentages
    double genrePercentage = widget.currentUser.preferredGenres.isEmpty || widget.friend.preferredGenres.isEmpty ? 0 :
        sharedGenres / 
        (widget.currentUser.preferredGenres.length + widget.friend.preferredGenres.length - sharedGenres);
    
    double vibePercentage = widget.currentUser.preferredVibes.isEmpty || widget.friend.preferredVibes.isEmpty ? 0 :
        sharedVibes / 
        (widget.currentUser.preferredVibes.length + widget.friend.preferredVibes.length - sharedVibes);
    
    // Calculate shared likes percentage
    double sharedLikesPercentage = 0;
    if (widget.currentUser.likedMovies.isNotEmpty || widget.friend.likedMovies.isNotEmpty) {
      sharedLikesPercentage = _sharedLikes.isEmpty ? 0 : 
          _sharedLikes.length / 
          (widget.currentUser.likedMovies.length + widget.friend.likedMovies.length - _sharedLikes.length);
    }
    
    // Weighted average (likes count more)
    return (genrePercentage * 0.3 + vibePercentage * 0.3 + sharedLikesPercentage * 0.4) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          widget.friend.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove Friend'),
              ),
            ],
            onSelected: (value) {
              if (value == 'remove') {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1F1F1F),
                    title: const Text(
                      "Remove Friend",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: Text(
                      "Are you sure you want to remove ${widget.friend.name} from your friends?",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle remove friend
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back to friends list
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          "Remove",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A00D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Friend profile card with compatibility
                  _buildProfileCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Match button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatcherScreen(
                              sessionId: sessionId,
                              allMovies: widget.allMovies,
                              currentUser: widget.currentUser,
                              friendIds: [widget.friend], // Add this line with at least the current friend
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.movie_filter, color: Colors.white),
                      label: const Text(
                        "Start Movie Matching",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A00D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Compatibility breakdown
                  const Text(
                    "Compatibility Breakdown",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // This would be a custom widget to show taste overlap
                  CompatibilityChart(
                    currentUser: widget.currentUser,
                    friend: widget.friend,
                    sharedLikes: _sharedLikes,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Movie recommendations section
                  const Text(
                    "Movies You Might Both Enjoy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Movie recommendations grid
                  _recommendedMovies.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              "Like more movies to get recommendations!",
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _buildRecommendationsGrid(),
                  
                  const SizedBox(height: 24),
                  
                  // Shared liked movies section
                  const Text(
                    "Movies You Both Liked",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Shared movies grid
                  _sharedLikes.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text(
                              "No shared likes yet. Start matching!",
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _buildSharedLikesGrid(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    final compatibilityScore = _compatibilityScore.round();
    
    // Determine compatibility level and color
    String compatibilityLevel;
    Color compatibilityColor;
    
    if (compatibilityScore >= 80) {
      compatibilityLevel = "Excellent";
      compatibilityColor = Colors.green;
    } else if (compatibilityScore >= 60) {
      compatibilityLevel = "Good";
      compatibilityColor = Colors.lightGreen;
    } else if (compatibilityScore >= 40) {
      compatibilityLevel = "Moderate";
      compatibilityColor = Colors.amber;
    } else if (compatibilityScore >= 20) {
      compatibilityLevel = "Fair";
      compatibilityColor = Colors.orange;
    } else {
      compatibilityLevel = "Poor";
      compatibilityColor = Colors.red;
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF1F1F1F),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // Friend avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[800],
                  child: Text(
                    widget.friend.name.isNotEmpty ? widget.friend.name[0].toUpperCase() : "?",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Compatibility info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Movie Compatibility",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Compatibility percentage
                          Text(
                            "$compatibilityScore%",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: compatibilityColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Compatibility level
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: compatibilityColor.withValues(
                                red: compatibilityColor.r.toDouble(),
                                green: compatibilityColor.g.toDouble(),
                                blue: compatibilityColor.b.toDouble(),
                                alpha: 51 // Using 0.2 * 255 = 51
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              compatibilityLevel,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: compatibilityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Shared likes stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("Shared\nGenres", _genreOverlap.entries.where((e) => e.value > 1).length),
                _buildStatColumn("Shared\nLikes", _sharedLikes.length),
                _buildStatColumn("Recommended\nMovies", _recommendedMovies.length),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE5A00D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildRecommendationsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _recommendedMovies.length,
      itemBuilder: (context, index) {
        final movie = _recommendedMovies[index];
        return _buildMovieCard(movie);
      },
    );
  }
  
  Widget _buildSharedLikesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _sharedLikes.length,
      itemBuilder: (context, index) {
        final movie = _sharedLikes[index];
        return _buildMovieCard(movie);
      },
    );
  }
  
  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () {
        // Show movie details
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                movie.posterUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white30),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            movie.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}