// File: lib/screens/liked_movies_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/user_profile_storage.dart';
import '../screens/movie_detail_screen.dart';
import '../utils/debug_loader.dart';
import '../utils/tmdb_api.dart'; // ✅ Added import for TMDB API

class LikedMoviesScreen extends StatefulWidget {
  final UserProfile currentUser;
  final Function(UserProfile)? onProfileUpdate;

  const LikedMoviesScreen({
    super.key,
    required this.currentUser,
    this.onProfileUpdate,
  });

  @override
  State<LikedMoviesScreen> createState() => _LikedMoviesScreenState();
}

class _LikedMoviesScreenState extends State<LikedMoviesScreen> {
  late UserProfile _profile;
  List<Movie> _displayedMovies = [];
  List<Movie> _allMovies = [];
  bool _isLoading = true;
  
  // Filter states
  String _searchQuery = '';
  String _selectedGenre = 'All';
  String _selectedDecade = 'All';
  String _sortBy = 'Recently Liked';
  
  // Available filter options
  List<String> _availableGenres = ['All'];
  List<String> _availableDecades = ['All'];
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = widget.currentUser;
    _loadLikedMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLikedMovies() async {
    setState(() => _isLoading = true);
    
    try {
      DebugLogger.log('🎬 Loading liked movies...');
      DebugLogger.log('Total liked IDs: ${_profile.likedMovieIds.length}');
      DebugLogger.log('Cached movies: ${_profile.likedMovies.length}');
      
      // Start with cached movies
      _allMovies = _profile.likedMovies.toList();
      DebugLogger.log('Starting with ${_allMovies.length} cached movies');
      
      // Check for missing movie data
      final missingIds = _profile.getMissingLikedMovieIds();
      DebugLogger.log('Missing movie IDs: ${missingIds.length}');
      
      if (missingIds.isNotEmpty) {
        DebugLogger.log('🔄 Fetching ${missingIds.length} missing movies from TMDB...');
        
        // Fetch missing movies from TMDB
        final missingMovies = await TMDBApi.getMoviesByIds(missingIds.toList());
        DebugLogger.log('✅ Fetched ${missingMovies.length} movies from TMDB');
        
        if (missingMovies.isNotEmpty) {
          // Load them into cache
          _profile.loadMoviesIntoCache(missingMovies);
          
          // Add to our display list
          _allMovies.addAll(missingMovies);
          
          // Save updated profile with new cached data
          if (widget.onProfileUpdate != null) {
            widget.onProfileUpdate!(_profile);
          }
          await UserProfileStorage.saveProfile(_profile);
          
          DebugLogger.log('💾 Saved ${missingMovies.length} movies to cache');
        }
        
        // Check if we still have missing data
        final stillMissing = _profile.likedMovieIds.length - _allMovies.length;
        if (stillMissing > 0) {
          DebugLogger.log('⚠️ Still missing $stillMissing movies after TMDB fetch');
        }
      }
      
      DebugLogger.log('📊 Final movie count: ${_allMovies.length}');
      
      // Build filter options from all available movie data
      _buildFilterOptions();
      
      // Apply initial filtering
      _applyFilters();
      
    } catch (e) {
      DebugLogger.log('❌ Error loading liked movies: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _buildFilterOptions() {
    // Extract unique genres
    final allGenres = <String>{};
    final allDecades = <String>{};
    
    for (final movie in _allMovies) {
      allGenres.addAll(movie.genres);
      
      if (movie.releaseDate != null && movie.releaseDate!.isNotEmpty) {
        try {
          final year = DateTime.parse(movie.releaseDate!).year;
          final decade = '${(year ~/ 10) * 10}s';
          allDecades.add(decade);
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    
    _availableGenres = ['All', ...allGenres.toList()..sort()];
    _availableDecades = ['All', ...allDecades.toList()..sort((a, b) => b.compareTo(a))]; // Newest first
  }

  void _applyFilters() {
    List<Movie> filtered = List.from(_allMovies);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((movie) {
        return movie.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               movie.overview.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               movie.cast.any((actor) => actor.toLowerCase().contains(_searchQuery.toLowerCase())) ||
               movie.directors.any((director) => director.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }
    
    // Genre filter
    if (_selectedGenre != 'All') {
      filtered = filtered.where((movie) => movie.genres.contains(_selectedGenre)).toList();
    }
    
    // Decade filter
    if (_selectedDecade != 'All') {
      filtered = filtered.where((movie) {
        if (movie.releaseDate == null || movie.releaseDate!.isEmpty) return false;
        try {
          final year = DateTime.parse(movie.releaseDate!).year;
          final decade = '${(year ~/ 10) * 10}s';
          return decade == _selectedDecade;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    // Sort
    switch (_sortBy) {
      case 'Recently Liked':
        // Sort by newest release date as proxy
        filtered.sort((a, b) {
          if (a.releaseDate == null) return 1;
          if (b.releaseDate == null) return -1;
          return b.releaseDate!.compareTo(a.releaseDate!);
        });
        break;
      case 'Alphabetical':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Rating High':
        filtered.sort((a, b) {
          final aRating = a.rating ?? 0.0;
          final bRating = b.rating ?? 0.0;
          return bRating.compareTo(aRating);
        });
        break;
      case 'Rating Low':
        filtered.sort((a, b) {
          final aRating = a.rating ?? 0.0;
          final bRating = b.rating ?? 0.0;
          return aRating.compareTo(bRating);
        });
        break;
    }
    
    setState(() {
      _displayedMovies = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(
          'Liked Movies',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: Stack(
              children: [
                Icon(Icons.tune, color: Colors.white, size: 24.sp),
                if (_hasActiveFilters())
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5A00D),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          
          // Quick filter chips
          _buildQuickFilterChips(),
          
          // Stats and sort
          _buildStatsAndSort(),
          
          // Movies grid/list
          Expanded(
            child: _isLoading 
                ? _buildLoadingState()
                : _displayedMovies.isEmpty 
                    ? _buildEmptyState()
                    : _buildMoviesGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: 'Search your liked movies...',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 16.sp),
          prefixIcon: Icon(Icons.search, color: Colors.white54, size: 20.sp),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                  icon: Icon(Icons.clear, color: Colors.white54, size: 20.sp),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF1F1F1F),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: const Color(0xFFE5A00D), width: 2.w),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _buildFilterChip(
            label: _selectedGenre == 'All' ? 'Genre' : _selectedGenre,
            isActive: _selectedGenre != 'All',
            onTap: () => _showGenrePicker(),
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            label: _selectedDecade == 'All' ? 'Decade' : _selectedDecade,
            isActive: _selectedDecade != 'All',
            onTap: () => _showDecadePicker(),
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            label: _sortBy,
            isActive: _sortBy != 'Recently Liked',
            onTap: () => _showSortPicker(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE5A00D) : const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(25.r),
          border: Border.all(
            color: isActive ? const Color(0xFFE5A00D) : Colors.white30,
            width: 1.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down,
              color: isActive ? Colors.black : Colors.white,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsAndSort() {
    final totalLikedIds = _profile.likedMovieIds.length;
    final loadedMovieCount = _allMovies.length;
    
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        children: [
          // Main stats row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loadedMovieCount < totalLikedIds)
                    Text(
                      '$totalLikedIds total liked • ${totalLikedIds - loadedMovieCount} couldn\'t load',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12.sp,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              if (_hasActiveFilters())
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(
                    'Clear filters',
                    style: TextStyle(
                      color: const Color(0xFFE5A00D),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
            ],
          ),
          
          // Info about missing movies
          if (loadedMovieCount < totalLikedIds) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 16.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Some movies couldn\'t be loaded from the database. This is normal for older likes.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: const Color(0xFFE5A00D),
            strokeWidth: 3.w,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading your liked movies...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'This may take a moment for the first load',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _hasActiveFilters();
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off : Icons.favorite_border,
              size: 64.sp,
              color: Colors.white30,
            ),
            SizedBox(height: 24.h),
            Text(
              hasFilters 
                  ? 'No movies match your filters'
                  : 'No liked movies yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters'
                  : 'Start swiping to build your movie collection!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: _clearAllFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A00D),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Clear All Filters',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoviesGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
      ),
      itemCount: _displayedMovies.length,
      itemBuilder: (context, index) {
        final movie = _displayedMovies[index];
        return _buildMovieCard(movie);
      },
    );
  }

  Widget _buildMovieCard(Movie movie) {
    return GestureDetector(
      onTap: () => _showMovieDetails(movie),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster image
              Image.network(
                movie.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1F1F1F),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie,
                          size: 40.sp,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'No Image',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),
              
              // Movie info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          if (movie.rating != null) ...[
                            Icon(Icons.star, color: Colors.amber, size: 12.sp),
                            SizedBox(width: 2.w),
                            Text(
                              movie.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                          ],
                          if (movie.releaseDate != null)
                            Text(
                              _getYearFromDate(movie.releaseDate!),
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.sp,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Remove button
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: () => _showRemoveDialog(movie),
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || 
           _selectedGenre != 'All' || 
           _selectedDecade != 'All' ||
           _sortBy != 'Recently Liked';
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedGenre = 'All';
      _selectedDecade = 'All';
      _sortBy = 'Recently Liked';
    });
    _searchController.clear();
    _applyFilters();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Text(
                    'Filter Movies',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _clearAllFilters();
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        color: const Color(0xFFE5A00D),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Filter options
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  _buildFilterSection('Genre', _availableGenres, _selectedGenre, (value) {
                    setState(() => _selectedGenre = value);
                    _applyFilters();
                  }),
                  
                  _buildFilterSection('Decade', _availableDecades, _selectedDecade, (value) {
                    setState(() => _selectedDecade = value);
                    _applyFilters();
                  }),
                  
                  _buildFilterSection('Sort By', [
                    'Recently Liked',
                    'Alphabetical', 
                    'Rating High',
                    'Rating Low'
                  ], _sortBy, (value) {
                    setState(() => _sortBy = value);
                    _applyFilters();
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((option) {
            final isSelected = option == selected;
            return GestureDetector(
              onTap: () => onSelect(option),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE5A00D) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFE5A00D) : Colors.white30,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 14.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  void _showGenrePicker() {
    _showPickerDialog('Select Genre', _availableGenres, _selectedGenre, (value) {
      setState(() => _selectedGenre = value);
      _applyFilters();
    });
  }

  void _showDecadePicker() {
    _showPickerDialog('Select Decade', _availableDecades, _selectedDecade, (value) {
      setState(() => _selectedDecade = value);
      _applyFilters();
    });
  }

  void _showSortPicker() {
    _showPickerDialog('Sort By', [
      'Recently Liked',
      'Alphabetical',
      'Rating High',
      'Rating Low'
    ], _sortBy, (value) {
      setState(() => _sortBy = value);
      _applyFilters();
    });
  }

  void _showPickerDialog(String title, List<String> options, String selected, Function(String) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              final option = options[index];
              final isSelected = option == selected;
              return ListTile(
                title: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFFE5A00D) : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: const Color(0xFFE5A00D)) : null,
                onTap: () {
                  onSelect(option);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showMovieDetails(Movie movie) {
    showMovieDetails(
      context: context,
      movie: movie,
      currentUser: _profile,
      isInFavorites: true,
      onRemoveFromFavorites: (movie) => _removeFromLiked(movie),
    );
  }

  void _showRemoveDialog(Movie movie) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text('Remove Movie', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        content: Text(
          'Remove "${movie.title}" from your liked movies?',
          style: TextStyle(color: Colors.white70, fontSize: 16.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromLiked(movie);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeFromLiked(Movie movie) async {
    try {
      // Remove from profile's liked movies
      _profile.likedMovieIds.remove(movie.id);
      
      // Create a new profile with updated liked movies cache
      final updatedLikedMovies = _profile.likedMovies.where((m) => m.id != movie.id).toSet();
      _profile.likedMovies = updatedLikedMovies;
      
      // Update UI
      _allMovies.removeWhere((m) => m.id == movie.id);
      _applyFilters();
      
      // Save to storage
      if (widget.onProfileUpdate != null) {
        widget.onProfileUpdate!(_profile);
      }
      await UserProfileStorage.saveProfile(_profile);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed "${movie.title}" from liked movies'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      DebugLogger.log('Error removing liked movie: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing movie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getYearFromDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return date.year.toString();
    } catch (e) {
      return dateString;
    }
  }
}