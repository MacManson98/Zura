import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../utils/debug_loader.dart';
import 'dart:async';

class FriendshipService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a friend request
  static Future<void> sendFriendRequest({
    required String fromUserId,
    required String toUserId,
    required String fromUserName,
    required String toUserName,
  }) async {
    try {
      final currentAuthUser = FirebaseAuth.instance.currentUser;
      DebugLogger.log("🔍 DEBUG - Auth user UID: ${currentAuthUser?.uid}");
      DebugLogger.log("🔍 DEBUG - fromUserId parameter: $fromUserId");
      DebugLogger.log("🔍 DEBUG - Are they equal? ${currentAuthUser?.uid == fromUserId}");
      DebugLogger.log("🔍 DEBUG - Is user authenticated? ${currentAuthUser != null}");

      // ✅ FIX BUG #4: Use transaction to prevent race condition
      await _firestore.runTransaction((transaction) async {
        // Check both directions for existing requests
        final requestId1 = '${fromUserId}_$toUserId';
        final requestId2 = '${toUserId}_$fromUserId';

        final request1Ref = _firestore.collection('friend_requests').doc(requestId1);
        final request2Ref = _firestore.collection('friend_requests').doc(requestId2);

        final request1 = await transaction.get(request1Ref);
        final request2 = await transaction.get(request2Ref);

        // Check if request exists in either direction
        if (request1.exists) {
          final status = request1.data()!['status'];
          if (status == 'pending') {
            throw Exception('Friend request already sent and is pending');
          }
          // Clean up old request
          transaction.delete(request1Ref);
          DebugLogger.log("🗑️ Cleaned up old friend request (direction 1)");
        }

        if (request2.exists) {
          final status = request2.data()!['status'];
          if (status == 'pending') {
            // If there's a reverse pending request, auto-accept it (mutual interest!)
            DebugLogger.log("🎉 Mutual friend request detected - auto-accepting!");

            // Delete both potential requests
            transaction.delete(request2Ref);

            // Add as friends immediately
            final fromUserRef = _firestore.collection('users').doc(fromUserId);
            final toUserRef = _firestore.collection('users').doc(toUserId);

            transaction.update(fromUserRef, {
              'friendIds': FieldValue.arrayUnion([toUserId]),
            });
            transaction.update(toUserRef, {
              'friendIds': FieldValue.arrayUnion([fromUserId]),
            });

            return; // Don't create new request, friendship established!
          }
          // Clean up old request
          transaction.delete(request2Ref);
          DebugLogger.log("🗑️ Cleaned up old friend request (direction 2)");
        }

        // Create new friend request document
        transaction.set(request1Ref, {
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'fromUserName': fromUserName,
          'toUserName': toUserName,
          'status': 'pending',
          'sentAt': FieldValue.serverTimestamp(),
        });

        DebugLogger.log("✅ Friend request created atomically in transaction");
      });

      DebugLogger.log("✅ Friend request sent from $fromUserName to $toUserName");
    } catch (e) {
      DebugLogger.log("❌ Error sending friend request: $e");
      throw e;
    }
  }

  static Future<List<Map<String, dynamic>>> getPendingFriendRequestsList(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('friend_requests')
          .where('toUserId', isEqualTo: userId)
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
      DebugLogger.log("❌ Error getting pending friend requests: $e");
      return [];
    }
  }

  // ✅ FIX BUG #10: Use transaction and reorder operations (friends first, delete last)
  static Future<void> acceptFriendRequestById({
    required String requestDocumentId,
    required String fromUserId,
    required String toUserId,
  }) async {
    try {
      DebugLogger.log("🤝 Starting to accept friend request with document ID: $requestDocumentId");
      DebugLogger.log("👥 From: $fromUserId -> To: $toUserId");

      // ✅ FIX: Use transaction for absolute atomicity
      await _firestore.runTransaction((transaction) async {
        final requestRef = _firestore.collection('friend_requests').doc(requestDocumentId);
        final fromUserRef = _firestore.collection('users').doc(fromUserId);
        final toUserRef = _firestore.collection('users').doc(toUserId);

        // Verify request still exists
        final requestDoc = await transaction.get(requestRef);
        if (!requestDoc.exists) {
          throw Exception('Friend request no longer exists');
        }

        // Verify request is still pending
        final requestData = requestDoc.data()!;
        if (requestData['status'] != 'pending') {
          throw Exception('Friend request is no longer pending');
        }

        // ✅ FIX: Update users to be friends FIRST (before deleting request)
        DebugLogger.log("👥 Adding $toUserId to $fromUserId's friends");
        transaction.update(fromUserRef, {
          'friendIds': FieldValue.arrayUnion([toUserId]),
        });

        DebugLogger.log("👥 Adding $fromUserId to $toUserId's friends");
        transaction.update(toUserRef, {
          'friendIds': FieldValue.arrayUnion([fromUserId]),
        });

        // ✅ FIX: Delete request LAST (after friendship established)
        DebugLogger.log("🗑️ Deleting friend request document");
        transaction.delete(requestRef);
      });

      DebugLogger.log("✅ Friend request accepted atomically. Users are now friends!");
    } catch (e) {
      DebugLogger.log("❌ Error accepting friend request by ID: $e");
      DebugLogger.log("❌ Document ID: $requestDocumentId");
      DebugLogger.log("❌ Error type: ${e.runtimeType}");
      throw e;
    }
  }

  static Future<void> declineFriendRequestById(String requestDocumentId) async {
    try {
      DebugLogger.log("🚫 Declining friend request with document ID: $requestDocumentId");
      
      // DELETE the friend request document using the ACTUAL document ID
      await _firestore.collection('friend_requests').doc(requestDocumentId).delete();

      DebugLogger.log("✅ Friend request declined and removed");
    } catch (e) {
      DebugLogger.log("❌ Error declining friend request by ID: $e");
      throw e;
    }
  }

  static Stream<List<Map<String, dynamic>>> getPendingFriendRequests(String userId) {
    DebugLogger.log("🔄 Setting up friend requests stream for user: $userId");
    
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          DebugLogger.log("📥 Friend requests stream update: ${snapshot.docs.length} pending requests");
          
          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            DebugLogger.log("📋 Friend request: ${doc.id} from ${data['fromUserName']} to ${data['toUserName']}");
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
          
          DebugLogger.log("✅ Returning ${requests.length} friend requests to UI");
          return requests;
        });
  }

  // Get user's friends list
  static Future<List<UserProfile>> getFriends(String userId) async {
    try {
      DebugLogger.log("🔍 Getting friends for user: $userId");
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        DebugLogger.log("❌ User document doesn't exist");
        return [];
      }

      final userData = userDoc.data()!;
      final List<String> friendIds = List<String>.from(userData['friendIds'] ?? []);
      DebugLogger.log("🔍 Found friendIds: $friendIds");

      if (friendIds.isEmpty) {
        DebugLogger.log("ℹ️ No friend IDs found");
        return [];
      }

      final List<UserProfile> friends = [];
      
      for (String friendId in friendIds) {
        DebugLogger.log("🔍 Loading friend: $friendId");
        final friendDoc = await _firestore.collection('users').doc(friendId).get();
        if (friendDoc.exists) {
          final friendData = friendDoc.data()!;
          DebugLogger.log("🔍 Friend data: ${friendData['name']} (${friendData['uid']})");
          friends.add(UserProfile.fromJson(friendData));
        } else {
          DebugLogger.log("❌ Friend document not found: $friendId");
        }
      }

      DebugLogger.log("✅ Loaded ${friends.length} friends");
      return friends;
    } catch (e) {
      DebugLogger.log("❌ Error getting friends: $e");
      return [];
    }
  }

  // Remove a friend
  static Future<void> removeFriend({
    required String userId,
    required String friendId,
  }) async {
    try {
      final batch = _firestore.batch();

      // Remove from both users' friends arrays
      final userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {
        'friendIds': FieldValue.arrayRemove([friendId]),
      });

      final friendRef = _firestore.collection('users').doc(friendId);
      batch.update(friendRef, {
        'friendIds': FieldValue.arrayRemove([userId]),
      });

      await batch.commit();

      DebugLogger.log("✅ Friend removed successfully");
    } catch (e) {
      DebugLogger.log("❌ Error removing friend: $e");
      throw e;
    }
  }

  static Future<List<UserProfile>> searchUsersByName(String searchTerm, String currentUserId) async {
    try {
      DebugLogger.log('🔍 Searching for: $searchTerm');
      
      // Simple Firestore query using the original approach but with better error handling
      final querySnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThanOrEqualTo: searchTerm + '\uf8ff')
          .get();

      DebugLogger.log('📥 Found ${querySnapshot.docs.length} documents');

      final List<UserProfile> users = [];
      
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          final user = UserProfile.fromJson(doc.data());
          users.add(user);
          DebugLogger.log('✅ Added user: ${user.name}');
        }
      }

      DebugLogger.log('🎯 Returning ${users.length} users');
      return users;
      
    } catch (e) {
      DebugLogger.log("❌ Search error: $e");
      return [];
    }
  }

  // IMPORTANT: You'll also need to add this method to update user documents
  // to include a lowercase name field for efficient searching:

  static Future<void> updateAllUsersForSearch() async {
    final users = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    
    for (var doc in users.docs) {
      final data = doc.data();
      if (data['name'] != null) {
        batch.update(doc.reference, {
          'nameLowercase': (data['name'] as String).toLowerCase(),
        });
      }
    }
    
    await batch.commit();
    DebugLogger.log('✅ Updated all users for optimized search');
  }

  // Check if two users are friends
  static Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId1).get();
      
      if (!userDoc.exists) return false;

      final userData = userDoc.data()!;
      final List<String> friendIds = List<String>.from(userData['friendIds'] ?? []);

      return friendIds.contains(userId2);
    } catch (e) {
      DebugLogger.log("❌ Error checking friendship: $e");
      return false;
    }
  }

  // Check if friend request exists
  static Future<String?> getFriendRequestStatus(String fromUserId, String toUserId) async {
    try {
      final requestDoc = await _firestore.collection('friend_requests').doc('${fromUserId}_$toUserId').get();
      
      if (requestDoc.exists) {
        return requestDoc.data()!['status'];
      }
      
      return null;
    } catch (e) {
      DebugLogger.log("❌ Error checking friend request: $e");
      return null;
    }
  }
  // ✅ FIX BUG #9: Batch load friends instead of N+1 queries
  static Stream<List<UserProfile>> watchFriends(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncMap((userDoc) async {
      if (!userDoc.exists) return <UserProfile>[];

      final userData = userDoc.data()!;
      final List<String> friendIds = List<String>.from(userData['friendIds'] ?? []);

      if (friendIds.isEmpty) return <UserProfile>[];

      // ✅ FIX: Batch load friends (Firestore limit is 10 per whereIn query)
      final List<UserProfile> friends = [];

      // Split into batches of 10 (Firestore whereIn limit)
      for (int i = 0; i < friendIds.length; i += 10) {
        final batch = friendIds.skip(i).take(10).toList();

        try {
          final snapshot = await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: batch)
              .get();

          for (final doc in snapshot.docs) {
            if (doc.exists) {
              friends.add(UserProfile.fromJson(doc.data()));
            }
          }
        } catch (e) {
          DebugLogger.log("❌ Error loading friend batch starting at index $i: $e");
        }
      }

      DebugLogger.log("✅ Loaded ${friends.length} friends in ${(friendIds.length / 10).ceil()} batch(es) (was ${friendIds.length} individual queries!)");
      return friends;
    });
  }
}