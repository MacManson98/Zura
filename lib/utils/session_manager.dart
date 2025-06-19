// File: lib/utils/session_manager.dart
import 'completed_session.dart';

// Session Management Utility for Active Solo Sessions
class SessionManager {
  static CompletedSession? _currentSession;
  static DateTime? _lastActivity;
  static int _swipeCount = 0;
  
  // Start a new session
  static void startSession({
    required SessionType type,
    required List<String> participantNames,
    String? mood,
  }) {
    _currentSession = CompletedSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      endTime: DateTime.now(), // Will be updated when session ends
      type: type,
      participantNames: participantNames,
      likedMovieIds: [],
      matchedMovieIds: [],
      mood: mood,
      totalSwipes: 0,
    );
    _lastActivity = DateTime.now();
    _swipeCount = 0;
  }

  // Record activity (swipe, like, etc.)
  static void recordActivity() {
    _lastActivity = DateTime.now();
    _swipeCount++;
  }

  // Add liked movie to current session
  static void addLikedMovie(String movieId) {
    if (_currentSession != null) {
      _currentSession = CompletedSession(
        id: _currentSession!.id,
        startTime: _currentSession!.startTime,
        endTime: _currentSession!.endTime,
        type: _currentSession!.type,
        participantNames: _currentSession!.participantNames,
        likedMovieIds: [..._currentSession!.likedMovieIds, movieId],
        matchedMovieIds: _currentSession!.matchedMovieIds,
        mood: _currentSession!.mood,
        totalSwipes: _swipeCount,
      );
    }
    recordActivity();
  }

  // Add matched movie to current session
  static void addMatchedMovie(String movieId) {
    if (_currentSession != null) {
      _currentSession = CompletedSession(
        id: _currentSession!.id,
        startTime: _currentSession!.startTime,
        endTime: _currentSession!.endTime,
        type: _currentSession!.type,
        participantNames: _currentSession!.participantNames,
        likedMovieIds: _currentSession!.likedMovieIds,
        matchedMovieIds: [..._currentSession!.matchedMovieIds, movieId],
        mood: _currentSession!.mood,
        totalSwipes: _swipeCount,
      );
    }
    recordActivity();
  }

  // Check if session should auto-end (10 minutes of inactivity)
  static bool shouldAutoEnd() {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!).inMinutes >= 10;
  }

  // End current session and return it
  static CompletedSession? endSession() {
    if (_currentSession == null) return null;
    
    final completedSession = CompletedSession(
      id: _currentSession!.id,
      startTime: _currentSession!.startTime,
      endTime: DateTime.now(),
      type: _currentSession!.type,
      participantNames: _currentSession!.participantNames,
      likedMovieIds: _currentSession!.likedMovieIds,
      matchedMovieIds: _currentSession!.matchedMovieIds,
      mood: _currentSession!.mood,
      totalSwipes: _swipeCount,
    );
    
    _currentSession = null;
    _lastActivity = null;
    _swipeCount = 0;
    
    return completedSession;
  }

  // Get current session
  static CompletedSession? get currentSession => _currentSession;
  
  // Check if session is active
  static bool get hasActiveSession => _currentSession != null;
  
  // Get session duration so far
  static Duration? get currentSessionDuration {
    if (_currentSession == null) return null;
    return DateTime.now().difference(_currentSession!.startTime);
  }
}