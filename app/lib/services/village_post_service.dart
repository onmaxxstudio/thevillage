import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_service.dart';

class VillageReply {
  const VillageReply({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    this.supportCount = 0,
    this.supportedByMe = false,
    this.authorUid,
  });

  final String id;
  final String text;
  final String author;
  final String? authorUid;
  final DateTime createdAt;
  final int supportCount;
  final bool supportedByMe;

  Map<String, Object> toJson() => {
        'id': id,
        'text': text,
        'author': author,
        if (authorUid != null) 'authorUid': authorUid!,
        'createdAt': createdAt.toIso8601String(),
        'supportCount': supportCount,
        'supportedByMe': supportedByMe,
      };

  Map<String, Object> toCloudJson() => {
        'id': id,
        'text': text,
        'author': author,
        if (authorUid != null) 'authorUid': authorUid!,
        'createdAt': Timestamp.fromDate(createdAt),
        'supportCount': supportCount,
      };

  factory VillageReply.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'];
    final createdAt = switch (rawCreatedAt) {
      Timestamp value => value.toDate(),
      String value => DateTime.tryParse(value) ?? DateTime.now(),
      _ => DateTime.now(),
    };
    return VillageReply(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      author: json['author'] as String? ?? 'Village neighbor',
      authorUid: json['authorUid'] as String?,
      createdAt: createdAt,
      supportCount: json['supportCount'] as int? ?? 0,
      supportedByMe: json['supportedByMe'] as bool? ?? false,
    );
  }

  VillageReply copyWith({
    int? supportCount,
    bool? supportedByMe,
  }) {
    return VillageReply(
      id: id,
      text: text,
      author: author,
      authorUid: authorUid,
      createdAt: createdAt,
      supportCount: supportCount ?? this.supportCount,
      supportedByMe: supportedByMe ?? this.supportedByMe,
    );
  }
}

class VillagePost {
  const VillagePost({
    required this.id,
    required this.question,
    required this.category,
    required this.audience,
    required this.author,
    required this.createdAt,
    required this.needsSupport,
    this.supportIntent = 'Advice',
    this.followUpStatus = 'Open',
    this.resolvedAt,
    this.supportCount = 0,
    this.saved = false,
    this.supportedByMe = false,
    this.replies = const [],
    this.isMine = true,
    this.authorUid,
  });

  final String id;
  final String question;
  final String category;
  final String audience;
  final String author;
  final String? authorUid;
  final DateTime createdAt;
  final bool needsSupport;
  final String supportIntent;
  final String followUpStatus;
  final DateTime? resolvedAt;
  final int supportCount;
  final bool saved;
  final bool supportedByMe;
  final List<VillageReply> replies;
  final bool isMine;

  Map<String, Object> toJson() => {
        'id': id,
        'question': question,
        'category': category,
        'audience': audience,
        'author': author,
        if (authorUid != null) 'authorUid': authorUid!,
        'createdAt': createdAt.toIso8601String(),
        'needsSupport': needsSupport,
        'supportIntent': supportIntent,
        'followUpStatus': followUpStatus,
        if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
        'supportCount': supportCount,
        'saved': saved,
        'supportedByMe': supportedByMe,
        'replies': replies.map((reply) => reply.toJson()).toList(),
        'isMine': isMine,
      };

  Map<String, Object> toCloudJson() => {
        'question': question,
        'category': category,
        'audience': audience,
        'author': author,
        if (authorUid != null) 'authorUid': authorUid!,
        'createdAt': Timestamp.fromDate(createdAt),
        'needsSupport': needsSupport,
        'supportIntent': supportIntent,
        'followUpStatus': followUpStatus,
        if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
        'supportCount': supportCount,
        'replies': replies.map((reply) => reply.toCloudJson()).toList(),
      };

