import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class VillageReply {
  const VillageReply({
    required this.id,
    required this.text,
    required this.author,
    required this.createdAt,
    this.supportCount = 0,
    this.supportedByMe = false,
  });

  final String id;
  final String text;
  final String author;
  final DateTime createdAt;
  final int supportCount;
  final bool supportedByMe;

  Map<String, Object> toJson() => {
        'id': id,
        'text': text,
        'author': author,
        'createdAt': createdAt.toIso8601String(),
        'supportCount': supportCount,
        'supportedByMe': supportedByMe,
      };

  factory VillageReply.fromJson(Map<String, dynamic> json) {
    return VillageReply(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      author: json['author'] as String? ?? 'Village neighbor',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
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
    this.supportCount = 0,
    this.saved = false,
    this.supportedByMe = false,
    this.replies = const [],
    this.isMine = true,
  });

  final String id;
  final String question;
  final String category;
  final String audience;
  final String author;
  final DateTime createdAt;
  final bool needsSupport;
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
        'createdAt': createdAt.toIso8601String(),
        'needsSupport': needsSupport,
        'supportCount': supportCount,
        'saved': saved,
        'supportedByMe': supportedByMe,
        'replies': replies.map((reply) => reply.toJson()).toList(),
        'isMine': isMine,
      };

  factory VillagePost.fromJson(Map<String, dynamic> json) {
    return VillagePost(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      category: json['category'] as String? ?? 'Other',
      audience: json['audience'] as String? ?? 'The Village',
      author: json['author'] as String? ?? '@KindHeart',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      needsSupport: json['needsSupport'] as bool? ?? false,
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
  }) {
    return VillagePost(
      id: id,
      question: question,
      category: category,
      audience: audience,
      author: author,
      createdAt: createdAt,
      needsSupport: needsSupport,
      supportCount: supportCount ?? this.supportCount,
      saved: saved ?? this.saved,
      supportedByMe: supportedByMe ?? this.supportedByMe,
      replies: replies ?? this.replies,
      isMine: isMine,
    );
  }
}

class VillagePostService {
  static const _storageKey = 'ask_the_village_posts';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<VillagePost>> load() async {
    final stored = await _preferences.getStringList(_storageKey) ?? const [];
    final posts = <VillagePost>[];
    for (final item in stored) {
      try {
        posts.add(
          VillagePost.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
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
  }) async {
    final posts = await load();
    final now = DateTime.now();
    final post = VillagePost(
      id: now.microsecondsSinceEpoch.toString(),
      question: question.trim(),
      category: category,
      audience: audience,
      author: anonymous ? 'Anonymous Neighbor' : '@KindHeart',
      createdAt: now,
      needsSupport: needsSupport,
    );
    posts.insert(0, post);
    await save(posts);
    return post;
  }

  Future<void> save(List<VillagePost> posts) {
    return _preferences.setStringList(
      _storageKey,
      posts.map((post) => jsonEncode(post.toJson())).toList(),
    );
  }
}
