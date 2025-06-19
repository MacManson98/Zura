// File: lib/widgets/mood_selection_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/mood_based_learning_engine.dart';

class MoodSelectionWidget extends StatefulWidget {
  final Function(List<CurrentMood>) onMoodsSelected; // Changed to List<CurrentMood>
  final bool isGroupMode;
  final int groupSize;

  const MoodSelectionWidget({
    super.key,
    required this.onMoodsSelected,
    this.isGroupMode = false,
    this.groupSize = 1,
  });

  @override
  State<MoodSelectionWidget> createState() => _MoodSelectionWidgetState();
}

class _MoodSelectionWidgetState extends State<MoodSelectionWidget>
    with TickerProviderStateMixin {
  Set<CurrentMood> selectedMoods = {}; // Changed to Set for multi-select
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Get the appropriate moods based on mode
  List<CurrentMood> get _availableMoods {
    if (widget.isGroupMode) {
      // Group/Friend modes get all moods except perfectForMe
      return CurrentMood.values.where((mood) => mood != CurrentMood.perfectForMe).toList();
    } else {
      // Solo mode gets all moods except perfectForUs
      return CurrentMood.values.where((mood) => mood != CurrentMood.perfectForUs).toList();
    }
  }

  // Check if a mood is profile-based
  bool _isProfileBased(CurrentMood mood) {
    return mood == CurrentMood.perfectForMe || mood == CurrentMood.perfectForUs;
  }

  // Handle mood selection with mutual exclusivity logic
  void _toggleMood(CurrentMood mood) {
    setState(() {
      if (_isProfileBased(mood)) {
        // Profile-based mood: clear all others and select only this one
        selectedMoods.clear();
        selectedMoods.add(mood);
      } else {
        // Non-profile mood
        if (selectedMoods.contains(mood)) {
          // Deselecting current mood
          selectedMoods.remove(mood);
        } else {
          // Selecting new mood: remove any profile-based moods first
          selectedMoods.removeWhere((m) => _isProfileBased(m));
          selectedMoods.add(mood);
        }
      }
    });
  }

  // Get display text for selected moods
  String _getSelectedMoodsText() {
    if (selectedMoods.isEmpty) return "";
    if (selectedMoods.length == 1) return selectedMoods.first.displayName;
    if (selectedMoods.length == 2) {
      return "${selectedMoods.first.displayName} + ${selectedMoods.last.displayName}";
    }
    return "${selectedMoods.first.displayName} + ${selectedMoods.length - 1} more";
  }

  // Get combined emoji for selected moods
  String _getSelectedMoodsEmoji() {
    if (selectedMoods.isEmpty) return "";
    if (selectedMoods.length == 1) return selectedMoods.first.emoji;
    return selectedMoods.take(3).map((m) => m.emoji).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF0F0F0F),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(24.r),
              child: Column(
                children: [
                  Text(
                    widget.isGroupMode 
                        ? "What's the group mood?" 
                        : "What's your mood?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    widget.isGroupMode
                        ? "Pick the vibe(s) that match your group of ${widget.groupSize}"
                        : "Pick your mood(s) - we'll blend them perfectly for you",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Mood Grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  childAspectRatio: 1.3,
                ),
                itemCount: _availableMoods.length,
                itemBuilder: (context, index) {
                  final mood = _availableMoods[index];
                  final isSelected = selectedMoods.contains(mood);
                  
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: isSelected ? _pulseAnimation.value : 1.0,
                        child: _buildMoodCard(mood, isSelected),
                      );
                    },
                  );
                },
              ),
            ),

            // Continue Button
            if (selectedMoods.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.all(24.r),
                child: Column(
                  children: [
                    // Selected moods preview
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5A00D).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(25.r),
                        border: Border.all(
                          color: const Color(0xFFE5A00D),
                          width: 1.5.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getSelectedMoodsEmoji(),
                            style: TextStyle(fontSize: 20.sp),
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              _getSelectedMoodsText(),
                              style: TextStyle(
                                color: const Color(0xFFE5A00D),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                    
                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () => widget.onMoodsSelected(selectedMoods.toList()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE5A00D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28.r),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                        ),
                        child: Text(
                          "Start Swiping",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildMoodCard(CurrentMood mood, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleMood(mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFE5A00D),
                    const Color(0xFFFF8A00),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1F1F1F),
                  ],
                ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : Colors.grey.withValues(alpha: 0.3),
            width: 1.w,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE5A00D).withValues(alpha: 0.3),
                    blurRadius: 12.r,
                    spreadRadius: 1.r,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6.r,
                    offset: Offset(0, 3.h),
                  ),
                ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Stack(
            children: [
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Emoji
                  Text(
                    mood.emoji,
                    style: TextStyle(fontSize: 28.sp),
                  ),
                  SizedBox(height: 8.h),
                  
                  // Mood name
                  Text(
                    mood.displayName,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  
                  // Description
                  Text(
                    _getMoodDescription(mood),
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.black.withValues(alpha: 0.7)
                          : Colors.grey[400],
                      fontSize: 10.sp,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              
              // Selection indicator for multi-select
              if (isSelected && selectedMoods.length > 1)
                Positioned(
                  top: 4.r,
                  right: 4.r,
                  child: Container(
                    width: 20.w,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14.sp,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodDescription(CurrentMood mood) {
    if (mood == CurrentMood.perfectForMe) {
      return "Based on your taste";
    } else if (mood == CurrentMood.perfectForUs) {
      return "Based on group taste";
    } else {
      return mood.preferredGenres.take(2).join(" • ");
    }
  }
}

// Quick mood selector for returning users
class QuickMoodSelector extends StatelessWidget {
  final Function(List<CurrentMood>) onMoodsSelected; // Changed to List<CurrentMood>
  final List<CurrentMood> recentMoods;
  final bool isGroupMode;

  const QuickMoodSelector({
    super.key,
    required this.onMoodsSelected,
    this.recentMoods = const [],
    this.isGroupMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final moodsToShow = recentMoods.isNotEmpty 
        ? recentMoods.take(4).toList()
        : _getDefaultMoods();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick mood pick:",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          
          Row(
            children: moodsToShow.map((mood) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _buildQuickMoodChip(mood),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  List<CurrentMood> _getDefaultMoods() {
    if (isGroupMode) {
      return [CurrentMood.adventurous, CurrentMood.lighthearted, CurrentMood.romantic, CurrentMood.perfectForUs];
    } else {
      return [CurrentMood.adventurous, CurrentMood.lighthearted, CurrentMood.romantic, CurrentMood.perfectForMe];
    }
  }

  Widget _buildQuickMoodChip(CurrentMood mood) {
    return GestureDetector(
      onTap: () => onMoodsSelected([mood]), // Pass as single-item list
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              mood.emoji,
              style: TextStyle(fontSize: 20.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              mood.displayName.split(' ').first, // First word only
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}