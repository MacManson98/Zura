import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
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
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(35.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
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
                      onTap: () => onItemTapped(index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: isSelected
                                ? BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.6),
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
                          SizedBox(height: 4.h),
                          Text(
                            items[index]['label']!,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.white : const Color(0xFFFFA726),
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12.sp,
                            ),
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
