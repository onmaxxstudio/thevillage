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
          .orderBy('date', descending: true).limit(60).snapshots();

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
