// File: lib/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';
import 'screens/matcher_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart';
import 'models/user_profile.dart';
import 'screens/home_screen.dart';
import 'movie.dart';
import 'custom_nav_bar.dart';
import 'services/friendship_service.dart';
import 'services/session_service.dart';
import 'models/session_models.dart';
import '../utils/debug_loader.dart';
import '../models/matching_models.dart';
import 'services/group_invitation_service.dart';
import 'widgets/notifications_bottom_sheet.dart';
import '../utils/movie_loader.dart';

class MainNavigation extends StatefulWidget {
  final UserProfile profile;
  
  const MainNavigation({
    super.key,
    required this.profile,
  });

  static void Function(SwipeSession)? _globalSessionCallback;
  
  static void setSessionCallback(void Function(SwipeSession) callback) {
    _globalSessionCallback = callback;
  }
  
  static void clearSessionCallback() {
    _globalSessionCallback = null;
  }

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  static const int matcherTabIndex = 1;

  UserProfile? _selectedFriend;
  MatchingMode _matcherMode = MatchingMode.solo;
  List<UserProfile> _friendIds = [];
  late Widget _matcherScreen;
  
  // ✅ BULLETPROOF: State management
  List<Movie> _completeMovieDatabase = [];
  bool _isLoadingMovies = false;
  bool _hasAttemptedLoad = false;
  bool _isInitialized = false;
  Timer? _loadTimer;
  Timer? _initTimer;

  @override
  void initState() {
    super.initState();
    _matcherScreen = _buildMatcherScreen();
    
    // 🆕 AGGRESSIVE: Delay ALL initialization for iOS
    if (!kIsWeb && Platform.isIOS) {
      _initTimer = Timer(const Duration(milliseconds: 3000), () {
        if (mounted) _safeInitializeUserSession();
      });
    } else {
      // Android can initialize immediately
      _safeInitializeUserSession();
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    _initTimer?.cancel();
    super.dispose();
  }

  // 🆕 COMPLETELY SAFE: No file operations until much later
  Future<void> _safeInitializeUserSession() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        print("🔄 MainNavigation: Starting safe initialization...");
      }
      
      // 🆕 STEP 1: Load friends first (network only, no local storage)
      await _loadFriends();
      
      // 🆕 STEP 2: Mark as initialized BEFORE any file operations
      setState(() {
        _isInitialized = true;
        _matcherScreen = _buildMatcherScreen();
      });
      
