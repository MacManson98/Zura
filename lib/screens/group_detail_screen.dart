// File: lib/screens/group_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/friend_group.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import 'matcher_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final FriendGroup group;
  final UserProfile currentUser;
  final List<Movie> allMovies;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.currentUser,
    required this.allMovies,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  bool _isLoading = false;
  Set<Movie> _recommendedMovies = {};

  @override
  void initState() {
    super.initState();
    _loadGroupRecommendations();
  }

  void _loadGroupRecommendations() {
    setState(() {
      _isLoading = true;
    });

    // Simple mock implementation
    Future.delayed(const Duration(milliseconds: 1200), () {
      // Find movies based on members' liked movies
      Set<String> allLikedMovieIds = {};
      
      for (final member in widget.group.members) {
        allLikedMovieIds.addAll(member.likedMovieIds);
      }
      
      // Get actual movie objects for liked movies
      _recommendedMovies = widget.allMovies
          .where((movie) => allLikedMovieIds.contains(movie.id))
          .toSet();
      
      // Limit to 6 for display
      if (_recommendedMovies.length > 6) {
        _recommendedMovies = _recommendedMovies.take(6).toSet();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _startGroupMatching() {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatcherScreen(
          sessionId: sessionId,
          allMovies: widget.allMovies,
          currentUser: widget.currentUser,
          friendIds: widget.group.members,
        ),
      ),
    );
  }

  void _inviteMembers() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildInviteMembersSheet(),
    );
  }

  void _showGroupSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildGroupSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = widget.group.isCreatedBy(widget.currentUser.uid);
                    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          widget.group.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          // Obvious Settings Button
          Container(
            margin: EdgeInsets.only(right: 16.w),
            child: GestureDetector(
              onTap: _showGroupSettings,
              child: Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5A00D)))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group header card
                  _buildGroupHeaderCard(isCreator),
                  
                  SizedBox(height: 24.h),
                  
                  // Action buttons row
                  _buildActionButtonsRow(),
                  
                  SizedBox(height: 24.h),
                  
                  // Members section
                  _buildMembersSection(),
                  
                  SizedBox(height: 24.h),
                  
                  // Group recommendations section
                  _buildRecommendationsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildGroupHeaderCard(bool isCreator) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 150.h,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.centerLeft,
      border: 2,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.05),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.2),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            // Enhanced group avatar
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                    blurRadius: 12.r,
                    spreadRadius: 2.r,
                  ),
                ],
              ),
              child: widget.group.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Image.network(
                        widget.group.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.group, color: Colors.white, size: 40);
                        },
                      ),
                    )
                  : const Icon(Icons.group, color: Colors.white, size: 40),
            ),
            
            SizedBox(width: 20.w),
            
            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.group.name,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  SizedBox(height: 4.h),
                  
                  Text(
                    "Created by ${widget.group.createdBy}",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white60,
                    ),
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // Stats row
                  Row(
                    children: [
                      _buildStatChip(
                        "${widget.group.members.length}",
                        "Members",
                        Icons.people,
                      ),
                      SizedBox(width: 12.w),
                      _buildStatChip(
                        "${widget.group.totalSessions}",
                        "Sessions",
                        Icons.movie_filter,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8.h),
                  
                  // Group type badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: widget.group.isPrivate 
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: widget.group.isPrivate 
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.group.isPrivate ? Icons.lock : Icons.public,
                          size: 12.sp,
                          color: widget.group.isPrivate ? Colors.red : Colors.green,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          widget.group.isPrivate ? "Private" : "Public",
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: widget.group.isPrivate ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: const Color(0xFFE5A00D)),
          SizedBox(width: 4.w),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        // Start Matching Button
        Expanded(
          flex: 2,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 56.h,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              colors: [
                const Color(0xFFE5A00D).withValues(alpha: 0.9),
                Colors.orange.shade600.withValues(alpha: 0.9),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFFE5A00D),
                Colors.orange.shade600,
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _startGroupMatching,
                borderRadius: BorderRadius.circular(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.movie_filter,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "Start Matching",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(width: 16.w),
        
        // Invite Members Button
        Expanded(
          flex: 1,
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 56.h,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.center,
            border: 1,
            linearGradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.2),
                Colors.blue.withValues(alpha: 0.1),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.6),
                Colors.blue.withValues(alpha: 0.3),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _inviteMembers,
                borderRadius: BorderRadius.circular(16.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add,
                      color: Colors.blue,
                      size: 20.sp,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Invite",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Members",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "${widget.group.members.length} people",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),
        
        // Enhanced Members list
        _buildEnhancedMembersList(),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Recommended For Group",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        _recommendedMovies.isEmpty
            ? _buildEmptyRecommendations()
            : _buildRecommendationsGrid(),
      ],
    );
  }

  Widget _buildEnhancedMembersList() {
    return Column(
      children: widget.group.members.map((member) {
        final bool isCurrentUser = member.uid == widget.currentUser.uid;
        final bool isCreator = member.uid == widget.group.creatorId;
        
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 70.h,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.centerLeft,
            border: 1,
            linearGradient: LinearGradient(
              colors: isCurrentUser
                  ? [
                      const Color(0xFFE5A00D).withValues(alpha: 0.15),
                      const Color(0xFFE5A00D).withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.05),
                      Colors.white.withValues(alpha: 0.02),
                    ],
            ),
            borderGradient: LinearGradient(
              colors: isCurrentUser
                  ? [
                      const Color(0xFFE5A00D).withValues(alpha: 0.6),
                      const Color(0xFFE5A00D).withValues(alpha: 0.3),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Enhanced member avatar
                  Stack(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isCreator 
                                ? [const Color(0xFFE5A00D), Colors.orange.shade600]
                                : [Colors.blue.shade400, Colors.blue.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : "?",
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Creator crown
                      if (isCreator)
                        Positioned(
                          top: -2.h,
                          right: -2.w,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A00D),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: const Color(0xFF121212), width: 1.w),
                            ),
                            child: Icon(Icons.star, color: Colors.white, size: 10.sp),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(width: 12.w),
                  
                  // Member details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                member.name.isEmpty ? 'Unknown User' : member.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Status badges
                            if (isCurrentUser)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  "You",
                                  style: TextStyle(
                                    color: const Color(0xFFE5A00D),
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        SizedBox(height: 2.h),
                        
                        // Role indicator
                        Text(
                          isCreator ? 'Group Creator' : 'Member',
                          style: TextStyle(
                            color: isCreator ? const Color(0xFFE5A00D) : Colors.white54,
                            fontSize: 11.sp,
                            fontWeight: isCreator ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Member actions for non-current users
                  if (!isCurrentUser && widget.group.isCreatedBy(widget.currentUser.uid))
                    GestureDetector(
                      onTap: () => _showMemberOptions(member),
                      child: Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.white60,
                          size: 16.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32.h),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.movie_outlined,
                size: 48.sp,
                color: Colors.white24,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "No recommendations yet",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Start matching with this group to get recommendations",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: _recommendedMovies.length,
      itemBuilder: (context, index) {
        final movie = _recommendedMovies.elementAt(index);
        
        return GestureDetector(
          onTap: () {
            // Show movie details dialog
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Image.network(
                    movie.posterUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: Icon(Icons.broken_image, color: Colors.white30, size: 24.sp),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                movie.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // Invite Members Bottom Sheet
  Widget _buildInviteMembersSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF161616),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Header
            Row(
              children: [
                Icon(Icons.person_add, color: Colors.blue, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  "Invite Members",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20.h),
            
            // Share link option
            GlassmorphicContainer(
              width: double.infinity,
              height: 60.h,
              borderRadius: 16,
              blur: 10,
              alignment: Alignment.centerLeft,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.05),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  Colors.blue.withValues(alpha: 0.3),
                  Colors.blue.withValues(alpha: 0.1),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Share group invite link logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invite link sharing coming soon!'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Icon(Icons.share, color: Colors.blue, size: 24.sp),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Share Invite Link",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Send group invitation to friends",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16.sp),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // Direct invite option
            GlassmorphicContainer(
              width: double.infinity,
              height: 60.h,
              borderRadius: 16,
              blur: 10,
              alignment: Alignment.centerLeft,
              border: 1,
              linearGradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.green.withValues(alpha: 0.05),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.3),
                  Colors.green.withValues(alpha: 0.1),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Direct friend invite logic
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Friend selection coming soon!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.green, size: 24.sp),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Invite Friends Directly",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Select friends from your list",
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.green, size: 16.sp),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: Colors.white30),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Group Settings Bottom Sheet
  Widget _buildGroupSettingsSheet() {
    final isCreator = widget.group.isCreatedBy(widget.currentUser.uid);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1F1F1F),
            const Color(0xFF161616),
            const Color(0xFF121212),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Header
            Row(
              children: [
                Icon(Icons.settings, color: Colors.white, size: 24.sp),
                SizedBox(width: 12.w),
                Text(
                  "Group Settings",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24.h),
            
            // Settings options
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (isCreator) ...[
                      // Edit Group
                      _buildSettingsOption(
                        icon: Icons.edit,
                        title: "Edit Group Info",
                        subtitle: "Change name, description, and privacy",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit group coming soon!')),
                          );
                        },
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      // Manage Members
                      _buildSettingsOption(
                        icon: Icons.people_outline,
                        title: "Manage Members",
                        subtitle: "View and remove group members",
                        color: Colors.purple,
                        onTap: () {
                          Navigator.pop(context);
                          _showManageMembersDialog();
                        },
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      // Group Privacy
                      _buildSettingsOption(
                        icon: widget.group.isPrivate ? Icons.lock : Icons.public,
                        title: widget.group.isPrivate ? "Make Public" : "Make Private",
                        subtitle: widget.group.isPrivate 
                            ? "Allow anyone to discover and join"
                            : "Require invitations to join",
                        color: widget.group.isPrivate ? Colors.green : Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleGroupPrivacy();
                        },
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Danger zone separator
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1.h,
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              "DANGER ZONE",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1.h,
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16.h),
                      
                      // Delete Group (Creator only)
                      _buildSettingsOption(
                        icon: Icons.delete_forever,
                        title: "Delete Group",
                        subtitle: "Permanently delete this group and all data",
                        color: Colors.red,
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmDeleteGroup();
                        },
                      ),
                    ] else ...[
                      // Non-creator options
                      _buildSettingsOption(
                        icon: Icons.notifications,
                        title: "Notifications",
                        subtitle: "Manage group notification settings",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notification settings coming soon!')),
                          );
                        },
                      ),
                      
                      SizedBox(height: 12.h),
                      
                      _buildSettingsOption(
                        icon: Icons.report,
                        title: "Report Group",
                        subtitle: "Report inappropriate content or behavior",
                        color: Colors.orange,
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Report feature coming soon!')),
                          );
                        },
                      ),
                      
                      SizedBox(height: 24.h),
                      
                      // Leave Group
                      _buildSettingsOption(
                        icon: Icons.exit_to_app,
                        title: "Leave Group",
                        subtitle: "You can be re-invited by the group creator",
                        color: Colors.red,
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          _confirmLeaveGroup();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(color: Colors.white30),
                  ),
                ),
                child: Text(
                  "Close",
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 70.h,
      borderRadius: 16,
      blur: 10,
      alignment: Alignment.centerLeft,
      border: 1,
      linearGradient: LinearGradient(
        colors: isDestructive
            ? [
                Colors.red.withValues(alpha: 0.1),
                Colors.red.withValues(alpha: 0.05),
              ]
            : [
                Colors.white.withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.02),
              ],
      ),
      borderGradient: LinearGradient(
        colors: isDestructive
            ? [
                Colors.red.withValues(alpha: 0.3),
                Colors.red.withValues(alpha: 0.1),
              ]
            : [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.05),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                
                SizedBox(width: 16.w),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDestructive ? Colors.red : Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isDestructive ? Colors.red.shade300 : Colors.white60,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Icon(
                  Icons.arrow_forward_ios,
                  color: isDestructive ? Colors.red : Colors.white30,
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberOptions(UserProfile member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1F1F1F),
              const Color(0xFF121212),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            SizedBox(height: 20.h),
            
            Text(
              member.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 20.h),
            
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text("View Profile", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Navigate to member profile
              },
            ),
            
            ListTile(
              leading: Icon(Icons.message, color: Colors.green),
              title: Text("Send Message", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Open message dialog
              },
            ),
            
            if (widget.group.isCreatedBy(widget.currentUser.uid))
              ListTile(
                leading: Icon(Icons.remove_circle, color: Colors.red),
                title: Text("Remove from Group", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmRemoveMember(member);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showManageMembersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Manage Members",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Member management features coming soon!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: const Color(0xFFE5A00D))),
          ),
        ],
      ),
    );
  }

  void _toggleGroupPrivacy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Change Group Privacy",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          "Privacy settings will be available soon!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: const Color(0xFFE5A00D))),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Delete Group?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "This will permanently delete \"${widget.group.name}\" and remove all members.",
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "This action cannot be undone!",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to groups list
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Group "${widget.group.name}" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              "Delete Group",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Leave Group?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          "Are you sure you want to leave \"${widget.group.name}\"? You can be re-invited by the group creator.",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to groups list
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You left "${widget.group.name}"'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: Text(
              "Leave Group",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveMember(UserProfile member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          "Remove Member?",
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        content: Text(
          "Are you sure you want to remove ${member.name} from this group?",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} removed from group'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              "Remove",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}