  factory VillagePost.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'];
    final createdAt = switch (rawCreatedAt) {
      Timestamp value => value.toDate(),
      String value => DateTime.tryParse(value) ?? DateTime.now(),
      _ => DateTime.now(),
    };
    final rawResolvedAt = json['resolvedAt'];
    final resolvedAt = switch (rawResolvedAt) {
      Timestamp value => value.toDate(),
      String value => DateTime.tryParse(value),
      _ => null,
    };
    return VillagePost(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      audience: json['audience'] as String? ?? 'The Village',
      author: json['author'] as String? ?? '@VillageMember',
      authorUid: json['authorUid'] as String?,
      createdAt: createdAt,
      needsSupport: json['needsSupport'] as bool? ?? false,
      supportIntent: json['supportIntent'] as String? ?? 'Advice',
      followUpStatus: json['followUpStatus'] as String? ?? 'Open',
      resolvedAt: resolvedAt,
      supportCount: json['supportCount'] as int? ?? 0,
      saved: json['saved'] as bool? ?? false,
      supportedByMe: json['supportedByMe'] as bool? ?? false,
      replies: (json['replies'] as List<dynamic>? ?? const [])
          .map((item) {
            if (item is String) {
              return VillageReply(
                id: 'legacy-${item.hashCode}',
                text: item,
                author: 'Village neighbor',
                createdAt: DateTime.now(),
              );
            }
            if (item is Map<String, dynamic>) {
              return VillageReply.fromJson(item);
            }
            if (item is Map) {
              return VillageReply.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              );
            }
            return null;
          })
          .whereType<VillageReply>()
          .toList(),
      isMine: json['isMine'] as bool? ?? true,
    );
  }

  VillagePost copyWith({
    int? supportCount,
    bool? saved,
    bool? supportedByMe,
    List<VillageReply>? replies,
    bool? isMine,
    bool? needsSupport,
    String? followUpStatus,
    DateTime? resolvedAt,
  }) {
    return VillagePost(
      id: id,
      question: question,
      category: category,
      audience: audience,
      author: author,
      authorUid: authorUid,
      createdAt: createdAt,
      needsSupport: needsSupport ?? this.needsSupport,
      supportIntent: supportIntent,
      followUpStatus: followUpStatus ?? this.followUpStatus,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      supportCount: supportCount ?? this.supportCount,
      saved: saved ?? this.saved,
      supportedByMe: supportedByMe ?? this.supportedByMe,
      replies: replies ?? this.replies,
      isMine: isMine ?? this.isMine,
    );
  }
}

class VillagePostService {
  static const _storageKey = 'ask_the_village_posts';
  static const _postsCollection = 'village_posts';
  static const _ownersCollection = 'village_post_owners';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool lastLoadUsedCloud = false;

  bool get _cloudReady =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _posts =>
      FirebaseFirestore.instance.collection(_postsCollection);

  CollectionReference<Map<String, dynamic>> get _owners =>
      FirebaseFirestore.instance.collection(_ownersCollection);

