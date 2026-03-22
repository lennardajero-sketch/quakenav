import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

import 'friends_screen.dart';
import 'manage_account_screen.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleThemeMode;
  final ThemeMode themeMode;

  const SettingsScreen({
    super.key,
    required this.onToggleThemeMode,
    required this.themeMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _updatingImage = false;

  Future<void> _changeProfileImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _updatingImage = true);
    try {
      await _authService.updateCurrentUserProfileImage(base64Encode(bytes));
    } finally {
      if (mounted) setState(() => _updatingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          if (user != null)
            StreamBuilder<String?>(
              stream: _authService.userProfileImageStream(user.uid),
              builder: (context, snapshot) {
                final image = snapshot.data;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: image != null && image.isNotEmpty
                        ? MemoryImage(base64Decode(image))
                        : null,
                    child: image == null || image.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: const Text('Profile picture'),
                  subtitle: const Text('Tap to change'),
                  trailing: _updatingImage
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: _updatingImage ? null : _changeProfileImage,
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme mode'),
            subtitle: Text(widget.themeMode.name),
            onTap: widget.onToggleThemeMode,
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Manage account'),
            subtitle: const Text('Edit name, address, username, and building'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ManageAccountScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Friends'),
            subtitle: const Text('Add/remove connections and search users'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const FriendsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}
