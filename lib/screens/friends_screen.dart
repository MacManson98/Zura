import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/user_profile.dart';
import '../models/friend_group.dart';
import '../movie.dart';
import 'friend_profile_screen.dart';
import 'add_friend_screen.dart';
import 'create_group_screen.dart';
import 'group_detail_screen.dart';
import '../services/friendship_service.dart';
import '../services/group_service.dart';
import '../utils/debug_loader.dart';
import '../utils/themed_notifications.dart';

class FriendsScreen extends StatefulWidget {
  final UserProfile currentUser;
  final List<Movie> allMovies;
  final void Function(UserProfile friend)? onMatchWithFriend;
  final void Function(VoidCallback callback)? onRegisterRefreshCallback; // ✅ NEW

  const FriendsScreen({
    super.key,
    required this.currentUser,
    required this.allMovies,
    this.onMatchWithFriend,
    this.onRegisterRefreshCallback, // ✅ NEW
  });

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<FriendGroup> _groups = [];
  bool _isLoadingGroups = false;

  final GroupService _groupService = GroupService();

  Future<void> refreshGroups() async {
    await _loadGroups();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGroups();
    
    // ✅ ADD THIS: Register the refresh callback with MainNavigation
    if (widget.onRegisterRefreshCallback != null) {
      widget.onRegisterRefreshCallback!(_loadGroups); // or _loadGroups
    }
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
        ThemedNotifications.showError(context, 'Error loading groups: $e');
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
            fontSize: 20.sp,
            letterSpacing: 0.3,
          )
        ),
      ),
      // Keep the floating action button functionality
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
        child: Column(
          children: [
            // Clean modern tab selector
            _buildModernTabSelector(),
            
            // Content based on selected tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsContent(),
                  _buildGroupsContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep the original floating action button logic
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

  Widget _buildModernTabSelector() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: StreamBuilder<List<UserProfile>>(
        stream: FriendshipService.watchFriends(widget.currentUser.uid),
        builder: (context, snapshot) {
          final friendCount = snapshot.data?.length ?? 0;
          
          return Container(
            height: 44.h,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1F1F),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                // Friends tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        final isSelected = _tabController.index == 0;
                        return Container(
                          height: double.infinity,
                          margin: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people,
                                size: 16.sp,
                                color: isSelected ? Colors.white : Colors.white60,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'FRIENDS ($friendCount)',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 13.sp,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Groups tab
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        final isSelected = _tabController.index == 1;
                        return Container(
                          height: double.infinity,
                          margin: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.group,
                                size: 16.sp,
                                color: isSelected ? Colors.white : Colors.white60,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                'GROUPS (${_groups.length})',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white60,
                                  fontSize: 13.sp,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendsContent() {
    return Column(
      children: [
        // Beautiful glassmorphic "Add Friends" section
        Container(
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 60.h,
            borderRadius: 16,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE5A00D).withValues(alpha: 0.3),
                Colors.orange.withValues(alpha: 0.25),
                Colors.orange.shade600.withValues(alpha: 0.2),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFE5A00D).withValues(alpha: 0.6),
                Colors.orange.withValues(alpha: 0.4),
                Colors.white.withValues(alpha: 0.2),
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
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Add Friends',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            Text(
                              'Find your movie mates',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.sp,
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
        
        // Friends list - keep all original functionality
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
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return _buildCleanFriendCard(friend, index);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsContent() {
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
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return _buildCleanGroupCard(group, index);
        },
      ),
    );
  }

  Widget _buildCleanFriendCard(UserProfile friend, int index) {
    final sharedGenres = friend.preferredGenres.intersection(widget.currentUser.preferredGenres);
    final sharedMovies = friend.likedMovieIds.intersection(widget.currentUser.likedMovieIds);
    
    final compatibility = sharedMovies.isNotEmpty 
        ? (sharedMovies.length / (widget.currentUser.likedMovieIds.length + friend.likedMovieIds.length - sharedMovies.length).clamp(1, double.infinity)) * 100
        : widget.currentUser.preferredGenres.isEmpty || friend.preferredGenres.isEmpty
            ? 0.0
            : (sharedGenres.length / (widget.currentUser.preferredGenres.length + friend.preferredGenres.length - sharedGenres.length)) * 100;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 16.h * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
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
                      blurRadius: 6.r,
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
                          // Avatar with online status
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 22.r,
                                backgroundColor: Colors.grey[800],
                                child: Text(
                                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : "?",
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12.w,
                                  height: 12.h,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF1F1F1F), width: 2.w),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 16.w),
                          
                          // Friend info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  friend.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                
                                // Compatibility indicator
                                Row(
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 12.sp,
                                      color: compatibility > 70 ? Colors.red : 
                                             compatibility > 40 ? Colors.orange : Colors.grey,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '${sharedMovies.length} movies in common',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Compatibility badge and action
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: compatibility > 70 ? Colors.green.withValues(alpha: 0.2) :
                                         compatibility > 40 ? Colors.orange.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  compatibility > 0 ? '${compatibility.toInt()}%' : 'New',
                                  style: TextStyle(
                                    color: compatibility > 70 ? Colors.green :
                                           compatibility > 40 ? Colors.orange : Colors.grey,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 12.sp,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildCleanGroupCard(FriendGroup group, int index) {
    final isCreator = group.isCreatedBy(widget.currentUser.uid);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 300 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Container(
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
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
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
                          onGroupUpdated: () async {
                            await _loadGroups();
                          },
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Group icon
                              Container(
                                width: 56.w,
                                height: 56.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFE5A00D).withValues(alpha: 0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: group.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(14.r),
                                        child: Image.network(
                                          group.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(Icons.group, color: Colors.white, size: 28);
                                          },
                                        ),
                                      )
                                    : const Icon(Icons.group, color: Colors.white, size: 28),
                              ),
                              SizedBox(width: 16.w),
                              
                              // Group info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            group.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (group.isPrivate)
                                          Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(5.r),
                                            ),
                                            child: Icon(Icons.lock, color: Colors.white54, size: 14.sp),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    if (group.description.isNotEmpty)
                                      Text(
                                        group.description,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 12.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Creator badge
                              if (isCreator)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, size: 12.sp, color: Color(0xFFE5A00D)),
                                      SizedBox(width: 3.w),
                                      Text(
                                        'Creator',
                                        style: TextStyle(color: Color(0xFFE5A00D), fontSize: 10.sp),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          
                          // Members and stats
                          if (group.members.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                // Member avatars
                                Expanded(
                                  child: SizedBox(
                                    height: 32.h,
                                    child: Stack(
                                      children: [
                                        ...group.members.take(5).toList().asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final member = entry.value;
                                          return Positioned(
                                            left: index * 24.0,
                                            child: Container(
                                              width: 32.w,
                                              height: 32.h,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [Colors.grey[600]!, Colors.grey[800]!],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF1F1F1F), width: 2.w),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
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
                                            left: 5 * 24.0,
                                            child: Container(
                                              width: 32.w,
                                              height: 32.h,
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF1F1F1F), width: 2.w),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  "+${group.members.length - 5}",
                                                  style: TextStyle(
                                                    fontSize: 9.sp,
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
                                
                                // Stats
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '${group.memberCount} members • ${group.totalSessions} sessions',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10.sp,
                                    ),
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
      ),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassmorphicContainer(
              width: 120.w,
              height: 120.h,
              borderRadius: 20,
              blur: 20,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              child: Icon(
                Icons.people_outline,
                size: 56.sp,
                color: const Color(0xFFE5A00D).withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No friends yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Add friends to match movies together and discover what you both love!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGroupsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassmorphicContainer(
              width: 120.w,
              height: 120.h,
              borderRadius: 20,
              blur: 20,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              child: Icon(
                Icons.group_outlined,
                size: 56.sp,
                color: const Color(0xFFE5A00D).withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No groups yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Create groups to match movies with multiple friends and find films everyone will enjoy',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            
            // Beautiful glassmorphic Create Group button
            GlassmorphicContainer(
              width: 200.w,
              height: 50.h,
              borderRadius: 16,
              blur: 15,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE5A00D).withValues(alpha: 0.3),
                  Colors.orange.withValues(alpha: 0.25),
                  Colors.orange.shade600.withValues(alpha: 0.2),
                ],
              ),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE5A00D).withValues(alpha: 0.6),
                  Colors.orange.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.2),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _createNewGroup,
                  borderRadius: BorderRadius.circular(16.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add, color: Colors.white, size: 20.sp),
                      SizedBox(width: 10.w),
                      Text(
                        'Create Group',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassmorphicContainer(
            width: 80.w,
            height: 80.h,
            borderRadius: 16,
            blur: 15,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFFE5A00D).withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: CircularProgressIndicator(
              color: const Color(0xFFE5A00D),
              strokeWidth: 2.w,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String title, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassmorphicContainer(
              width: 80.w,
              height: 80.h,
              borderRadius: 16,
              blur: 15,
              alignment: Alignment.center,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.2),
                  Colors.red.withValues(alpha: 0.1),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  Colors.red.withValues(alpha: 0.4),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              child: Icon(Icons.error_outline, size: 40.sp, color: Colors.red),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 12.sp),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}