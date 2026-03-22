import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  final AuthService _authService = AuthService();
  final MessageService _messageService = MessageService();

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
        return 'EVAC';
      case 'not_safe':
      case 'needs_help':
        return 'HELP';
      default:
        return 'UNK';
    }
  }

  String _titleFor(ChatThread thread) {
    if (thread.username.isNotEmpty) return '@${thread.username}';
    if (thread.name.isNotEmpty) return thread.name;
    return thread.otherUid;
  }

  String _timeText(int? millis) {
    if (millis == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.month}/${dt.day}';
  }

  Future<void> _openNewMessagePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StreamBuilder<List<FriendUser>>(
          stream: _authService.friendsStream(),
          builder: (context, snapshot) {
            final friends = snapshot.data ?? const <FriendUser>[];
            if (friends.isEmpty) {
              return const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No friends yet. Add connections first.'),
                ),
              );
            }
            return SafeArea(
              child: ListView(
                children: [
                  const ListTile(
                    title: Text(
                      'New Message',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  ...friends.map((friend) {
                    final title = friend.username.isNotEmpty
                        ? '@${friend.username}'
                        : (friend.name.isNotEmpty ? friend.name : friend.uid);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend.profileImageBase64.isNotEmpty
                            ? MemoryImage(base64Decode(friend.profileImageBase64))
                            : null,
                        child: friend.profileImageBase64.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(title),
                      subtitle: friend.name.isNotEmpty ? Text(friend.name) : null,
                      onTap: () async {
                        final user = _authService.currentUser;
                        if (user == null) return;
                        final chatId = await _messageService.ensureDirectChat(
                          myUid: user.uid,
                          otherUid: friend.uid,
                        );
                        if (!mounted) return;
                        Navigator.of(context).pop();
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
                        Navigator.of(this.context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ChatScreen(
                              myUid: user.uid,
                              thread: thread,
                              messageService: _messageService,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in required')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: _openNewMessagePicker,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<ChatThread>>(
        stream: _messageService.userThreadsStream(user.uid),
        builder: (context, snapshot) {
          final threads = snapshot.data ?? const <ChatThread>[];
          if (threads.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.forum_outlined, size: 48),
                  const SizedBox(height: 8),
                  const Text('No messages yet'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _openNewMessagePicker,
                    child: const Text('Start chat'),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final thread = threads[index];
              final avatar = thread.profileImageBase64;
              final title = _titleFor(thread);
              final hasUnread = thread.unreadCount > 0;
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: avatar.isNotEmpty
                      ? MemoryImage(base64Decode(avatar))
                      : null,
                  child: avatar.isEmpty ? const Icon(Icons.person) : null,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                    StreamBuilder<String>(
                      stream: _authService.userSafetyStatusStream(thread.otherUid),
                      builder: (context, statusSnap) {
                        final status = statusSnap.data ?? 'unknown';
                        final color = _statusColor(status);
                        return Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
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
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                subtitle: Text(
                  thread.lastText.isNotEmpty ? thread.lastText : 'Say hi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _timeText(thread.lastSentAtMs),
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    if (hasUnread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          thread.unreadCount > 99
                              ? '99+'
                              : thread.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(
                        myUid: user.uid,
                        thread: thread,
                        messageService: _messageService,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
