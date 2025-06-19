// File: lib/widgets/pending_invitations_widget.dart
// Widget to show pending invitations count and quick access

import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../movie.dart';
import '../models/session_models.dart';
import '../services/session_service.dart';
import '../services/friendship_service.dart';
import '../services/group_invitation_service.dart';
import '../screens/notifications_screen.dart';

class PendingInvitationsWidget extends StatelessWidget {
  final UserProfile currentUser;
  final List<Movie> allMovies;
  final Function(SwipeSession session)? onSessionJoined;

  const PendingInvitationsWidget({
    super.key,
    required this.currentUser,
    required this.allMovies,
    this.onSessionJoined,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SessionService.watchPendingInvitations(),
      builder: (context, sessionSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: FriendshipService.getPendingFriendRequests(currentUser.uid),
          builder: (context, friendSnapshot) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: GroupInvitationService().watchPendingGroupInvitations(currentUser.uid),
              builder: (context, groupSnapshot) {
                final sessionCount = sessionSnapshot.data?.length ?? 0;
                final friendCount = friendSnapshot.data?.length ?? 0;
                final groupCount = groupSnapshot.data?.length ?? 0;
                final totalCount = sessionCount + friendCount + groupCount;

                if (totalCount == 0) {
                  return const SizedBox.shrink();
                }

                return _buildInvitationsBadge(context, totalCount, sessionCount, friendCount, groupCount);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInvitationsBadge(BuildContext context, int total, int sessions, int friends, int groups) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: const Color(0xFF1F1F1F),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(
                              currentUser: currentUser,
                              allMovies: allMovies,
                              onSessionJoined: onSessionJoined,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Notification icon with count badge
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFFE5A00D),
                                        Colors.orange.shade600,
                                      ],
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
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                // Count badge
                                Positioned(
                                  top: -2,
                                  right: -2,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 18,
                                      minHeight: 18,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF121212),
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        total > 99 ? '99+' : total.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getInvitationText(total, sessions, friends, groups),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (total > 1) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      _getDetailText(sessions, friends, groups),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            // Action indicator
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "View",
                                    style: TextStyle(
                                      color: Color(0xFFE5A00D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Color(0xFFE5A00D),
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  String _getInvitationText(int total, int sessions, int friends, int groups) {
    if (total == 1) {
      if (sessions > 0) return 'Movie session invitation';
      if (friends > 0) return 'Friend request';
      if (groups > 0) return 'Group invitation';
    }
    
    return '$total new notifications';
  }

  String _getDetailText(int sessions, int friends, int groups) {
    List<String> parts = [];
    
    if (sessions > 0) {
      parts.add('$sessions session${sessions != 1 ? 's' : ''}');
    }
    if (friends > 0) {
      parts.add('$friends friend${friends != 1 ? 's' : ''}');
    }
    if (groups > 0) {
      parts.add('$groups group${groups != 1 ? 's' : ''}');
    }
    
    if (parts.length <= 2) {
      return parts.join(' & ');
    } else {
      return '${parts.take(2).join(', ')} & more';
    }
  }
}