// File: lib/widgets/trailer_player_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:youtube_player_iframe/youtube_player_iframe.dart'; // ← REMOVED - This was causing crashes
import 'package:url_launcher/url_launcher.dart';
import '../services/trailer_service.dart';
import '../movie.dart';

class TrailerPlayerWidget extends StatefulWidget {
  final Movie movie;
  final bool autoPlay;
  final bool showControls;

  const TrailerPlayerWidget({
    Key? key,
    required this.movie,
    this.autoPlay = false,
    this.showControls = true,
  }) : super(key: key);

  @override
  State<TrailerPlayerWidget> createState() => _TrailerPlayerWidgetState();
}

class _TrailerPlayerWidgetState extends State<TrailerPlayerWidget> {
  // YoutubePlayerController? _youtubeController; // ← REMOVED - No more YouTube controller
  MovieTrailer? _trailer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadTrailer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    // No more controller to dispose - safer!
    super.dispose();
  }

  Future<void> _loadTrailer() async {
    if (_isDisposed) return;
    
    try {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }
    } catch (e) {
      return;
    }

    try {
      final trailer = await TrailerService.getTrailerForMovie(widget.movie.id);

      if (!mounted || _isDisposed) return;

      if (trailer != null) {
        // No controller creation - just store the trailer data
        try {
          setState(() {
            _trailer = trailer;
            _isLoading = false;
            _hasError = false;
          });
        } catch (e) {
          // Widget was disposed during setState
        }
      } else {
        if (!mounted || _isDisposed) return;
        
        try {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'No trailer available for this movie';
          });
        } catch (e) {
          // Widget was disposed during setState
        }
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      
      try {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load trailer';
        });
      } catch (e) {
        // Widget was disposed during setState
      }
    }
  }

  Future<void> _openInYouTube() async {
    if (_isDisposed || _trailer == null) return;
    
    try {
      final url = Uri.parse(_trailer!.youTubeUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted && !_isDisposed) {
          _showErrorSnackbar('Could not open YouTube');
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        _showErrorSnackbar('Error opening trailer');
      }
    }
  }

  Future<void> _searchYouTubeTrailer() async {
    if (_isDisposed) return;
    
    try {
      final query = Uri.encodeComponent('${widget.movie.title} trailer');
      final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted && !_isDisposed) {
          _showErrorSnackbar('Could not open YouTube');
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        _showErrorSnackbar('Error searching for trailer');
      }
    }
  }

  void _showErrorSnackbar(String message) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Context might be invalid if disposed
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return Container(
        width: double.infinity,
        height: 200.h,
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(12.r),
        ),
      );
    }
    
    return Container(
      width: double.infinity,
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isDisposed) return _buildNoTrailerState();
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();
    if (_trailer != null) return _buildTrailerFoundState();
    return _buildNoTrailerState();
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: const Color(0xFFE5A00D),
          strokeWidth: 2.w,
        ),
        SizedBox(height: 16.h),
        Text(
          'Finding trailer...',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: Colors.white54, size: 48.sp),
        SizedBox(height: 16.h),
        Text(
          _errorMessage ?? 'Failed to load trailer',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isDisposed ? null : _loadTrailer,
              icon: Icon(Icons.refresh, size: 16.sp),
              label: Text('Retry', style: TextStyle(fontSize: 14.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE5A00D),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
            ),
            SizedBox(width: 12.w),
            OutlinedButton.icon(
              onPressed: _isDisposed ? null : _searchYouTubeTrailer,
              icon: Icon(Icons.search, size: 16.sp),
              label: Text('Search YouTube', style: TextStyle(fontSize: 14.sp)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white30),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoTrailerState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.movie_outlined, color: Colors.white54, size: 48.sp),
        SizedBox(height: 16.h),
        Text(
          'No trailer found',
          style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          'But you can search for one!',
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        SizedBox(height: 16.h),
        ElevatedButton.icon(
          onPressed: _isDisposed ? null : _searchYouTubeTrailer,
          icon: Icon(Icons.search, size: 20.sp),
          label: Text('Search on YouTube', style: TextStyle(fontSize: 14.sp)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrailerFoundState() {
    if (_isDisposed || _trailer == null) {
      return _buildNoTrailerState();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        children: [
          // Beautiful gradient background instead of video player
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.withValues(alpha: 0.8),
                  Colors.red.withValues(alpha: 0.6),
                  Colors.orange.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
          
          // Play button and info overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large play button
                Container(
                  width: 80.w,
                  height: 80.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(40.r),
                      onTap: _isDisposed ? null : _openInYouTube,
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.red,
                        size: 48.sp,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 16.h),
                
                // Trailer title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    _trailer!.name.isNotEmpty 
                        ? _trailer!.name 
                        : '${widget.movie.title} Trailer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Trailer type and official badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_trailer!.type.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _trailer!.type.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    if (_trailer!.official) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'OFFICIAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // Watch button
                ElevatedButton.icon(
                  onPressed: _isDisposed ? null : _openInYouTube,
                  icon: Icon(Icons.open_in_new, size: 16.sp),
                  label: Text(
                    'Watch on YouTube',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
          
          // Info button in corner
          if (widget.showControls && !_isDisposed)
            Positioned(
              top: 12.h,
              right: 12.w,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isDisposed ? null : _openInYouTube,
                  icon: Icon(Icons.info_outline, color: Colors.white, size: 20.sp),
                  tooltip: 'Trailer Info',
                ),
              ),
            ),
        ],
      ),
    );
  }
}