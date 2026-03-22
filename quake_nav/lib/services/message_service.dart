import 'package:firebase_database/firebase_database.dart';

class MessageService {
  final DatabaseReference _root = FirebaseDatabase.instance.ref();

  DatabaseReference get _usersRef => _root.child('users');
  DatabaseReference get _chatsRef => _root.child('chats');
  DatabaseReference get _userChatsRef => _root.child('userChats');

  String directChatId(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return 'dm_${ids[0]}_${ids[1]}';
  }

  Future<String> ensureDirectChat({
    required String myUid,
    required String otherUid,
  }) async {
    final chatId = directChatId(myUid, otherUid);
    await _chatsRef.child(chatId).child('participants').update({
      myUid: true,
      otherUid: true,
    });
    await _userChatsRef.child(myUid).child(chatId).set(true);
    await _userChatsRef.child(otherUid).child(chatId).set(true);
    return chatId;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderUid,
    required String text,
  }) async {
    final body = text.trim();
    if (body.isEmpty) {
      return;
    }
    final messageRef = _chatsRef.child(chatId).child('messages').push();
    await messageRef.set({
      'senderUid': senderUid,
      'text': body,
      'sentAt': ServerValue.timestamp,
      'readBy': {senderUid: true},
    });
    await _chatsRef.child(chatId).child('lastMessage').set({
      'text': body,
      'senderUid': senderUid,
      'sentAt': ServerValue.timestamp,
    });
  }

  Stream<List<ChatMessage>> chatMessagesStream(String chatId) {
    return _chatsRef.child(chatId).child('messages').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return <ChatMessage>[];
      }
      final map = Map<Object?, Object?>.from(value);
      final list = <ChatMessage>[];
      map.forEach((key, raw) {
        if (raw is! Map) {
          return;
        }
        final data = Map<Object?, Object?>.from(raw);
        final readByRaw = data['readBy'];
        final readBy = <String>{};
        if (readByRaw is Map) {
          final rb = Map<Object?, Object?>.from(readByRaw);
          for (final entry in rb.entries) {
            if (entry.value == true) {
              readBy.add(entry.key.toString());
            }
          }
        }
        list.add(
          ChatMessage(
            id: key.toString(),
            senderUid: (data['senderUid'] ?? '').toString(),
            text: (data['text'] ?? '').toString(),
            sentAtMs: int.tryParse((data['sentAt'] ?? '').toString()),
            readBy: readBy,
          ),
        );
      });
      list.sort((a, b) => (a.sentAtMs ?? 0).compareTo(b.sentAtMs ?? 0));
      return list;
    });
  }

  Future<void> markChatSeen({
    required String chatId,
    required String myUid,
  }) async {
    final snapshot = await _chatsRef.child(chatId).child('messages').get();
    final value = snapshot.value;
    if (value is! Map) {
      return;
    }
    final map = Map<Object?, Object?>.from(value);
    final updates = <String, Object?>{};
    map.forEach((key, raw) {
      if (raw is! Map) {
        return;
      }
      final data = Map<Object?, Object?>.from(raw);
      if ((data['senderUid'] ?? '').toString() == myUid) {
        return;
      }
      final readByRaw = data['readBy'];
      final alreadySeen = readByRaw is Map &&
          Map<Object?, Object?>.from(readByRaw)[myUid] == true;
      if (!alreadySeen) {
        updates['$key/readBy/$myUid'] = true;
      }
    });
    if (updates.isNotEmpty) {
      await _chatsRef.child(chatId).child('messages').update(updates);
    }
  }

  Stream<List<ChatThread>> userThreadsStream(String myUid) {
    return _userChatsRef.child(myUid).onValue.asyncMap((event) async {
      final value = event.snapshot.value;
      if (value is! Map) {
        return <ChatThread>[];
      }
      final map = Map<Object?, Object?>.from(value);
      final threads = <ChatThread>[];

      for (final key in map.keys) {
        final chatId = key.toString();
        final chatSnapshot = await _chatsRef.child(chatId).get();
        if (!chatSnapshot.exists || chatSnapshot.value is! Map) {
          continue;
        }
        final chatData = Map<Object?, Object?>.from(chatSnapshot.value as Map);
        final participantsRaw = chatData['participants'];
        if (participantsRaw is! Map) {
          continue;
        }
        final participantsMap = Map<Object?, Object?>.from(participantsRaw);
        final participants = participantsMap.keys.map((e) => e.toString()).toList();
        final otherUid = participants.firstWhere(
          (uid) => uid != myUid,
          orElse: () => '',
        );
        if (otherUid.isEmpty) {
          continue;
        }
        final userSnapshot = await _usersRef.child(otherUid).get();
        String username = '';
        String name = '';
        String profileImageBase64 = '';
        if (userSnapshot.exists && userSnapshot.value is Map) {
          final userData = Map<Object?, Object?>.from(userSnapshot.value as Map);
          username = (userData['username'] ?? '').toString();
          name = (userData['name'] ?? '').toString();
          profileImageBase64 = (userData['profileImageBase64'] ?? '').toString();
        }

        String lastText = '';
        int? lastSentAt;
        String lastSenderUid = '';
        final lastRaw = chatData['lastMessage'];
        if (lastRaw is Map) {
          final last = Map<Object?, Object?>.from(lastRaw);
          lastText = (last['text'] ?? '').toString();
          lastSentAt = int.tryParse((last['sentAt'] ?? '').toString());
          lastSenderUid = (last['senderUid'] ?? '').toString();
        }

        var unreadCount = 0;
        final messagesRaw = chatData['messages'];
        if (messagesRaw is Map) {
          final messagesMap = Map<Object?, Object?>.from(messagesRaw);
          for (final raw in messagesMap.values) {
            if (raw is! Map) continue;
            final msg = Map<Object?, Object?>.from(raw);
            final senderUid = (msg['senderUid'] ?? '').toString();
            if (senderUid == myUid) continue;
            final readByRaw = msg['readBy'];
            final seen = readByRaw is Map &&
                Map<Object?, Object?>.from(readByRaw)[myUid] == true;
            if (!seen) unreadCount++;
          }
        }

        threads.add(
          ChatThread(
            chatId: chatId,
            otherUid: otherUid,
            username: username,
            name: name,
            profileImageBase64: profileImageBase64,
            lastText: lastText,
            lastSentAtMs: lastSentAt,
            lastSenderUid: lastSenderUid,
            unreadCount: unreadCount,
          ),
        );
      }

      threads.sort((a, b) => (b.lastSentAtMs ?? 0).compareTo(a.lastSentAtMs ?? 0));
      return threads;
    });
  }
}

class ChatThread {
  final String chatId;
  final String otherUid;
  final String username;
  final String name;
  final String profileImageBase64;
  final String lastText;
  final int? lastSentAtMs;
  final String lastSenderUid;
  final int unreadCount;

  const ChatThread({
    required this.chatId,
    required this.otherUid,
    required this.username,
    required this.name,
    required this.profileImageBase64,
    required this.lastText,
    required this.lastSentAtMs,
    required this.lastSenderUid,
    required this.unreadCount,
  });
}

class ChatMessage {
  final String id;
  final String senderUid;
  final String text;
  final int? sentAtMs;
  final Set<String> readBy;

  const ChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.sentAtMs,
    required this.readBy,
  });
}
