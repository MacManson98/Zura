import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/session_models.dart';
import '../models/user_profile.dart';
import '../utils/mood_based_learning_engine.dart';
import '../utils/debug_loader.dart';

class SessionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final _sessionsCollection = _firestore.collection('swipeSessions');
  static final _usersCollection = _firestore.collection('users');

  // Generate a unique 6-digit session code
  static String _generateSessionCode() {
    final random = Random();
    final code = random.nextInt(900000) + 100000; // 6-digit number
    return code.toString();
  }

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

    final sessionCode = inviteType == InvitationType.code ? _generateSessionCode() : null;
    
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
      sessionCode: sessionCode,
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

  // 🆕 UPDATED: Send direct friend invitation with mood support
  static Future<void> inviteFriend({
    required String sessionId,
    required String friendId,
    required String friendName,
    CurrentMood? selectedMood, // 🆕 NEW: Changed to CurrentMood? for type safety
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("User not authenticated");
      
      final currentUserProfile = await getCurrentUserProfile();
      
      // 🆕 NEW: Prepare mood information for invitation
      Map<String, dynamic> invitationData = {
        'sessionId': sessionId,
        'fromUserId': currentUser.uid,
        'fromUserName': currentUserProfile.name,
        'invitedAt': DateTime.now().toIso8601String(),
        'type': 'swipe_session',
      };
      
      // 🆕 FIXED: Use correct CurrentMood properties
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
      
      DebugLogger.log("✅ Invitation sent to $friendName");
      if (selectedMood != null) {
        DebugLogger.log("   Mood: ${selectedMood.displayName} ${selectedMood.emoji}");
      }
      
    } catch (e) {
      DebugLogger.log("❌ Error sending invitation: $e");
      throw e;
    }
  }

  // Add this method to your SessionService class if it's not there:
  static Future<SwipeSession?> joinSessionByCode(String sessionCode, String userName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception("User not authenticated");

    // Find session with this code
    final querySnapshot = await _sessionsCollection
        .where('sessionCode', isEqualTo: sessionCode)
        .where('status', isEqualTo: SessionStatus.created.name)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // Session not found or no longer available
    }

    final sessionDoc = querySnapshot.docs.first;
    final session = SwipeSession.fromJson(sessionDoc.data());

    // Add user to session
    final updatedSession = session.copyWith(
      participantIds: [...session.participantIds, currentUser.uid],
      participantNames: [...session.participantNames, userName],
      userLikes: {...session.userLikes, currentUser.uid: []},
      userPasses: {...session.userPasses, currentUser.uid: []},
    );

    await _sessionsCollection.doc(session.sessionId).update(updatedSession.toJson());
    return updatedSession;
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
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      DebugLogger.log("❌ Error getting pending invitations: $e");
      return [];
    }
  }

  // Clean up invitations for a deleted session
  static Future<void> _cleanupInvitationsForSession(String sessionId) async {
    try {
      // 🆕 ADD: Authentication guard
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        DebugLogger.log("⚠️ Skipping invitation cleanup - user not authenticated");
        return;
      }

      // Get all users and check their pending invitations
      final usersSnapshot = await _usersCollection.get();
      
      for (final userDoc in usersSnapshot.docs) {
        final invitationsSnapshot = await userDoc.reference
            .collection('pending_invitations')
            .where('sessionId', isEqualTo: sessionId)
            .get();
        
        // Delete invitations for this session
        for (final invitationDoc in invitationsSnapshot.docs) {
          await invitationDoc.reference.delete();
        }
      }
      
      DebugLogger.log("✅ Cleaned up invitations for session: $sessionId");
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

      final cutoffDate = DateTime.now().subtract(const Duration(hours: 48));
      
      final oldInvitationsSnapshot = await _usersCollection
          .doc(userId)
          .collection('pending_invitations')
          .where('invitedAt', isLessThan: cutoffDate.toIso8601String())
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in oldInvitationsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      if (oldInvitationsSnapshot.docs.isNotEmpty) {
        await batch.commit();
        DebugLogger.log("✅ Cleaned up ${oldInvitationsSnapshot.docs.length} old invitations for user");
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

      // Remove invitation from user's pending invitations
      await _usersCollection
          .doc(currentUserId)
          .collection('pending_invitations')
          .doc(invitationId)
          .delete();

      // Update session to track declined invitations
      if (sessionId != null) {
        try {
          final sessionDoc = await _sessionsCollection.doc(sessionId).get();
          if (sessionDoc.exists) {
            await _sessionsCollection.doc(sessionId).update({
              'declinedBy': FieldValue.arrayUnion([currentUserId]),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            // Check if session should be cleaned up after this decline
            await checkAndCleanupSession(sessionId);
          }
        } catch (e) {
          DebugLogger.log("Note: Could not update session with decline info: $e");
        }
      }

      DebugLogger.log("✅ Invitation declined and removed");
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
  static Future<SwipeSession?> acceptInvitation(String sessionId, String userName) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        DebugLogger.log("❌ No current user found");
        return null;
      }

      DebugLogger.log("🤝 Accepting invitation for session: $sessionId, user: $userName");

      // First, check if session exists and get current data
      final sessionDoc = await _sessionsCollection.doc(sessionId).get();
      if (!sessionDoc.exists) {
        DebugLogger.log("❌ Session not found: $sessionId");
        return null;
      }

      final currentSession = SwipeSession.fromJson(sessionDoc.data()!);
      DebugLogger.log("📋 Current session status: ${currentSession.status}");
      DebugLogger.log("📋 Current participants: ${currentSession.participantNames}");

      // Update session to add participant and activate
      await _sessionsCollection.doc(sessionId).update({
        'status': SessionStatus.active.name, // Use enum value
        'participantNames': FieldValue.arrayUnion([userName]),
        'participantIds': FieldValue.arrayUnion([currentUserId]),
        'updatedAt': FieldValue.serverTimestamp(),
        // Initialize user likes/passes if not exists
        'userLikes.$currentUserId': [],
        'userPasses.$currentUserId': [],
      });

      DebugLogger.log("✅ Session updated successfully");

      // Clean up the invitation from user's pending invitations
      try {
        final invitationsSnapshot = await _usersCollection
            .doc(currentUserId)
            .collection('pending_invitations')
            .where('sessionId', isEqualTo: sessionId)
            .get();

        for (final inviteDoc in invitationsSnapshot.docs) {
          await inviteDoc.reference.delete();
          DebugLogger.log("🗑️ Cleaned up invitation: ${inviteDoc.id}");
        }
      } catch (e) {
        DebugLogger.log("⚠️ Could not clean up invitations (not critical): $e");
      }

      // Return updated session
      final updatedDoc = await _sessionsCollection.doc(sessionId).get();
      if (updatedDoc.exists) {
        final updatedSession = SwipeSession.fromJson(updatedDoc.data()!);
        DebugLogger.log("🎉 Successfully joined session with ${updatedSession.participantNames.length} participants");
        return updatedSession;
      }
      
      return null;
    } catch (e) {
      DebugLogger.log("❌ Error accepting invitation: $e");
      DebugLogger.log("❌ Session ID: $sessionId");
      DebugLogger.log("❌ User: $userName");
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
        .map((snapshot) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList());
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
      
    } catch (e) {
      DebugLogger.log("❌ Error ending session: $e");
      rethrow;
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
}