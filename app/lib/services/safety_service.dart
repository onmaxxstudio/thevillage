import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafetyService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user;
  }

  Future<Set<String>> blockedUserIds() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('blocked')
        .get();
    return snapshot.docs.map((document) => document.id).toSet();
  }

  Future<void> blockUser({
    required String uid,
    required String username,
  }) async {
    if (uid == _user.uid) return;
    await _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('blocked')
        .doc(uid)
        .set({
      'uid': uid,
      'username': username.replaceFirst('@', ''),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String uid) {
    return _firestore
        .collection('users')
        .doc(_user.uid)
        .collection('blocked')
        .doc(uid)
        .delete();
  }

  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? reportedUid,
    String details = '',
  }) {
    final reference = _firestore.collection('reports').doc();
    return reference.set({
      'reporterUid': _user.uid,
      'reportedUid': reportedUid ?? '',
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'details': details.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
