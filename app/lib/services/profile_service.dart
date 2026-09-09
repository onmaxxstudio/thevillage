import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VillageProfile {
  const VillageProfile({
    required this.uid,
    required this.username,
    required this.email,
  });

  final String uid;
  final String username;
  final String email;
}

class UsernameLookup {
  const UsernameLookup({
    required this.uid,
    required this.username,
    required this.email,
  });

  final String uid;
  final String username;
  final String email;

  dynamic operator [](String key) {
    return switch (key) {
      'uid' => uid,
      'username' => username,
      'email' => email,
      _ => null,
    };
  }

  @override
  String toString() => username;
}

class BlockedAccount {
  const BlockedAccount({required this.uid, required this.username});

  final String uid;
  final String username;
}

class ProfileService {
  static final ValueNotifier<String?> usernameNotifier =
      ValueNotifier<String?>(null);

  static String _localUsernameKey(String uid) => 'profile_username_$uid';

  static Future<String?> _localUsername(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final username = _cleanUsername(
      preferences.getString(_localUsernameKey(uid)) ?? '',
    );
    return _isValidUsername(username) ? username : null;
  }

  static Future<void> _saveLocalUsername(String uid, String username) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localUsernameKey(uid), username);
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user;
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) =>
      _firestore.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _publicProfileDocument(String uid) =>
      _firestore.collection('public_profiles').doc(uid);

  DocumentReference<Map<String, dynamic>> _usernameDocument(String username) =>
      _firestore.collection('usernames').doc(username.toLowerCase());

  static String _cleanUsername(String value) {
    return value.trim().replaceFirst(RegExp(r'^@+'), '');
  }

  static bool _isValidUsername(String value) {
    return RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(value);
  }

  static String _fallbackUsername(User user) {
    final displayName = _cleanUsername(user.displayName ?? '');
    final sanitized =
        displayName.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');
    final compact =
        sanitized.length > 20 ? sanitized.substring(0, 20) : sanitized;
    if (_isValidUsername(compact)) return compact;
    return 'member_${user.uid.substring(0, 6)}';
  }

  Future<void> ensureCurrentUserProfile({String? preferredUsername}) async {
    final user = _user;
    final requested = _cleanUsername(preferredUsername ?? '');
    final local = await _localUsername(user.uid);
    final fallback = _fallbackUsername(user);
    final desired = _isValidUsername(requested)
        ? requested
        : local ?? fallback;

    if (Firebase.apps.isEmpty) {
      await _saveLocalUsername(user.uid, desired);
      usernameNotifier.value = desired;
      return;
    }

    try {
      // A username saved on this device is newer than an older Firestore or
      // Firebase Auth display name. Keep it visible while cloud sync retries.
      if (local != null && !_isValidUsername(requested)) {
        usernameNotifier.value = local;
        await _claimUsername(user: user, username: local);
        return;
      }

      final userReference = _userDocument(user.uid);
      final existing = await userReference.get();
      if (existing.exists) {
        final saved = existing.data()?['username'] as String?;
        if (saved != null && saved.isNotEmpty) {
          await _saveLocalUsername(user.uid, saved);
          usernameNotifier.value = saved;
          try {
            if (user.displayName != saved) await user.updateDisplayName(saved);
          } on Object {
            // Firestore remains the source of truth if Auth profile sync fails.
          }
          return;
        }
      }

      await _claimUsername(user: user, username: desired);
    } on Object {
      // Authentication remains usable while Firestore rules are being deployed.
      await _saveLocalUsername(user.uid, desired);
      usernameNotifier.value = desired;
    }
  }

  Future<void> _claimUsername({
    required User user,
    required String username,
  }) async {
    final lower = username.toLowerCase();
    final userReference = _userDocument(user.uid);
    final newUsernameReference = _usernameDocument(lower);
    String? conflictingUid;

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userReference);
      final oldLower = userSnapshot.data()?['usernameLower'] as String?;
      final newClaim = await transaction.get(newUsernameReference);
      DocumentSnapshot<Map<String, dynamic>>? oldClaim;

      if (oldLower != null && oldLower != lower) {
        oldClaim = await transaction.get(_usernameDocument(oldLower));
      }

      final claimedUid = newClaim.data()?['uid'] as String?;
      if (newClaim.exists && claimedUid != user.uid) {
        // Do not throw a custom Dart exception inside a Firestore web
        // transaction. Safari boxes it as an unreadable converted Future.
        conflictingUid = claimedUid ?? 'unknown';
        return;
      }
      conflictingUid = null;

      transaction.set(newUsernameReference, {
        'uid': user.uid,
        'username': username,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!newClaim.exists) 'createdAt': FieldValue.serverTimestamp(),
      });

      if (oldClaim != null &&
          oldClaim.exists &&
          oldClaim.data()?['uid'] == user.uid) {
        transaction.delete(_usernameDocument(oldLower!));
      }

      transaction.set(
        userReference,
        {
          'uid': user.uid,
          'username': username,
          'usernameLower': lower,
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
          if (!userSnapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        _publicProfileDocument(user.uid),
        {
          'uid': user.uid,
          'username': username,
          'usernameLower': lower,
          'photoUrl': user.photoURL ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    if (conflictingUid != null) {
      throw const ProfileValidationException(
        'That username is already taken. Try another one.',
      );
    }

    await _saveLocalUsername(user.uid, username);
    usernameNotifier.value = username;
    try {
      if (user.displayName != username) await user.updateDisplayName(username);
    } on Object {
      // The public profile and local cache already contain the new username.
    }
  }

  static Future<String?> currentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final local = await _localUsername(user.uid);
    if (local != null) {
      usernameNotifier.value = local;
      return local;
    }

    if (Firebase.apps.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final saved = snapshot.data()?['username'] as String?;
        if (saved != null && saved.trim().isNotEmpty) {
          await _saveLocalUsername(user.uid, saved.trim());
          usernameNotifier.value = saved.trim();
          return saved.trim();
        }
      } on FirebaseException {
        // Fall back to the authenticated profile until Firestore is available.
      }
    }

    final username = _cleanUsername(user.displayName ?? '');
    final resolved = username.isEmpty ? null : username;
    if (resolved != null) await _saveLocalUsername(user.uid, resolved);
    usernameNotifier.value = resolved;
    return resolved;
  }

  static Future<String?> publicUsername(String? uid) async {
    if (uid == null || uid.isEmpty || Firebase.apps.isEmpty) return null;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (uid == currentUser?.uid) return currentUsername();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('public_profiles')
          .doc(uid)
          .get();
      final username = snapshot.data()?['username'] as String?;
      return username == null || username.trim().isEmpty
          ? null
          : username.trim();
    } on FirebaseException {
      return null;
    }
  }

  static Future<UsernameLookup?> findUsername(String value) async {
    final query = _cleanUsername(value).toLowerCase();
    if (query.isEmpty || Firebase.apps.isEmpty) return null;

    try {
      final claim = await FirebaseFirestore.instance
          .collection('usernames')
          .doc(query)
          .get();
      final uid = claim.data()?['uid'] as String?;
      if (uid == null || uid.isEmpty) return null;

      final profile = await FirebaseFirestore.instance
          .collection('public_profiles')
          .doc(uid)
          .get();
      final data = profile.data();
      if (data == null) return null;
      return UsernameLookup(
        uid: uid,
        username: data['username'] as String? ??
            claim.data()?['username'] as String? ??
            value,
        email: '',
      );
    } on FirebaseException {
      return null;
    }
  }

  Future<VillageProfile> loadProfile() async {
    final user = _user;
    await ensureCurrentUserProfile();
    await user.reload();
    final refreshedUser = _auth.currentUser ?? user;
    final username =
        await currentUsername() ?? _fallbackUsername(refreshedUser);
    return VillageProfile(
      uid: refreshedUser.uid,
      username: username,
      email: refreshedUser.email ?? '',
    );
  }

  Future<void> updateUsername(String value) async {
    final username = _cleanUsername(value);
    if (!_isValidUsername(username)) {
      throw const ProfileValidationException(
        'Use 3–20 letters, numbers, or underscores.',
      );
    }

    final user = _user;
    try {
      await _claimUsername(user: user, username: username);
    } on ProfileValidationException {
      rethrow;
    } on Object {
      // Keep the username working throughout the app when Firestore is
      // temporarily unavailable or its rules have not finished deploying.
      await _saveLocalUsername(user.uid, username);
      usernameNotifier.value = username;
      try {
        if (user.displayName != username) {
          await user.updateDisplayName(username);
        }
      } on Object {
        // Local state is enough to update every current-user surface.
      }
    }
  }

  Future<void> requestEmailChange(String newEmail) async {
    final email = newEmail.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      throw const ProfileValidationException('Enter a valid email address.');
    }
    await _user.verifyBeforeUpdateEmail(email);
  }

  Future<void> sendPasswordReset() async {
    final email = _user.email;
    if (email == null || email.isEmpty) {
      throw const ProfileValidationException(
        'This account does not use an email password.',
      );
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<String> exportMyData() async {
    final user = _user;
    final payload = <String, Object?>{
      'exportedAt': DateTime.now().toIso8601String(),
      'account': {
        'uid': user.uid,
        'email': user.email ?? '',
        'username': await currentUsername() ?? '',
      },
    };
    if (Firebase.apps.isNotEmpty) {
      try {
        final results = await Future.wait([
          _userDocument(user.uid)
              .collection('blocked')
              .limit(500)
              .get(),
          _firestore
              .collection('circles')
              .doc(user.uid)
              .collection('members')
              .limit(500)
              .get(),
          _firestore
              .collection('notifications')
              .doc(user.uid)
              .collection('items')
              .orderBy('createdAt', descending: true)
              .limit(500)
              .get(),
          _firestore
              .collection('check_ins')
              .doc(user.uid)
              .collection('items')
              .orderBy('createdAt', descending: true)
              .limit(500)
              .get(),
          _firestore
              .collection('village_post_owners')
              .where('uid', isEqualTo: user.uid)
              .limit(500)
              .get(),
        ]);
        List<Map<String, Object?>> documents(
          QuerySnapshot<Map<String, dynamic>> snapshot,
        ) => snapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data().map(
            (key, value) => MapEntry(key, _exportValue(value)),
          ),
        }).toList();

        payload['blockedAccounts'] = documents(results[0]);
        payload['circleMembers'] = documents(results[1]);
        payload['notifications'] = documents(results[2]);
        payload['checkIns'] = documents(results[3]);
        final ownerDocs = results[4].docs;
        final posts = await Future.wait(ownerDocs.map((owner) async {
          final post = await _firestore
              .collection('village_posts')
              .doc(owner.id)
              .get();
          return post.exists
              ? {'id': post.id, ...post.data()!.map(
                  (key, value) => MapEntry(key, _exportValue(value)),
                )}
              : <String, Object?>{};
        }));
        payload['posts'] = posts.where((post) => post.isNotEmpty).toList();
      } on Object {
        payload['notice'] =
            'Some cloud information was unavailable when this copy was made.';
      }
    }
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  static Object? _exportValue(Object? value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is Iterable) return value.map(_exportValue).toList();
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _exportValue(item)),
      );
    }
    return value;
  }

  String get _blockedKey => 'blocked_accounts_${_user.uid}';

  Future<List<BlockedAccount>> blockedAccounts() async {
    try {
      final snapshot = await _userDocument(_user.uid)
          .collection('blocked')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((document) {
        final data = document.data();
        return BlockedAccount(
          uid: document.id,
          username: data['username'] as String? ?? 'Village member',
        );
      }).toList();
    } on FirebaseException {
      final preferences = await SharedPreferences.getInstance();
      final saved =
          preferences.getStringList(_blockedKey) ?? const <String>[];
      return saved.map((entry) {
        final separator = entry.indexOf('|');
        if (separator == -1) {
          return BlockedAccount(uid: entry, username: 'Village member');
        }
        return BlockedAccount(
          uid: entry.substring(0, separator),
          username: entry.substring(separator + 1),
        );
      }).toList();
    }
  }

  Future<void> unblock(String blockedUserId) async {
    try {
      await _userDocument(_user.uid)
          .collection('blocked')
          .doc(blockedUserId)
          .delete();
    } on FirebaseException {
      // Also remove the cached copy below.
    }
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_blockedKey) ?? <String>[];
    saved.removeWhere(
      (entry) =>
          entry == blockedUserId || entry.startsWith('$blockedUserId|'),
    );
    await preferences.setStringList(_blockedKey, saved);
  }

  Future<void> deleteAccount() async {
    final user = _user;
    try {
      final profile = await _userDocument(user.uid).get();
      final lower = profile.data()?['usernameLower'] as String?;
      final batch = _firestore.batch();
      batch.delete(_userDocument(user.uid));
      batch.delete(_publicProfileDocument(user.uid));
      if (lower != null) batch.delete(_usernameDocument(lower));
      await batch.commit();
    } on FirebaseException {
      // The authentication account can still be deleted if profile cleanup fails.
    }
    await user.delete();
  }
}

class ProfileValidationException implements Exception {
  const ProfileValidationException(this.message);
  final String message;
}
import 'dart:convert';
