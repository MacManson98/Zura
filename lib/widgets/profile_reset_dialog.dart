import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileResetDialog extends StatefulWidget {
  final UserProfile currentUser;
  final VoidCallback onProfileReset;

  const ProfileResetDialog({
    Key? key,
    required this.currentUser,
    required this.onProfileReset,
  }) : super(key: key);

  @override
  State<ProfileResetDialog> createState() => _ProfileResetDialogState();
}

class _ProfileResetDialogState extends State<ProfileResetDialog> {
  bool _keepLikedMovies = true;
  bool _keepSavedMovies = false;
  bool _resetTutorials = true;
  bool _isResetting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),
      title: const Text(
        "Reset Profile for Testing",
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Choose what to preserve when resetting your profile:",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          
          // Keep liked movies option
          CheckboxListTile(
            title: const Text("Keep Liked Movies", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Preserve your movie likes for testing matches", style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _keepLikedMovies,
            activeColor: const Color(0xFFE5A00D),
            checkColor: Colors.black,
            onChanged: (value) {
              setState(() {
                _keepLikedMovies = value ?? true;
              });
            },
          ),
          
          // Keep saved movies option
          CheckboxListTile(
            title: const Text("Keep Saved Movies", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Preserve your saved movies collection", style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _keepSavedMovies,
            activeColor: const Color(0xFFE5A00D),
            checkColor: Colors.black,
            onChanged: (value) {
              setState(() {
                _keepSavedMovies = value ?? false;
              });
            },
          ),
          
          // Reset tutorials option
          CheckboxListTile(
            title: const Text("Reset Tutorials", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Show tutorial screens again", style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _resetTutorials,
            activeColor: const Color(0xFFE5A00D),
            checkColor: Colors.black,
            onChanged: (value) {
              setState(() {
                _resetTutorials = value ?? true;
              });
            },
          ),
          
          const SizedBox(height: 8),
          if (_isResetting)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(
                  color: Color(0xFFE5A00D),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isResetting 
              ? null 
              : () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: _isResetting ? null : _resetProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE5A00D),
          ),
          child: _isResetting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text("Reset Profile", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _resetProfile() async {
  setState(() {
    _isResetting = true;
  });

  try {
    final currentProfile = widget.currentUser;

    // Create a blank profile with same UID and name
    final newProfile = UserProfile.empty();
    newProfile.uid = currentProfile.uid;
    newProfile.name = currentProfile.name;

    // Preserve selected fields
    if (_keepLikedMovies) {
      newProfile.likedMovies = Set.from(currentProfile.likedMovies);
    }

    // Reset in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentProfile.uid)
        .set(newProfile.toJson());

    // Reset tutorials if selected
    if (_resetTutorials) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tutorial_seen', false);
    }

    // Notify parent to reload
    widget.onProfileReset();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile has been reset for testing'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  } finally {
    if (mounted) {
      setState(() {
        _isResetting = false;
      });
    }
  }
}
}