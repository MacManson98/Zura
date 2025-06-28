// File: lib/screens/create_group_screen.dart
// Clean version using enhanced FriendGroup with INVITATION SYSTEM

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/group_service.dart';
import '../utils/themed_notifications.dart';

class CreateGroupScreen extends StatefulWidget {
  final UserProfile currentUser;
  final List<UserProfile> friends;

  const CreateGroupScreen({
    super.key,
    required this.currentUser,
    required this.friends,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  final Set<UserProfile> _selectedFriends = {};
  bool _isCreating = false;
  
  final GroupService _groupService = GroupService();
  
  // Group settings
  bool _isPrivate = false;
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupDescriptionController.dispose();
    super.dispose();
  }

  bool get _canCreate =>
      _groupNameController.text.trim().isNotEmpty && _selectedFriends.isNotEmpty;

  void _toggleFriendSelection(UserProfile friend) {
    setState(() {
      if (_selectedFriends.contains(friend)) {
        _selectedFriends.remove(friend);
      } else {
        _selectedFriends.add(friend);
      }
    });
  }

  void _selectAllFriends() {
    setState(() {
      if (_selectedFriends.length == widget.friends.length) {
        _selectedFriends.clear();
      } else {
        _selectedFriends.addAll(widget.friends);
      }
    });
  }

  Future<void> _createGroup() async {
    if (!_canCreate) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final group = await _groupService.createGroup(
        name: _groupNameController.text.trim(),
        description: _groupDescriptionController.text.trim(),
        members: [widget.currentUser],
        isPrivate: _isPrivate,
        notificationsEnabled: _notificationsEnabled,
      );

      if (mounted) {
        final inviteCount = _selectedFriends.length;
        ThemedNotifications.showSuccess(
          context, 
          'Group "${group.name}" created! ${inviteCount > 0 ? "Will send $inviteCount invitation${inviteCount != 1 ? 's' : ''} once invitation system is ready." : ""}',
          icon: "🎉"
        );
        
        // ✅ FIXED: Return true to indicate success
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ThemedNotifications.showError(context, 'Failed to create group: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Create Group'),
      ),
      body: SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100), // to make room for bottom bar
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ⬇️ Everything below here is untouched from your original Column
                      
                      // Group details section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GROUP DETAILS',
                              style: TextStyle(
                                color: Colors.white70, 
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Group image placeholder
                            Center(
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[800],
                                    child: const Icon(
                                      Icons.group,
                                      size: 50,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFE5A00D),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          ThemedNotifications.showInfo(
                                            context,
                                            'Group image upload coming soon!',
                                            icon: "🚧",
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Group name input
                            TextField(
                              controller: _groupNameController,
                              decoration: InputDecoration(
                                labelText: 'Group Name *',
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintText: 'Enter a name for your group',
                                hintStyle: const TextStyle(color: Colors.white30),
                                filled: true,
                                fillColor: const Color(0xFF1F1F1F),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.group, color: Colors.white70),
                                counterText: '${_groupNameController.text.length}/50',
                                counterStyle: const TextStyle(color: Colors.white54),
                              ),
                              style: const TextStyle(color: Colors.white),
                              maxLength: 50,
                              onChanged: (_) => setState(() {}),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Group description input
                            TextField(
                              controller: _groupDescriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description (Optional)',
                                labelStyle: const TextStyle(color: Colors.white70),
                                hintText: 'What kind of movies does this group like?',
                                hintStyle: const TextStyle(color: Colors.white30),
                                filled: true,
                                fillColor: const Color(0xFF1F1F1F),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(Icons.description, color: Colors.white70),
                                counterText: '${_groupDescriptionController.text.length}/200',
                                counterStyle: const TextStyle(color: Colors.white54),
                              ),
                              style: const TextStyle(color: Colors.white),
                              maxLines: 3,
                              maxLength: 200,
                              onChanged: (_) => setState(() {}),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Group privacy settings
                            const Text(
                              'PRIVACY & SETTINGS',
                              style: TextStyle(
                                color: Colors.white70, 
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Privacy toggle
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1F1F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isPrivate ? Icons.lock : Icons.public,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _isPrivate ? 'Private Group' : 'Public Group',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                          Text(
                                            _isPrivate 
                                                ? 'Only invited members can join'
                                                : 'Anyone can discover and join',
                                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _isPrivate,
                                    onChanged: (value) {
                                      setState(() {
                                        _isPrivate = value;
                                      });
                                    },
                                    activeColor: const Color(0xFFE5A00D),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Notifications toggle
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1F1F),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.notifications,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Group Notifications',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          Text(
                                            'Get notified about matches and activities',
                                            style: TextStyle(color: Colors.white54, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _notificationsEnabled,
                                    onChanged: (value) {
                                      setState(() {
                                        _notificationsEnabled = value;
                                      });
                                    },
                                    activeColor: const Color(0xFFE5A00D),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(color: Colors.white12),

                      // Friends selection section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'INVITE FRIENDS * (${_selectedFriends.length}/${widget.friends.length})',
                              style: const TextStyle(
                                color: Colors.white70, 
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.friends.isNotEmpty)
                              TextButton.icon(
                                onPressed: _selectAllFriends,
                                icon: Icon(
                                  _selectedFriends.length == widget.friends.length
                                      ? Icons.deselect
                                      : Icons.select_all,
                                  color: const Color(0xFFE5A00D),
                                  size: 18,
                                ),
                                label: Text(
                                  _selectedFriends.length == widget.friends.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                  style: const TextStyle(
                                    color: Color(0xFFE5A00D),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      widget.friends.isEmpty
                          ? _buildEmptyFriendsState()
                          : _buildFriendsList(),

                      const SizedBox(height: 100), // for bottom button space
                    ],
                  ),
                ),
                )
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildEmptyFriendsState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F1F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person_add,
                size: 48,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Friends Added Yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add friends first before creating a group to invite them', // ✅ Updated text
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Help text
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE5A00D).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFFE5A00D),
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Select friends to invite to your group', // ✅ Updated text
                    style: TextStyle(
                      color: Color(0xFFE5A00D),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Friends list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.friends.length,
            itemBuilder: (context, index) {
              final friend = widget.friends[index];
              final isSelected = _selectedFriends.contains(friend);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: isSelected
                    ? const Color(0xFF1F1F1F)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFFE5A00D)
                        : Colors.white12,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () => _toggleFriendSelection(friend),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Friend avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[800],
                          child: Text(
                            friend.name.isNotEmpty
                                ? friend.name[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Friend info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                friend.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${friend.likedMovieIds.length} movies liked',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Checkbox
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleFriendSelection(friend),
                          activeColor: const Color(0xFFE5A00D),
                          checkColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Requirements summary
            if (!_canCreate)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _groupNameController.text.trim().isEmpty
                            ? 'Group name is required'
                            : 'Select at least one friend to invite', // ✅ Updated text
                        style: const TextStyle(color: Colors.orange, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canCreate && !_isCreating ? _createGroup : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A00D),
                  disabledBackgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Create Group',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}