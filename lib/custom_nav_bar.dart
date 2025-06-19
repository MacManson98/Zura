// File: lib/custom_nav_bar.dart (Updated)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
    // Updated items to change "Groups" label to "Friends"
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
        'label': 'Friends', // Changed from "Groups" to "Friends"
      },
      {
        'icon': 'assets/icons/user.svg',
        'active': 'assets/icons/user_active.svg',
        'label': 'Profile',
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(35),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final isSelected = index == selectedIndex;
          final iconSize = isSelected ? 28.0 : 24.0;

          return Expanded(
            child: GestureDetector(
              onTap: () => onItemTapped(index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    isSelected
                        ? items[index]['active']!
                        : items[index]['icon']!,
                    height: iconSize,
                    // Updated to use colorFilter instead of deprecated color property
                    colorFilter: ColorFilter.mode(
                      isSelected ? Colors.white : const Color(0xFFFFA726),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index]['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFFFA726),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}