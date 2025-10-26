import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_models.dart';
import '../models/user_profile.dart';
import '../utils/mood_engine.dart';
import '../utils/debug_loader.dart';

class SessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _sessionsCollection = _firestore.collection('swipeSessions');
  static final _usersCollection = _firestore.collection('users');


  // In session_service.dart, add this method:
  static Stream<List<Map<String, dynamic>>> watchSessionInvites(String userId) {
    return _firestore
        .collection('session_invites')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // FIXED: Create a new swipe session with correct mood properties
  static Future<SwipeSession> createSession({
    required String hostName,
    required InvitationType inviteType,
    CurrentMood? selectedMood, // 🆕 NEW: Changed to CurrentMood? for type safety
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");
    
    // 🆕 FIXED: Extract mood information using correct properties
    String? moodId;
    String? moodName;
    String? moodEmoji;
    
    if (selectedMood != null) {
      // Use correct CurrentMood properties
      moodId = selectedMood.toString().split('.').last;  // e.g., "chill" from "CurrentMood.chill"
      moodName = selectedMood.displayName;               // e.g., "Chill & Relaxed"
      moodEmoji = selectedMood.emoji;                    // e.g., "😌"
      
      DebugLogger.log("🎭 Creating session with mood: $moodName ($moodEmoji)");
    } else {
      DebugLogger.log("📝 Creating session without specific mood");
    }
    
    final session = SwipeSession.create(
      hostId: currentUser.uid,
      hostName: hostName,
      inviteType: inviteType,
      // 🆕 NEW: Pass mood information to session creation
      selectedMoodId: moodId,
      selectedMoodName: moodName,
      selectedMoodEmoji: moodEmoji,
    );

    await _sessionsCollection.doc(session.sessionId).set(session.toJson());
    
    DebugLogger.log("✅ Session created: ${session.sessionId}");
    if (session.hasMoodSelected) {
      DebugLogger.log("   Mood: ${session.selectedMoodName} ${session.selectedMoodEmoji}");
    }
    
    return session;
  }

  static Future<SwipeSession> createGroupSession({
    required String hostName,
    required CurrentMood selectedMood,
    required String groupId,
    required String groupName,
    required List<UserProfile> groupMembers,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");

      DebugLogger.log("🎭 Creating group session with enhanced group context");
      DebugLogger.log("👥 Group: $groupName ($groupId)");
      DebugLogger.log("🎬 Mood: ${selectedMood.displayName} ${selectedMood.emoji}");
      DebugLogger.log("📊 Members: ${groupMembers.map((m) => m.name).join(', ')}");

      // Extract mood information
      final moodId = selectedMood.toString().split('.').last;
      final moodName = selectedMood.displayName;
      final moodEmoji = selectedMood.emoji;

      // ✅ FIXED: Create session with GROUP invite type
      final session = SwipeSession.create(
        hostId: currentUser.uid,
        hostName: hostName,
        inviteType: InvitationType.group, // ✅ CHANGED: Use group type instead of friend
        selectedMoodId: moodId,
        selectedMoodName: moodName,
        selectedMoodEmoji: moodEmoji,
        groupName: groupName, // ✅ CRITICAL: Store group name in session
      );

      // ✅ ENHANCED: Create session data with comprehensive group context
      final sessionData = session.toJson();
      sessionData.addAll({
        // Group identification fields
        'groupId': groupId,
        'groupName': groupName,
        'isGroupSession': true,
        'groupMemberCount': groupMembers.length,
        'groupMemberIds': groupMembers.map((m) => m.uid).toList(),
        'groupMemberNames': groupMembers.map((m) => m.name).toList(),
        
        // Session type markers
        'sessionType': 'group',
        'collaborativeType': 'group_matching',
        
        // Mood context
        'groupMoodId': moodId,
        'groupMoodName': moodName,
        'groupMoodEmoji': moodEmoji,
        
        // Timestamps for tracking
        'groupSessionCreatedAt': FieldValue.serverTimestamp(),
        'lastGroupActivity': FieldValue.serverTimestamp(),
      });

      // Save to Firebase with enhanced group context
      await _sessionsCollection.doc(session.sessionId).set(sessionData);
      
      DebugLogger.log("✅ Group session saved to Firebase with comprehensive context");
      DebugLogger.log("📍 Session ID: ${session.sessionId}");
      DebugLogger.log("📍 Group ID: $groupId");
      DebugLogger.log("📍 Group Name: $groupName");
      DebugLogger.log("📍 Mood: $moodName $moodEmoji");
      DebugLogger.log("📍 Invite Type: GROUP"); // ✅ Now it will log GROUP
      
      return session;
      
    } catch (e) {
      DebugLogger.log("❌ Error creating group session: $e");
      throw Exception('Failed to create group session: $e');
    }
  }

  static Future<void> verifySessionCreated(String sessionId) async {
    try {
      DebugLogger.log("🔍 Verifying session was created: $sessionId");
      
      final sessionDoc = await _sessionsCollection.doc(sessionId).get();
      
      if (!sessionDoc.exists) {
        DebugLogger.log("❌ Session NOT found in Firebase: $sessionId");
        return;
      }
      
      final data = sessionDoc.data()!;
      DebugLogger.log("✅ Session found in Firebase:");
      DebugLogger.log("   ID: $sessionId");
      DebugLogger.log("   Group Session: ${data['isGroupSession'] ?? false}");
      DebugLogger.log("   Group Name: ${data['groupName']}");
      DebugLogger.log("   Status: ${data['status']}");
      DebugLogger.log("   Participants: ${data['participantNames']}");
      
    } catch (e) {
      DebugLogger.log("❌ Error verifying session: $e");
    }
  }

  static Future<void> debugCheckGroupSessions(String userId) async {
    try {
      DebugLogger.log("🔍 DEBUG: Checking group sessions for user: $userId");
      
      // Check all sessions where user is a participant
      final userSessions = await _sessionsCollection
          .where('participantIds', arrayContains: userId)
          .get();
      
      DebugLogger.log("📊 Found ${userSessions.docs.length} total sessions for user");
      
      for (final doc in userSessions.docs) {
        final data = doc.data();
        final sessionId = doc.id;
        final isGroupSession = data['isGroupSession'] ?? false;
        final groupName = data['groupName'];
        final groupId = data['groupId'];
        final status = data['status'];
        final participantNames = List<String>.from(data['participantNames'] ?? []);
        
        DebugLogger.log("📋 Session: $sessionId");
        DebugLogger.log("   Group Session: $isGroupSession");
        DebugLogger.log("   Group Name: $groupName");
        DebugLogger.log("   Group ID: $groupId");
        DebugLogger.log("   Status: $status");
        DebugLogger.log("   Participants: ${participantNames.join(', ')}");
        DebugLogger.log("   Created: ${data['createdAt']}");
        DebugLogger.log("---");
      }
      
      // Check specifically for group sessions
      final groupSessions = await _sessionsCollection
          .where('participantIds', arrayContains: userId)
          .where('isGroupSession', isEqualTo: true)
          .get();
      
      DebugLogger.log("🎯 Found ${groupSessions.docs.length} group sessions specifically");
      
      // Check for recent sessions (last 24 hours)
      final yesterday = DateTime.now().subtract(Duration(hours: 24));
      final recentSessions = await _sessionsCollection
          .where('participantIds', arrayContains: userId)
          .where('createdAt', isGreaterThan: yesterday.toIso8601String())
          .get();
      
      DebugLogger.log("⏰ Found ${recentSessions.docs.length} sessions from last 24 hours");
      
    } catch (e) {
      DebugLogger.log("❌ Error debugging group sessions: $e");
    }
  }

  // 🆕 UPDATED: Send direct friend invitation with mood support
  static Future<void> inviteFriend({
    required String sessionId,
    required String friendId,
    required String friendName,
    CurrentMood? selectedMood,
    String? groupName, // NEW: Optional group context
    bool isGroupInvitation = false, // NEW: Flag for group invitations
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception("User not authenticated");

      // ✅ FIX BUG #6: Check if user already has invitation for this session (prevent duplicates)
      final existingInvites = await _usersCollection
          .doc(friendId)
          .collection('pending_invitations')
          .where('sessionId', isEqualTo: sessionId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (existingInvites.docs.isNotEmpty) {
        DebugLogger.log("⚠️ User $friendName already has a pending invitation for this session - skipping");
        return;
      }

      // Get host information
      final hostDoc = await _usersCollection.doc(currentUserId).get();
      final hostName = hostDoc.data()?['name'] ?? 'Someone';

      DebugLogger.log("📨 Sending ${isGroupInvitation ? 'group' : 'friend'} session invitation");
      DebugLogger.log("   Session: $sessionId");
      DebugLogger.log("   To: $friendName ($friendId)");
      DebugLogger.log("   From: $hostName");
      if (groupName != null) {
        DebugLogger.log("   Group: $groupName");
      }

      // ✅ FIX: Add invitation expiration (48 hours)
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 48));

      // Create invitation data
      final invitationData = <String, dynamic>{
        'sessionId': sessionId,
        'fromUserId': currentUserId,
        'fromUserName': hostName,
        'toUserId': friendId,
        'toUserName': friendName,
        'invitedAt': now.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(), // ✅ NEW: Expiration timestamp
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'type': isGroupInvitation ? 'group_session' : 'friend_session', // NEW: Different types
      };

      // Add group context if this is a group invitation
      if (isGroupInvitation && groupName != null) {
        invitationData.addAll({
          'groupName': groupName,
          'isGroupSession': true,
          'invitationType': 'group',
        });
      } else {
        invitationData.addAll({
          'isGroupSession': false,
          'invitationType': 'friend',
        });
      }

      // Add mood information if provided
      if (selectedMood != null) {
        invitationData.addAll({
          'selectedMoodId': selectedMood.toString().split('.').last, // e.g., "chill" from "CurrentMood.chill"
          'selectedMoodName': selectedMood.displayName,  // e.g., "Chill & Relaxed"
          'selectedMoodEmoji': selectedMood.emoji,       // e.g., "😌"
          'hasMood': true,
        });
        
        DebugLogger.log("🎭 Sending invitation with mood: ${selectedMood.displayName} ${selectedMood.emoji}");
      } else {
        invitationData['hasMood'] = false;
        DebugLogger.log("📝 Sending invitation without specific mood");
      }
      
      // Add invitation to friend's pending invitations
      await _usersCollection.doc(friendId).collection('pending_invitations').add(invitationData);

      // ✅ FIX BUG #1 & #6: Track invited users in session for efficient cleanup & duplicate prevention
      await _sessionsCollection.doc(sessionId).update({
        'invitedUserIds': FieldValue.arrayUnion([friendId]),
        'lastInviteSentAt': FieldValue.serverTimestamp(),
      });

      DebugLogger.log("✅ Invitation sent to $friendName");
      if (selectedMood != null) {
        DebugLogger.log("   Mood: ${selectedMood.displayName} ${selectedMood.emoji}");
      }
      if (groupName != null) {
        DebugLogger.log("   Group context: $groupName");
      }
      
    } catch (e) {
      DebugLogger.log("❌ Error sending invitation: $e");
      throw e;
    }
  }

  static Future<void> inviteGroupToSession({
    required String sessionId,
    required List<UserProfile> groupMembers,
    required String groupName,
    required String hostName,
    CurrentMood? selectedMood,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception("User not authenticated");

      DebugLogger.log("📧 Inviting ${groupMembers.length} group members to session: $sessionId");
      DebugLogger.log("👥 Group: $groupName");
      if (selectedMood != null) {
        DebugLogger.log("🎭 Mood: ${selectedMood.displayName} ${selectedMood.emoji}");
      }

      // Send individual session invitations to each group member
      final futures = groupMembers.map((member) async {
        try {
          // Skip sending invitation to the host (current user)
          if (member.uid == currentUserId) {
            DebugLogger.log("⏭️ Skipping invitation to host: ${member.name}");
            return;
          }

          await inviteFriend(
            sessionId: sessionId,
            friendId: member.uid,
            friendName: member.name,
            selectedMood: selectedMood,
            // Add group context to the invitation
            groupName: groupName,
            isGroupInvitation: true,
          );

          DebugLogger.log("✅ Session invitation sent to: ${member.name}");
        } catch (e) {
          DebugLogger.log("⚠️ Failed to invite ${member.name}: $e");
          // Continue with other invitations even if one fails
        }
      });

      // Wait for all invitations to complete
      await Future.wait(futures);

      final invitedCount = groupMembers.where((m) => m.uid != currentUserId).length;
      DebugLogger.log("📨 Completed sending $invitedCount session invitations for group: $groupName");
      
    } catch (e) {
      DebugLogger.log("❌ Error inviting group to session: $e");
      throw Exception('Failed to invite group to session: $e');
    }
  }


  // Clean up old sessions automatically
  static Future<void> cleanupOldSessions() async {
    try {
      // 🆕 ADD: Authentication guard
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        DebugLogger.log("⚠️ Skipping session cleanup - user not authenticated");
        return;
      }

      final now = DateTime.now();
      final cutoffDate = now.subtract(const Duration(hours: 24));
      
      // Query for old sessions to delete
      final oldSessionsQuery = await _sessionsCollection
          .where('createdAt', isLessThan: cutoffDate.toIso8601String())
          .get();
      
      // Delete old sessions in batches
      final batch = _firestore.batch();
      int operationCount = 0;
      
      for (final doc in oldSessionsQuery.docs) {
        batch.delete(doc.reference);
        operationCount++;
        
        if (operationCount >= 450) {
          await batch.commit();
          operationCount = 0;
        }
      }
      
      if (operationCount > 0) {
        await batch.commit();
      }
      
      DebugLogger.log("✅ Cleaned up ${oldSessionsQuery.docs.length} old sessions");
    } catch (e) {
      DebugLogger.log("❌ Error cleaning up old sessions: $e");
    }
  }

  // Clean up session when all invitations are declined or expired
  static Future<void> checkAndCleanupSession(String sessionId) async {
    try {
      final sessionDoc = await _sessionsCollection.doc(sessionId).get();
      if (!sessionDoc.exists) return;
      
      final sessionData = sessionDoc.data()!;
      final session = SwipeSession.fromJson(sessionData);
      
      // Check if session should be deleted
      bool shouldDelete = false;
      
      // Delete if session is older than 24 hours and never started
      final createdAt = DateTime.parse(session.createdAt as String);
      final isOld = DateTime.now().difference(createdAt).inHours > 24;
      final neverStarted = session.status == SessionStatus.created;
      
      if (isOld && neverStarted) {
        shouldDelete = true;
      }
      
      // Delete if session is completed or cancelled and older than 1 hour
      final isFinished = session.status == SessionStatus.completed || 
                        session.status == SessionStatus.cancelled;
      final isOldFinished = DateTime.now().difference(createdAt).inHours > 1;
      
      if (isFinished && isOldFinished) {
        shouldDelete = true;
      }
      
      // Delete if it's a friend-invite session with only 1 participant (host) and old
      final isFriendSession = session.inviteType == InvitationType.friend;
      final onlyHost = session.participantIds.length <= 1;
      final isOldAndEmpty = DateTime.now().difference(createdAt).inHours > 2;
      
      if (isFriendSession && onlyHost && isOldAndEmpty) {
        shouldDelete = true;
      }
      
      if (shouldDelete) {
        await _sessionsCollection.doc(sessionId).delete();
        DebugLogger.log("✅ Cleaned up abandoned session: $sessionId");
        
        // Also clean up any remaining invitations for this session
        await _cleanupInvitationsForSession(sessionId);
      }
      
    } catch (e) {
      DebugLogger.log("❌ Error checking session for cleanup: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingInvitations() async {
    try {
      // 🆕 ADD: Authentication guard
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        DebugLogger.log("⚠️ Skipping pending invitations - user not authenticated");
        return [];
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('session_invitations')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'inviteId': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      DebugLogger.log("❌ Error getting pending invitations: $e");
      return [];
    }
  }

  // ✅ FIX BUG #1 & #3: Clean up invitations efficiently using tracked invited users
  static Future<void> _cleanupInvitationsForSession(String sessionId) async {
    try {
      // 🆕 ADD: Authentication guard
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        DebugLogger.log("⚠️ Skipping invitation cleanup - user not authenticated");
        return;
      }

      // ✅ FIX: Get the session to find invited users (much more efficient!)
      final sessionDoc = await _sessionsCollection.doc(sessionId).get();

      if (!sessionDoc.exists) {
        DebugLogger.log("⚠️ Session not found for cleanup: $sessionId");
        return;
      }

      final sessionData = sessionDoc.data()!;
      final invitedUserIds = List<String>.from(sessionData['invitedUserIds'] ?? []);
      final participantIds = List<String>.from(sessionData['participantIds'] ?? []);

      // Combine invited and participant IDs (some may have accepted already)
      final allRelevantUserIds = {...invitedUserIds, ...participantIds};

      DebugLogger.log("🧹 Cleaning up invitations for ${allRelevantUserIds.length} users (was querying ALL users!)");

      // ✅ FIX: Only query the specific users who were invited (not all users!)
      int cleanedCount = 0;
      for (final userId in allRelevantUserIds) {
        try {
          final invitationsSnapshot = await _usersCollection
              .doc(userId)
              .collection('pending_invitations')
              .where('sessionId', isEqualTo: sessionId)
              .get();

          // Delete invitations for this session
          for (final invitationDoc in invitationsSnapshot.docs) {
            await invitationDoc.reference.delete();
            cleanedCount++;
          }
        } catch (e) {
          DebugLogger.log("⚠️ Could not clean invitations for user $userId: $e");
          // Continue with other users even if one fails
        }
      }

      DebugLogger.log("✅ Cleaned up $cleanedCount invitations for session: $sessionId");
    } catch (e) {
      DebugLogger.log("❌ Error cleaning up invitations: $e");
    }
  }

  // Clean up user's old pending invitations (call this periodically)
  static Future<void> cleanupUserInvitations(String userId) async {
    try {
      // 🆕 ADD: Authentication guard
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        DebugLogger.log("⚠️ Skipping user cleanup - user not authenticated");
        return;
      }

      // ✅ FIX: Use expiresAt field to find expired invitations
      final now = DateTime.now();

      final oldInvitationsSnapshot = await _usersCollection
          .doc(userId)
          .collection('pending_invitations')
          .where('expiresAt', isLessThan: now.toIso8601String())
          .get();

      final batch = _firestore.batch();

      for (final doc in oldInvitationsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      if (oldInvitationsSnapshot.docs.isNotEmpty) {
        await batch.commit();
        DebugLogger.log("✅ Cleaned up ${oldInvitationsSnapshot.docs.length} expired invitations for user");
      }
    } catch (e) {
      DebugLogger.log("❌ Error cleaning up user invitations: $e");
    }
  }

  // Updated decline invitation method with cleanup
  static Future<void> declineInvitation(String invitationId, String? sessionId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) throw Exception("User not authenticated");

      DebugLogger.log("❌ Declining invitation: $invitationId");

      // ✅ Step 1: Remove invitation from user's pending invitations
      await _usersCollection
          .doc(currentUserId)
          .collection('pending_invitations')
          .doc(invitationId)
          .delete();

      DebugLogger.log("✅ Invitation removed from pending list");

      // ✅ Step 2: Track the decline for host to see (without permission issues)
      if (sessionId != null) {
        try {
          final sessionDoc = await _sessionsCollection.doc(sessionId).get();
          
          if (sessionDoc.exists) {
            final sessionData = sessionDoc.data()!;
            final hostId = sessionData['hostId'];
            
            // 📝 Add declined user to a tracking field (this should work with basic write permissions)
            try {
              await _sessionsCollection.doc(sessionId).update({
                'declinedParticipants': FieldValue.arrayUnion([currentUserId]),
                'lastDeclineAt': FieldValue.serverTimestamp(),
              });
              DebugLogger.log("📝 Added decline tracking to session");
            } catch (e) {
              DebugLogger.log("⚠️ Could not track decline in session (using notification instead): $e");
            }
            
            // 📨 Notify host about the decline
            if (hostId != null && hostId != currentUserId) {
              final inviteType = sessionData['inviteType'];
              final participantIds = List<String>.from(sessionData['participantIds'] ?? []);
              final isFriendSession = inviteType == 'friend';
              final onlyHostParticipating = participantIds.length <= 1;
              
              if (isFriendSession && onlyHostParticipating) {
                // ✅ FIX: Auto-cancel 1-on-1 friend session when declined
                DebugLogger.log("🚫 Auto-cancelling 1-on-1 friend session: $sessionId");

                try {
                  await _sessionsCollection.doc(sessionId).update({
                    'status': SessionStatus.cancelled.name,
                    'cancelledAt': FieldValue.serverTimestamp(),
                    'cancelledBy': currentUserId,
                    'cancelReason': 'friend_declined_invitation',
                  });
                  DebugLogger.log("✅ Session auto-cancelled after friend declined");
                } catch (e) {
                  DebugLogger.log("⚠️ Could not auto-cancel session: $e");
                }

                // Also notify host about the decline
                await _usersCollection
                    .doc(hostId)
                    .collection('notifications')
                    .add({
                      'type': 'friend_session_declined',
                      'fromUserId': currentUserId,
                      'sessionId': sessionId,
                      'message': 'Your friend declined the session invitation. Session has been cancelled.',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                DebugLogger.log("📨 Host notified: friend declined 1-on-1 session (session cancelled)");
              } else {
                // Regular decline notification
                await _usersCollection
                    .doc(hostId)
                    .collection('notifications')
                    .add({
                      'type': 'session_declined',
                      'fromUserId': currentUserId,
                      'sessionId': sessionId,
                      'message': 'Your session invite was declined.',
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                
                DebugLogger.log("📨 Host notified of declined invitation");
              }
            }
          }
        } catch (e) {
          DebugLogger.log("⚠️ Could not process session/notify host (not critical): $e");
          // Don't throw - the invitation was still successfully declined
        }
      }

      DebugLogger.log("✅ Invitation declined successfully");
      
    } catch (e) {
      DebugLogger.log("❌ Error declining invitation: $e");
      throw e;
    }
  }

  // Call this when app starts or periodically
  static Future<void> performMaintenanceCleanup() async {
    try {
      // 🆕 ADD: Authentication guard for entire cleanup
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        DebugLogger.log("⚠️ Skipping maintenance cleanup - user not authenticated");
        return;
      }

      DebugLogger.log("🧹 Starting maintenance cleanup...");
      
      // Clean up old sessions
      await cleanupOldSessions();
      
      // Clean up current user's old invitations
      await cleanupUserInvitations(currentUser.uid);
      
      DebugLogger.log("✅ Maintenance cleanup completed");
    } catch (e) {
      DebugLogger.log("❌ Error during maintenance cleanup: $e");
    }
  }

  // Accept friend invitation
  static Future<SwipeSession?> acceptInvitation({
    required String invitationId,
    required String sessionId,
    required String userName,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");

      final currentUserId = currentUser.uid;
      DebugLogger.log("🎯 Accepting invitation to session: $sessionId");
      DebugLogger.log("📨 Invitation ID: $invitationId");
      DebugLogger.log("👤 User: $userName ($currentUserId)");

      // ✅ FIX 1: Use a transaction to prevent race conditions
      return await FirebaseFirestore.instance.runTransaction<SwipeSession?>((transaction) async {
        // Get current session state
        final sessionRef = _sessionsCollection.doc(sessionId);
        final sessionSnapshot = await transaction.get(sessionRef);
        
        if (!sessionSnapshot.exists) {
          throw Exception("Session not found: $sessionId");
        }
        
        final sessionData = sessionSnapshot.data()!;
        final currentSession = SwipeSession.fromJson(sessionData);
        
        DebugLogger.log("📋 Current session status: ${currentSession.status}");
        DebugLogger.log("📋 Current participants: ${currentSession.participantNames}");
        DebugLogger.log("📋 Current participant IDs: ${currentSession.participantIds}");
        
        // ✅ FIX 2: Check if user is already in the session
        if (currentSession.participantIds.contains(currentUserId)) {
          DebugLogger.log("✅ User already in session, returning current session");
          return currentSession;
        }
        
        // ✅ FIX BUG #8: Transaction ensures these checks are atomic
        // If session status changes between read and write, Firestore will retry the transaction

        // ✅ FIX 3: Validate session can accept new participants
        if (currentSession.status == SessionStatus.cancelled) {
          throw Exception("Cannot join cancelled session");
        }

        if (currentSession.status == SessionStatus.completed) {
          throw Exception("Cannot join completed session");
        }

        // ✅ FIX 4: Allow joining both created and active sessions for groups
        final validStatuses = [SessionStatus.created, SessionStatus.active];
        if (!validStatuses.contains(currentSession.status)) {
          throw Exception("Session is not available for joining (status: ${currentSession.status})");
        }
        
        // ✅ FIX 5: Smart status management
        final newParticipantIds = [...currentSession.participantIds, currentUserId];
        final newParticipantNames = [...currentSession.participantNames, userName];
        
        SessionStatus newStatus;
        if (newParticipantIds.length >= 2) {
          newStatus = SessionStatus.active;
          DebugLogger.log("🟢 Session will be set to ACTIVE (${newParticipantIds.length} participants)");
        } else {
          newStatus = currentSession.status;
          DebugLogger.log("🟡 Session status unchanged (${newParticipantIds.length} participants)");
        }

        // ✅ FIX 6: Update session with atomic transaction
        final updateData = <String, dynamic>{
          'status': newStatus.name,
          'participantNames': newParticipantNames,
          'participantIds': newParticipantIds,
          'updatedAt': FieldValue.serverTimestamp(),
          'userLikes.$currentUserId': [],
          'userPasses.$currentUserId': [],
        };
        
        if (newStatus == SessionStatus.active && currentSession.status != SessionStatus.active) {
          updateData['startedAt'] = FieldValue.serverTimestamp();
          DebugLogger.log("🚀 Session is now starting - recording startedAt timestamp");
        }
        
        transaction.update(sessionRef, updateData);

        DebugLogger.log("✅ Session updated successfully in transaction");
        DebugLogger.log("   New status: ${newStatus.name}");
        DebugLogger.log("   Total participants: ${newParticipantIds.length}");

        // ✅ FIX: Delete the invitation from pending_invitations after successful join
        final invitationRef = _usersCollection
            .doc(currentUserId)
            .collection('pending_invitations')
            .doc(invitationId);
        transaction.delete(invitationRef);
        DebugLogger.log("🗑️ Deleted invitation from pending_invitations: $invitationId");

        return currentSession.copyWith(
          status: newStatus,
          participantIds: newParticipantIds,
          participantNames: newParticipantNames,
          startedAt: newStatus == SessionStatus.active && currentSession.status != SessionStatus.active
              ? DateTime.now()
              : currentSession.startedAt,
        );
      });
      
    } catch (e) {
      DebugLogger.log("❌ Error accepting invitation: $e");
      DebugLogger.log("❌ Session ID: $sessionId");
      DebugLogger.log("❌ User: $userName");
      
      // Clean up invitation even if join failed
      try {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          final invitationsSnapshot = await _usersCollection
              .doc(currentUserId)
              .collection('pending_invitations')
              .where('sessionId', isEqualTo: sessionId)
              .get();

          for (final inviteDoc in invitationsSnapshot.docs) {
            await inviteDoc.reference.delete();
            DebugLogger.log("🗑️ Cleaned up invitation after failed join: ${inviteDoc.id}");
          }
        }
      } catch (cleanupError) {
        DebugLogger.log("⚠️ Could not clean up invitations after failed join: $cleanupError");
      }
      
      throw e;
    }
  }
  

  // Start the actual swiping session
  static Future<void> startSession(
    String sessionId, {
    required List<String> selectedMoodIds,
    required List<String> moviePool,
  }) async {
    try {
      // Changed from 'swipeSessions' to use the _sessionsCollection variable
      await _sessionsCollection
          .doc(sessionId)
          .update({
        'status': SessionStatus.active.toString().split('.').last,
        'selectedMoodIds': selectedMoodIds,
        'selectedMoodId': selectedMoodIds.isNotEmpty ? selectedMoodIds.first : null,
        'selectedMoodName': selectedMoodIds.isNotEmpty 
            ? _getMoodDisplayName(selectedMoodIds.first) 
            : null,
        'hasMoodSelected': true,
        'moviePool': moviePool,
        'startedAt': FieldValue.serverTimestamp(),
      });

      DebugLogger.log("✅ SessionService: Started session with ${moviePool.length} movies");
    } catch (e) {
      DebugLogger.log("❌ SessionService: Error starting session: $e");
      rethrow;
    }
  }

  static String _getMoodDisplayName(String moodId) {
    try {
      final mood = CurrentMood.values.firstWhere(
        (mood) => mood.toString().split('.').last == moodId
      );
      return mood.displayName;
    } catch (e) {
      return moodId; // Fallback to raw ID
    }
  }

  // Record a user's swipe
  static Future<void> recordSwipe({
    required String sessionId,
    required String movieId,
    required bool isLike,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Changed from 'swipeSessions' to use the _sessionsCollection variable
      final sessionDoc = _sessionsCollection.doc(sessionId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final sessionSnapshot = await transaction.get(sessionDoc);
        
        if (!sessionSnapshot.exists) {
          throw Exception("Session not found");
        }

        final sessionData = sessionSnapshot.data()!;
        final swipes = Map<String, dynamic>.from(sessionData['swipes'] ?? {});
        final matches = List<String>.from(sessionData['matches'] ?? []);

        // Record this user's swipe
        swipes['${userId}_$movieId'] = {
          'isLike': isLike,
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Check for matches if it's a like
        if (isLike) {
          final participantIds = List<String>.from(sessionData['participantIds'] ?? []);
          final otherParticipants = participantIds.where((id) => id != userId).toList();
          
          // Check if all other participants have also liked this movie
          bool isMatch = otherParticipants.every((otherUserId) {
            final otherSwipeKey = '${otherUserId}_$movieId';
            return swipes[otherSwipeKey]?['isLike'] == true;
          });

          if (isMatch && !matches.contains(movieId)) {
            matches.add(movieId);
            DebugLogger.log("🎉 MATCH FOUND: $movieId");
          }
        }

        // Update session
        transaction.update(sessionDoc, {
          'swipes': swipes,
          'matches': matches,
          'lastActivity': FieldValue.serverTimestamp(),
        });
      });

    } catch (e) {
      DebugLogger.log("❌ SessionService: Error recording swipe: $e");
    }
  }

  // Listen to session updates
  static Stream<SwipeSession> watchSession(String sessionId) {
    return _sessionsCollection
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw Exception("Session not found: $sessionId");
          }
          return SwipeSession.fromJson(doc.data()!);
        });
  }

  // Get pending invitations for current user
  static Stream<List<Map<String, dynamic>>> watchPendingInvitations() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Stream.empty();

    return _usersCollection.doc(currentUser.uid)
        .collection('pending_invitations')
        .orderBy('invitedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();

          // ✅ FIX: Filter out expired invitations
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                final expiresAtStr = data['expiresAt'] as String?;

                // If no expiration set, keep the invitation (backward compatibility)
                if (expiresAtStr == null) return true;

                try {
                  final expiresAt = DateTime.parse(expiresAtStr);
                  final isExpired = now.isAfter(expiresAt);

                  if (isExpired) {
                    DebugLogger.log("⏰ Filtering out expired invitation: ${doc.id}");
                  }

                  return !isExpired; // Only keep non-expired invitations
                } catch (e) {
                  DebugLogger.log("⚠️ Error parsing expiration date: $e");
                  return true; // Keep if parsing fails
                }
              })
              .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
              .toList();
        });
  }

  // End session
  static Future<void> endSession(String sessionId) async {
    try {
      final batch = _firestore.batch();
      final sessionRef = _sessionsCollection.doc(sessionId);
      
      // First, get the current session data to notify participants
      final sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        DebugLogger.log("⚠️ Session not found: $sessionId");
        return;
      }
      
      final sessionData = sessionDoc.data()!;
      final session = SwipeSession.fromJson(sessionData);
      
      // Update session to completed status
      batch.update(sessionRef, {
        'status': SessionStatus.completed.name,
        'endedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Create a "session ended" notification for all participants
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final endedByName = session.participantNames.firstWhere(
        (name) => session.participantIds[session.participantNames.indexOf(name)] == currentUserId,
        orElse: () => 'Someone',
      );
      
      // Add notifications for other participants
      for (int i = 0; i < session.participantIds.length; i++) {
        final participantId = session.participantIds[i];
        
        // Skip the person who ended the session
        if (participantId == currentUserId) continue;
        
        // Add notification about session ending
        final notificationRef = _usersCollection
            .doc(participantId)
            .collection('notifications')
            .doc();
        
        batch.set(notificationRef, {
          'id': notificationRef.id,
          'type': 'session_ended',
          'sessionId': sessionId,
          'endedBy': endedByName,
          'endedByUserId': currentUserId,
          'matchCount': session.matches.length,
          'message': session.matches.isEmpty 
              ? '$endedByName ended the session'
              : '$endedByName ended the session - ${session.matches.length} matches found!',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
      
      // Commit all changes
      await batch.commit();
      
      DebugLogger.log("✅ Session ended successfully: $sessionId");
      DebugLogger.log("📨 Notified ${session.participantIds.length - 1} other participants");
      
      // ✅ NEW: Clean up pending invitations for this session
      await cleanupInvitationsAfterSessionEnd(sessionId);
      
    } catch (e) {
      DebugLogger.log("❌ Error ending session: $e");
      rethrow;
    }
  }

  // ✅ FIX BUG #3: Use the efficient cleanup method instead of limit(100)
  static Future<void> cleanupInvitationsAfterSessionEnd(String sessionId) async {
    // Delegate to the efficient cleanup function that tracks invited users
    await _cleanupInvitationsForSession(sessionId);
  }



  static Stream<List<Map<String, dynamic>>> watchSessionNotifications(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('notifications')
        .where('type', whereIn: ['friend_session_declined', 'session_declined'])
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // Add this method to automatically handle friend session declines
  static Future<void> handleFriendSessionDeclined({
    required String sessionId,
    required String declinedByUserId,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;
      
      DebugLogger.log("🚫 Auto-cancelling session due to friend decline: $sessionId");
      
      // Cancel the session since the invited friend declined
      await _sessionsCollection.doc(sessionId).update({
        'status': SessionStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': currentUserId,
        'cancelReason': 'invited_friend_declined',
        'declinedBy': declinedByUserId,
      });
      
      DebugLogger.log("✅ Session auto-cancelled successfully");
      
    } catch (e) {
      DebugLogger.log("❌ Error auto-cancelling session: $e");
      throw e;
    }
  }

  // Add this method to mark notifications as read
  static Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
            'read': true,
            'readAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      DebugLogger.log("⚠️ Could not mark notification as read: $e");
    }
  }

  // Cancel session
  static Future<void> cancelSession(String sessionId, {String? cancelledBy}) async {
    try {
      DebugLogger.log("🚫 Cancelling session: $sessionId by: $cancelledBy");
      
      final sessionRef = _sessionsCollection.doc(sessionId);
      
      // Update session status to cancelled with who cancelled it
      await sessionRef.update({
        'status': SessionStatus.cancelled.name,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancelledBy': cancelledBy ?? 'Unknown', // ADD THIS FIELD
      });
      
      DebugLogger.log("✅ Session cancelled successfully by: $cancelledBy");
      
      // Clean up any related pending invitations
      try {
        final usersSnapshot = await _usersCollection.limit(50).get();
        
        final batch = _firestore.batch();
        int deleteCount = 0;
        
        for (final userDoc in usersSnapshot.docs) {
          final invitationsSnapshot = await userDoc.reference
              .collection('pending_invitations')
              .where('sessionId', isEqualTo: sessionId)
              .get();
          
          for (final inviteDoc in invitationsSnapshot.docs) {
            batch.delete(inviteDoc.reference);
            deleteCount++;
          }
        }
        
        if (deleteCount > 0) {
          await batch.commit();
          DebugLogger.log("✅ Cancelled $deleteCount pending invitations");
        }
      } catch (e) {
        DebugLogger.log("⚠️ Could not clean up invitations (not critical): $e");
      }
      
    } catch (e) {
      DebugLogger.log("❌ Error cancelling session: $e");
      throw e;
    }
  }

  // Helper to get current user profile
  static Future<UserProfile> getCurrentUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    final doc = await _usersCollection.doc(currentUser.uid).get();
    return UserProfile.fromJson(doc.data()!);
  }

  // Send mood change request to all session participants
  static Future<void> sendMoodChangeRequest({
    required String sessionId,
    required String fromUserId,
    required String fromUserName,
    required String requestedMoodId,
    required String requestedMoodName,
  }) async {
    final requestRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('moodChangeRequests')
        .doc();

    await requestRef.set({
      'id': requestRef.id,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'requestedMoodId': requestedMoodId,
      'requestedMoodName': requestedMoodName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'responses': <String, dynamic>{}, // Track who responded what
    });

    DebugLogger.log("✅ Mood change request sent: $requestedMoodName");
  }

  // Watch for mood change requests for current user
  static Stream<List<Map<String, dynamic>>> watchMoodChangeRequests(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('mood_change_requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  // Respond to mood change request
  static Future<void> respondToMoodChangeRequest({
    required String sessionId,
    required String requestId,
    required String userId,
    required bool accepted,
  }) async {
    final requestRef = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('moodChangeRequests')
        .doc(requestId);

    await requestRef.update({
      'responses.$userId': accepted,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Check if all participants have responded
    final requestDoc = await requestRef.get();
    if (requestDoc.exists) {
      final data = requestDoc.data()!;
      final responses = data['responses'] as Map<String, dynamic>;
      
      // Get session to know how many participants there are
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .get();
      
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final participantCount = (sessionData['participantIds'] as List).length;
        
        // If everyone has responded
        if (responses.length >= participantCount) {
          final allAccepted = responses.values.every((response) => response == true);
          
          if (allAccepted) {
            // Apply mood change to session
            await FirebaseFirestore.instance
                .collection('sessions')
                .doc(sessionId)
                .update({
              'selectedMoodId': data['requestedMoodId'],
              'selectedMoodName': data['requestedMoodName'],
              'hasMoodSelected': true,
              'moodChangedAt': FieldValue.serverTimestamp(),
              'moviePool': [], // Clear existing movies to regenerate
            });
          }
          
          // Mark request as completed
          await requestRef.update({
            'status': allAccepted ? 'accepted' : 'declined',
            'completedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // Clean up old mood change requests (call periodically)
  static Future<void> cleanupOldMoodChangeRequests(String userId) async {
    try {
      // 🆕 ADD: Authentication guard
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        DebugLogger.log("⚠️ Skipping mood request cleanup - user not authenticated");
        return;
      }

      final cutoffDate = DateTime.now().subtract(const Duration(hours: 24));
      
      final oldRequestsSnapshot = await _usersCollection
          .doc(userId)
          .collection('mood_change_requests')
          .where('createdAt', isLessThan: cutoffDate.toIso8601String())
          .get();
      
      final batch = _firestore.batch();
      for (final doc in oldRequestsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (oldRequestsSnapshot.docs.isNotEmpty) {
        await batch.commit();
        DebugLogger.log("✅ Cleaned up ${oldRequestsSnapshot.docs.length} old mood change requests");
      }
    } catch (e) {
      DebugLogger.log("❌ Error cleaning up old mood change requests: $e");
    }
  }

  static Future<void> addMoviesToSession(
    String sessionId,
    List<String> newMovieIds,
  ) async {
    try {
      // Changed from 'swipeSessions' to use the _sessionsCollection variable
      await _sessionsCollection
          .doc(sessionId)
          .update({
        'moviePool': FieldValue.arrayUnion(newMovieIds),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      DebugLogger.log("✅ SessionService: Added ${newMovieIds.length} movies to session");
    } catch (e) {
      DebugLogger.log("❌ SessionService: Error adding movies to session: $e");
      rethrow;
    }
  }

  static SessionStatus calculateSessionStatus(int participantCount, bool isGroupSession) {
    final minParticipants = isGroupSession ? 2 : 2; // Can adjust thresholds later
    return participantCount >= minParticipants ? SessionStatus.active : SessionStatus.created;
  }
}