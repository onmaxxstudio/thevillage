import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AdminContentService {
  bool get cloudReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> _collection(String type) =>
      FirebaseFirestore.instance.collection('admin_$type');

  Stream<QuerySnapshot<Map<String, dynamic>>> watch(String type) {
    return _collection(type).orderBy('sortOrder').snapshots();
  }

  List<ManagedContentItem> _publishedItems(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    final items = snapshot.docs
        .where((doc) => doc.data()['published'] == true)
        .map((doc) => ManagedContentItem(id: doc.id, data: doc.data()))
        .toList();
    items.sort((a, b) {
      final aOrder = a.data['sortOrder'];
      final bOrder = b.data['sortOrder'];
      final av = aOrder is num ? aOrder.toInt() : 0;
      final bv = bOrder is num ? bOrder.toInt() : 0;
      return av.compareTo(bv);
    });
    return items;
  }

  Stream<List<ManagedContentItem>> watchPublished(String type) {
    if (!cloudReady) return Stream.value(const []);
    return _collection(type).snapshots().map(_publishedItems);
  }

  Future<List<ManagedContentItem>> loadPublished(String type) async {
    if (!cloudReady) return const [];
    try {
      final snapshot = await _collection(type).get();
      return _publishedItems(snapshot);
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