      // 🆕 STEP 3: Delay cleanup operations significantly
      if (!kIsWeb && Platform.isIOS) {
        Timer(const Duration(milliseconds: 5000), () {
          if (mounted) _performPostAuthCleanup();
        });
      } else {
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) _performPostAuthCleanup();
        });
      }
      
      if (kDebugMode) {
        print("✅ MainNavigation: Safe initialization completed");
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in safe initialization: $e');
      }
      // Set as initialized anyway to show UI
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _matcherScreen = _buildMatcherScreen();
        });
      }
    }
  }

  // 🆕 ULTRA-SAFE: SharedPreferences with maximum error handling
  Future<void> _performPostAuthCleanup() async {
    if (!mounted) return;
    
    try {
      if (kDebugMode) {
        print("🧹 Attempting post-auth cleanup...");
      }
      
      SharedPreferences? prefs;
      
      // 🆕 MULTIPLE RETRY ATTEMPTS for iOS
      if (!kIsWeb && Platform.isIOS) {
        for (int attempt = 1; attempt <= 5; attempt++) {
          try {
            await Future.delayed(Duration(milliseconds: 500 * attempt));
            prefs = await SharedPreferences.getInstance();
            if (kDebugMode) {
              print("✅ SharedPreferences obtained on attempt $attempt");
            }
            break;
          } catch (e) {
            if (kDebugMode) {
              print("⚠️ SharedPreferences attempt $attempt failed: $e");
            }
            if (attempt == 5) {
              if (kDebugMode) {
                print("❌ All SharedPreferences attempts failed, continuing without cleanup");
              }
              return; // Give up gracefully
            }
          }
        }
      } else {
        // Android - normal approach
        prefs = await SharedPreferences.getInstance();
      }
      
      if (prefs == null) {
        if (kDebugMode) {
          print("⚠️ SharedPreferences not available, skipping cleanup");
        }
        return;
      }
      
      final lastCleanup = prefs.getInt('last_cleanup') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - lastCleanup > 6 * 60 * 60 * 1000) {
        if (kDebugMode) {
          print("🧹 Starting post-auth cleanup...");
        }
        await SessionService.performMaintenanceCleanup();
        await prefs.setInt('last_cleanup', now);
        if (kDebugMode) {
          print("✅ Post-auth cleanup completed");
        }
      } else {
        if (kDebugMode) {
          print("ℹ️ Cleanup not needed yet");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Note: Post-auth cleanup failed: $e");
      }
      // Continue silently - cleanup is not critical
    }
  }

  // ✅ SAFE: Load movies with ultra-conservative timing
  Future<void> _loadCompleteMovieDatabase() async {
    if (_isLoadingMovies || _hasAttemptedLoad || !mounted || !_isInitialized) return;
    
    _hasAttemptedLoad = true;
    setState(() => _isLoadingMovies = true);
    
    try {
      // 🆕 AGGRESSIVE: Extra long delay for iOS movie loading
      if (!kIsWeb && Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 2000));
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (!mounted) return;
      
      if (kDebugMode) {
        print('🎬 MainNavigation: Loading complete movie database...');
      }
      
      _completeMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      
      if (kDebugMode) {
        print('✅ MainNavigation: Loaded ${_completeMovieDatabase.length} movies with complete data');
      }
      
      if (_completeMovieDatabase.isNotEmpty && mounted) {
        final firstMovie = _completeMovieDatabase.first;
        if (kDebugMode) {
          print('🔍 Sample movie: ${firstMovie.title}');
          print('🔍 Has streaming: ${firstMovie.hasAnyStreamingOptions}');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ MainNavigation: Error loading movie database: $e');
      }
      _completeMovieDatabase = []; // ✅ GRACEFUL: Always provide empty list
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMovies = false;
          _matcherScreen = _buildMatcherScreen(); // ✅ REBUILD: Update matcher with movies
        });
      }
    }
  }

  Future<void> _loadFriends() async {
    try {
      final friends = await FriendshipService.getFriends(widget.profile.uid);
      if (mounted) {
        setState(() {
          _friendIds = friends;
          _matcherScreen = _buildMatcherScreen();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading friends: $e');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToFriendMatcher(UserProfile friend) {
    if (kDebugMode) {
      print("🟢 Switching to Matcher tab with ${friend.name}");
    }
    setState(() {
      _selectedFriend = friend;
      _matcherMode = MatchingMode.friend;
      _matcherScreen = _buildMatcherScreen();
      _selectedIndex = matcherTabIndex;
    });
  }

  Widget _buildMatcherScreen() {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    return MatcherScreen(
      sessionId: sessionId,
      allMovies: _completeMovieDatabase, // ✅ SAFE: Empty list is handled gracefully
      currentUser: widget.profile,
      friendIds: _friendIds,
      selectedFriend: _selectedFriend,
      mode: _matcherMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 CONSERVATIVE: Only start movie loading when fully initialized
    if (_isInitialized && !_hasAttemptedLoad && !_isLoadingMovies) {
      _loadTimer?.cancel();
      final delay = !kIsWeb && Platform.isIOS ? 1000 : 100;
      _loadTimer = Timer(Duration(milliseconds: delay), () {
        if (mounted) _loadCompleteMovieDatabase();
      });
    }

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialTab = args?['initialTab'] as int?;    
    
    if (initialTab != null && initialTab != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = initialTab);
        }
      });
    }

    // ✅ BULLETPROOF: Always build screens, even with empty movie lists
    final screens = [
      HomeScreen(
        profile: widget.profile,
        movies: _completeMovieDatabase, // ✅ SAFE: Empty list handled gracefully
      ),
      _matcherScreen,
      FriendsScreen(
        currentUser: widget.profile,
        allMovies: _completeMovieDatabase, // ✅ SAFE: Empty list handled gracefully
        onMatchWithFriend: _goToFriendMatcher,
      ),
      ProfileScreen(
        currentUser: widget.profile,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // ✅ BULLETPROOF: Always show app content
          IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          
          // 🆕 SHOW INITIALIZATION STATUS
          if (!_isInitialized)
            Container(
              color: const Color(0xFF121212).withValues(alpha: 0.95),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_filter,
                      size: 64,
                      color: const Color(0xFFE5A00D),
                    ),
                    SizedBox(height: 24),
                    CircularProgressIndicator(
                      color: const Color(0xFFE5A00D),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Initializing app...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      Platform.isIOS 
                        ? 'Preparing iOS environment...' 
                        : 'Loading app data...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          
          // ✅ BULLETPROOF: Show loading overlay only when loading movies
          if (_isInitialized && _isLoadingMovies)
            Container(
              color: const Color(0xFF121212).withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: const Color(0xFFE5A00D),
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Loading movie database...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Just a moment...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: !_isInitialized 
        ? null 
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: SessionService.watchPendingInvitations(),
            builder: (context, sessionSnapshot) {
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: FriendshipService.getPendingFriendRequests(widget.profile.uid),
                builder: (context, friendSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: GroupInvitationService().watchPendingGroupInvitations(widget.profile.uid),
                    builder: (context, groupSnapshot) {
                      final sessionCount = sessionSnapshot.data?.length ?? 0;
                      final friendCount = friendSnapshot.data?.length ?? 0;
                      final groupCount = groupSnapshot.data?.length ?? 0;
                      final totalNotifications = sessionCount + friendCount + groupCount;
                      final hasHighPriority = sessionCount > 0 || friendCount > 0;

                      return CustomNavBar(
                        selectedIndex: _selectedIndex,
                        onItemTapped: _onItemTapped,
                        notificationCount: totalNotifications,
                        hasHighPriorityNotifications: hasHighPriority,
                        onNotificationTap: () {
                          final sessionInvites = sessionSnapshot.data ?? [];
                          final friendRequests = friendSnapshot.data ?? [];
                          
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => NotificationBottomSheet(
                              sessionInvites: sessionInvites,
                              friendRequests: friendRequests,
                              regularNotifications: [],
                              onSessionAccept: (invitation) {
                                Navigator.pop(context);
                                _handleSessionJoinFromNotification(invitation);
                              },
                              onFriendAccept: (request) {
                                _handleFriendRequestAccept(request);
                              },
                              onClearAll: () {
                                Navigator.pop(context);
                                _handleClearAllNotifications();
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
    );
  }

  // ... rest of your notification handling methods (unchanged)
  Future<void> _handleSessionJoinFromNotification(Map<String, dynamic> invitation) async {
    try {
      DebugLogger.log("📥 Accepting session invitation: ${invitation['sessionId']}");
      
      final session = await SessionService.acceptInvitation(
        invitation['sessionId'],
        widget.profile.name,
      );
      
      if (!mounted) return;
      
      if (session != null) {
        setState(() {
          _selectedIndex = 1;
        });
        
        if (MainNavigation._globalSessionCallback != null) {
          DebugLogger.log("📥 Loading joined session in matcher");
          MainNavigation._globalSessionCallback!(session);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Joined session! Loading matcher...'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      DebugLogger.log("❌ Error accepting session invitation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join session: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleFriendRequestAccept(Map<String, dynamic> request) async {
    try {
      await FriendshipService.acceptFriendRequest(
        fromUserId: request['fromUserId'],
        toUserId: request['toUserId'],
      );
      
      await _loadFriends();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.people, color: Colors.white),
                SizedBox(width: 8),
                Text('${request['fromUserName']} is now your friend!'),
              ],
            ),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept request: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleClearAllNotifications() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.clear_all, color: const Color(0xFFE5A00D), size: 24),
            SizedBox(width: 12),
            Text(
              'Clear All Notifications',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'This will decline all invitations and clear all notifications. This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A00D),
              foregroundColor: Colors.black,
            ),
            child: Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    try {
      final sessionInvitations = await SessionService.getPendingInvitations();
      for (final invitation in sessionInvitations) {
        await SessionService.declineInvitation(
          invitation['id'], 
          invitation['sessionId']
        );
      }
      
      final friendRequests = await FriendshipService.getPendingFriendRequestsList(widget.profile.uid);
      for (final request in friendRequests) {
        await FriendshipService.declineFriendRequest(
          fromUserId: request['fromUserId'],
          toUserId: request['toUserId'],
        );
      }
      
      await GroupInvitationService().declineAllGroupInvitations(widget.profile.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('All notifications cleared successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear notifications: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}