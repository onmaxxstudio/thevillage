import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PrivateJournalEntry {
  const PrivateJournalEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
    this.prompt = '',
    this.entryType = 'journal',
    this.favorite = false,
    this.mood,
    this.extraFields = const {},
  });

  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final List<String> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String prompt;
  final String entryType;
  final bool favorite;
  final String? mood;
  final Map<String, dynamic> extraFields;

  factory PrivateJournalEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return PrivateJournalEntry(
      id: document.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      attachments: (data['attachments'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      prompt: data['prompt'] as String? ?? '',
      entryType: data['entryType'] as String? ?? 'journal',
      favorite: data['favorite'] == true,
      mood: data['mood'] as String?,
      extraFields: {
        for (final key in const ['linkedEntryId', 'milestoneDate', 'milestoneIcon', 'goalProgress', 'actionSteps'])
          if (data.containsKey(key)) key: data[key],
      },
    );
  }

  static DateTime? _toDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}

class PrivateJournalDraft {
  const PrivateJournalDraft({
    required this.title,
    required this.body,
    required this.tags,
    required this.attachments,
    required this.entryId,
  });

  final String title;
  final String body;
  final List<String> tags;
  final List<String> attachments;
  final String? entryId;

  bool get hasContent => title.trim().isNotEmpty || body.trim().isNotEmpty || tags.isNotEmpty || attachments.isNotEmpty;

  factory PrivateJournalDraft.fromMap(Map<String, dynamic> data) {
    return PrivateJournalDraft(
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      attachments: (data['attachments'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      entryId: data['entryId'] as String?,
    );
  }
}

class PrivateJournalService {
  PrivateJournalService({
    required this.uid,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final String uid;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _entries => _firestore
      .collection('private_journals')
      .doc(uid)
      .collection('entries');

  DocumentReference<Map<String, dynamic>> get _draft => _firestore
      .collection('private_journals')
      .doc(uid)
      .collection('drafts')
      .doc('write_freely');

  Stream<List<PrivateJournalEntry>> watchEntries() => _entries
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map(PrivateJournalEntry.fromDocument)
          .toList(growable: false));

  Future<List<PrivateJournalEntry>> loadEntries() async {
    final snapshot = await _entries.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(PrivateJournalEntry.fromDocument).toList();
  }

  Future<PrivateJournalDraft?> loadDraft() async {
    final snapshot = await _draft.get();
    if (!snapshot.exists) return null;
    return PrivateJournalDraft.fromMap(snapshot.data() ?? const {});
  }

  Future<String> saveDraft({
    required String title,
    required String body,
    required List<String> tags,
    required List<String> attachments,
    String? entryId,
  }) async {
    final reservedId = entryId ?? _entries.doc().id;
    await _draft.set({
      'title': title,
      'body': body,
      'tags': tags,
      'attachments': attachments,
      'entryId': reservedId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reservedId;
  }

  Future<PrivateJournalEntry> saveEntry({
    required String title,
    required String body,
    required List<String> tags,
    required List<String> attachments,
    required String entryId,
    PrivateJournalEntry? existing,
  }) async {
    final reference = _entries.doc(entryId);
    final prior = existing == null ? await reference.get() : null;
    DateTime? originalCreatedAt = existing?.createdAt;
    final priorCreatedAt = prior?.data()?['createdAt'];
    if (originalCreatedAt == null && priorCreatedAt is Timestamp) {
      originalCreatedAt = priorCreatedAt.toDate();
    } else if (originalCreatedAt == null && priorCreatedAt is DateTime) {
      originalCreatedAt = priorCreatedAt;
    }
    final batch = _firestore.batch();
    batch.set(reference, {
      'title': title.trim(),
      'body': body,
      'tags': tags,
      'attachments': attachments,
      'prompt': existing?.prompt ?? '',
      'entryType': existing?.entryType ?? 'journal',
      if (existing?.mood != null) 'mood': existing!.mood,
      ...?existing?.extraFields,
      'favorite': existing?.favorite ?? false,
      'createdAt': originalCreatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(originalCreatedAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_draft);
    await batch.commit();
    final saved = await reference.get();
    return PrivateJournalEntry(
      id: entryId,
      title: title.trim(),
      body: body,
      tags: List.unmodifiable(tags),
      attachments: List.unmodifiable(attachments),
      createdAt: _timestamp(saved.data()?['createdAt']) ?? originalCreatedAt,
      updatedAt: _timestamp(saved.data()?['updatedAt']),
      prompt: existing?.prompt ?? '',
      entryType: existing?.entryType ?? 'journal',
      favorite: existing?.favorite ?? false,
      mood: existing?.mood,
      extraFields: existing?.extraFields ?? const {},
    );
  }

  Future<void> clearDraft() => _draft.delete();

  Future<void> setFavorite(String id, bool favorite) => _entries.doc(id).update({
        'favorite': favorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteEntry(String id) async {
    final draftSnapshot = await _draft.get();
    final batch = _firestore.batch()..delete(_entries.doc(id));
    if (draftSnapshot.data()?['entryId'] == id) batch.delete(_draft);
    await batch.commit();
  }

  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final cleanName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = 'private_journals/$uid/attachments/${DateTime.now().microsecondsSinceEpoch}_$cleanName';
    await _storage.ref(path).putData(
          bytes,
          SettableMetadata(contentType: _imageMime(cleanName)),
        );
    return path;
  }

  Future<Uint8List?> loadImage(String path) =>
      _storage.ref(path).getData(5 * 1024 * 1024);

  Future<void> deleteImage(String path) async {
    await _storage.ref(path).delete();
  }

  static DateTime? _timestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static String _imageMime(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}
