import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class ProfileService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user;
  }

  Future<VillageProfile> loadProfile() async {
    final user = _user;
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final savedUsername = snapshot.data()?['username'] as String?;
    return VillageProfile(
      uid: user.uid,
      username: savedUsername?.trim().isNotEmpty == true
          ? savedUsername!.trim()
          : (user.displayName?.trim() ?? ''),
      email: user.email ?? '',
    );
  }

  Future<void> updateUsername(String value) async {
    final username = value.trim();
    final usernameLower = username.toLowerCase();
    if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(username)) {
      throw const ProfileValidationException(
        'Use 3–20 letters, numbers, or underscores.',
      );
    }

    final user = _user;
    final userRef = _firestore.collection('users').doc(user.uid);
    final newUsernameRef =
        _firestore.collection('usernames').doc(usernameLower);

    await _firestore.runTransaction<void>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final oldUsernameLower =
          userSnapshot.data()?['usernameLower'] as String?;
      final newUsernameSnapshot = await transaction.get(newUsernameRef);

      DocumentSnapshot<Map<String, dynamic>>? oldUsernameSnapshot;
      DocumentReference<Map<String, dynamic>>? oldUsernameRef;
      if (oldUsernameLower != null &&
          oldUsernameLower.isNotEmpty &&
          oldUsernameLower != usernameLower) {
        oldUsernameRef =
            _firestore.collection('usernames').doc(oldUsernameLower);
        oldUsernameSnapshot = await transaction.get(oldUsernameRef);
      }

      if (newUsernameSnapshot.exists &&
          newUsernameSnapshot.data()?['uid'] != user.uid) {
        throw const UsernameTakenException();
      }

      transaction.set(newUsernameRef, {
        'uid': user.uid,
        'username': username,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (oldUsernameRef != null &&
          oldUsernameSnapshot?.data()?['uid'] == user.uid) {
        transaction.delete(oldUsernameRef);
      }

      transaction.set(
        userRef,
        {
          'username': username,
          'usernameLower': usernameLower,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!userSnapshot.exists)
            'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await user.updateDisplayName(username);
    await user.reload();
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

  Stream<QuerySnapshot<Map<String, dynamic>>> blockedAccounts() {
    return _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('blocked')
        .orderBy('username')
        .snapshots();
  }

  Future<void> unblock(String blockedUserId) {
    return _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('blocked')
        .doc(blockedUserId)
        .delete();
  }

  Future<void> deleteAccount() => _user.delete();
}

class UsernameTakenException implements Exception {
  const UsernameTakenException();
}

class ProfileValidationException implements Exception {
  const ProfileValidationException(this.message);
  final String message;
}
