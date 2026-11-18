import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A pre-approved daily schedule allows Spark-plan publishing without a
/// scheduled Cloud Function. Dates are keyed to America/New_York.
class DailyVillageQuestionService {
  DailyVillageQuestionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static String dateKey(DateTime easternDate) =>
      '${easternDate.year.toString().padLeft(4, '0')}-'
      '${easternDate.month.toString().padLeft(2, '0')}-'
      '${easternDate.day.toString().padLeft(2, '0')}';

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchQuestion(String date) =>
      _db.collection('village_daily_questions').doc(date).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchResponses(String date) =>
      _db.collection('village_daily_questions').doc(date)
          .collection('responses').orderBy('createdAt', descending: true)
          .limit(100).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchArchive() =>
      _db.collection('village_daily_questions')
          .where('status', isEqualTo: 'published')
          .where('publishAt', isLessThanOrEqualTo: Timestamp.now())
          .orderBy('publishAt', descending: true).limit(60).snapshots();

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to participate.');
    return uid;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReplies(
          String date, String responseId) =>
      _db.collection('village_daily_questions').doc(date)
          .collection('responses').doc(responseId)
          .collection('replies').orderBy('createdAt').limit(100).snapshots();

  Future<void> postReply(String date, String responseId, String text) async {
    final message = text.trim();
    if (message.isEmpty || message.length > 1000) {
      throw ArgumentError('Replies must contain 1–1000 characters.');
    }
    await _db.collection('village_daily_questions').doc(date)
        .collection('responses').doc(responseId)
        .collection('replies').add({
          'authorUid': _uid,
          'body': message,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  DocumentReference<Map<String, dynamic>> _savedRef(
          String date, String responseId) =>
      _db.collection('users').doc(_uid)
          .collection('saved_village_perspectives').doc('${date}_${responseId}');

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSaved(
          String date, String responseId) =>
      _savedRef(date, responseId).snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSavedPerspectives() =>
      _db.collection('users').doc(_uid)
          .collection('saved_village_perspectives')
          .orderBy('savedAt', descending: true).limit(100).snapshots();

  Future<void> toggleSaved(String date, String responseId, String body) async {
    final ref = _savedRef(date, responseId);
    final existing = await ref.get();
    if (existing.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'date': date,
        'responseId': responseId,
        'body': body,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  DocumentReference<Map<String, dynamic>> _helpfulRef(
          String date, String responseId) =>
      _db.collection('village_daily_questions').doc(date)
          .collection('responses').doc(responseId)
          .collection('helpful').doc(_uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchHelpful(
          String date, String responseId) =>
      _helpfulRef(date, responseId).snapshots();

  Future<void> markHelpful(String date, String responseId) async {
    final ref = _helpfulRef(date, responseId);
    await ref.set({'uid': _uid, 'createdAt': FieldValue.serverTimestamp()});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyResponses() =>
      _db.collectionGroup('responses')
          .where('authorUid', isEqualTo: _uid)
          .orderBy('createdAt', descending: true).limit(100).snapshots();

  Future<void> postResponse(String date, String text) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to participate.');
    final message = text.trim();
    if (message.isEmpty || message.length > 2000) {
      throw ArgumentError('Responses must contain 1–2000 characters.');
    }
    await _db.collection('village_daily_questions').doc(date)
        .collection('responses').add({
          'authorUid': user.uid,
          'body': message,
          'createdAt': FieldValue.serverTimestamp(),
          'supportCount': 0,
        });
  }
}
