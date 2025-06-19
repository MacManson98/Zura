import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import '../models/session_models.dart';
import '../services/session_service.dart';
import '../services/friendship_service.dart';
import 'movie_detail_screen.dart';
import 'package:collection/collection.dart';
import '../utils/debug_loader.dart';

class NotificationsScreen extends StatefulWidget {
  final UserProfile currentUser;
  final List<Movie> allMovies;
  final Function(SwipeSession session)? onSessionJoined;

  const NotificationsScreen({
    super.key,
    required this.currentUser,
    required this.allMovies,
    this.onSessionJoined,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> 
    with TickerProviderStateMixin {
  bool _isClearing = false;
  List<Map<String, dynamic>> _regularNotifications = [];
  late AnimationController _animationController;
  late AnimationController _refreshController;
  
  // Animation controllers for different sections
  List<AnimationController> _sectionControllers = [];
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _loadRegularNotifications();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _refreshController.dispose();
    for (var controller in _sectionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRegularNotifications() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _regularNotifications = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'movieId': data['movieId'],
          'timestamp': data['timestamp'],
          'read': data['read'] ?? false,
          'type': data['type'] ?? 'general',
        };
      }).toList();
    });

    // Mark all as read
    for (final doc in snapshot.docs) {
      if (!(doc.data()['read'] ?? false)) {
        doc.reference.update({'read': true});
      }
    }
  }

  Future<void> _refreshNotifications() async {
    _refreshController.forward();
    await _loadRegularNotifications();
    await Future.delayed(const Duration(milliseconds: 500));
    _refreshController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          // Custom animated app bar
          SliverAppBar(
            expandedHeight: 120.h,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(0.0, 0.6, curve: Curves.easeOutBack),
                    )),
                    child: FadeTransition(
                      opacity: _animationController,
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24.sp,
                        ),
                      ),
                    ),
                  );
                },
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF1F1F1F),
                      const Color(0xFF121212),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              AnimatedBuilder(
                animation: _refreshController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _refreshController.value * 2 * 3.14159,
                    child: IconButton(
                      icon: Icon(Icons.refresh, color: const Color(0xFFE5A00D)),
                      onPressed: _refreshNotifications,
                    ),
                  );
                },
              ),
            ],
          ),
          
          // Main content
          SliverToBoxAdapter(
            child: _buildNotificationsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SessionService.watchPendingInvitations(),
      builder: (context, sessionSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FriendshipService.getPendingFriendRequests(widget.currentUser.uid),
          builder: (context, friendSnapshot) {
            final sessionInvites = sessionSnapshot.data ?? [];
            final friendRequests = friendSnapshot.data ?? [];
            
            final hasHighPriority = sessionInvites.isNotEmpty || friendRequests.isNotEmpty;
            final hasAnyNotifications = hasHighPriority || _regularNotifications.isNotEmpty;
            
            if (!hasAnyNotifications) {
              return _buildEmptyState();
            }

            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    _buildClearAllButton(hasAnyNotifications),
                    // High Priority Section (Session Invites)
                    if (sessionInvites.isNotEmpty)
                      _buildAnimatedSection(
                        title: "Movie Session Invites",
                        subtitle: "${sessionInvites.length} waiting for you",
                        icon: Icons.movie_creation,
                        color: const Color(0xFFE5A00D),
                        animationDelay: 0.0,
                        children: sessionInvites.asMap().entries.map((entry) =>
                          _buildSessionInviteCard(entry.value, entry.key)
                        ).toList(),
                      ),
                    
                    // Friend Requests Section
                    if (friendRequests.isNotEmpty)
                      _buildAnimatedSection(
                        title: "Friend Requests",
                        subtitle: "${friendRequests.length} new requests",
                        icon: Icons.people_alt,
                        color: Colors.blue,
                        animationDelay: 0.2,
                        children: friendRequests.asMap().entries.map((entry) =>
                          _buildFriendRequestCard(entry.value, entry.key)
                        ).toList(),
                      ),
                    
                    // Regular Notifications Section
                    if (_regularNotifications.isNotEmpty)
                      _buildAnimatedSection(
                        title: hasHighPriority ? "Other Updates" : "Recent Activity",
                        subtitle: "${_regularNotifications.length} notifications",
                        icon: Icons.notifications,
                        color: Colors.grey[400]!,
                        animationDelay: hasHighPriority ? 0.4 : 0.0,
                        children: _regularNotifications.asMap().entries.map((entry) =>
                          _buildRegularNotificationCard(entry.value, entry.key)
                        ).toList(),
                      ),
                    
                    SizedBox(height: 32.h),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAnimatedSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double animationDelay,
    required List<Widget> children,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          animationDelay,
          (animationDelay + 0.6).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            animationDelay,
            (animationDelay + 0.4).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(icon, color: color, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: color,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 8.h),
              
              // Fixed staggered animation for cards - limits to first 10 items for animation
              ...children.asMap().entries.map((entry) {
                final index = entry.key;
                final child = entry.value;
                
                // Limit animation stagger to first 10 items to prevent interval overflow
                final animationIndex = index.clamp(0, 9);
                final maxStagger = 0.3; // Maximum total stagger time
                final itemDelay = (maxStagger / 10) * animationIndex;
                
                final slideStart = (animationDelay + 0.1 + itemDelay).clamp(0.0, 0.95);
                final slideEnd = (animationDelay + 0.5 + itemDelay).clamp(slideStart + 0.05, 1.0);
                final fadeStart = (animationDelay + 0.1 + (itemDelay * 0.5)).clamp(0.0, 0.95);
                final fadeEnd = (animationDelay + 0.4 + (itemDelay * 0.5)).clamp(fadeStart + 0.05, 1.0);
                
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _animationController,
                    curve: Interval(
                      slideStart,
                      slideEnd,
                      curve: Curves.easeOutCubic,
                    ),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        fadeStart,
                        fadeEnd,
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: child,
                  ),
                );
              }).toList(),
              
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInviteCard(Map<String, dynamic> invitation, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.15),
            const Color(0xFF1F1F1F),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.movie_creation,
                    color: const Color(0xFFE5A00D),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${invitation['fromUserName']} invited you",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            "to a movie night",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14.sp,
                            ),
                          ),
                          if (invitation['hasMood'] == true) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (invitation['selectedMoodEmoji'] != null)
                                    Text(
                                      invitation['selectedMoodEmoji'],
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                  if (invitation['selectedMoodName'] != null) ...[
                                    SizedBox(width: 4.w),
                                    Text(
                                      invitation['selectedMoodName'],
                                      style: TextStyle(
                                        color: const Color(0xFFE5A00D),
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _declineSessionInvitation(invitation['id'], invitation['sessionId']),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.w),
                      minimumSize: Size(0, 44.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                    child: Text(
                      "Decline",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptSessionInvitation(invitation),
                    icon: Icon(Icons.play_arrow, size: 18.sp),
                    label: Text("Join Session"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5A00D),
                      foregroundColor: Colors.black,
                      minimumSize: Size(0, 44.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRequestCard(Map<String, dynamic> request, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            const Color(0xFF1F1F1F),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Center(
                child: Text(
                  request['fromUserName'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['fromUserName'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "wants to be friends",
                    style: TextStyle(
                      color: Colors.blue.shade300,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: IconButton(
                    onPressed: () => _declineFriendRequest(request),
                    icon: Icon(Icons.close, color: Colors.white70, size: 18.sp),
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: IconButton(
                    onPressed: () => _acceptFriendRequest(request),
                    icon: Icon(Icons.check, color: Colors.white, size: 18.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegularNotificationCard(Map<String, dynamic> note, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.w,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            _getNotificationIcon(note['type']),
            color: Colors.grey[400],
            size: 20.sp,
          ),
        ),
        title: Text(
          note['title'],
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          note['message'],
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13.sp,
          ),
        ),
        trailing: note['movieId'] != null
            ? Icon(Icons.chevron_right, color: Colors.grey[500], size: 20.sp)
            : null,
        onTap: note['movieId'] != null
            ? () => _openMovieDetails(note['movieId'])
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      )),
      child: FadeTransition(
        opacity: _animationController,
        child: Container(
          margin: EdgeInsets.all(32.w),
          padding: EdgeInsets.all(48.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1F1F1F),
                const Color(0xFF2A2A2A),
              ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1.w,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_off_outlined,
                  size: 64.sp,
                  color: const Color(0xFFE5A00D),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "All caught up! 🎉",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                "No new notifications to show",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'match':
        return Icons.favorite;
      case 'friend_activity':
        return Icons.people;
      case 'system':
        return Icons.settings;
      case 'movie_recommendation':
        return Icons.movie;
      default:
        return Icons.notifications;
    }
  }

  // Action methods
  Future<void> _acceptSessionInvitation(Map<String, dynamic> invitation) async {
    try {
      final session = await SessionService.acceptInvitation(
        invitation['sessionId'],
        widget.currentUser.name,
      );
      
      if (!mounted) return;
      
      if (session != null) {
        widget.onSessionJoined?.call(session);
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.w),
                Text('Successfully joined the session!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      DebugLogger.log("❌ Error accepting session invitation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineSessionInvitation(String invitationId, String? sessionId) async {
    try {
      await SessionService.declineInvitation(invitationId, sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session invitation declined'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      DebugLogger.log("❌ Error declining session invitation: $e");
    }
  }

  Future<void> _acceptFriendRequest(Map<String, dynamic> request) async {
    try {
      await FriendshipService.acceptFriendRequest(
        fromUserId: request['fromUserId'],
        toUserId: request['toUserId'],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.people, color: Colors.white),
                SizedBox(width: 8.w),
                Text('${request['fromUserName']} is now your friend!'),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept request: $e')),
        );
      }
    }
  }

  Future<void> _declineFriendRequest(Map<String, dynamic> request) async {
    try {
      await FriendshipService.declineFriendRequest(
        fromUserId: request['fromUserId'],
        toUserId: request['toUserId'],
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request: $e')),
        );
      }
    }
  }

  Future<void> _openMovieDetails(String movieId) async {
    final movie = widget.allMovies.firstWhereOrNull((m) => m.id == movieId);
    if (movie == null) {
      DebugLogger.log("⚠️ Movie not found.");
      return;
    }

    showMovieDetails(
      context: context,
      movie: movie,
      currentUser: widget.currentUser,
    );
  }

  Widget _buildClearAllButton(bool hasNotifications) {
    if (!hasNotifications) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.1, 0.5, curve: Curves.easeOutBack),
        )),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.1),
                  Colors.red.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1.w,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isClearing ? null : () => _clearAllNotifications(context),
                borderRadius: BorderRadius.circular(12.r),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isClearing) ...[
                        SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Clearing all notifications...',
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.clear_all,
                          color: Colors.red,
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Clear All Notifications',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllNotifications(BuildContext context) async {
    // Show confirmation dialog
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            Icon(Icons.clear_all, color: const Color(0xFFE5A00D), size: 24.sp),
            SizedBox(width: 12.w),
            Text(
              'Clear All Notifications',
              style: TextStyle(color: Colors.white, fontSize: 18.sp),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will:',
              style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.h),
            _buildClearOption('• Clear all regular notifications'),
            _buildClearOption('• Decline all session invitations'),
            _buildClearOption('• Decline all friend requests'),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone',
                      style: TextStyle(color: Colors.orange, fontSize: 13.sp),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A00D),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('Clear All', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldClear != true) return;

    setState(() {
      _isClearing = true;
    });

    try {
      // Start clearing animation
      _refreshController.forward();

      // 1. Clear regular notifications from Firestore
      await _clearRegularNotifications();

      // 2. Get and decline all session invitations
      await _declineAllSessionInvitations();

      // 3. Get and decline all friend requests  
      await _declineAllFriendRequests();

      // 4. Clear local state
      setState(() {
        _regularNotifications.clear();
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Text(
                  'All notifications cleared successfully',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }

    } catch (e) {
      DebugLogger.log("❌ Error clearing notifications: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white, size: 20.sp),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Failed to clear some notifications: $e',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
        );
      }
    } finally {
      setState(() {
        _isClearing = false;
      });
      _refreshController.reset();
    }
  }

  Widget _buildClearOption(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[300], fontSize: 14.sp),
      ),
    );
  }

  // Clear regular notifications from Firestore
  Future<void> _clearRegularNotifications() async {
    final batch = FirebaseFirestore.instance.batch();
    
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.uid)
        .collection('notifications')
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    DebugLogger.log("✅ Cleared ${snapshot.docs.length} regular notifications");
  }

  // Decline all session invitations
  Future<void> _declineAllSessionInvitations() async {
    try {
      final invitations = await SessionService.getPendingInvitations();
      
      for (final invitation in invitations) {
        await SessionService.declineInvitation(
          invitation['id'], 
          invitation['sessionId']
        );
      }
      
      DebugLogger.log("✅ Declined ${invitations.length} session invitations");
    } catch (e) {
      DebugLogger.log("⚠️ Error declining session invitations: $e");
      // Don't throw - we want to continue with other clearing operations
    }
  }

  // Decline all friend requests
  Future<void> _declineAllFriendRequests() async {
    try {
      final requests = await FriendshipService.getPendingFriendRequestsList(widget.currentUser.uid);
      
      for (final request in requests) {
        await FriendshipService.declineFriendRequest(
          fromUserId: request['fromUserId'],
          toUserId: request['toUserId'],
        );
      }
      
      DebugLogger.log("✅ Declined ${requests.length} friend requests");
    } catch (e) {
      DebugLogger.log("⚠️ Error declining friend requests: $e");
      // Don't throw - we want to continue with other clearing operations
    }
  }
}