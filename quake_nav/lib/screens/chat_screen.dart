import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final String myUid;
  final ChatThread thread;
  final MessageService messageService;

  const ChatScreen({
    super.key,
    required this.myUid,
    required this.thread,
    required this.messageService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await widget.messageService.sendMessage(
      chatId: widget.thread.chatId,
      senderUid: widget.myUid,
      text: text,
    );
  }

  String _title() {
    if (widget.thread.username.isNotEmpty) {
      return '@${widget.thread.username}';
    }
    if (widget.thread.name.isNotEmpty) {
      return widget.thread.name;
    }
    return 'Chat';
  }

  @override
  Widget build(BuildContext context) {
    final avatar = widget.thread.profileImageBase64;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: avatar.isNotEmpty
                  ? MemoryImage(base64Decode(avatar))
                  : null,
              child: avatar.isEmpty ? const Icon(Icons.person, size: 16) : null,
            ),
            const SizedBox(width: 10),
            Text(_title()),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.messageService.chatMessagesStream(widget.thread.chatId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <ChatMessage>[];
                widget.messageService
                    .markChatSeen(chatId: widget.thread.chatId, myUid: widget.myUid);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final mine = msg.senderUid == widget.myUid;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFF0095F6)
                              : Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2D33)
                                  : const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: mine ? Colors.white : null,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1F2228)
                            : const Color(0xFFF2F3F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
