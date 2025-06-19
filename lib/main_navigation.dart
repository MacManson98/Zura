import 'package:flutter/material.dart';
import 'screens/matcher_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/profile_screen.dart'; // This imports EnhancedProfileScreen
import 'models/user_profile.dart';
import 'screens/home_screen.dart';
import 'movie.dart';
import 'custom_nav_bar.dart';
import 'services/friendship_service.dart';
import 'services/session_service.dart';
import 'services/group_invitation_service.dart'; // ✅ ADD THIS
import 'screens/notifications_screen.dart';
import 'models/session_models.dart'; // ✅ ADD THIS IMPORT
import '../utils/debug_loader.dart';
import '../models/matching_models.dart';

class MainNavigation extends StatefulWidget {
  final UserProfile profile;
  final List<Movie> movies;

  const MainNavigation({
    super.key,
    required this.profile,
    required this.movies,
  });

  // ✅ ADD: Static callback that matcher can set
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
  
  static const int matchesTabIndex = 1;
  static const int matcherTabIndex = 2;

  UserProfile? _selectedFriend;
  MatchingMode _matcherMode = MatchingMode.solo;
  List<UserProfile> _friendIds = [];
  late Widget _matcherScreen;

  @override
  void initState() {
    super.initState();
    _initializeUserSession();
    _matcherScreen = _buildMatcherScreen();
  }

  // ✅ Enhanced initialization with cleanup
  Future<void> _initializeUserSession() async {
    try {
      // Load friends
      await _loadFriends();
      
      // Clean up user's old data (run in background)
      _performUserCleanup();
    } catch (e) {
      DebugLogger.log('Error initializing user session: $e');
    }
  }

  // ✅ User-specific cleanup
  Future<void> _performUserCleanup() async {
    try {
      DebugLogger.log("🧹 Cleaning up user data for ${widget.profile.name}...");
      
      // Clean up user's old invitations
      await SessionService.cleanupUserInvitations(widget.profile.uid);
      
      DebugLogger.log("✅ User cleanup completed");
    } catch (e) {
      DebugLogger.log("Note: User cleanup failed: $e");
      // Don't affect user experience if cleanup fails
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

  void _goToMatchesTab() {
    _onItemTapped(matchesTabIndex);
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
      allMovies: widget.movies,
      currentUser: widget.profile,
      friendIds: _friendIds,
      selectedFriend: _selectedFriend,
      mode: _matcherMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle navigation arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final initialTab = args?['initialTab'] as int?;    
    // If we have an initial tab, set it
    if (initialTab != null && initialTab != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedIndex = initialTab;
        });
      });
    }

    final screens = [
      HomeScreen(
        profile: widget.profile,
        movies: widget.movies,
        onNavigateToMatches: _goToMatchesTab,
      ),
      _matcherScreen,
      FriendsScreen(
        currentUser: widget.profile,
        allMovies: widget.movies,
        onShowMatches: _goToMatchesTab,
        onMatchWithFriend: _goToFriendMatcher,
      ),
      // FIXED: Add missing allMovies parameter to ProfileScreen
      ProfileScreen(
        currentUser: widget.profile,
        onNavigateToMatches: _goToMatchesTab,
      ),
    ];

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: CustomNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        ),
        
        // ✅ UPDATED: Notification icon with all invitation types
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 16,
          child: StreamBuilder<List<Map<String, dynamic>>>(
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
                      
                      final hasNotifications = totalNotifications > 0;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationsScreen(
                                currentUser: widget.profile,
                                allMovies: widget.movies,
                                onSessionJoined: (session) {
                                  DebugLogger.log("📥 MAIN NAV: Session joined from notifications: ${session.sessionId}");
                                  
                                  // If matcher screen has registered a callback, use it directly
                                  if (MainNavigation._globalSessionCallback != null) {
                                    DebugLogger.log("📥 MAIN NAV: Using direct matcher callback");
                                    
                                    // Switch to matcher tab first
                                    setState(() {
                                      _selectedIndex = 2; // Switch to matcher tab
                                    });
                                    
                                    // Then call the callback
                                    MainNavigation._globalSessionCallback!(session);
                                    return;
                                  }
                                  
                                  // If no callback registered, just switch to matcher tab
                                  DebugLogger.log("📥 MAIN NAV: No callback registered, just switching to matcher");
                                  setState(() {
                                    _selectedIndex = 2;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: hasNotifications 
                                ? const Color(0xFFE5A00D).withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                hasNotifications 
                                    ? Icons.notifications 
                                    : Icons.notifications_none_outlined,
                                size: 28, 
                                color: hasNotifications 
                                    ? const Color(0xFFE5A00D)
                                    : Colors.white,
                              ),
                              
                              if (hasNotifications && totalNotifications > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFE5A00D), Color(0xFFD4940A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF121212),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    constraints: BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    child: Text(
                                      totalNotifications > 9 ? '9+' : totalNotifications.toString(),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}