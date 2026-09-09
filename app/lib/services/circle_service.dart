import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_service.dart';

class CirclePerson {
  const CirclePerson({
    required this.uid,
    required this.username,
    this.photoUrl = '',
    this.status = '',
  });

  final String uid;
  final String username;
  final String photoUrl;
  final String status;

  factory CirclePerson.fromJson(Map<String, dynamic> json) {
    return CirclePerson(
      uid: json['uid'] as String? ?? '',
      username: json['username'] as String? ?? 'Village member',
      photoUrl: json['photoUrl'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class CircleRequest {
  const CircleRequest({
    required this.sender,
    required this.createdAt,
  });

  final CirclePerson sender;
  final DateTime createdAt;

  factory CircleRequest.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawCreatedAt = data['createdAt'];
    return CircleRequest(
      sender: CirclePerson.fromJson({
        ...data,
        'uid': data['senderUid'] ?? document.id,
      }),
      createdAt:
          rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : DateTime.now(),
    );
  }
}

class CircleMessage {
  const CircleMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;

  factory CircleMessage.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final rawCreatedAt = data['createdAt'];
    return CircleMessage(
      id: document.id,
      senderUid: data['senderUid'] as String? ?? '',
      text: data['text'] as String? ?? '',
      createdAt:
          rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : DateTime.now(),
    );
  }
}

class CircleService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user;
  }

  String conversationId(String otherUid) {
    final ids = [_user.uid, otherUid]..sort();
    return ids.join('_');
  }

  Future<CirclePerson?> findPerson(String username) async {
    final result = await ProfileService.findUsername(username);
    if (result == null) return null;
    return CirclePerson(
      uid: result.uid,
      username: result.username,
    );
  }

  Future<void> sendRequest(CirclePerson recipient) async {
    final user = _user;
    if (recipient.uid == user.uid) {
      throw const CircleException('That is your own username.');
    }

    final myUsername =
        await ProfileService.currentUsername() ?? 'Village member';
    final requestReference = _firestore
        .collection('circle_requests')
        .doc(recipient.uid)
        .collection('incoming')
        .doc(user.uid);
    final existingMember = await _firestore
        .collection('circles')
        .doc(user.uid)
        .collection('members')
        .doc(recipient.uid)
        .get();
    if (existingMember.exists) {
      throw const CircleException('This person is already in your Circle.');
    }

    await requestReference.set({
      'senderUid': user.uid,
      'recipientUid': recipient.uid,
      'username': myUsername,
      'photoUrl': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _createNotification(
      recipientUid: recipient.uid,
      type: 'circle_request',
      title: 'New Circle request',
      message: '@$myUsername would like to join your trusted circle.',
      destinationIndex: 1,
    );
  }

  Stream<List<CircleRequest>> incomingRequests() {
    return _firestore
        .collection('circle_requests')
        .doc(_user.uid)
        .collection('incoming')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final requests = snapshot.docs.map(CircleRequest.fromDocument).toList();
          return Future.wait(requests.map((request) async {
            final latest = await ProfileService.publicUsername(
              request.sender.uid,
            );
            if (latest == null) return request;
            return CircleRequest(
              sender: CirclePerson(
                uid: request.sender.uid,
                username: latest,
                photoUrl: request.sender.photoUrl,
                status: request.sender.status,
              ),
              createdAt: request.createdAt,
            );
          }));
        });
  }

  Stream<List<CirclePerson>> members() {
    return _firestore
        .collection('circles')
        .doc(_user.uid)
        .collection('members')
        .orderBy('usernameLower')
        .snapshots()
        .asyncMap((snapshot) async {
          final people = snapshot.docs
              .map((document) => CirclePerson.fromJson({
                  ...document.data(),
                  'uid': document.id,
                }))
              .toList();
          return Future.wait(people.map((person) async {
            final latest = await ProfileService.publicUsername(person.uid);
            return CirclePerson(
              uid: person.uid,
              username: latest ?? person.username,
              photoUrl: person.photoUrl,
              status: person.status,
            );
          }));
        });
  }

