import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';
import '../services/friendship_service.dart';
import '../utils/debug_loader.dart';
import '../utils/themed_notifications.dart';

class AddFriendScreen extends StatefulWidget {
  final UserProfile currentUser;

  const AddFriendScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<UserProfile> _searchResults = []; // ✅ FIXED: Changed from final to regular list
  bool _isSearching = false;
  String? _searchError; // ✅ ADDED: Missing _searchError variable
  Timer? _debounceTimer;
  String _lastQuery = '';
  
  // Cache for user states to prevent excessive API calls
  final Map<String, bool> _friendshipCache = {};
  final Map<String, String?> _requestStatusCache = {};
  final Set<String> _loadingUsers = {}; // Track which users are currently being loaded

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
        _searchError = null; // ✅ FIXED: Clear error when empty
        _lastQuery = '';
      });
      return;
    }
    
    if (query == _lastQuery || query.length < 2) {
      return;
    }
    
    if (!_isSearching) {
      setState(() {
        _isSearching = true;
        _searchError = null; // ✅ FIXED: Clear error when starting new search
      });
    }
    
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _searchUsers(query);
    });
  }

  // ✅ FIXED: Updated method signature to match usage
  void _searchUsers(String query) async {
    if (!mounted || query != _searchController.text || query == _lastQuery) {
      return;
    }
    
    _lastQuery = query;
    
    // ✅ IMPROVED: Better validation
    if (query.length < 2) {
      setState(() {
        _searchError = "Enter at least 2 characters to search";
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }
    
    try {
      DebugLogger.log('🔍 Searching for: $query');
      
      // ✅ IMPROVED: Add timeout and better error handling
      final results = await FriendshipService.searchUsersByName(query, widget.currentUser.uid)
          .timeout(const Duration(seconds: 10));
      
      if (!mounted || query != _searchController.text) {
        return;
      }
      
      // Clear caches for new search
      _friendshipCache.clear();
      _requestStatusCache.clear();
      _loadingUsers.clear(); // Clear loading tracking
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _searchResults.clear();
            _searchResults.addAll(results);
            _isSearching = false;
            
            // ✅ IMPROVED: Better user feedback
            if (results.isEmpty) {
              _searchError = "No users found matching '$query'";
            } else {
              _searchError = null;
            }
          });
        }
      });
      
      DebugLogger.log('✅ Search completed: ${results.length} results');
    } catch (e) {
      DebugLogger.log('❌ Search error: $e');
      
      if (!mounted) return;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _searchResults.clear();
            _isSearching = false;
            
            // ✅ IMPROVED: User-friendly error messages
            if (e.toString().contains('timed out')) {
              _searchError = "Search timed out. Check your connection and try again.";
            } else if (e.toString().contains('permission')) {
              _searchError = "Unable to search. Please try logging out and back in.";
            } else {
              _searchError = "Search failed. Please try again.";
            }
          });
        }
      });
    }
  }

  // ✅ IMPROVED: Better friend request sending with retry logic
  Future<void> _sendFriendRequest(UserProfile user) async {
    setState(() {
      _loadingUsers.add(user.uid);
    });

    try {
      DebugLogger.log("📤 Sending friend request to: ${user.name} (${user.uid})");
      
      // ✅ IMPROVED: Add timeout for friend request
      await FriendshipService.sendFriendRequest(
        fromUserId: widget.currentUser.uid,
        toUserId: user.uid,
        fromUserName: widget.currentUser.name,
        toUserName: user.name,
      ).timeout(
        const Duration(seconds: 15),
      );

      // ✅ IMPROVED: Update cache immediately for better UX
      if (mounted) {
        setState(() {
          _requestStatusCache[user.uid] = 'pending';
        });
        
        ThemedNotifications.showSuccess(
          context, 
          'Friend request sent to ${user.name}!', 
          icon: "🤝"
        );
      }
    } catch (e) {
      DebugLogger.log("❌ Error sending friend request: $e");
      if (mounted) {
        // ✅ IMPROVED: Better error messages
        String errorMessage = 'Failed to send request';
        if (e.toString().contains('already sent')) {
          errorMessage = 'Friend request already sent';
        } else if (e.toString().contains('timed out')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Unable to send request. Please try logging out and back in.';
        }
        
        ThemedNotifications.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingUsers.remove(user.uid);
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
        elevation: 0,
        title: Text(
          'Add Friends',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24.sp,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF121212),
              Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search section - Fixed height
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
              child: Column(
                children: [
                  // Search input
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF2A2A2A),
                          Color(0xFF1F1F1F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for friends by name...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 16.sp,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: const Color(0xFFE5A00D),
                          size: 24.sp,
                        ),
                        suffixIcon: _isSearching
                            ? Padding(
                                padding: EdgeInsets.all(12.w),
                                child: SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.w,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFFE5A00D),
                                    ),
                                  ),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.white.withValues(alpha: 0.7),
                                      size: 20.sp,
                                    ),
                                  )
                                : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                      ),
                    ),
                  ),
                  
                  // ✅ ADDED: Error message display
                  if (_searchError != null) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.red,
                            size: 16.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              _searchError!,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Results section - Expandable
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildEmptySearchState()
                  : _isSearching
                      ? _buildLoadingState()
                      : _searchResults.isEmpty
                          ? _buildNoResultsState()
                          : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2A2A2A),
                    Color(0xFF1F1F1F),
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
                Icons.person_search,
                size: 72.sp,
                color: const Color(0xFFE5A00D).withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'Discover Movie Mates',
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
              'Type a name above to search for friends and start matching movies together!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16.sp,
                height: 1.5,
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
            'Searching for friends...',
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

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.search_off,
                size: 64.sp,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Users Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Try searching with a different name or check the spelling',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(UserProfile user, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1F1F1F),
                  ],
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE5A00D),
                          Color(0xFFFF6B00),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  
                  // User details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        if (user.preferredGenres.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Likes: ${user.preferredGenres.take(3).join(", ")}',
                              style: TextStyle(
                                color: const Color(0xFFE5A00D),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: 16.w),
                  
                  // Button - simplified to avoid nested FutureBuilders
                  _buildActionButton(user),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(UserProfile user) {
    // Check cache first
    bool? isFriend = _friendshipCache[user.uid];
    String? requestStatus = _requestStatusCache[user.uid];
    
    // If we don't have cached data, load it (but only once)
    if (isFriend == null && requestStatus == null && !_isLoadingUser(user.uid)) {
      _loadUserRelationship(user.uid);
    }
    
    // If still loading, show loading state
    if ((isFriend == null || requestStatus == null) && _isLoadingUser(user.uid)) {
      return Container(
        padding: EdgeInsets.all(12.w),
        child: SizedBox(
          width: 20.w,
          height: 20.h,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFFE5A00D),
            ),
          ),
        ),
      );
    }
    
    // If we have no data and not loading, show default button
    if (isFriend == null && requestStatus == null) {
      isFriend = false;
      requestStatus = null;
    }
    
    // Determine button state
    String buttonText = "Add";
    IconData buttonIcon = Icons.person_add;
    bool isDisabled = false;
    Color buttonColor = const Color(0xFFE5A00D);
    
    if (isFriend == true) {
      buttonText = "Friends";
      buttonIcon = Icons.check;
      isDisabled = true;
      buttonColor = Colors.green;
    } else if (requestStatus == 'pending') {
      buttonText = "Sent";
      buttonIcon = Icons.schedule;
      isDisabled = true;
      buttonColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: isDisabled 
            ? LinearGradient(
                colors: [buttonColor.withValues(alpha: 0.5), buttonColor.withValues(alpha: 0.3)],
              )
            : LinearGradient(
                colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: isDisabled ? null : [
          BoxShadow(
            color: buttonColor.withValues(alpha: 0.3),
            blurRadius: 6.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : () => _sendFriendRequest(user),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 12.h,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  buttonIcon,
                  color: Colors.white,
                  size: 18.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  buttonText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Check if user is currently being loaded
  bool _isLoadingUser(String userId) {
    return _loadingUsers.contains(userId);
  }

  // Load user relationship data and cache it
  void _loadUserRelationship(String userId) async {
    // Prevent multiple simultaneous loads for the same user
    if (_loadingUsers.contains(userId)) {
      return;
    }
    
    _loadingUsers.add(userId);
    
    try {
      DebugLogger.log("🔍 Loading relationship data for user: $userId");
      
      final friendship = FriendshipService.areFriends(widget.currentUser.uid, userId);
      final requestStatus = FriendshipService.getFriendRequestStatus(widget.currentUser.uid, userId);
      
      final results = await Future.wait([friendship, requestStatus]).timeout(
        const Duration(seconds: 10), // Add timeout
      );
      
      if (mounted) {
        setState(() {
          _friendshipCache[userId] = results[0] as bool;
          _requestStatusCache[userId] = results[1] as String?;
        });
        DebugLogger.log("✅ Loaded relationship data: isFriend=${results[0]}, status=${results[1]}");
      }
    } catch (e) {
      DebugLogger.log("❌ Error loading user relationship: $e");
      // Set defaults to prevent infinite loading
      if (mounted) {
        setState(() {
          _friendshipCache[userId] = false;
          _requestStatusCache[userId] = null;
        });
      }
    } finally {
      _loadingUsers.remove(userId);
    }
  }
}