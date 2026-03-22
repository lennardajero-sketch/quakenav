import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef =
      FirebaseDatabase.instance.ref('users');
  final DatabaseReference _friendsRef =
      FirebaseDatabase.instance.ref('friends');
  final DatabaseReference _friendRequestsRef =
      FirebaseDatabase.instance.ref('friendRequests');
  final DatabaseReference _locationsRef =
      FirebaseDatabase.instance.ref('locations');

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> ensureCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await _ensureUserProfile(user);
  }

  Stream<String?> userBuildingStream(String uid) {
    return _usersRef.child(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        final direct = value['building']?.toString().trim();
        if (direct != null && direct.isNotEmpty) {
          return direct;
        }
        // Backward compatibility with older schemas.
        final legacyZone = value['zone']?.toString().trim();
        if (legacyZone != null && legacyZone.isNotEmpty) {
          return legacyZone;
        }
        final legacyName = value['buildingName']?.toString().trim();
        if (legacyName != null && legacyName.isNotEmpty) {
          return legacyName;
        }
      }
      return null;
    });
  }

  Stream<String?> userUsernameStream(String uid) {
    return _usersRef.child(uid).child('username').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        return null;
      }
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    });
  }

  Stream<String?> userProfileImageStream(String uid) {
    return _usersRef.child(uid).child('profileImageBase64').onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) {
        return null;
      }
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    });
  }

  Stream<String> userSafetyStatusStream(String uid) {
    return _usersRef.child(uid).child('safetyStatus').onValue.map((event) {
      final value = event.snapshot.value?.toString().trim().toLowerCase();
      if (value == null || value.isEmpty) {
        return 'unknown';
      }
      return value;
    });
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      await _ensureUserProfile(user);
    }
    return credential;
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String address,
    required String building,
    required String username,
    String? profileImageBase64,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid != null) {
      await _usersRef.child(uid).set({
        'name': name,
        'address': address,
        'building': building,
        'username': username.trim(),
        'usernameLower': username.trim().toLowerCase(),
        'email': email,
        'profileImageBase64': profileImageBase64 ?? '',
        'tourSeen': false,
        'safetyStatus': 'unknown',
        'createdAt': ServerValue.timestamp,
      });
    }
    return credential;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> updateCurrentUserBuilding(String building) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    await _usersRef.child(user.uid).update({
      'building': building.trim(),
    });
  }

  Future<void> updateCurrentUserFcmToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    await _usersRef.child(user.uid).update({
      'fcmToken': token.trim(),
      'fcmTokenUpdatedAt': ServerValue.timestamp,
    });
  }

  Future<void> updateCurrentUserProfileImage(String? profileImageBase64) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    await _usersRef.child(user.uid).update({
      'profileImageBase64': (profileImageBase64 ?? '').trim(),
      'profileImageUpdatedAt': ServerValue.timestamp,
    });
  }

  Future<void> updateCurrentUserUsername(String username) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw ArgumentError('Username is required.');
    }
    await _usersRef.child(user.uid).update({
      'username': normalized,
      'usernameLower': normalized.toLowerCase(),
      'usernameUpdatedAt': ServerValue.timestamp,
    });
  }

  Future<void> updateCurrentUserSafetyStatus(String status) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError('Safety status is required.');
    }
    await _usersRef.child(user.uid).update({
      'safetyStatus': normalized,
      'safetyStatusUpdatedAt': ServerValue.timestamp,
    });
  }

  Future<Map<String, String>> getCurrentUserAccountData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    final snapshot = await _usersRef.child(user.uid).get();
    if (snapshot.value is! Map) {
      return <String, String>{
        'name': '',
        'address': '',
        'username': _defaultUsernameFor(user.email),
        'building': '',
        'email': user.email ?? '',
      };
    }
    final data = Map<Object?, Object?>.from(snapshot.value as Map);
    return <String, String>{
      'name': (data['name'] ?? '').toString(),
      'address': (data['address'] ?? '').toString(),
      'username': (data['username'] ?? '').toString(),
      'building': (data['building'] ?? '').toString(),
      'email': (data['email'] ?? user.email ?? '').toString(),
    };
  }

  Future<void> updateCurrentUserAccount({
    required String name,
    required String address,
    required String username,
    required String building,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) {
      throw ArgumentError('Username is required.');
    }
    await _usersRef.child(user.uid).update({
      'name': name.trim(),
      'address': address.trim(),
      'username': cleanUsername,
      'usernameLower': cleanUsername.toLowerCase(),
      'building': building.trim(),
      'profileUpdatedAt': ServerValue.timestamp,
    });
  }

  Future<List<UserSearchResult>> searchUsersByUsername(String username) async {
    final current = _auth.currentUser;
    if (current == null) return const [];
    final query = username.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final snapshot = await _usersRef
        .orderByChild('usernameLower')
        .equalTo(query)
        .get();
    if (!snapshot.exists || snapshot.value is! Map) return const [];

    final map = Map<Object?, Object?>.from(snapshot.value as Map);
    final results = <UserSearchResult>[];
    map.forEach((key, value) {
      final uid = key.toString();
      if (uid == current.uid) return;
      if (value is Map) {
        final data = Map<Object?, Object?>.from(value);
        results.add(
          UserSearchResult(
            uid: uid,
            username: (data['username'] ?? '').toString(),
            name: (data['name'] ?? '').toString(),
            email: (data['email'] ?? '').toString(),
          ),
        );
      }
    });
    return results;
  }

  Future<void> sendFriendRequest(String targetUid) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw StateError('No signed-in user.');
    }
    if (targetUid == current.uid) {
      throw ArgumentError('Cannot add yourself.');
    }

    final alreadyFriend = await _friendsRef
        .child(current.uid)
        .child(targetUid)
        .get();
    if (alreadyFriend.exists) {
      throw StateError('Already connected.');
    }

    final meSnapshot = await _usersRef.child(current.uid).get();
    final meData = meSnapshot.value is Map
        ? Map<Object?, Object?>.from(meSnapshot.value as Map)
        : <Object?, Object?>{};

    await _friendRequestsRef.child(targetUid).child(current.uid).set({
      'fromUid': current.uid,
      'fromUsername': (meData['username'] ?? '').toString(),
      'fromName': (meData['name'] ?? '').toString(),
      'status': 'pending',
      'createdAt': ServerValue.timestamp,
    });
  }

  Stream<List<FriendRequestItem>> incomingFriendRequestsStream() {
    final current = _auth.currentUser;
    if (current == null) return Stream.value(const []);
    return _friendRequestsRef.child(current.uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return const <FriendRequestItem>[];
      final map = Map<Object?, Object?>.from(value);
      final requests = <FriendRequestItem>[];
      map.forEach((key, raw) {
        if (raw is! Map) return;
        final data = Map<Object?, Object?>.from(raw);
        if ((data['status'] ?? '').toString() != 'pending') return;
        requests.add(
          FriendRequestItem(
            fromUid: key.toString(),
            fromUsername: (data['fromUsername'] ?? '').toString(),
            fromName: (data['fromName'] ?? '').toString(),
          ),
        );
      });
      return requests;
    });
  }

  Future<void> acceptFriendRequest(String fromUid) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw StateError('No signed-in user.');
    }
    await _friendsRef.child(current.uid).child(fromUid).set(true);
    await _friendsRef.child(fromUid).child(current.uid).set(true);
    await _friendRequestsRef.child(current.uid).child(fromUid).remove();
  }

  Future<void> declineFriendRequest(String fromUid) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw StateError('No signed-in user.');
    }
    await _friendRequestsRef.child(current.uid).child(fromUid).remove();
  }

  Stream<List<FriendUser>> friendsStream() {
    final current = _auth.currentUser;
    if (current == null) return Stream.value(const []);
    return _friendsRef.child(current.uid).onValue.asyncMap((event) async {
      final value = event.snapshot.value;
      if (value is! Map) return const <FriendUser>[];

      final ids = value.keys.map((e) => e.toString()).toList();
      if (ids.isEmpty) return const <FriendUser>[];

      final users = <FriendUser>[];
      for (final uid in ids) {
        final userSnap = await _usersRef.child(uid).get();
        if (!userSnap.exists || userSnap.value is! Map) continue;
        final data = Map<Object?, Object?>.from(userSnap.value as Map);
        users.add(
          FriendUser(
            uid: uid,
            username: (data['username'] ?? '').toString(),
            name: (data['name'] ?? '').toString(),
            profileImageBase64: (data['profileImageBase64'] ?? '').toString(),
            safetyStatus: (data['safetyStatus'] ?? 'unknown').toString(),
          ),
        );
      }
      return users;
    });
  }

  Stream<Map<String, FriendLocation>> allLocationsStream() {
    return _locationsRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return <String, FriendLocation>{};
      }
      final root = Map<Object?, Object?>.from(value);
      final result = <String, FriendLocation>{};
      root.forEach((key, raw) {
        if (raw is! Map) return;
        final data = Map<Object?, Object?>.from(raw);
        final lat = double.tryParse((data['lat'] ?? '').toString());
        final lng = double.tryParse((data['lng'] ?? '').toString());
        if (lat == null || lng == null) return;
        final heading = double.tryParse((data['heading'] ?? '').toString());
        final updatedAt = int.tryParse((data['updatedAt'] ?? '').toString());
        result[key.toString()] = FriendLocation(
          lat: lat,
          lng: lng,
          heading: heading,
          updatedAtMs: updatedAt,
        );
      });
      return result;
    });
  }

  Future<void> updateCurrentUserLocation({
    required double lat,
    required double lng,
    double? heading,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await _locationsRef.child(user.uid).update({
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> removeFriend(String friendUid) async {
    final current = _auth.currentUser;
    if (current == null) {
      throw StateError('No signed-in user.');
    }
    await _friendsRef.child(current.uid).child(friendUid).remove();
    await _friendsRef.child(friendUid).child(current.uid).remove();
  }

  Stream<bool> userTourSeenStream(String uid) {
    return _usersRef.child(uid).child('tourSeen').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is bool) {
        return value;
      }
      if (value is String) {
        return value.toLowerCase() == 'true';
      }
      return false;
    });
  }

  Future<void> markCurrentUserTourSeen() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user.');
    }
    await _usersRef.child(user.uid).update({
      'tourSeen': true,
      'tourSeenAt': ServerValue.timestamp,
    });
  }

  Future<void> _ensureUserProfile(User user) async {
    final profileRef = _usersRef.child(user.uid);
    final snapshot = await profileRef.get();
    if (snapshot.value is Map) {
      final data = Map<Object?, Object?>.from(snapshot.value as Map);
      final updates = <String, Object?>{};

      final email = data['email']?.toString().trim();
      if (email == null || email.isEmpty) {
        updates['email'] = user.email ?? '';
      }

      final name = data['name']?.toString().trim();
      if (name == null || name.isEmpty) {
        updates['name'] = user.displayName ?? '';
      }
      final username = data['username']?.toString().trim();
      if (username == null || username.isEmpty) {
        final suggested = _defaultUsernameFor(user.email);
        updates['username'] = suggested;
        updates['usernameLower'] = suggested.toLowerCase();
      } else if (!data.containsKey('usernameLower')) {
        updates['usernameLower'] = username.toLowerCase();
      }

      if (!data.containsKey('address')) {
        updates['address'] = '';
      }
      if (!data.containsKey('building')) {
        updates['building'] = '';
      }
      if (!data.containsKey('createdAt')) {
        updates['createdAt'] = ServerValue.timestamp;
      }
      if (!data.containsKey('profileImageBase64')) {
        updates['profileImageBase64'] = '';
      }
      if (!data.containsKey('tourSeen')) {
        updates['tourSeen'] = false;
      }
      if (!data.containsKey('safetyStatus')) {
        updates['safetyStatus'] = 'unknown';
      }

      if (updates.isNotEmpty) {
        await profileRef.update(updates);
      }
      return;
    }

    await profileRef.set({
      'name': user.displayName ?? '',
      'address': '',
      'building': '',
      'username': _defaultUsernameFor(user.email),
      'usernameLower': _defaultUsernameFor(user.email).toLowerCase(),
      'email': user.email ?? '',
      'profileImageBase64': '',
      'createdAt': ServerValue.timestamp,
      'tourSeen': false,
      'safetyStatus': 'unknown',
    });
  }

  String _defaultUsernameFor(String? email) {
    final value = (email ?? '').trim();
    if (value.isEmpty) {
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
    final local = value.split('@').first.trim();
    return local.isEmpty ? 'user_${DateTime.now().millisecondsSinceEpoch}' : local;
  }
}

class UserSearchResult {
  final String uid;
  final String username;
  final String name;
  final String email;

  const UserSearchResult({
    required this.uid,
    required this.username,
    required this.name,
    required this.email,
  });
}

class FriendRequestItem {
  final String fromUid;
  final String fromUsername;
  final String fromName;

  const FriendRequestItem({
    required this.fromUid,
    required this.fromUsername,
    required this.fromName,
  });
}

class FriendUser {
  final String uid;
  final String username;
  final String name;
  final String profileImageBase64;
  final String safetyStatus;

  const FriendUser({
    required this.uid,
    required this.username,
    required this.name,
    required this.profileImageBase64,
    required this.safetyStatus,
  });
}

class FriendLocation {
  final double lat;
  final double lng;
  final double? heading;
  final int? updatedAtMs;

  const FriendLocation({
    required this.lat,
    required this.lng,
    required this.heading,
    required this.updatedAtMs,
  });
}
