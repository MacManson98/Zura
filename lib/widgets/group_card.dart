// File: lib/widgets/group_card.dart

import 'package:flutter/material.dart';
import '../models/friend_group.dart';

class GroupCard extends StatelessWidget {
  final FriendGroup group;
  final String currentUserUid;
  final VoidCallback onTap;
  final VoidCallback onMatchPressed;

  const GroupCard({
    super.key,
    required this.group,
    required this.currentUserUid,
    required this.onTap,
    required this.onMatchPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isCreator = group.isCreatedBy(currentUserUid);

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
                    // Group avatar with gradient
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFFE5A00D), Colors.orange.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: group.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(width: 16),
                    
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
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (group.isPrivate)
                                const Icon(Icons.lock, color: Colors.white54, size: 16),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (group.description.isNotEmpty)
                            Text(
                              group.description,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          
                          // Group stats
                          Row(
                            children: [
                              const Icon(Icons.people, size: 16, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(
                                '${group.memberCount} member${group.memberCount != 1 ? 's' : ''}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.movie, size: 16, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(
                                '${group.totalSessions} session${group.totalSessions != 1 ? 's' : ''}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
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
                
                // Member avatars preview
                if (group.members.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: Stack(
                      children: [
                        ...group.members.take(4).toList().asMap().entries.map((entry) {
                          final index = entry.key;
                          final member = entry.value;
                          return Positioned(
                            left: index * 24.0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey[700],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1F1F1F),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  member.name.isNotEmpty
                                      ? member.name[0].toUpperCase()
                                      : "?",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        if (group.members.length > 4)
                          Positioned(
                            left: 4 * 24.0,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1F1F1F),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  "+${group.members.length - 4}",
                                  style: const TextStyle(
                                    fontSize: 10,
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
                ],
                
                // Creator badge
                if (isCreator) ...[
                  const SizedBox(height: 12),
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
                          'Created by you',
                          style: TextStyle(color: Color(0xFFE5A00D), fontSize: 12),
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