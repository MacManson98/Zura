// File: lib/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
import '../models/matching_models.dart';
import 'services/group_invitation_service.dart';
import 'utils/debug_loader.dart';
import 'widgets/notifications_bottom_sheet.dart';
import 'services/notification_helper.dart';
import 'utils/themed_notifications.dart';


class MainNavigation extends StatefulWidget {
  final UserProfile profile;
  final List<Movie> preloadedMovies; // ✅ NEW: Accept preloaded movies
  
  const MainNavigation({
    super.key,
    required this.profile,
    this.preloadedMovies = const [], // ✅ Default to empty list
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
  
  // ✅ SIMPLIFIED: No more complex loading states
  List<Movie> _completeMovieDatabase = [];
  bool _isInitialized = false;
  
  // ✅ IN-MEMORY: Track cleanup without SharedPreferences
  static DateTime? _lastCleanupTime;

  @override
  void initState() {
    super.initState();
    
    // ✅ IMMEDIATE: Use preloaded movies
    _completeMovieDatabase = widget.preloadedMovies;
    
    if (kDebugMode) {
      print("✅ MainNavigation: Initialized with ${_completeMovieDatabase.length} preloaded movies");
    }
    
    _matcherScreen = _buildMatcherScreen();
    
    // ✅ FAST: Quick initialization without file system dependencies
    _initializeUserSession();
  }

  // ✅ STREAMLINED: Much simpler initialization
  Future<void> _initializeUserSession() async {
    if (_isInitialized) return;
    
    try {
      if (kDebugMode) {
        print("🔄 MainNavigation: Starting streamlined initialization...");
      }
      
      // Load friends (network only) - this is fast
      await _loadFriends();
      
      // Mark as initialized immediately - no more loading screens!
      setState(() {
        _isInitialized = true;
        _matcherScreen = _buildMatcherScreen();
      });
      
      // ✅ OPTIONAL: Schedule cleanup for later (non-blocking)
      Timer(const Duration(seconds: 10), () {
        if (mounted) _performOptionalCleanup();
      });
      
      if (kDebugMode) {
        print("✅ MainNavigation: Streamlined initialization completed");
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in initialization: $e');
      }
      // Always show UI even if friends loading fails
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _matcherScreen = _buildMatcherScreen();
        });
      }
    }
  }

  // ✅ OPTIONAL: Cleanup without SharedPreferences dependency
  Future<void> _performOptionalCleanup() async {
    if (!mounted) return;
    
    try {
      // ✅ IN-MEMORY: Check if we need cleanup (6 hour interval)
      final now = DateTime.now();
      if (_lastCleanupTime != null) {
        final timeSinceCleanup = now.difference(_lastCleanupTime!);
        if (timeSinceCleanup.inHours < 6) {
          if (kDebugMode) {
            print("ℹ️ Cleanup not needed yet");
          }
          return;
        }
      }
      
      if (kDebugMode) {
        print("🧹 Starting optional cleanup...");
      }
      
      await SessionService.performMaintenanceCleanup();
      _lastCleanupTime = now;
      
      if (kDebugMode) {
        print("✅ Optional cleanup completed");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Note: Optional cleanup failed: $e");
      }
      // Cleanup failures are not critical
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

  Widget _buildMatcherScreen() {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    
    return MatcherScreen(
      sessionId: sessionId,
      allMovies: _completeMovieDatabase,
      currentUser: widget.profile,
      friendIds: _friendIds,
      selectedFriend: _selectedFriend,
      mode: _matcherMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialTab = args?['initialTab'] as int?;    
    
    if (initialTab != null && initialTab != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _selectedIndex = initialTab);
        }
      });
    }

    final screens = [
      HomeScreen(
        profile: widget.profile,
        movies: _completeMovieDatabase,
        onNavigateToMatches: () {
          setState(() => _selectedIndex = matcherTabIndex);
        },
        onNavigateToMatcher: _goToSoloMatcher,
        onNavigateToFriends: () {
          setState(() => _selectedIndex = 2);
        },
        onNavigateToNotifications: () {
          // Handle notifications if needed
        },
        onProfileUpdate: (updatedProfile) {
          // Handle profile updates if needed
        },
        onNavigateToSoloMatcher: _goToSoloMatcher,
        onNavigateToFriendMatcher: _goToFriendMatcherTab,
        onNavigateToGroupMatcher: _goToGroupMatcher,
      ),
      _matcherScreen,
      FriendsScreen(
        currentUser: widget.profile,
        allMovies: _completeMovieDatabase,
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
          IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          
          // ✅ REMOVED: All loading overlays - everything loads in auth_gate now!
          
          // Floating nav bar
          if (_isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 25,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: SessionService.watchPendingInvitations(),
                builder: (context, sessionSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FriendshipService.getPendingFriendRequests(widget.profile.uid),
                    builder: (context, friendSnapshot) {
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: GroupInvitationService().watchPendingGroupInvitations(widget.profile.uid),
                        builder: (context, groupSnapshot) {
                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: SessionService.watchSessionNotifications(widget.profile.uid),
                            builder: (context, notificationSnapshot) {
                              
                              // Handle background notifications
                              NotificationHelper.handleBackgroundNotifications(
                                notificationSnapshot.data ?? [],
                                widget.profile.uid,
                                context,
                                (tabIndex) => setState(() => _selectedIndex = tabIndex),
                              );
                              
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
                                onNotificationTap: () => _showNotifications(
                                  sessionSnapshot.data ?? [],
                                  friendSnapshot.data ?? [],
                                  groupSnapshot.data ?? [],
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
            ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  void _showNotifications(
    List<Map<String, dynamic>> sessionInvites,
    List<Map<String, dynamic>> friendRequests,
    List<Map<String, dynamic>> groupInvites,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationBottomSheet(
        sessionInvites: sessionInvites,
        friendRequests: friendRequests,
        groupInvitations: groupInvites,
        regularNotifications: const [], // ADD THIS LINE (empty for now)
        onSessionAccept: (invitation) => _handleSessionAccept(invitation),
        onSessionDecline: (invitation) => _handleSessionDecline(invitation),
        onFriendAccept: (request) => _handleFriendAccept(request),
        onFriendDecline: (request) => _handleFriendDecline(request),
        onGroupAccept: (invitation) => _handleGroupAccept(invitation), 
        onGroupDecline: (invitation) => _handleGroupDecline(invitation),
        onClearAll: _clearAllNotifications,
      ),
    );
  }

  Future<void> _handleGroupAccept(Map<String, dynamic> invitation) async {
    Navigator.pop(context);
    
    try {
      await NotificationHelper.handleGroupInviteAction(
        inviteData: invitation,
        action: 'accept',
        context: context,
      );
      
      // ✅ ADD THIS: Refresh friends/groups data
      await _loadFriends();
      
      // Navigate to friends screen to see the new group
      setState(() {
        _selectedIndex = 2;
      });
      
    } catch (e) {
      DebugLogger.log("❌ Error accepting group invitation: $e");
      if (mounted) {
        ThemedNotifications.showError(context, 'Failed to join group');
      }
    }
  }

  Future<void> _handleGroupDecline(Map<String, dynamic> invitation) async {
    Navigator.pop(context);
    
    try {
      await NotificationHelper.handleGroupInviteAction(
        inviteData: invitation,
        action: 'decline',
        context: context,
      );
    } catch (e) {
      DebugLogger.log("❌ Error declining group invitation: $e");
      if (mounted) {
        ThemedNotifications.showError(context, 'Failed to decline group invitation');
      }
    }
  }

  // ✅ RESTORED: Session handling with proper callback (based on your original code)
  Future<void> _handleSessionAccept(Map<String, dynamic> invitation) async {
    Navigator.pop(context);
    
    try {
      DebugLogger.log("📥 Accepting session invitation: ${invitation['sessionId']}");
      
      final session = await SessionService.acceptInvitation(
        invitation['sessionId'],
        widget.profile.name,
      );
      
      if (!mounted) return;
      
      if (session != null) {
        setState(() {
          _selectedIndex = 1; // Go to matcher tab
        });
        
        // ✅ RESTORED: This is the critical part that was missing
        if (MainNavigation._globalSessionCallback != null) {
          DebugLogger.log("📥 Loading joined session in matcher");
          MainNavigation._globalSessionCallback!(session);
        }
        
        if (mounted) {
          ThemedNotifications.showSuccess(context, 'Joined session! Loading matcher...', icon: "🎬");
        }
      }
    } catch (e) {
      DebugLogger.log("❌ Error accepting session invitation: $e");
      if (mounted) {
        ThemedNotifications.showError(context, 'Failed to join session');
      }
    }
  }

  Future<void> _handleSessionDecline(Map<String, dynamic> invitation) async {
    Navigator.pop(context);
    
    try {
      final inviteId = invitation['id'] as String?;
      final sessionId = invitation['sessionId'] as String?;

      if (inviteId == null || sessionId == null) {
        throw Exception("Missing id or sessionId: id=$inviteId, sessionId=$sessionId");
      }

      DebugLogger.log("❌ Declining session invitation: $inviteId for session $sessionId");

      await SessionService.declineInvitation(inviteId, sessionId);

      if (!mounted) return;

      setState(() {
        _selectedIndex = 2; // Go to friends screen
      });

      ThemedNotifications.showDecline(context, 'Declined session invitation.');
    } catch (e) {
      DebugLogger.log("❌ Error declining session invitation: $e");
      if (mounted) {
        ThemedNotifications.showError(context, 'Failed to decline session');
      }
    }
  }

  // ✅ SIMPLIFIED: Friend request handling using helper
  Future<void> _handleFriendAccept(Map<String, dynamic> request) async {
    Navigator.pop(context);
    await NotificationHelper.handleFriendRequestAction(
      requestData: request,
      action: 'accept',
      context: context,
      onFriendsUpdated: _loadFriends,
    );
  }

  Future<void> _handleFriendDecline(Map<String, dynamic> request) async {
    Navigator.pop(context);
    await NotificationHelper.handleFriendRequestAction(
      requestData: request,
      action: 'decline',
      context: context,
      onFriendsUpdated: _loadFriends,
    );
  }

  // ✅ SIMPLIFIED: Clear all using helper
  Future<void> _clearAllNotifications() async {
    Navigator.pop(context);
    
    final shouldClear = await NotificationHelper.showClearAllDialog(context);
    if (shouldClear == true) {
      await NotificationHelper.clearAllNotifications(widget.profile.uid, context);
    }
  }


  void _goToSoloMatcher() {
    if (kDebugMode) {
      print("🔍 Navigating to Solo Matcher");
    }
    setState(() {
      _matcherMode = MatchingMode.solo;
      _selectedFriend = null;
      _selectedIndex = matcherTabIndex;
      _matcherScreen = _buildMatcherScreen();
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

  void _goToGroupMatcher() {
    if (kDebugMode) {
      print("🔍 Navigating to Group Matcher");
    }
    setState(() {
      _matcherMode = MatchingMode.group;
      _selectedFriend = null;
      _selectedIndex = matcherTabIndex;
      _matcherScreen = _buildMatcherScreen();
    });
  }

  void _goToFriendMatcherTab() {
    if (kDebugMode) {
      print("🟢 Switching to Friend Matcher");
    }
    setState(() {
      _matcherMode = MatchingMode.friend;
      _matcherScreen = _buildMatcherScreen();
      _selectedIndex = matcherTabIndex;
    });
  }
}