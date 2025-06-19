import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../movie.dart';

class QuickPickWidget extends StatefulWidget {
  final List<Movie> matchedMovies;
  final Function(Movie) onMovieSelected;
  
  const QuickPickWidget({
    Key? key,
    required this.matchedMovies,
    required this.onMovieSelected,
  }) : super(key: key);

  @override
  State<QuickPickWidget> createState() => _QuickPickWidgetState();
}

class _QuickPickWidgetState extends State<QuickPickWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  Movie? _selectedMovie;
  bool _isAnimating = false;
  int _currentMovieIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    // Create a curved animation that slows down at the end
    _rotationAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    
    // Listen for animation completion
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
          _selectedMovie = widget.matchedMovies[_currentMovieIndex];
        });
        
        // Notify parent about the selected movie
        if (_selectedMovie != null) {
          widget.onMovieSelected(_selectedMovie!);
        }
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _startSpin() {
    if (widget.matchedMovies.isEmpty) return;
    
    setState(() {
      _isAnimating = true;
      _selectedMovie = null;
      
      // Pick a random index to land on
      _currentMovieIndex = math.Random().nextInt(widget.matchedMovies.length);
    });
    
    // Reset and start the animation
    _animationController.reset();
    _animationController.forward();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.matchedMovies.isEmpty) {
      return _buildEmptyState();
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Can\'t decide what to watch?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Wheel animation
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) {
            return _buildWheel();
          },
        ),
        
        const SizedBox(height: 16),
        
        // Spin button
        ElevatedButton(
          onPressed: _isAnimating ? null : _startSpin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5A00D),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            disabledBackgroundColor: Colors.grey,
          ),
          child: Text(
            _isAnimating ? 'Picking...' : 'Quick Pick',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        
        // Selected movie display
        if (_selectedMovie != null && !_isAnimating)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              children: [
                const Text(
                  'Tonight\'s Pick:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedMovie!.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.movie_filter,
            color: Color(0xFFE5A00D),
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'No matched movies yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Match with your friends to find movies you all want to watch!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navigate to matching screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A00D),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Start Matching',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWheel() {
    // Calculate current rotation based on the animation
    final rotations = 5.0; // Number of full rotations
    final randomOffset = _currentMovieIndex / widget.matchedMovies.length; // Add a fraction to land on the correct movie
    final currentRotation = _rotationAnimation.value * (rotations * 2 * math.pi) + (randomOffset * 2 * math.pi);

    // Size of the wheel
    final wheelSize = 220.0;
    final itemCount = widget.matchedMovies.length;
    final anglePerItem = (2 * math.pi) / itemCount;
    
    return SizedBox(
      height: wheelSize,
      width: wheelSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Center circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE5A00D),
                width: 3,
              ),
            ),
            child: const Icon(
              Icons.movie,
              color: Color(0xFFE5A00D),
              size: 30,
            ),
          ),
          
          // Movie items positioned around the wheel
          ...List.generate(itemCount, (index) {
            // Calculate angle for this item
            final angle = index * anglePerItem;
            
            // Calculate position
            final itemRadius = wheelSize / 2 - 40; // Distance from center
            final x = itemRadius * math.cos(angle - currentRotation);
            final y = itemRadius * math.sin(angle - currentRotation);
            
            // Scale and opacity based on position (items in front are larger and more opaque)
            final scale = 0.8 + 0.2 * math.cos(angle - currentRotation).abs();
            final opacity = 0.4 + 0.6 * math.cos(angle - currentRotation).abs();
            
            return Positioned(
              left: wheelSize / 2 + x - 40, // Center the item on this position (40 is half the item size)
              top: wheelSize / 2 + y - 40,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: _buildMovieItem(widget.matchedMovies[index]),
                ),
              ),
            );
          }),
          
          // Pointer at the top
          Positioned(
            top: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFE5A00D),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_drop_down,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMovieItem(Movie movie) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE5A00D),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        movie.posterUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1F1F1F),
            child: Center(
              child: Text(
                movie.title.characters.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}