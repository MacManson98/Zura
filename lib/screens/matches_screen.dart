// File: lib/screens/matches_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../movie.dart';
import '../models/user_profile.dart';
import '../utils/user_profile_storage.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/watch_options_screen.dart';
import '../utils/debug_loader.dart';
import '../utils/tmdb_api.dart';
import 'package:intl/intl.dart';

class MatchesScreen extends StatefulWidget {
  final UserProfile currentUser;
  final Function(UserProfile)? onProfileUpdate;

  const MatchesScreen({
    super.key,
    required this.currentUser,
    this.onProfileUpdate,
  });

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  late UserProfile _profile;
  List<MatchData> _displayedMatches = [];
  List<MatchData> _allMatches = [];
  bool _isLoading = true;
  
  // Filter states
  String _searchQuery = '';
  String _selectedGenre = 'All';
  String _selectedPartner = 'All';
  String _selectedStatus = 'All'; // All, Watched, Not Watched
  String _sortBy = 'Recent'; // Recent, Oldest, Alphabetical, Rating
  
  // Available filter options
  List<String> _availableGenres = ['All'];
  List<String> _availablePartners = ['All'];
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profile = widget.currentUser;
    _loadMatches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    
    try {
      DebugLogger.log('🎯 Loading matches...');
      DebugLogger.log('Total match history entries: ${_profile.matchHistory.length}');
      
      // Collect all movie IDs we need from match history
      final movieIds = <String>{};
      for (final match in _profile.matchHistory) {
        if (match['movieId'] != null) {
          movieIds.add(match['movieId']);
        }
      }
      
      DebugLogger.log('Unique movie IDs needed: ${movieIds.length}');
      
      // Get movies we already have cached
      final Map<String, Movie> availableMovies = {};
      
      // Check both liked and matched movie caches
      for (final movie in _profile.likedMovies) {
        if (movieIds.contains(movie.id)) {
          availableMovies[movie.id] = movie;
        }
      }
      
      for (final movie in _profile.matchedMovies) {
        if (movieIds.contains(movie.id)) {
          availableMovies[movie.id] = movie;
        }
      }
      
      DebugLogger.log('Movies available in cache: ${availableMovies.length}');
      
      // Find missing movie IDs
      final missingIds = movieIds.difference(availableMovies.keys.toSet());
      DebugLogger.log('Missing movie IDs: ${missingIds.length}');
      
      if (missingIds.isNotEmpty) {
        DebugLogger.log('🔄 Fetching ${missingIds.length} missing movies from TMDB...');
        
        // Fetch missing movies from TMDB
        final missingMovies = await TMDBApi.getMoviesByIds(missingIds.toList());
        DebugLogger.log('✅ Fetched ${missingMovies.length} movies from TMDB');
        
        if (missingMovies.isNotEmpty) {
          // Add them to our available movies
          for (final movie in missingMovies) {
            availableMovies[movie.id] = movie;
          }
          
          // Load them into cache (they'll be categorized as liked or matched as appropriate)
          _profile.loadMoviesIntoCache(missingMovies);
          
          // Save updated profile with new cached data
          if (widget.onProfileUpdate != null) {
            widget.onProfileUpdate!(_profile);
          }
          await UserProfileStorage.saveProfile(_profile);
          
          DebugLogger.log('💾 Saved ${missingMovies.length} movies to cache');
        }
      }
      
      // Now create MatchData objects for all matches where we have movie data
      final matchDataList = <MatchData>[];
      int skippedMatches = 0;
      
      for (final match in _profile.matchHistory) {
        final movieId = match['movieId'];
        final movie = availableMovies[movieId];
        
        if (movie != null) {
          // Handle different date formats (String or Timestamp)
          DateTime matchDate = DateTime.now();
          final rawDate = match['matchDate'];
          
          if (rawDate != null) {
            if (rawDate is String) {
              matchDate = DateTime.tryParse(rawDate) ?? DateTime.now();
            } else if (rawDate is Timestamp) {
              matchDate = rawDate.toDate();
            } else {
              // Try to convert other types to string first
              try {
                matchDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
              } catch (e) {
                DebugLogger.log('Could not parse date: $rawDate, using current time');
                matchDate = DateTime.now();
              }
            }
          }
          
          // Handle archivedDate similarly
          DateTime? archivedDate;
          final rawArchivedDate = match['archivedDate'];
          if (rawArchivedDate != null) {
            if (rawArchivedDate is String) {
              archivedDate = DateTime.tryParse(rawArchivedDate);
            } else if (rawArchivedDate is Timestamp) {
              archivedDate = rawArchivedDate.toDate();
            }
          }
          
          matchDataList.add(MatchData(
            movie: movie,
            partnerName: match['username'] ?? 'Unknown',
            matchDate: matchDate,
            watched: match['watched'] ?? false,
            archived: match['archived'] ?? false,
            groupName: match['groupName'],
            archivedDate: archivedDate,
          ));
        } else {
          skippedMatches++;
          DebugLogger.log('Skipping match for missing movie: $movieId');
        }
      }
      
      _allMatches = matchDataList;
      
      DebugLogger.log('📊 Created ${matchDataList.length} matches, skipped $skippedMatches');
      
      // Show info if some matches are missing movie data
      if (skippedMatches > 0) {
        DebugLogger.log('⚠️ Skipped $skippedMatches matches due to missing movie data');
      }
      
      // Build filter options
      _buildFilterOptions();
      
      // Apply initial filtering
      _applyFilters();
      
    } catch (e) {
      DebugLogger.log('❌ Error loading matches: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _buildFilterOptions() {
    // Extract unique genres and partners
    final allGenres = <String>{};
    final allPartners = <String>{};
    
    for (final match in _allMatches) {
      allGenres.addAll(match.movie.genres);
      allPartners.add(match.partnerName);
    }
    
    _availableGenres = ['All', ...allGenres.toList()..sort()];
    _availablePartners = ['All', ...allPartners.toList()..sort()];
  }

  void _applyFilters() {
    List<MatchData> filtered = List.from(_allMatches);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((match) {
        return match.movie.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               match.partnerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               match.movie.overview.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Genre filter
    if (_selectedGenre != 'All') {
      filtered = filtered.where((match) => match.movie.genres.contains(_selectedGenre)).toList();
    }
    
    // Partner filter
    if (_selectedPartner != 'All') {
      filtered = filtered.where((match) => match.partnerName == _selectedPartner).toList();
    }
    
    // Status filter
    if (_selectedStatus != 'All') {
      if (_selectedStatus == 'Watched') {
        filtered = filtered.where((match) => match.watched).toList();
      } else if (_selectedStatus == 'Not Watched') {
        filtered = filtered.where((match) => !match.watched).toList();
      }
    }
    
    // Sort
    switch (_sortBy) {
      case 'Recent':
        filtered.sort((a, b) => b.matchDate.compareTo(a.matchDate));
        break;
      case 'Oldest':
        filtered.sort((a, b) => a.matchDate.compareTo(b.matchDate));
        break;
      case 'Alphabetical':
        filtered.sort((a, b) => a.movie.title.compareTo(b.movie.title));
        break;
      case 'Rating':
        filtered.sort((a, b) {
          final aRating = a.movie.rating ?? 0.0;
          final bRating = b.movie.rating ?? 0.0;
          return bRating.compareTo(aRating);
        });
        break;
    }
    
    setState(() {
      _displayedMatches = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: Text(
          'Your Matches',
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
          
          // Stats and summary
          _buildStatsSection(),
          
          // Matches list
          Expanded(
            child: _isLoading 
                ? _buildLoadingState()
                : _displayedMatches.isEmpty 
                    ? _buildEmptyState()
                    : _buildMatchesList(),
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
          hintText: 'Search matches...',
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
            label: _selectedPartner == 'All' ? 'Partner' : _selectedPartner,
            isActive: _selectedPartner != 'All',
            onTap: () => _showPartnerPicker(),
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            label: _selectedStatus == 'All' ? 'Status' : _selectedStatus,
            isActive: _selectedStatus != 'All',
            onTap: () => _showStatusPicker(),
          ),
          SizedBox(width: 8.w),
          _buildFilterChip(
            label: _sortBy,
            isActive: _sortBy != 'Recent',
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

  Widget _buildStatsSection() {
    final watchedCount = _displayedMatches.where((m) => m.watched).length;
    final notWatchedCount = _displayedMatches.length - watchedCount;
    final totalMatchHistoryCount = _profile.matchHistory.length;
    
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_displayedMatches.length} of ${_allMatches.length} matches shown',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp,
                    ),
                  ),
                  if (_allMatches.length < totalMatchHistoryCount)
                    Text(
                      '$totalMatchHistoryCount total • ${totalMatchHistoryCount - _allMatches.length} missing movie details',
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
          
          // Quick stats
          if (_displayedMatches.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                _buildQuickStat(
                  icon: Icons.check_circle,
                  label: 'Watched',
                  count: watchedCount,
                  color: Colors.green,
                ),
                SizedBox(width: 16.w),
                _buildQuickStat(
                  icon: Icons.radio_button_unchecked,
                  label: 'To Watch',
                  count: notWatchedCount,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16.sp),
        SizedBox(width: 4.w),
        Text(
          '$count $label',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
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
            'Loading your matches...',
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
              hasFilters ? Icons.search_off : Icons.movie_filter_outlined,
              size: 64.sp,
              color: Colors.white30,
            ),
            SizedBox(height: 24.h),
            Text(
              hasFilters 
                  ? 'No matches found'
                  : 'No matches yet',
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
                  : 'Start swiping with friends to find movie matches!',
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

  Widget _buildMatchesList() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _displayedMatches.length,
      itemBuilder: (context, index) {
        final match = _displayedMatches[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(MatchData match) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMatchDetails(match),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Movie poster
              Container(
                width: 80.w,
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4.r,
                      offset: Offset(0, 2.h),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    match.movie.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFF2A2A2A),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.movie,
                              size: 24.sp,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'No Image',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              SizedBox(width: 16.w),
              
              // Movie details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            match.movie.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusBadge(match),
                      ],
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    // Partner and date
                    Row(
                      children: [
                        Icon(Icons.people, color: const Color(0xFFE5A00D), size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'with ${match.partnerName}',
                          style: TextStyle(
                            color: const Color(0xFFE5A00D),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 4.h),
                    
                    Text(
                      'Matched ${_formatDate(match.matchDate)}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12.sp,
                      ),
                    ),
                    
                    SizedBox(height: 8.h),
                    
                    // Movie info
                    Row(
                      children: [
                        if (match.movie.rating != null) ...[
                          Icon(Icons.star, color: Colors.amber, size: 12.sp),
                          SizedBox(width: 2.w),
                          Text(
                            match.movie.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                        ],
                        if (match.movie.releaseDate != null)
                          Text(
                            _getYearFromDate(match.movie.releaseDate!),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.sp,
                            ),
                          ),
                      ],
                    ),
                    
                    if (match.movie.genres.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 4.w,
                        children: match.movie.genres.take(2).map((genre) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.sp,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action button
              Column(
                children: [
                  IconButton(
                    onPressed: () => _showWatchOptions(match),
                    icon: Icon(
                      Icons.play_circle_fill,
                      color: const Color(0xFFE5A00D),
                      size: 32.sp,
                    ),
                  ),
                  Text(
                    'Watch',
                    style: TextStyle(
                      color: const Color(0xFFE5A00D),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MatchData match) {
    if (match.watched) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.green, width: 1.w),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Colors.green, size: 12.sp),
            SizedBox(width: 2.w),
            Text(
              'Watched',
              style: TextStyle(
                color: Colors.green,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.orange, width: 1.w),
        ),
        child: Text(
          'To Watch',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  // Helper methods
  bool _hasActiveFilters() {
    return _searchQuery.isNotEmpty || 
           _selectedGenre != 'All' || 
           _selectedPartner != 'All' ||
           _selectedStatus != 'All' ||
           _sortBy != 'Recent';
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedGenre = 'All';
      _selectedPartner = 'All';
      _selectedStatus = 'All';
      _sortBy = 'Recent';
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
                    'Filter Matches',
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
                  
                  _buildFilterSection('Partner', _availablePartners, _selectedPartner, (value) {
                    setState(() => _selectedPartner = value);
                    _applyFilters();
                  }),
                  
                  _buildFilterSection('Status', ['All', 'Watched', 'Not Watched'], _selectedStatus, (value) {
                    setState(() => _selectedStatus = value);
                    _applyFilters();
                  }),
                  
                  _buildFilterSection('Sort By', [
                    'Recent',
                    'Oldest',
                    'Alphabetical', 
                    'Rating'
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

  void _showPartnerPicker() {
    _showPickerDialog('Select Partner', _availablePartners, _selectedPartner, (value) {
      setState(() => _selectedPartner = value);
      _applyFilters();
    });
  }

  void _showStatusPicker() {
    _showPickerDialog('Select Status', ['All', 'Watched', 'Not Watched'], _selectedStatus, (value) {
      setState(() => _selectedStatus = value);
      _applyFilters();
    });
  }

  void _showSortPicker() {
    _showPickerDialog('Sort By', [
      'Recent',
      'Oldest',
      'Alphabetical',
      'Rating'
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

  void _showMatchDetails(MatchData match) {
    showMovieDetails(
      context: context,
      movie: match.movie,
      currentUser: _profile,
      isInFavorites: _profile.likedMovieIds.contains(match.movie.id),
      onAddToFavorites: (movie) => _addToFavorites(movie),
      onMarkAsWatched: (movie) => _markAsWatched(match),
    );
  }

  void _showWatchOptions(MatchData match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WatchOptionsScreen(
          movie: match.movie,
          currentUser: _profile,
          matchedName: match.partnerName,
        ),
      ),
    );
  }

  Future<void> _addToFavorites(Movie movie) async {
    try {
      _profile.addLikedMovie(movie);
      
      if (widget.onProfileUpdate != null) {
        widget.onProfileUpdate!(_profile);
      }
      await UserProfileStorage.saveProfile(_profile);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${movie.title}" to favorites'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      DebugLogger.log('Error adding to favorites: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAsWatched(MatchData match) async {
    try {
      // Update the match in the profile's match history
      final matchIndex = _profile.matchHistory.indexWhere(
        (m) => m['movieId'] == match.movie.id && m['username'] == match.partnerName,
      );
      
      if (matchIndex != -1) {
        _profile.matchHistory[matchIndex]['watched'] = true;
        _profile.matchHistory[matchIndex]['watchedDate'] = DateTime.now().toIso8601String();
        
        // Update local state
        match.watched = true;
        _applyFilters();
        
        if (widget.onProfileUpdate != null) {
          widget.onProfileUpdate!(_profile);
        }
        await UserProfileStorage.saveProfile(_profile);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked "${match.movie.title}" as watched'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      DebugLogger.log('Error marking as watched: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
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

// Data class to represent a match with all its details
class MatchData {
  final Movie movie;
  final String partnerName;
  final DateTime matchDate;
  bool watched;
  final bool archived;
  final String? groupName;
  final DateTime? archivedDate;

  MatchData({
    required this.movie,
    required this.partnerName,
    required this.matchDate,
    this.watched = false,
    this.archived = false,
    this.groupName,
    this.archivedDate,
  });
}