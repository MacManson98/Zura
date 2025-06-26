// File: lib/widgets/minigames_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/minigame_models.dart';
import '../../utils/minigame_manager.dart';
import '../../movie.dart';
import '../../utils/themed_notifications.dart';
import 'emoji_movie_game.dart';

class MinigamesSection extends StatefulWidget {
  final List<Movie> movies;

  const MinigamesSection({
    super.key,
    required this.movies,
  });

  @override
  State<MinigamesSection> createState() => _MinigamesSectionState();
}

class _MinigamesSectionState extends State<MinigamesSection> 
    with TickerProviderStateMixin {
  List<MinigameChallenge> challenges = [];
  late AnimationController _streakController;
  late Animation<double> _streakAnimation;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    
    _streakController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _streakAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _streakController,
      curve: Curves.elasticOut,
    ));
    
    // Animate streak if > 0
    if (MinigameManager.stats.currentStreak > 0) {
      _streakController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _streakController.dispose();
    super.dispose();
  }

  void _loadChallenges() {
    setState(() {
      challenges = MinigameManager.getActiveChallenges();
    });
  }

  void _launchGame(MinigameChallenge challenge) async {
    Widget gameWidget;
    
    switch (challenge.type) {
      case GameType.emojiGuess:
        gameWidget = EmojiMovieGame(
          movies: widget.movies,
          onExit: () {
            Navigator.pop(context);
            _loadChallenges(); // Refresh after game
          },
          onGameComplete: (score, completed) async {
            await MinigameManager.updateProgress(
              challenge.id, 
              score, 
              completed
            );
            _loadChallenges();
          },
        );
        break;
      default:
        ThemedNotifications.showInfo(
          context,
          '${challenge.title} coming soon!',
          icon: '🎮',
        );
        return;
    }
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => gameWidget),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with Stats
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE5A00D),
                      const Color(0xFFFF8A00),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.games,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Challenges',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${MinigameManager.stats.totalPoints} points earned',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Streak indicator
              if (MinigameManager.stats.currentStreak > 0)
                AnimatedBuilder(
                  animation: _streakAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _streakAnimation.value,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange,
                              Colors.deepOrange,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🔥',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${MinigameManager.stats.currentStreak}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          
          SizedBox(height: 16.h),
          
          // Challenge Cards
          SizedBox(
            height: 140.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                final status = MinigameManager.getChallengeStatus(challenge);
                final progress = MinigameManager.getProgress(challenge.id);
                
                return _buildChallengeCard(challenge, status, progress);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    MinigameChallenge challenge, 
    GameStatus status, 
    GameProgress? progress
  ) {
    // Determine card colors and state
    Color borderColor = Colors.grey.withValues(alpha: 0.3);
    Color backgroundColor = const Color(0xFF1F1F1F);
    IconData? statusIcon;
    Color? statusIconColor;
    String? statusText;
    
    switch (status) {
      case GameStatus.completed:
        borderColor = Colors.green;
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        statusIcon = Icons.check_circle;
        statusIconColor = Colors.green;
        statusText = 'Completed';
        break;
      case GameStatus.available:
        borderColor = _getFrequencyColor(challenge.frequency);
        backgroundColor = _getFrequencyColor(challenge.frequency).withValues(alpha: 0.1);
        break;
      case GameStatus.locked:
        borderColor = Colors.grey;
        backgroundColor = Colors.grey.withValues(alpha: 0.1);
        statusIcon = Icons.lock;
        statusIconColor = Colors.grey;
        statusText = 'Locked';
        break;
      case GameStatus.expired:
        borderColor = Colors.red.withValues(alpha: 0.5);
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        statusIcon = Icons.access_time;
        statusIconColor = Colors.red;
        statusText = 'Expired';
        break;
    }

    return Container(
      width: 160.w,
      margin: EdgeInsets.only(right: 12.w),
      child: GestureDetector(
        onTap: status == GameStatus.available 
            ? () => _launchGame(challenge)
            : null,
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: 2.w),
            boxShadow: status == GameStatus.available ? [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 8.r,
                offset: Offset(0, 4.h),
              ),
            ] : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with emoji and status
              Row(
                children: [
                  Text(
                    challenge.emoji,
                    style: TextStyle(fontSize: 24.sp),
                  ),
                  const Spacer(),
                  if (statusIcon != null)
                    Icon(
                      statusIcon,
                      color: statusIconColor,
                      size: 16.sp,
                    ),
                ],
              ),
              
              SizedBox(height: 8.h),
              
              // Title
              Text(
                challenge.title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 4.h),
              
              // Description
              Text(
                challenge.description,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Bottom info
              Row(
                children: [
                  // Frequency badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _getFrequencyColor(challenge.frequency).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      _getFrequencyText(challenge.frequency),
                      style: TextStyle(
                        color: _getFrequencyColor(challenge.frequency),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // ADD THIS: Status text for non-available states
                  if (statusText != null && status != GameStatus.available)
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusIconColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  // Points or progress (existing code)
                  else if (progress?.bestScore != null && progress!.bestScore > 0)
                    Text(
                      '${progress.bestScore}pts',
                      style: TextStyle(
                        color: const Color(0xFFE5A00D),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else if (status == GameStatus.available)
                    Text(
                      '+${challenge.rewardPoints}',
                      style: TextStyle(
                        color: const Color(0xFFE5A00D),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              
              // Time remaining for time-limited challenges
              if (challenge.frequency == GameFrequency.daily && status == GameStatus.available) ...[
                SizedBox(height: 4.h),
                Text(
                  '⏰ ${challenge.timeRemainingText}',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getFrequencyColor(GameFrequency frequency) {
    switch (frequency) {
      case GameFrequency.daily:
        return const Color(0xFFE5A00D);
      case GameFrequency.weekly:
        return const Color(0xFF8B5CF6);
      case GameFrequency.monthly:
        return const Color(0xFFEF4444);
    }
  }

  String _getFrequencyText(GameFrequency frequency) {
    switch (frequency) {
      case GameFrequency.daily:
        return 'DAILY';
      case GameFrequency.weekly:
        return 'WEEKLY';
      case GameFrequency.monthly:
        return 'MONTHLY';
    }
  }
}