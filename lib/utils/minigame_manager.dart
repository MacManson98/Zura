// File: lib/utils/minigame_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/minigame_models.dart';
import '../utils/debug_loader.dart';

class MinigameManager {
  static const String _progressKey = 'minigame_progress';
  static const String _statsKey = 'minigame_stats';
  
  static MinigameStats _stats = MinigameStats();
  static Map<String, GameProgress> _progress = {};
  
  // Initialize the manager
  static Future<void> initialize() async {
    await _loadProgress();
    await _loadStats();
  }
  
  // Get current challenges for today
  static List<MinigameChallenge> getTodaysChallenges() {
    final now = DateTime.now();
    final challenges = <MinigameChallenge>[];
    
    // Daily Challenge
    challenges.add(_generateDailyChallenge(now));
    
    // Weekly Challenge (only on certain days)
    if (now.weekday == DateTime.monday) {
      challenges.add(_generateWeeklyChallenge(now));
    }
    
    // Monthly Challenge (only on the 1st)
    if (now.day == 1) {
      challenges.add(_generateMonthlyChallenge(now));
    }
    
    return challenges;
  }
  
  // Get all active challenges
  static List<MinigameChallenge> getActiveChallenges() {
    final now = DateTime.now();
    final challenges = <MinigameChallenge>[];
    
    // Always include today's daily challenge
    challenges.add(_generateDailyChallenge(now));
    
    // Include current week's challenge if it exists and hasn't expired
    final weeklyChallenge = _generateWeeklyChallenge(_getStartOfWeek(now));
    if (weeklyChallenge.endDate.isAfter(now)) {
      challenges.add(weeklyChallenge);
    }
    
    // Include current month's challenge if it exists and hasn't expired
    final monthlyChallenge = _generateMonthlyChallenge(_getStartOfMonth(now));
    if (monthlyChallenge.endDate.isAfter(now)) {
      challenges.add(monthlyChallenge);
    }
    
    return challenges;
  }
  
  // Generate daily challenge
  static MinigameChallenge _generateDailyChallenge(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    // Rotate game types by day of week
    final gameTypes = [
      GameType.emojiGuess,
      GameType.trivia,
      GameType.yearGuess,
      GameType.castGuess,
      GameType.emojiGuess, // More emoji games since they're fun
      GameType.trivia,
      GameType.yearGuess,
    ];
    
    final gameType = gameTypes[date.weekday - 1];
    
    return MinigameChallenge(
      id: 'daily_${startOfDay.toIso8601String().split('T')[0]}',
      type: gameType,
      frequency: GameFrequency.daily,
      title: _getDailyTitle(gameType),
      description: _getDailyDescription(gameType),
      emoji: _getGameEmoji(gameType),
      startDate: startOfDay,
      endDate: endOfDay,
      maxScore: 100,
      rewardPoints: 10,
      rewards: ['Daily Streak Point'],
    );
  }
  
  // Generate weekly challenge
  static MinigameChallenge _generateWeeklyChallenge(DateTime weekStart) {
    final endOfWeek = weekStart.add(const Duration(days: 7));
    
    // Weekly challenges are harder and worth more
    return MinigameChallenge(
      id: 'weekly_${weekStart.toIso8601String().split('T')[0]}',
      type: GameType.emojiGuess, // Could be any type
      frequency: GameFrequency.weekly,
      title: 'Weekly Movie Marathon',
      description: 'Score 80+ on emoji challenges',
      emoji: '🏆',
      startDate: weekStart,
      endDate: endOfWeek,
      maxScore: 200,
      rewardPoints: 50,
      rewards: ['Weekly Champion Badge', '50 Bonus Points'],
    );
  }
  
  // Generate monthly challenge
  static MinigameChallenge _generateMonthlyChallenge(DateTime monthStart) {
    final endOfMonth = DateTime(monthStart.year, monthStart.month + 1, 1);
    
    return MinigameChallenge(
      id: 'monthly_${monthStart.year}_${monthStart.month}',
      type: GameType.emojiGuess,
      frequency: GameFrequency.monthly,
      title: 'Movie Master Challenge',
      description: 'Complete 20 daily challenges',
      emoji: '👑',
      startDate: monthStart,
      endDate: endOfMonth,
      maxScore: 500,
      rewardPoints: 200,
      rewards: ['Monthly Master Title', 'Exclusive Avatar'],
    );
  }
  
  // Helper methods for challenge generation
  static String _getDailyTitle(GameType type) {
    switch (type) {
      case GameType.emojiGuess:
        return 'Daily Emoji Challenge';
      case GameType.trivia:
        return 'Daily Movie Trivia';
      case GameType.yearGuess:
        return 'Guess the Year';
      case GameType.castGuess:
        return 'Name the Cast';
    }
  }
  
