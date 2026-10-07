import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Daily Village Census storage. Security rules must enforce admin-only question
/// management and one immutable vote per authenticated user per poll.
class VillageCensusService {
  VillageCensusService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get questions =>
      _db.collection('village_census_questions');

  DocumentReference<Map<String, dynamic>> questionForDate(String dateKey) => questions.doc(dateKey);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchQuestions() =>
      questions.orderBy('dateKey', descending: true).limit(90).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchQuestion(String id) =>
      questions.doc(id).snapshots();

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMyVote(String id) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to vote');
    return questions.doc(id).collection('votes').doc(uid).snapshots();
  }

  Future<void> vote({required String questionId, required String option}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to vote');
    final questionRef = questions.doc(questionId);
    final voteRef = questionRef.collection('votes').doc(uid);
    await _db.runTransaction((tx) async {
      final question = await tx.get(questionRef);
      final previous = await tx.get(voteRef);
      if (!question.exists || question.data()?['status'] != 'published') {
        throw StateError('This question is unavailable');
      }
      if (previous.exists) throw StateError('You already voted');
      final options = List<String>.from(question.data()?['options'] ?? []);
      if (!options.contains(option)) throw ArgumentError('Invalid answer');
      tx.set(voteRef, {'option': option, 'createdAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> createQuestion({
    required String id,
    required String text,
    required List<String> options,
    required String dateKey,
    required String category,
  }) async {
    if (options.length < 2 || options.length > 4 || options.toSet().length != options.length) {
      throw ArgumentError('Provide 2–4 unique answers');
    }
    final ref = questions.doc(id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) throw StateError('A question is already scheduled for this date');
      transaction.set(ref, {
      'text': text.trim(),
      'options': options,
      'dateKey': dateKey,
      'category': category,
      'status': 'draft',
      'sponsored': false,
      'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> publishQuestion(String id) =>
      questions.doc(id).update({'status': 'published'});

  Future<Map<String, int>> countVotes(String id, List<String> options) async {
    final votes = await questions.doc(id).collection('votes').get();
    final counts = {for (final option in options) option: 0};
    for (final vote in votes.docs) {
      final answer = vote.data()['option'];
      if (counts.containsKey(answer)) counts[answer] = counts[answer]! + 1;
    }
    return counts;
  }
}
