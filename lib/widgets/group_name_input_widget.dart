// File: lib/widgets/group_name_input_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/user_profile.dart';

class GroupNameInputWidget extends StatefulWidget {
  final List<UserProfile> selectedMembers;
  final Function(String groupName) onGroupNameSet;
  final VoidCallback onSkip;

  const GroupNameInputWidget({
    super.key,
    required this.selectedMembers,
    required this.onGroupNameSet,
    required this.onSkip,
  });

  @override
  State<GroupNameInputWidget> createState() => _GroupNameInputWidgetState();
}

class _GroupNameInputWidgetState extends State<GroupNameInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _suggestions = [
    "Movie Night Crew",
    "The Critics",
    "Popcorn Squad",
    "Cinema Club",
    "Film Fanatics",
    "Weekend Warriors",
    "The Binge Watchers",
    "Screen Team",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Name Your Group",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            "Give your group a fun name (optional)",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
            ),
          ),
          
          SizedBox(height: 20.h),
          
          // Group name input
          TextField(
            controller: _controller,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: "e.g. Movie Night Crew",
              hintStyle: TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: const Color(0xFFE5A00D), width: 2.w),
              ),
            ),
          ),
          
          SizedBox(height: 16.h),
          
          // Quick suggestions
          Text(
            "Quick suggestions:",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          SizedBox(height: 8.h),
          
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _suggestions.map((suggestion) => GestureDetector(
              onTap: () => _controller.text = suggestion,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  suggestion,
                  style: TextStyle(
                    color: const Color(0xFFE5A00D),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )).toList(),
          ),
          
          SizedBox(height: 24.h),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onSkip,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white30),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text("Skip", style: TextStyle(fontSize: 14.sp)),
                ),
              ),
              
              SizedBox(width: 12.w),
              
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final groupName = _controller.text.trim();
                    if (groupName.isNotEmpty) {
                      widget.onGroupNameSet(groupName);
                    } else {
                      widget.onSkip(); // Treat empty as skip
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5A00D),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    "Create Group",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}