  Future<List<VillagePost>> load() async {
    if (_cloudReady) {
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final results = await Future.wait([
          _posts.orderBy('createdAt', descending: true).limit(100).get(),
          _owners.where('uid', isEqualTo: user.uid).get(),
          _loadLocal(),
        ]);
        final postSnapshot =
            results[0] as QuerySnapshot<Map<String, dynamic>>;
        final ownerSnapshot =
            results[1] as QuerySnapshot<Map<String, dynamic>>;
        final localPosts = results[2] as List<VillagePost>;
        final ownedIds = ownerSnapshot.docs.map((doc) => doc.id).toSet();
        final localById = {
          for (final post in localPosts) post.id: post,
        };
        final cloudPosts = postSnapshot.docs.map((doc) {
          final local = localById[doc.id];
          return VillagePost.fromJson({
            ...doc.data(),
            'id': doc.id,
            'isMine': ownedIds.contains(doc.id),
            'saved': local?.saved ?? false,
            'supportedByMe': local?.supportedByMe ?? false,
          });
        }).toList();
        lastLoadUsedCloud = true;
        await _saveLocal(cloudPosts);
        return cloudPosts;
      } on FirebaseException {
        // Keep the app usable while Firestore is being enabled or configured.
      }
    }
    lastLoadUsedCloud = false;
    return _loadLocal();
  }

  Future<List<VillagePost>> _loadLocal() async {
    final stored = await _preferences.getStringList(_storageKey) ?? const [];
    final posts = <VillagePost>[];
    for (final item in stored) {
      try {
        final post =
            VillagePost.fromJson(jsonDecode(item) as Map<String, dynamic>);
        if (!post.id.startsWith('sample-')) posts.add(post);
      } on Object {
        // Ignore one damaged local post without losing the others.
      }
    }
    posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<VillagePost> publish({
    required String question,
    required String category,
    required String audience,
    required bool anonymous,
    required bool needsSupport,
    required String supportIntent,
  }) async {
    final now = DateTime.now();
    final username =
        await ProfileService.currentUsername() ?? 'VillageMember';
    final resolvedAuthor =
        anonymous ? 'Anonymous Neighbor' : '@$username';
    if (_cloudReady && audience != 'My Circle') {
      try {
        final user = FirebaseAuth.instance.currentUser!;
        final postReference = _posts.doc();
        final post = VillagePost(
          id: postReference.id,
          question: question.trim(),
          category: category,
          audience: audience,
          author: resolvedAuthor,
          authorUid: anonymous ? null : user.uid,
          createdAt: now,
          needsSupport: needsSupport,
          supportIntent: supportIntent,
        );
        final batch = FirebaseFirestore.instance.batch();
        batch.set(postReference, post.toCloudJson());
        batch.set(_owners.doc(post.id), {
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        final local = await _loadLocal();
        await _saveLocal([post, ...local]);
        return post;
      } on FirebaseException {
        // Fall back locally rather than lose a post the user already wrote.
      }
    }

    final local = await _loadLocal();
    final post = VillagePost(
      id: now.microsecondsSinceEpoch.toString(),
      question: question.trim(),
      category: category,
      audience: audience,
      author: resolvedAuthor,
      authorUid:
          anonymous ? null : FirebaseAuth.instance.currentUser?.uid,
      createdAt: now,
      needsSupport: needsSupport,
      supportIntent: supportIntent,
    );
    await _saveLocal([post, ...local]);
    return post;
  }

  Future<void> save(List<VillagePost> posts) async {
    await _saveLocal(posts);
    if (!_cloudReady || !lastLoadUsedCloud) return;

    final batch = FirebaseFirestore.instance.batch();
    var hasCloudChanges = false;
    for (final post in posts) {
      if (post.id.startsWith('sample-') || post.audience == 'My Circle') {
        continue;
      }
      batch.update(_posts.doc(post.id), {
        'supportCount': post.supportCount,
        'replies': post.replies.map((reply) => reply.toCloudJson()).toList(),
      });
      hasCloudChanges = true;
    }
    if (hasCloudChanges) {
      try {
        await batch.commit();
      } on FirebaseException {
        // The local copy remains available and can sync after reconnecting.
      }
    }
  }

  Future<void> notifyPostOwner({
    required VillagePost post,
    required String type,
  }) async {
    final actor = FirebaseAuth.instance.currentUser;
    final recipientUid = post.authorUid;
    if (!_cloudReady ||
        actor == null ||
        recipientUid == null ||
        recipientUid == actor.uid ||
        post.id.startsWith('sample-')) {
      return;
    }

    final notificationId = type == 'post_support'
        ? '${post.id}_${actor.uid}_support'
        : '${post.id}_${actor.uid}_${DateTime.now().microsecondsSinceEpoch}';
    final username =
        await ProfileService.currentUsername() ?? 'A Village member';
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(recipientUid)
        .collection('items')
        .doc(notificationId)
        .set({
      'recipientUid': recipientUid,
      'actorUid': actor.uid,
      'type': type,
      'title': type == 'post_support'
          ? 'Someone supported your question'
          : 'New reply to your question',
      'message': type == 'post_support'
          ? '@$username supported your Village question.'
          : '@$username replied to your Village question.',
      'destinationIndex': 3,
      'postId': post.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(VillagePost post) async {
    final local = await _loadLocal();
    await _saveLocal(local.where((item) => item.id != post.id).toList());
    if (!_cloudReady ||
        post.id.startsWith('sample-') ||
        post.audience == 'My Circle') {
      return;
    }
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.delete(_posts.doc(post.id));
      batch.delete(_owners.doc(post.id));
      await batch.commit();
    } on FirebaseException {
      // Firestore rules will reject deleting a post the user does not own.
      rethrow;
    }
  }

  Future<void> updateFollowUp(
    VillagePost post, {
    required String status,
  }) async {
    final resolved = status == 'Resolved';
    final updated = post.copyWith(
      followUpStatus: status,
      needsSupport: resolved ? false : post.needsSupport,
      resolvedAt: resolved ? DateTime.now() : post.resolvedAt,
    );
    final local = await _loadLocal();
    await _saveLocal([
      for (final item in local) if (item.id == post.id) updated else item,
    ]);
    if (!_cloudReady || post.audience == 'My Circle') return;
    await _posts.doc(post.id).update({
      'followUpStatus': status,
      'needsSupport': updated.needsSupport,
      if (resolved) 'resolvedAt': Timestamp.fromDate(updated.resolvedAt!),
    });
  }

  Future<void> _saveLocal(List<VillagePost> posts) {
    return _preferences.setStringList(
      _storageKey,
      posts.map((post) => jsonEncode(post.toJson())).toList(),
    );
  }
}