  static String _getDailyDescription(GameType type) {
    switch (type) {
      case GameType.emojiGuess:
        return 'Guess movies from emoji clues';
      case GameType.trivia:
        return 'Test your movie knowledge';
      case GameType.yearGuess:
        return 'When was this movie released?';
      case GameType.castGuess:
        return 'Identify actors and actresses';
    }
  }
  
  static String _getGameEmoji(GameType type) {
    switch (type) {
      case GameType.emojiGuess:
        return '🎭';
      case GameType.trivia:
        return '🧠';
      case GameType.yearGuess:
        return '📅';
      case GameType.castGuess:
        return '🎬';
    }
  }
  
  // Progress tracking
  static GameProgress? getProgress(String challengeId) {
    return _progress[challengeId];
  }
  
  static GameStatus getChallengeStatus(MinigameChallenge challenge) {
    final progress = _progress[challenge.id];
    if (progress?.isCompleted == true) return GameStatus.completed;
    return challenge.status;
  }
  
  static Future<void> updateProgress(String challengeId, int score, bool completed) async {
    final existing = _progress[challengeId] ?? GameProgress(challengeId: challengeId);
    
    _progress[challengeId] = existing.copyWith(
      bestScore: score > existing.bestScore ? score : existing.bestScore,
      attempts: existing.attempts + 1,
      lastPlayed: DateTime.now(),
      completedAt: completed ? DateTime.now() : existing.completedAt,
      isCompleted: completed || existing.isCompleted,
      pointsEarned: completed ? 10 : existing.pointsEarned, // Base points
    );
    
    // Update overall stats
    await _updateStats(score, completed);
    
    await _saveProgress();
    await _saveStats();
  }
  
  static Future<void> _updateStats(int score, bool completed) async {
    final now = DateTime.now();
    final lastPlay = _stats.lastPlayDate;
    
    // Calculate streak
    int newStreak = _stats.currentStreak;
    if (lastPlay == null || _isDifferentDay(lastPlay, now)) {
      if (lastPlay != null && _isConsecutiveDay(lastPlay, now)) {
        newStreak += 1;
      } else {
        newStreak = 1;
      }
    }
    
    _stats = _stats.copyWith(
      totalPoints: _stats.totalPoints + (completed ? 10 : 0),
      gamesPlayed: _stats.gamesPlayed + 1,
      gamesCompleted: completed ? _stats.gamesCompleted + 1 : _stats.gamesCompleted,
      currentStreak: newStreak,
      longestStreak: newStreak > _stats.longestStreak ? newStreak : _stats.longestStreak,
      lastPlayDate: now,
    );
  }
  
  // Getters
  static MinigameStats get stats => _stats;
  static Map<String, GameProgress> get progress => _progress;
  
  // Persistence
  static Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_progressKey);
      if (jsonString != null) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        _progress = json.map((key, value) => 
          MapEntry(key, GameProgress.fromJson(value))
        );
      }
    } catch (e) {
      DebugLogger.log('Error loading minigame progress: $e');
      _progress = {};
    }
  }
  
  static Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = _progress.map((key, value) => 
        MapEntry(key, value.toJson())
      );
      await prefs.setString(_progressKey, jsonEncode(json));
    } catch (e) {
      DebugLogger.log('Error saving minigame progress: $e');
    }
  }
  
  static Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_statsKey);
      if (jsonString != null) {
        _stats = MinigameStats.fromJson(jsonDecode(jsonString));
      }
    } catch (e) {
      DebugLogger.log('Error loading minigame stats: $e');
      _stats = MinigameStats();
    }
  }
  
  static Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_statsKey, jsonEncode(_stats.toJson()));
    } catch (e) {
      DebugLogger.log('Error saving minigame stats: $e');
    }
  }
  
  // Helper methods
  static DateTime _getStartOfWeek(DateTime date) {
    final daysFromMonday = date.weekday - 1;
    return DateTime(date.year, date.month, date.day).subtract(Duration(days: daysFromMonday));
  }
  
  static DateTime _getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }
  
  static bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year || 
           date1.month != date2.month || 
           date1.day != date2.day;
  }
  
  static bool _isConsecutiveDay(DateTime lastPlay, DateTime today) {
    final yesterday = today.subtract(const Duration(days: 1));
    return lastPlay.year == yesterday.year &&
           lastPlay.month == yesterday.month &&
           lastPlay.day == yesterday.day;
  }
}