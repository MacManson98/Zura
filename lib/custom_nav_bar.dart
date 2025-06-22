import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final bool hasHighPriorityNotifications;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.hasHighPriorityNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    const List<Map<String, String>> items = [
      {
        'icon': 'assets/icons/home.svg',
        'active': 'assets/icons/home_active.svg',
        'label': 'Home',
      },
      {
        'icon': 'assets/icons/heart.svg',
        'active': 'assets/icons/heart_active.svg',
        'label': 'Match',
      },
      {
        'icon': 'assets/icons/groups.svg',
        'active': 'assets/icons/groups_active.svg',
        'label': 'Friends',
      },
      {
        'icon': 'assets/icons/user.svg',
        'active': 'assets/icons/user_active.svg',
        'label': 'Profile',
      },
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: 0.h),
      child: ClipRRect( // 👈 Clip the parent background too
        borderRadius: BorderRadius.circular(35.r),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(35.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            Container(
              height: 70.h,
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final isSelected = index == selectedIndex;
                  final iconSize = isSelected ? 28.w : 24.w;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Handle notification tap for Friends tab (index 2)
                        if (index == 2 && notificationCount > 0 && onNotificationTap != null) {
                          onNotificationTap!();
                        } else {
                          onItemTapped(index);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: isSelected
                                    ? BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.6),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      )
                                    : null,
                                child: SvgPicture.asset(
                                  isSelected
                                      ? items[index]['active']!
                                      : items[index]['icon']!,
                                  height: iconSize,
                                  colorFilter: ColorFilter.mode(
                                    isSelected ? Colors.white : const Color(0xFFFFA726),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              
                              // Add notification badge to Friends tab (index 2)
                              if (index == 2 && notificationCount > 0)
                                Positioned(
                                  right: -4.w,
                                  top: -4.h,
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minWidth: 18.w,
                                      minHeight: 18.h,
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: hasHighPriorityNotifications
                                            ? [Colors.red.shade400, Colors.red.shade600]
                                            : [const Color(0xFFFFA726), const Color(0xFFFF8F00)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        width: 1.w,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (hasHighPriorityNotifications ? Colors.red : const Color(0xFFFFA726))
                                              .withValues(alpha: 0.6),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      notificationCount > 99 ? '99+' : notificationCount.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                items[index]['label']!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : const Color(0xFFFFA726),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12.sp,
                                ),
                              ),
                              
                              // Add a small indicator next to "Friends" label when there are notifications
                              if (index == 2 && notificationCount > 0) ...[
                                SizedBox(width: 4.w),
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: BoxDecoration(
                                    color: hasHighPriorityNotifications ? Colors.red : const Color(0xFFFFA726),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (hasHighPriorityNotifications ? Colors.red : const Color(0xFFFFA726))
                                            .withValues(alpha: 0.8),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}