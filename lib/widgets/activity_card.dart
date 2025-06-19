// File: lib/widgets/activity_card.dart

import 'package:flutter/material.dart';
import '../models/activity_item.dart';

class ActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
  });

  IconData _getActivityIcon() {
    switch (activity.type) {
      case ActivityType.movieLiked:
        return Icons.favorite;
      case ActivityType.friendMatch:
        return Icons.movie;
      case ActivityType.groupCreated:
        return Icons.group_add;
      case ActivityType.movieWatched:
        return Icons.visibility;
      case ActivityType.friendAdded:
        return Icons.person_add;
    }
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.movieLiked:
        return Colors.red;
      case ActivityType.friendMatch:
        return Colors.green;
      case ActivityType.groupCreated:
        return Colors.purple;
      case ActivityType.movieWatched:
        return Colors.blue;
      case ActivityType.friendAdded:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF1F1F1F),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Activity icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getActivityColor().withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getActivityIcon(),
                  color: _getActivityColor(),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Activity details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity.timeAgo,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}