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

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user;
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) =>
      _firestore.collection('users').doc(uid);

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
    final compact =
        displayName.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '').substring(
              0,
              displayName
                  .replaceAll(RegExp(r'[^A-Za-z0-9_]'), '')
                  .length
                  .clamp(0, 20),
            );
    if (_isValidUsername(compact)) return compact;
    return 'member_${user.uid.substring(0, 6)}';
  }

  Future<void> ensureCurrentUserProfile({String? preferredUsername}) async {
    final user = _user;
    final requested = _cleanUsername(preferredUsername ?? '');
    final fallback = _fallbackUsername(user);
    final desired = _isValidUsername(requested) ? requested : fallback;

    if (Firebase.apps.isEmpty) {
      usernameNotifier.value = desired;
      return;
    }

    try {
      final userReference = _userDocument(user.uid);
      final existing = await userReference.get();
      if (existing.exists) {
        final saved = existing.data()?['username'] as String?;
        if (saved != null && saved.isNotEmpty) {
          usernameNotifier.value = saved;
          if (user.displayName != saved) await user.updateDisplayName(saved);
          return;
        }
      }

      await _claimUsername(user: user, username: desired);
    } on FirebaseException {
      // Authentication remains usable while Firestore rules are being deployed.
      usernameNotifier.value =
          _cleanUsername(user.displayName ?? '').isNotEmpty
              ? _cleanUsername(user.displayName ?? '')
              : desired;
    }
  }

  Future<void> _claimUsername({
    required User user,
    required String username,
  }) async {
    final lower = username.toLowerCase();
    final userReference = _userDocument(user.uid);
    final newUsernameReference = _usernameDocument(lower);

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
        throw const ProfileValidationException(
          'That username is already taken. Try another one.',
        );
      }

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
    });

    if (user.displayName != username) await user.updateDisplayName(username);
    usernameNotifier.value = username;
  }

  static Future<String?> currentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    if (Firebase.apps.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final saved = snapshot.data()?['username'] as String?;
        if (saved != null && saved.trim().isNotEmpty) {
          usernameNotifier.value = saved.trim();
          return saved.trim();
        }
      } on FirebaseException {
        // Fall back to the authenticated profile until Firestore is available.
      }
    }

    final username = _cleanUsername(user.displayName ?? '');
    final resolved = username.isEmpty ? null : username;
    usernameNotifier.value = resolved;
    return resolved;
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
          .collection('users')
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

    try {
      await _claimUsername(user: _user, username: username);
    } on ProfileValidationException {
      rethrow;
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied' ||
          error.code == 'unavailable' ||
          error.code == 'failed-precondition') {
        await _user.updateDisplayName(username);
        await _user.reload();
        usernameNotifier.value = username;
        return;
      }
      rethrow;
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

  String get _blockedKey => 'blocked_accounts_${_user.uid}';

  Future<List<BlockedAccount>> blockedAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_blockedKey) ?? const <String>[];
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

  Future<void> unblock(String blockedUserId) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_blockedKey) ?? <String>[];
    saved.removeWhere(
      (entry) => entry == blockedUserId || entry.startsWith('$blockedUserId|'),
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
