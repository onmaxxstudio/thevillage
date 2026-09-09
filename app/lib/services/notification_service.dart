import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VillageNotification {
  const VillageNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.destinationIndex,
    this.type = 'other',
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final int destinationIndex;
  final String type;
  final bool isRead;

  VillageNotification copyWith({bool? isRead}) => VillageNotification(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        destinationIndex: destinationIndex,
        type: type,
        isRead: isRead ?? this.isRead,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'destinationIndex': destinationIndex,
        'type': type,
        'isRead': isRead,
      };

  factory VillageNotification.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'];
    return VillageNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Village update',
      message: json['message'] as String? ?? '',
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.tryParse(rawCreatedAt as String? ?? '') ?? DateTime.now(),
      destinationIndex: json['destinationIndex'] as int? ?? 0,
      type: json['type'] as String? ?? 'other',
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class NotificationService {
  static const _legacyStorageKey = 'ask_the_village_notifications';
  static const _legacyIds = {
    'welcome-reply',
    'circle-request',
    'check-in',
  };
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'signed_out';
    return '${_legacyStorageKey}_$uid';
  }

  bool get _cloudReady =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _items {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items');
  }

  Future<List<VillageNotification>> load() async {
    if (_cloudReady) {
      try {
        final snapshot =
            await _items.orderBy('createdAt', descending: true).limit(100).get();
        final notifications = snapshot.docs
            .map((document) => VillageNotification.fromJson({
                  ...document.data(),
                  'id': document.id,
                }))
            .toList();
        final filtered = await _applyPreferences(notifications);
        await _saveLocal(filtered);
        return filtered;
      } on FirebaseException {
        // Use the last cached real notifications while offline.
      }
    }
    return _loadLocal();
  }

  Future<void> startListening() async {
    await _subscription?.cancel();
    if (!_cloudReady) {
      await load();
      return;
    }
    _subscription = _items
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen(
      (snapshot) {
        final notifications = snapshot.docs
            .map((document) => VillageNotification.fromJson({
                  ...document.data(),
                  'id': document.id,
                }))
            .toList();
        _applyPreferences(notifications).then(_saveLocal);
      },
      onError: (_) => load(),
    );
  }

  Future<List<VillageNotification>> _applyPreferences(
    List<VillageNotification> notifications,
  ) async {
    final replies =
        await _preferences.getBool('setting_reply_notifications') ?? true;
    final circle =
        await _preferences.getBool('setting_circle_notifications') ?? true;
    return notifications.where((item) {
      if (!replies &&
          const {'post_reply', 'post_support'}.contains(_typeFor(item))) {
        return false;
      }
      if (!circle &&
          const {'circle_request', 'circle_accepted', 'message'}
              .contains(_typeFor(item))) {
        return false;
      }
      return true;
    }).toList();
  }

  String _typeFor(VillageNotification notification) {
    if (notification.type != 'other') return notification.type;
    final title = notification.title.toLowerCase();
    if (title.contains('request accepted')) return 'circle_accepted';
    if (title.contains('circle request')) return 'circle_request';
    if (title.contains('private message')) return 'message';
    if (title.contains('repl')) return 'post_reply';
    if (title.contains('support')) return 'post_support';
    return 'other';
  }

  static Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    unreadCount.value = 0;
  }

  Future<List<VillageNotification>> _loadLocal() async {
    final stored = await _preferences.getStringList(_storageKey) ?? const [];
    final notifications = <VillageNotification>[];
    for (final item in stored) {
      try {
        final notification = VillageNotification.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );
        if (!_legacyIds.contains(notification.id)) {
          notifications.add(notification);
        }
      } on Object {
        // Keep valid cached notifications if one item is damaged.
      }
    }
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _updateUnreadCount(notifications);
    return notifications;
  }

  Future<void> _saveLocal(
    List<VillageNotification> notifications,
  ) async {
    await _preferences.setStringList(
      _storageKey,
      notifications.map((item) => jsonEncode(item.toJson())).toList(),
    );
    _updateUnreadCount(notifications);
  }

  Future<List<VillageNotification>> markRead(
    List<VillageNotification> notifications,
    String id,
  ) async {
    final updated = notifications
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    if (_cloudReady) {
      try {
        await _items.doc(id).update({'isRead': true});
      } on FirebaseException {
        // The local read state remains correct and can refresh later.
      }
    }
    await _saveLocal(updated);
    return updated;
  }

  Future<List<VillageNotification>> markAllRead(
    List<VillageNotification> notifications,
  ) async {
    final updated =
        notifications.map((item) => item.copyWith(isRead: true)).toList();
    if (_cloudReady) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final item in notifications.where((item) => !item.isRead)) {
          batch.update(_items.doc(item.id), {'isRead': true});
        }
        await batch.commit();
      } on FirebaseException {
        // The local read state remains correct and can refresh later.
      }
    }
    await _saveLocal(updated);
    return updated;
  }

  void _updateUnreadCount(List<VillageNotification> notifications) {
    unreadCount.value = notifications.where((item) => !item.isRead).length;
  }
}
