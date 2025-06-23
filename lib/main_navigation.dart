import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Timer? _loadTimer;

  @override
  void initState() {
    super.initState();
    // ✅ BULLETPROOF: No file access during initialization
    _initializeUserSession();
    _matcherScreen = _buildMatcherScreen();
    _performPostAuthCleanup();
  }

  Future<void> _performPostAuthCleanup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCleanup = prefs.getInt('last_cleanup') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - lastCleanup > 6 * 60 * 60 * 1000) {
        DebugLogger.log("🧹 Starting post-auth cleanup...");
        await SessionService.performMaintenanceCleanup();
        await prefs.setInt('last_cleanup', now);
        DebugLogger.log("✅ Post-auth cleanup completed");
      }
    } catch (e) {
      DebugLogger.log("Note: Post-auth cleanup failed: $e");
    }
  }

  @override
  void dispose() {
    _loadTimer?.cancel();
    super.dispose();
  }

  // ✅ BULLETPROOF: Load movies only when safe and needed
  Future<void> _loadCompleteMovieDatabase() async {
    if (_isLoadingMovies || _hasAttemptedLoad || !mounted) return;
    
    _hasAttemptedLoad = true;
    setState(() => _isLoadingMovies = true);
    
    try {
      // ✅ SAFETY: Wait for iOS to be fully ready
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!mounted) return;
      
      DebugLogger.log('🎬 MainNavigation: Loading complete movie database...');
      _completeMovieDatabase = await MovieDatabaseLoader.loadMovieDatabase();
      DebugLogger.log('✅ MainNavigation: Loaded ${_completeMovieDatabase.length} movies with complete data');
      
      if (_completeMovieDatabase.isNotEmpty && mounted) {
        final firstMovie = _completeMovieDatabase.first;
        DebugLogger.log('🔍 Sample movie: ${firstMovie.title}');
        DebugLogger.log('🔍 Has streaming: ${firstMovie.hasAnyStreamingOptions}');
      }
      
    } catch (e) {
      DebugLogger.log('❌ MainNavigation: Error loading movie database: $e');
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

  Future<void> _initializeUserSession() async {
    try {
      await _loadFriends();
      _performUserCleanup();
    } catch (e) {
      DebugLogger.log('Error initializing user session: $e');
    }
  }

  Future<void> _performUserCleanup() async {
    try {
      DebugLogger.log("🧹 Cleaning up user data for ${widget.profile.name}...");
      await SessionService.cleanupUserInvitations(widget.profile.uid);
      DebugLogger.log("✅ User cleanup completed");
    } catch (e) {
      DebugLogger.log("Note: User cleanup failed: $e");
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
      DebugLogger.log('Error loading friends: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToFriendMatcher(UserProfile friend) {
    DebugLogger.log("🟢 Switching to Matcher tab with ${friend.name}");
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
    // ✅ BULLETPROOF: Trigger movie loading when app is stable
    if (!_hasAttemptedLoad && !_isLoadingMovies) {
      _loadTimer?.cancel();
      _loadTimer = Timer(const Duration(milliseconds: 100), () {
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
          
          // ✅ BULLETPROOF: Show loading overlay only when loading
          if (_isLoadingMovies)
            Container(
              color: const Color(0xFF121212).withOpacity(0.8),
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
      bottomNavigationBar: StreamBuilder<List<Map<String, dynamic>>>(
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