import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NotificationBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> sessionInvites;
  final List<Map<String, dynamic>> friendRequests;
  final List<Map<String, dynamic>> regularNotifications;
  final Function(Map<String, dynamic>) onSessionAccept;
  final Function(Map<String, dynamic>) onSessionDecline;
  final Function(Map<String, dynamic>) onFriendAccept;
  final Function(Map<String, dynamic>) onFriendDecline;
  final VoidCallback onClearAll;

  const NotificationBottomSheet({
    super.key,
    required this.sessionInvites,
    required this.friendRequests,
    required this.regularNotifications,
    required this.onSessionAccept,
    required this.onSessionDecline,
    required this.onFriendAccept,
    required this.onFriendDecline,
    required this.onClearAll,
  });

  @override
  State<NotificationBottomSheet> createState() => _NotificationBottomSheetState();
}

class _NotificationBottomSheetState extends State<NotificationBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _staggerController;
  
  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalNotifications = widget.sessionInvites.length + 
                              widget.friendRequests.length + 
                              widget.regularNotifications.length;
    
    return AnimatedBuilder(
      animation: _slideController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _slideController,
            curve: Curves.easeOutCubic,
          )),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with grab handle and controls
                _buildHeader(totalNotifications),
                
                // Content
                Expanded(
                  child: totalNotifications == 0
                      ? _buildEmptyState()
                      : _buildNotificationsList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int totalNotifications) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      child: Column(
        children: [
          // Grab handle
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Header row
          Row(
            children: [
              // Title with count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_active,
                          color: const Color(0xFFE5A00D),
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (totalNotifications > 0)
                      Text(
                        '$totalNotifications unread',
                        style: TextStyle(
                          color: const Color(0xFFE5A00D),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Action buttons
              if (totalNotifications > 0) ...[
                // Clear all button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: IconButton(
                    onPressed: widget.onClearAll,
                    icon: Icon(
                      Icons.clear_all,
                      color: Colors.red,
                      size: 20.sp,
                    ),
                    tooltip: 'Clear All',
                  ),
                ),
                SizedBox(width: 8.w),
              ],
              
              // Close button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // High priority notifications first
              if (widget.sessionInvites.isNotEmpty)
                _buildNotificationSection(
                  title: "🎬 Movie Session Invites",
                  subtitle: "${widget.sessionInvites.length} waiting for you",
                  color: const Color(0xFFE5A00D),
                  notifications: widget.sessionInvites,
                  builder: _buildSessionInviteCard,
                  animationDelay: 0.0,
                ),
              
              if (widget.friendRequests.isNotEmpty)
                _buildNotificationSection(
                  title: "👥 Friend Requests", 
                  subtitle: "${widget.friendRequests.length} new requests",
                  color: Colors.blue,
                  notifications: widget.friendRequests,
                  builder: _buildFriendRequestCard,
                  animationDelay: 0.2,
                ),
              
              if (widget.regularNotifications.isNotEmpty)
                _buildNotificationSection(
                  title: "📢 Recent Activity",
                  subtitle: "${widget.regularNotifications.length} updates",
                  color: Colors.grey[400]!,
                  notifications: widget.regularNotifications,
                  builder: _buildRegularNotificationCard,
                  animationDelay: 0.4,
                ),
              
              SizedBox(height: 32.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required String subtitle,
    required Color color,
    required List<Map<String, dynamic>> notifications,
    required Widget Function(Map<String, dynamic>, int) builder,
    required double animationDelay,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          animationDelay,
          (animationDelay + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            animationDelay,
            (animationDelay + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(bottom: 24.h),
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
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        _getSectionIcon(title),
                        color: color,
                        size: 16.sp,
                      ),
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
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: color,
                              fontSize: 11.sp,
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
              
              // Notification cards with staggered animation
              ...notifications.asMap().entries.map((entry) {
                final index = entry.key;
                final notification = entry.value;
                
                final itemDelay = (0.05 * index.clamp(0, 10));
                
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.2, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _staggerController,
                    curve: Interval(
                      (animationDelay + 0.1 + itemDelay).clamp(0.0, 0.95),
                      (animationDelay + 0.3 + itemDelay).clamp(0.05, 1.0),
                      curve: Curves.easeOutCubic,
                    ),
                  )),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _staggerController,
                      curve: Interval(
                        (animationDelay + 0.1 + (itemDelay * 0.5)).clamp(0.0, 0.95),
                        (animationDelay + 0.25 + (itemDelay * 0.5)).clamp(0.05, 1.0),
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: builder(notification, index),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    if (title.contains('Movie')) return Icons.movie_creation;
    if (title.contains('Friend')) return Icons.people_alt;
    return Icons.notifications;
  }

  Widget _buildSessionInviteCard(Map<String, dynamic> invitation, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.1),
            const Color(0xFF2A2A2A),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${invitation['fromUserName']} invited you to a movie session!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => widget.onSessionDecline(invitation),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white24),
                    minimumSize: Size(0, 36.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text(
                    "Decline",
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
                  ),
                ),

              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => widget.onSessionAccept(invitation),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A00D),
                    foregroundColor: Colors.black,
                    minimumSize: Size(0, 36.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  child: Text(
                    "Join Session",
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFriendRequestCard(Map<String, dynamic> request, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Center(
              child: Text(
                request['fromUserName'][0].toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request['fromUserName'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "wants to be friends",
                  style: TextStyle(
                    color: Colors.blue.shade300,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => widget.onFriendDecline(request),
                icon: Icon(Icons.check, color: Colors.white, size: 18.sp),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(32.w, 32.h),
                ),
              ),
              SizedBox(width: 4.w),
              IconButton(
                onPressed: () => widget.onFriendAccept(request),
                icon: Icon(Icons.check, color: Colors.white, size: 18.sp),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(32.w, 32.h),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegularNotificationCard(Map<String, dynamic> notification, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications,
            color: Colors.grey[400],
            size: 16.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification['title'] ?? 'Notification',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (notification['message'] != null)
                  Text(
                    notification['message'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 11.sp,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 48.sp,
              color: const Color(0xFFE5A00D),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "All caught up! 🎉",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "No new notifications to show",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}