  Future<void> acceptRequest(CircleRequest request) async {
    final user = _user;
    final myUsername =
        await ProfileService.currentUsername() ?? 'Village member';
    final incomingReference = _firestore
        .collection('circle_requests')
        .doc(user.uid)
        .collection('incoming')
        .doc(request.sender.uid);
    final myMemberReference = _firestore
        .collection('circles')
        .doc(user.uid)
        .collection('members')
        .doc(request.sender.uid);
    final theirMemberReference = _firestore
        .collection('circles')
        .doc(request.sender.uid)
        .collection('members')
        .doc(user.uid);
    final conversationReference = _firestore
        .collection('conversations')
        .doc(conversationId(request.sender.uid));

    final batch = _firestore.batch();
    batch.set(myMemberReference, {
      'uid': request.sender.uid,
      'username': request.sender.username,
      'usernameLower': request.sender.username.toLowerCase(),
      'photoUrl': request.sender.photoUrl,
      'status': '',
      'connectedAt': FieldValue.serverTimestamp(),
    });
    batch.set(theirMemberReference, {
      'uid': user.uid,
      'username': myUsername,
      'usernameLower': myUsername.toLowerCase(),
      'photoUrl': user.photoURL ?? '',
      'status': '',
      'connectedAt': FieldValue.serverTimestamp(),
    });
    batch.set(conversationReference, {
      'members': [user.uid, request.sender.uid]..sort(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(incomingReference);
    await batch.commit();

    await _createNotification(
      recipientUid: request.sender.uid,
      type: 'circle_accepted',
      title: 'Circle request accepted',
      message: '@$myUsername is now in your Circle.',
      destinationIndex: 1,
    );
  }

  Future<void> declineRequest(CircleRequest request) {
    return _firestore
        .collection('circle_requests')
        .doc(_user.uid)
        .collection('incoming')
        .doc(request.sender.uid)
        .delete();
  }

  Future<void> removeMember(String memberUid) async {
    final user = _user;
    final batch = _firestore.batch();
    batch.delete(_firestore
        .collection('circles')
        .doc(user.uid)
        .collection('members')
        .doc(memberUid));
    batch.delete(_firestore
        .collection('circles')
        .doc(memberUid)
        .collection('members')
        .doc(user.uid));
    await batch.commit();
  }

  Stream<List<CircleMessage>> messages(String otherUid) {
    return _firestore
        .collection('conversations')
        .doc(conversationId(otherUid))
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CircleMessage.fromDocument).toList());
  }

  Future<void> sendMessage({
    required CirclePerson recipient,
    required String text,
  }) async {
    final message = text.trim();
    if (message.isEmpty || message.length > 1000) {
      throw const CircleException('Write a message under 1,000 characters.');
    }

    final user = _user;
    final conversationReference =
        _firestore.collection('conversations').doc(conversationId(recipient.uid));
    final messageReference = conversationReference.collection('messages').doc();
    final batch = _firestore.batch();
    batch.set(
      conversationReference,
      {
        'members': [user.uid, recipient.uid]..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(messageReference, {
      'senderUid': user.uid,
      'recipientUid': recipient.uid,
      'text': message,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
    });
    await batch.commit();

    final username =
        await ProfileService.currentUsername() ?? 'A Circle member';
    await _createNotification(
      recipientUid: recipient.uid,
      type: 'message',
      title: 'New private message',
      message: '@$username sent you a message.',
      destinationIndex: 1,
    );
  }

  Future<void> markMessagesRead(String otherUid) async {
    final snapshot = await _firestore
        .collection('conversations')
        .doc(conversationId(otherUid))
        .collection('messages')
        .where('recipientUid', isEqualTo: _user.uid)
        .where('readAt', isNull: true)
        .limit(100)
        .get();
    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> updateStatus(String status) async {
    final user = _user;
    final membersSnapshot = await _firestore
        .collection('circles')
        .doc(user.uid)
        .collection('members')
        .get();
    if (membersSnapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final member in membersSnapshot.docs) {
      final visibleProfile = _firestore
          .collection('circles')
          .doc(member.id)
          .collection('members')
          .doc(user.uid);
      batch.set(
        visibleProfile,
        {'status': status, 'statusUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> _createNotification({
    required String recipientUid,
    required String type,
    required String title,
    required String message,
    required int destinationIndex,
  }) {
    final reference = _firestore
        .collection('notifications')
        .doc(recipientUid)
        .collection('items')
        .doc();
    return reference.set({
      'recipientUid': recipientUid,
      'actorUid': _user.uid,
      'type': type,
      'title': title,
      'message': message,
      'destinationIndex': destinationIndex,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class CircleException implements Exception {
  const CircleException(this.message);
  final String message;
}
