import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final AuthService _authService = AuthService();
  final MessageService _messageService = MessageService();
  final TextEditingController _searchController = TextEditingController();

  List<UserSearchResult> _searchResults = const [];
  bool _searching = false;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return Colors.green;
      case 'evacuating':
        return Colors.orange;
      case 'not_safe':
      case 'needs_help':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'safe':
        return 'SAFE';
      case 'evacuating':
        return 'EVACUATING';
      case 'not_safe':
      case 'needs_help':
        return 'NEEDS HELP';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    setState(() => _searching = true);
    try {
      final results = await _authService.searchUsersByUsername(text);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendRequest(String uid) async {
    try {
      await _authService.sendFriendRequest(uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection request sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _openChatWithFriend(FriendUser friend) async {
    final me = _authService.currentUser;
    if (me == null) return;
    final chatId = await _messageService.ensureDirectChat(
      myUid: me.uid,
      otherUid: friend.uid,
    );
    if (!mounted) return;
    final thread = ChatThread(
      chatId: chatId,
      otherUid: friend.uid,
      username: friend.username,
      name: friend.name,
      profileImageBase64: friend.profileImageBase64,
      lastText: '',
      lastSentAtMs: null,
      lastSenderUid: '',
      unreadCount: 0,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          myUid: me.uid,
          thread: thread,
          messageService: _messageService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Search by username',
              suffixIcon: IconButton(
                onPressed: _searching ? null : _search,
                icon: _searching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_searchResults.isNotEmpty) ...[
            const Text(
              'Search results',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ..._searchResults.map(
              (user) => ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('@${user.username}'),
                subtitle: Text(
                  user.name.isNotEmpty ? user.name : user.email,
                ),
                trailing: FilledButton(
                  onPressed: () => _sendRequest(user.uid),
                  child: const Text('Add'),
                ),
              ),
            ),
            const Divider(height: 24),
          ],
          const Text(
            'Incoming requests',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<FriendRequestItem>>(
            stream: _authService.incomingFriendRequestsStream(),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? const [];
              if (requests.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('No pending requests'),
                );
              }
              return Column(
                children: requests
                    .map(
                      (request) => ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('@${request.fromUsername}'),
                        subtitle: Text(
                          request.fromName.isNotEmpty
                              ? request.fromName
                              : request.fromUid,
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              tooltip: 'Decline',
                              onPressed: () => _authService
                                  .declineFriendRequest(request.fromUid),
                              icon: const Icon(Icons.close),
                            ),
                            IconButton(
                              tooltip: 'Accept',
                              onPressed: () => _authService
                                  .acceptFriendRequest(request.fromUid),
                              icon: const Icon(Icons.check),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const Divider(height: 24),
          const Text(
            'Your connections',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<FriendUser>>(
            stream: _authService.friendsStream(),
            builder: (context, snapshot) {
              final friends = snapshot.data ?? const [];
              if (friends.isEmpty) {
                return const Text('No connections yet');
              }
              return Column(
                children: friends
                    .map(
                      (friend) => ListTile(
                        leading: CircleAvatar(
                          backgroundImage: friend.profileImageBase64.isNotEmpty
                              ? MemoryImage(base64Decode(friend.profileImageBase64))
                              : null,
                          child: friend.profileImageBase64.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text('@${friend.username}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              friend.name.isNotEmpty ? friend.name : friend.uid,
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<String>(
                              stream: _authService.userSafetyStatusStream(friend.uid),
                              initialData: friend.safetyStatus,
                              builder: (context, safetySnap) {
                                final status = safetySnap.data ?? friend.safetyStatus;
                                final color = _statusColor(status);
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 0,
                          children: [
                            IconButton(
                              tooltip: 'Message',
                              onPressed: () => _openChatWithFriend(friend),
                              icon: const Icon(Icons.chat_bubble_outline),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () => _authService.removeFriend(friend.uid),
                              icon: const Icon(Icons.person_remove),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
