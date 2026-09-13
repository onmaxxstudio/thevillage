import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminModerationService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> watchPosts() {
    return _firestore
        .collection('village_posts')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchReports() {
    return _firestore
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots();
  }

  Future<void> deletePost(String postId) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('village_posts').doc(postId));
    batch.delete(_firestore.collection('village_post_owners').doc(postId));
    await batch.commit();
  }

  Future<bool> deleteReportedTarget({
    required String targetType,
    required String targetId,
  }) async {
    if (targetType == 'post') {
      await deletePost(targetId);
      return true;
    }
    if (targetType == 'reply') {
      final posts = await _firestore
          .collection('village_posts')
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();
      for (final post in posts.docs) {
        final data = post.data();
        final replies = List<dynamic>.from(data['replies'] as List? ?? const []);
        final filtered = replies.where((item) {
          if (item is! Map) return true;
          return (item['id'] ?? '').toString() != targetId;
        }).toList();
        if (filtered.length != replies.length) {
          await post.reference.update({'replies': filtered});
          return true;
        }
      }
    }
    return false;
  }

  Future<void> setReportStatus(String reportId, String status) async {
    await _firestore.collection('reports').doc(reportId).update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': FirebaseAuth.instance.currentUser?.uid ?? '',
    });
  }
}
