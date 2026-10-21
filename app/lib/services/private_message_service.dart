import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class PrivateConversation {
  const PrivateConversation({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String get otherUid {
    final participants = List<String>.from(data['participantUids'] ?? const []);
    return participants.firstWhere(
      (uid) => uid != FirebaseAuth.instance.currentUser?.uid,
      orElse: () => '',
    );
  }

  String get sourceType => data['sourceType'] as String? ?? 'village';
  String get communityId => data['communityId'] as String? ?? '';
  String get communityName => data['communityName'] as String? ?? '';
  String get lastMessage => data['lastMessage'] as String? ?? '';
  String get lastSenderUid => data['lastSenderUid'] as String? ?? '';
  bool get unreadForMe => List<String>.from(data['unreadFor'] ?? const [])
      .contains(FirebaseAuth.instance.currentUser?.uid);
  DateTime get updatedAt {
    final value = data['updatedAt'];
    return value is Timestamp ? value.toDate() : DateTime.now();
  }
}

class PrivateChatMessage {
  const PrivateChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;

  factory PrivateChatMessage.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final raw = data['createdAt'];
    return PrivateChatMessage(
      id: document.id,
      senderUid: data['senderUid'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt: raw is Timestamp ? raw.toDate() : DateTime.now(),
    );
  }
}

class PrivateMessageService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to use private messages.');
    return user;
  }

  bool get isAvailable => Firebase.apps.isNotEmpty && _auth.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('private_conversations');

  Stream<List<PrivateConversation>> watchConversations() {
    final uid = _user.uid;
    return _conversations
        .where('participantUids', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map((doc) => PrivateConversation(id: doc.id, data: doc.data()))
              .toList();
          conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return conversations;
        });
  }

  Future<String> openOrCreate({
    required String otherUid,
    required String sourceType,
    required String sourcePostId,
    required String sourcePostExcerpt,
    String communityId = '',
    String communityName = '',
    String commentExcerpt = '',
  }) async {
    final current = _user;
    if (otherUid.isEmpty || otherUid == current.uid) {
      throw StateError('This member cannot be messaged.');
    }
    if (sourceType != 'village' && sourceType != 'community') {
      throw ArgumentError.value(sourceType, 'sourceType');
    }
    final existing = await _conversations
        .where('participantUids', arrayContains: current.uid)
        .get();
    final match = existing.docs.where((doc) {
      final data = doc.data();
      final participants = List<String>.from(data['participantUids'] ?? const []);
      return participants.contains(otherUid) &&
          (data['sourceKey'] == (sourceType == 'community' ? communityId : 'village'));
    });
    if (match.isNotEmpty) return match.first.id;

    final reference = _conversations.doc();
    final participants = [current.uid, otherUid]..sort();
    await reference.set({
      'participantUids': participants,
      'sourceKey': sourceType == 'community' ? communityId : 'village',
      'sourceType': sourceType,
      'communityId': sourceType == 'community' ? communityId : '',
      'communityName': sourceType == 'community' ? communityName : '',
      'sourcePostId': sourcePostId,
      'sourcePostExcerpt': sourcePostExcerpt.trim(),
      'contextExcerpt': commentExcerpt.trim(),
      'lastMessage': '',
      'lastSenderUid': current.uid,
      'unreadFor': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reference.id;
  }

  Stream<List<PrivateChatMessage>> watchMessages(String conversationId) =>
      _conversations
          .doc(conversationId)
          .collection('messages')
          .orderBy('createdAt')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map(PrivateChatMessage.fromDocument)
              .toList());

  Future<void> send(String conversationId, String text) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 2000) return;
    final user = _user;
    final conversation = _conversations.doc(conversationId);
    final conversationSnapshot = await conversation.get();
    final participants = List<String>.from(
      conversationSnapshot.data()?['participantUids'] ?? const [],
    );
    if (!participants.contains(user.uid) || participants.length != 2) {
      throw StateError('You are not a member of this private chat.');
    }
    final recipientUid = participants.firstWhere((uid) => uid != user.uid);
    final message = conversation.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(message, {
      'senderUid': user.uid,
      'text': value,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(conversation, {
      'lastMessage': value,
      'lastSenderUid': user.uid,
      'unreadFor': [recipientUid],
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> markRead(String conversationId) async {
    final uid = _user.uid;
    final conversation = _conversations.doc(conversationId);
    final snapshot = await conversation.get();
    final unreadFor = List<String>.from(snapshot.data()?['unreadFor'] ?? const []);
    if (unreadFor.contains(uid)) {
      try {
        await conversation.update({'unreadFor': <String>[]});
      } on FirebaseException {
        // Another open client may have cleared the unread marker first.
      }
    }
  }
}
