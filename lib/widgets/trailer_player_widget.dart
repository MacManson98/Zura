// File: lib/widgets/trailer_player_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
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
  YoutubePlayerController? _youtubeController;
  MovieTrailer? _trailer;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isDisposed = false;
  
  // ✅ ADD: Debounce mechanism to prevent rapid recreation
  bool _isCreatingController = false;

  @override
  void initState() {
    super.initState();
    _loadTrailer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeController();
    super.dispose();
  }

  // ✅ IMPROVED: Better controller disposal
  void _disposeController() {
    if (_youtubeController != null) {
      try {
        // Give the controller time to clean up properly
        Future.microtask(() {
          try {
            _youtubeController?.close();
          } catch (e) {
            // Silently ignore disposal errors
            debugPrint('YouTube disposal: $e');
          }
        });
      } catch (e) {
        // Ignore any synchronous disposal errors
      }
      _youtubeController = null;
    }
  }

  Future<void> _loadTrailer() async {
    if (_isDisposed || _isCreatingController) return;
    
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
        await _createYouTubeController(trailer);
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

  // ✅ IMPROVED: Better controller creation with debouncing
  Future<void> _createYouTubeController(MovieTrailer trailer) async {
    if (_isDisposed || _isCreatingController) return;
    
    _isCreatingController = true;
    
    try {
      // ✅ ADD: Small delay to prevent rapid recreation
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted || _isDisposed) {
        _isCreatingController = false;
        return;
      }

      // Dispose existing controller first
      _disposeController();
      
      // ✅ IMPROVED: Better YouTube player configuration
      final controller = YoutubePlayerController.fromVideoId(
        videoId: trailer.key,
        autoPlay: false, // Always start paused to reduce errors
        params: const YoutubePlayerParams(
          mute: true, // Start muted to reduce audio issues
          showControls: true,
          showFullscreenButton: true,
          enableCaption: false, // Disable captions to reduce errors
          strictRelatedVideos: true,
          enableJavaScript: true,
          playsInline: true, // Better mobile support
          showVideoAnnotations: false, // Reduce errors
        ),
      );

      if (!mounted || _isDisposed) {
        try {
          controller.close();
        } catch (e) {
          // Ignore disposal errors
        }
        _isCreatingController = false;
        return;
      }

      try {
        setState(() {
          _trailer = trailer;
          _youtubeController = controller;
          _isLoading = false;
          _hasError = false;
        });
      } catch (e) {
        try {
          controller.close();
        } catch (e) {
          // Ignore disposal errors
        }
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      
      try {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to create video player';
        });
      } catch (e) {
        // Widget was disposed during setState
      }
    } finally {
      _isCreatingController = false;
    }
  }

  Future<void> _openInYouTube() async {
    if (_isDisposed || _trailer == null) return;
    
    final url = Uri.parse(_trailer!.youTubeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted && !_isDisposed) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open YouTube'),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          // Context might be invalid if disposed
        }
      }
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
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isDisposed) return _buildNoTrailerState();
    if (_isLoading) return _buildLoadingState();
    if (_hasError) return _buildErrorState();
    if (_youtubeController != null && _trailer != null) return _buildPlayerState();
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
          'Loading trailer...',
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
          'No trailer available',
          style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          'This movie doesn\'t have a trailer',
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _buildPlayerState() {
    if (_isDisposed || _youtubeController == null) {
      return _buildNoTrailerState();
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        children: [
          // ✅ IMPROVED: Wrap YouTube player in error boundary
          Container(
            width: double.infinity,
            height: double.infinity,
            child: YoutubePlayer(
              controller: _youtubeController!,
              aspectRatio: 16 / 9,
            ),
          ),
          
          // Custom overlay with trailer info and controls
          if (widget.showControls && !_isDisposed)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _trailer?.name ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            (_trailer?.type ?? '') + ((_trailer?.official ?? false) ? ' • Official' : ''),
                            style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _isDisposed ? null : _openInYouTube,
                      icon: Icon(Icons.open_in_new, color: Colors.white, size: 20.sp),
                      tooltip: 'Open in YouTube',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}