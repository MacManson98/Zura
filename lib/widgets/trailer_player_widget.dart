// File: lib/widgets/trailer_player_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
  bool _isDisposed = false; // Add this flag

  @override
  void initState() {
    super.initState();
    _loadTrailer();
  }

  @override
  void dispose() {
    _isDisposed = true; // Set flag before disposing
    _youtubeController?.dispose();
    _youtubeController = null; // Clear reference
    super.dispose();
  }

  Future<void> _loadTrailer() async {
    if (_isDisposed) return; // Early exit if disposed
    
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final trailer = await TrailerService.getTrailerForMovie(widget.movie.id);

      // Check if widget is still mounted AND not disposed
      if (!mounted || _isDisposed) {
        return;
      }

      if (trailer != null) {
        final controller = YoutubePlayerController(
          initialVideoId: trailer.key,
          flags: YoutubePlayerFlags(
            autoPlay: widget.autoPlay,
            mute: false,
            enableCaption: true,
            captionLanguage: 'en',
            showLiveFullscreenButton: true,
          ),
        );

        // Double-check we're still mounted and not disposed before setting state
        if (!mounted || _isDisposed) {
          // If we're disposed, clean up the controller we just created
          controller.dispose();
          return;
        }

        setState(() {
          _trailer = trailer;
          _youtubeController = controller;
          _isLoading = false;
        });
      } else {
        if (!mounted || _isDisposed) return;
        
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'No trailer available for this movie';
        });
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load trailer: $e';
      });
    }
  }

  Future<void> _openInYouTube() async {
    if (_isDisposed || _trailer == null) return; // Add disposal check
    
    final url = Uri.parse(_trailer!.youTubeUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open YouTube'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      // Return empty container if disposed
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
          onPressed: _isDisposed ? null : _loadTrailer, // Disable if disposed
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
    
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFFE5A00D),
        progressColors: ProgressBarColors(
          playedColor: const Color(0xFFE5A00D),
          handleColor: const Color(0xFFE5A00D),
        ),
      ),
      builder: (context, player) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Stack(
            children: [
              player,
              if (widget.showControls)
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
                                _trailer!.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _trailer!.type + (_trailer!.official ? ' • Official' : ''),
                                style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _openInYouTube,
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
      },
    );
  }
}