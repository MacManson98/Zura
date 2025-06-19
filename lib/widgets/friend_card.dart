// File: lib/widgets/friend_card.dart

import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class FriendCard extends StatelessWidget {
  final UserProfile friend;
  final UserProfile currentUser;
  final double compatibility;
  final VoidCallback onTap;
  final VoidCallback onMatchPressed;

  const FriendCard({
    super.key,
    required this.friend,
    required this.currentUser,
    required this.compatibility,
    required this.onTap,
    required this.onMatchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final sharedGenres = friend.preferredGenres.intersection(currentUser.preferredGenres);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1F1F1F),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar with online status
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[800],
                          child: Text(
                            friend.name.isNotEmpty ? friend.name[0].toUpperCase() : "?",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1F1F1F), width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Friend info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (friend.preferredGenres.isNotEmpty)
                            Text(
                              'Loves: ${friend.preferredGenres.take(3).join(", ")}${friend.preferredGenres.length > 3 ? "..." : ""}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          
                          // Compatibility bar
                          Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 16,
                                color: compatibility > 70 ? Colors.red : 
                                       compatibility > 40 ? Colors.orange : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: compatibility / 100,
                                  backgroundColor: Colors.grey[800],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    compatibility > 70 ? Colors.red :
                                    compatibility > 40 ? Colors.orange : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${compatibility.toInt()}%',
                                style: TextStyle(
                                  color: compatibility > 70 ? Colors.red :
                                         compatibility > 40 ? Colors.orange : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Match button
                    ElevatedButton(
                      onPressed: onMatchPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A00D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Match',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Shared genres section
                if (sharedGenres.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5A00D).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 14, color: Color(0xFFE5A00D)),
                        const SizedBox(width: 6),
                        Text(
                          'Both love: ${sharedGenres.take(2).join(", ")}${sharedGenres.length > 2 ? " +${sharedGenres.length - 2} more" : ""}',
                          style: const TextStyle(
                            color: Color(0xFFE5A00D),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}