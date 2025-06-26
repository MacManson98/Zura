// File: lib/main_navigation.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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
import '../utils/debug_loader.dart';
import '../models/matching_models.dart';
import 'services/group_invitation_service.dart';
import 'widgets/notifications_bottom_sheet.dart';


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
                                  onSessionDecline: (invitation) async {
                                    await _handleSessionDeclineFromNotification(invitation);
                                    final inviteId = invitation['inviteId'];
                                    setState(() {
                                      sessionInvites.removeWhere((inv) => inv['inviteId'] == inviteId);
                                    });
                                  },


                                  onFriendAccept: (request) {
                                    _handleFriendRequestAccept(request);
                                  },
                                  onFriendDecline: (request) {
                                    _handleFriendRequestDecline(request); // 👈 AND THIS
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
            ),
        ],
      ),
      bottomNavigationBar: null,
    );
  }

  // ✅ UNCHANGED: All notification methods remain the same
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

  Future<void> _handleSessionDeclineFromNotification(Map<String, dynamic> invitation) async {
    try {
      final inviteId = invitation['inviteId'] as String?;
      final sessionId = invitation['sessionId'] as String?;

      if (inviteId == null || sessionId == null) {
        throw Exception("Missing inviteId or sessionId: inviteId=$inviteId, sessionId=$sessionId");
      }

      DebugLogger.log("❌ Declining session invitation: $inviteId for session $sessionId");

      await SessionService.declineInvitation(inviteId, sessionId);

      await FirebaseFirestore.instance
          .collection('session_invitations')
          .doc(inviteId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 8),
              Text('Declined session invitation.'),
            ],
          ),
          backgroundColor: Colors.grey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      DebugLogger.log("❌ Error declining session invitation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline session: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }



  Future<void> _handleFriendRequestAccept(Map<String, dynamic> request) async {
    try {
      await FriendshipService.acceptFriendRequestById(
        requestDocumentId: request['id'],
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

  Future<void> _handleFriendRequestDecline(Map<String, dynamic> request) async {
    try {
      await FriendshipService.declineFriendRequestById(request['id']);

      await _loadFriends(); // Optional: refreshes UI if needed

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.person_off, color: Colors.white),
                SizedBox(width: 8),
                Text('Declined friend request from ${request['fromUserName']}'),
              ],
            ),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
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
          // Use the document ID from the request data, not the user IDs
          await FriendshipService.declineFriendRequestById(request['id']);
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