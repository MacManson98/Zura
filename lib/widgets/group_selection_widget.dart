// File: lib/widgets/group_selection_widget.dart
// Enhanced group selection widget with modal mood selection

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../models/user_profile.dart';
import '../models/friend_group.dart';
import '../models/session_models.dart';
import '../services/group_service.dart';
import '../services/session_service.dart';
import '../screens/create_group_screen.dart';
import '../utils/mood_engine.dart';
import '../utils/debug_loader.dart';
import '../utils/themed_notifications.dart';
import 'mood_selection_widget.dart';

class GroupSelectionWidget extends StatefulWidget {
  final UserProfile currentUser;
  final List<UserProfile> friendIds;
  final Function(List<UserProfile>) onGroupSelected;
  final Function(SwipeSession session) onSessionCreated;

  const GroupSelectionWidget({
    super.key,
    required this.currentUser,
    required this.friendIds,
    required this.onGroupSelected,
    required this.onSessionCreated,
  });

  @override
  State<GroupSelectionWidget> createState() => _GroupSelectionWidgetState();
}

class _GroupSelectionWidgetState extends State<GroupSelectionWidget> {
  List<FriendGroup> _userGroups = [];
  bool _isLoadingGroups = true;
  FriendGroup? _selectedGroup;

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    try {
      final groups = await GroupService().getUserGroups(widget.currentUser.uid);
      if (mounted) {
        setState(() {
          _userGroups = groups;
          _isLoadingGroups = false;
        });
      }
    } catch (e) {
      DebugLogger.log("❌ Error loading user groups: $e");
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 500.h,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 2,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1F1F1F).withValues(alpha: 0.95),
            const Color(0xFF161616).withValues(alpha: 0.95),
            const Color(0xFF121212).withValues(alpha: 0.95),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFE5A00D).withValues(alpha: 0.8),
            Colors.orange.withValues(alpha: 0.6),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          spreadRadius: 2.r,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.groups,
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
                          "Select Group", 
                          style: TextStyle(
                            color: Colors.white, 
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "Choose a group to swipe with",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 24.h),
              
              _isLoadingGroups 
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: const Color(0xFFE5A00D),
                            strokeWidth: 3.w,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            "Loading your groups...",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: Column(
                      children: [
                        // Create new group button (prominent)
                        _buildCreateNewGroupButton(),
                        
                        if (_userGroups.isNotEmpty) ...[
                          SizedBox(height: 20.h),
                          
                          // Divider with "OR"
                          _buildDivider(),
                          
                          SizedBox(height: 20.h),
                          
                          // Existing groups header
                          _buildGroupsHeader(),
                          
                          SizedBox(height: 12.h),
                          
                          // Groups list
                          Expanded(child: _buildGroupsList()),
                        ] else ...[
                          SizedBox(height: 20.h),
                          Expanded(child: _buildEmptyGroupsState()),
                        ],
                      ],
                    ),
                  ),
              
              SizedBox(height: 16.h),
              
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.w,
                      ),
                    ),
                  ),
                  child: Text(
                    "Cancel", 
                    style: TextStyle(
                      color: Colors.white70, 
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNewGroupButton() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 64.h,
      borderRadius: 18,
      blur: 15,
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
          onTap: _createNewGroup,
          borderRadius: BorderRadius.circular(18.r),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  "Create New Group",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            "OR",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.w,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsHeader() {
    return Row(
      children: [
        Icon(
          Icons.group,
          color: const Color(0xFFE5A00D),
          size: 18.sp,
        ),
        SizedBox(width: 8.w),
        Text(
          "Your Groups",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Text(
            "${_userGroups.length}",
            style: TextStyle(
              color: const Color(0xFFE5A00D),
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupsList() {
    return ListView.builder(
      itemCount: _userGroups.length,
      itemBuilder: (context, index) {
        final group = _userGroups[index];
        
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 80.h,
            borderRadius: 16,
            blur: 10,
            alignment: Alignment.centerLeft,
            border: 1,
            linearGradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                const Color(0xFFE5A00D).withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.1),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectGroup(group),
                borderRadius: BorderRadius.circular(16.r),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    children: [
                      // Group avatar
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFE5A00D),
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: Center(
                          child: group.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14.r),
                                  child: Image.network(
                                    group.imageUrl,
                                    width: 48.w,
                                    height: 48.h,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.group,
                                        color: Colors.white,
                                        size: 24.sp,
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                        ),
                      ),
                      
                      SizedBox(width: 16.w),
                      
                      // Group info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  color: Colors.white54,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  "${group.memberCount} members",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      SizedBox(width: 12.w),
                      
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: const Color(0xFFE5A00D),
                          size: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyGroupsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Icon(
              Icons.group_outlined,
              size: 48.sp,
              color: Colors.white30,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            "No Groups Yet",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Create your first group to start\nmatching with multiple friends",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14.sp,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _createNewGroup() async {
    Navigator.pop(context); // Close group selection
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(
          currentUser: widget.currentUser,
          friends: widget.friendIds,
        ),
      ),
    );
    
    // If group was created, reload groups and show selection again
    if (result == true) {
      await _loadUserGroups();
      
      // Show group selection again
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => GroupSelectionWidget(
            currentUser: widget.currentUser,
            friendIds: widget.friendIds,
            onGroupSelected: widget.onGroupSelected,
            onSessionCreated: widget.onSessionCreated,
          ),
        );
      }
    }
  }

  void _selectGroup(FriendGroup group) {
    DebugLogger.log('🔍 DEBUG: _selectGroup called with group: ${group.name}');
    _showMoodSelectionModal(group);
  }

  void _showMoodSelectionModal(FriendGroup group) {
    DebugLogger.log('🔍 DEBUG: _showMoodSelectionModal called for group: ${group.name}');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Stack(
          children: [
            MoodSelectionWidget(
              onMoodsSelected: (moods) {
                Navigator.pop(context); // Close the modal
                _onMoodsSelectedForGroup(group, moods);
              },
              isGroupMode: true,
              groupSize: group.memberCount,
              moodContext: MoodSelectionContext.groupInvite,
            ),
            
            // Close button
            Positioned(
              top: 16.h,
              right: 16.w,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onMoodsSelectedForGroup(FriendGroup group, List<CurrentMood> moods) {
    DebugLogger.log('🔍 DEBUG: _onMoodsSelectedForGroup called');
    DebugLogger.log('🔍 DEBUG: Group: ${group.name}, Moods: ${moods.map((m) => m.displayName).join(", ")}');
    
    // Set the selected group for the original callback
    _selectedGroup = group;
    
    // Call the original callback
    _onMoodsSelected(moods);
  }

  void _onMoodsSelected(List<CurrentMood> moods) async {
    if (moods.isEmpty || _selectedGroup == null) return;

    try {
      DebugLogger.log("🎭 Creating group session with mood: ${moods.first.displayName}");
      DebugLogger.log("📦 Group: ${_selectedGroup!.name} (${_selectedGroup!.memberCount} members)");

      // ✅ ENHANCED: Create collaborative session with group context
      final session = await SessionService.createGroupSession(
        hostName: widget.currentUser.name,
        selectedMood: moods.first,
        groupId: _selectedGroup!.id,
        groupName: _selectedGroup!.name,
        groupMembers: _selectedGroup!.members,
      );

      DebugLogger.log("✅ Group session created: ${session.sessionId}");
      DebugLogger.log("📊 Session will be stored with group context: ${_selectedGroup!.name}");

      // Get group members (excluding current user)
      final groupMembers = _selectedGroup!.members
          .where((member) => member.uid != widget.currentUser.uid)
          .toList();

      DebugLogger.log("📧 Sending session invitations to ${groupMembers.length} group members");

      // Send session invitations with group context
      await SessionService.inviteGroupToSession(
        sessionId: session.sessionId,
        groupMembers: groupMembers,
        groupName: _selectedGroup!.name,
        hostName: widget.currentUser.name,
        selectedMood: moods.first,
      );

      DebugLogger.log("✅ All session invitations sent successfully");

      // Update group activity
      try {
        await GroupService().updateGroupActivity(
          groupId: _selectedGroup!.id,
          addSessions: 1,
        );
      } catch (e) {
        DebugLogger.log("⚠️ Failed to update group activity: $e");
      }

      if (mounted) {
        Navigator.pop(context); // Close dialog
        widget.onSessionCreated(session);

        ThemedNotifications.showSuccess(
          context,
          '${moods.first.displayName} session started! Session invitations sent to ${_selectedGroup!.name}',
          icon: '🎬',
        );
      }

    } catch (e) {
      DebugLogger.log("❌ Error creating group session: $e");
      if (mounted) {
        ThemedNotifications.showError(
          context,
          'Failed to create group session: $e',
        );
      }
    } finally {
      if (mounted) {
        _selectedGroup = null;
      }
    }
  }
}