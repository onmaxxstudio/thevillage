import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminContentService {
  bool get cloudReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> _collection(String type) =>
      FirebaseFirestore.instance.collection('admin_$type');

  Stream<QuerySnapshot<Map<String, dynamic>>> watch(String type) {
    return _collection(type).orderBy('sortOrder').snapshots();
  }

  Future<List<ManagedContentItem>> loadPublished(String type) async {
    if (!cloudReady) return const [];
    try {
      final snapshot = await _collection(type)
          .where('published', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      return snapshot.docs
          .map((doc) => ManagedContentItem(id: doc.id, data: doc.data()))
          .toList(growable: false);
    } on FirebaseException {
      return const [];
    }
  }

  Future<void> save({
    required String type,
    String? id,
    required Map<String, dynamic> data,
  }) async {
    if (!cloudReady) return;
    final ref = id == null ? _collection(type).doc() : _collection(type).doc(id);
    await ref.set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      if (id == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String type, String id) async {
    if (!cloudReady) return;
    await _collection(type).doc(id).delete();
  }

  Future<void> setPublished(String type, String id, bool value) async {
    if (!cloudReady) return;
    await _collection(type).doc(id).set({
      'published': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class ManagedContentItem {
  const ManagedContentItem({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  String text(String key, [String fallback = '']) =>
      (data[key] ?? fallback).toString();
}