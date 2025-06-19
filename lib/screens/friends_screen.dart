import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../models/friend_group.dart';
import '../movie.dart';
import 'friend_profile_screen.dart';
import 'add_friend_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import 'matcher_screen.dart';
import '../services/friendship_service.dart';
import '../services/group_service.dart';
import '../utils/debug_loader.dart';

class FriendsScreen extends StatefulWidget {
  final UserProfile currentUser;
  final List<Movie> allMovies;
  final VoidCallback onShowMatches;
  final void Function(UserProfile friend)? onMatchWithFriend;

  const FriendsScreen({
    super.key,
    required this.currentUser,
    required this.allMovies,
    required this.onShowMatches,
    this.onMatchWithFriend,
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FriendGroup> _groups = [];
  bool _isLoadingGroups = false;

  final GroupService _groupService = GroupService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;

    setState(() => _isLoadingGroups = true);

    try {
      final loadedGroups = await _groupService.getUserGroups(widget.currentUser.uid);

      if (mounted) {
        setState(() {
          _groups = loadedGroups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      DebugLogger.log('❌ Error loading groups: $e');
      setState(() => _isLoadingGroups = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading groups: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _createNewGroup() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StreamBuilder<List<UserProfile>>(
          stream: FriendshipService.watchFriends(widget.currentUser.uid),
          builder: (context, snapshot) {
            final friends = snapshot.data ?? [];
            return CreateGroupScreen(
              currentUser: widget.currentUser,
              friends: friends,
            );
          },
        ),
      ),
    );
    _loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        title: Text(
          'Friends', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            letterSpacing: 0.5,
          )
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.h),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFE5A00D),
              indicatorWeight: 3.h,
              indicatorPadding: EdgeInsets.symmetric(horizontal: 20.w),
              labelColor: const Color(0xFFE5A00D),
              unselectedLabelColor: Colors.white60,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16.sp,
              ),
              tabs: [
                StreamBuilder<List<UserProfile>>(
                  stream: FriendshipService.watchFriends(widget.currentUser.uid),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return                     Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people, size: 20.sp),
                          SizedBox(width: 8.w),
                          Text('FRIENDS ($count)'),
                        ],
                      ),
                    );
                  },
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text('GROUPS (${_groups.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF121212),
              const Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildEnhancedFriendsTab(),
            _buildEnhancedGroupsTab(),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Only show FAB for groups tab since friends has prominent add button
    if (_tabController.index == 1) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_tabController.index),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: LinearGradient(
              colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                blurRadius: 12.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _createNewGroup,
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Icon(
              Icons.group_add,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildEnhancedFriendsTab() {
    return Column(
      children: [
        // Enhanced add friends section
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1F1F1F),
                const Color(0xFF1F1F1F).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddFriendScreen(currentUser: widget.currentUser),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Friends',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Find your movie mates',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Friends list with enhanced design
        Expanded(
          child: StreamBuilder<List<UserProfile>>(
            stream: FriendshipService.watchFriends(widget.currentUser.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState('Error loading friends', snapshot.error.toString());
              }

              final friends = snapshot.data ?? [];
              
              if (friends.isEmpty) {
                return _buildEmptyFriendsState();
              }

              return RefreshIndicator(
                onRefresh: () async => setState(() {}),
                color: const Color(0xFFE5A00D),
                backgroundColor: const Color(0xFF1F1F1F),
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 100.h),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return _buildEnhancedFriendCard(friend, index);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedGroupsTab() {
    if (_isLoadingGroups) {
      return _buildLoadingState();
    }

    if (_groups.isEmpty) {
      return _buildEmptyGroupsState();
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: const Color(0xFFE5A00D),
      backgroundColor: const Color(0xFF1F1F1F),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 100.h),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildEnhancedGroupCard(group, index);
        },
      ),
    );
  }

  Widget _buildEnhancedFriendCard(UserProfile friend, int index) {
    final sharedGenres = friend.preferredGenres.intersection(widget.currentUser.preferredGenres);
    final compatibility = widget.currentUser.preferredGenres.isEmpty || friend.preferredGenres.isEmpty
        ? 0.0
        : (sharedGenres.length / (widget.currentUser.preferredGenres.length + friend.preferredGenres.length - sharedGenres.length)) * 100;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20.h * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1F1F1F),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendProfileScreen(
                        currentUser: widget.currentUser,
                        friend: friend,
                        allMovies: widget.allMovies,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        // Compact avatar with online status
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 24.r,
                              backgroundColor: Colors.grey[800],
                              child: Text(
                                friend.name.isNotEmpty ? friend.name[0].toUpperCase() : "?",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14.w,
                                height: 14.h,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF1F1F1F), width: 2.w),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 12.w),
                        
                        // Compact friend info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      friend.name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // See more indicator
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14.sp,
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              
                              // Simple compatibility bar
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 14.sp,
                                    color: compatibility > 70 ? Colors.red : 
                                           compatibility > 40 ? Colors.orange : Colors.grey,
                                  ),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: Container(
                                      height: 3.h,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(1.5.r),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: compatibility / 100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: compatibility > 70 ? Colors.red :
                                                   compatibility > 40 ? Colors.orange : Colors.grey,
                                            borderRadius: BorderRadius.circular(1.5.r),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    compatibility > 0 ? '${compatibility.toInt()}%' : 'New',
                                    style: TextStyle(
                                      color: compatibility > 70 ? Colors.red :
                                             compatibility > 40 ? Colors.orange : Colors.grey,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 12.w),
                        
                        // Compact match button
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                                blurRadius: 6.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                DebugLogger.log("🟡 Creating match session with friend: ${friend.name}");
                                // Create session and navigate to matcher screen
                                final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MatcherScreen(
                                      sessionId: sessionId,
                                      allMovies: widget.allMovies,
                                      currentUser: widget.currentUser,
                                      friendIds: [friend], // Single friend session
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12.r),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                child: Text(
                                  'Match',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedGroupCard(FriendGroup group, int index) {
    final isCreator = group.isCreatedBy(widget.currentUser.uid);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1F1F1F),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(
                        group: group,
                        currentUser: widget.currentUser,
                        allMovies: widget.allMovies,
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Enhanced group avatar
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: group.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        group.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.group, color: Colors.white, size: 32);
                                        },
                                      ),
                                    )
                                  : const Icon(Icons.group, color: Colors.white, size: 32),
                            ),
                            const SizedBox(width: 16),
                            
                            // Enhanced group info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          group.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (group.isPrivate)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.lock, color: Colors.white54, size: 16),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (group.description.isNotEmpty)
                                    Text(
                                      group.description,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  
                                  // Enhanced group stats
                                  Row(
                                    children: [
                                      _buildStatChip(Icons.people, '${group.memberCount} member${group.memberCount != 1 ? 's' : ''}'),
                                      const SizedBox(width: 12),
                                      _buildStatChip(Icons.movie, '${group.totalSessions} session${group.totalSessions != 1 ? 's' : ''}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            // Enhanced match button
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MatcherScreen(
                                          sessionId: sessionId,
                                          allMovies: widget.allMovies,
                                          currentUser: widget.currentUser,
                                          friendIds: group.members,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.movie_filter, color: Colors.white, size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Match',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Enhanced member section
                        if (group.members.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 40,
                                  child: Stack(
                                    children: [
                                      ...group.members.take(5).toList().asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final member = entry.value;
                                        return Positioned(
                                          left: index * 30.0,
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [Colors.grey[600]!, Colors.grey[800]!],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFF1F1F1F), width: 3),
                                            ),
                                            child: Center(
                                              child: Text(
                                                member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      if (group.members.length > 5)
                                        Positioned(
                                          left: 5 * 30.0,
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                              border: Border.all(color: const Color(0xFF1F1F1F), width: 3),
                                            ),
                                            child: Center(
                                              child: Text(
                                                "+${group.members.length - 5}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              // Creator badge
                              if (isCreator)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, size: 14, color: Color(0xFFE5A00D)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Creator',
                                        style: TextStyle(color: Color(0xFFE5A00D), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white54),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: CircularProgressIndicator(
              color: const Color(0xFFE5A00D),
              strokeWidth: 3.w,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Keep existing empty state methods but with enhanced styling
  Widget _buildEmptyFriendsState() {
    return _buildEmptyState(
      icon: Icons.people_outline,
      title: 'No friends yet',
      subtitle: 'Add friends to match movies together and discover what you both love!',
      actionText: 'Add Friends',
      actionIcon: Icons.person_add,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddFriendScreen(currentUser: widget.currentUser),
        ),
      ),
    );
  }

  Widget _buildEmptyGroupsState() {
    return _buildEmptyState(
      icon: Icons.group_outlined,
      title: 'No groups yet',
      subtitle: 'Create groups to match movies with multiple friends and find films everyone will enjoy',
      actionText: 'Create Group',
      actionIcon: Icons.group_add,
      onPressed: _createNewGroup,
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required IconData actionIcon,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1F1F1F),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 72.sp,
                color: const Color(0xFFE5A00D).withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 40.h),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                    blurRadius: 12.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(actionIcon, color: Colors.white, size: 24.sp),
                        SizedBox(width: 12.w),
                        Text(
                          actionText,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String title, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}