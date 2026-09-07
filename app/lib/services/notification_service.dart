import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VillageNotification {
  const VillageNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.destinationIndex,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final int destinationIndex;
  final bool isRead;

  VillageNotification copyWith({bool? isRead}) => VillageNotification(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        destinationIndex: destinationIndex,
        isRead: isRead ?? this.isRead,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'createdAt': createdAt.toIso8601String(),
        'destinationIndex': destinationIndex,
        'isRead': isRead,
      };

  factory VillageNotification.fromJson(Map<String, dynamic> json) {
    return VillageNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Village update',
      message: json['message'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      destinationIndex: json['destinationIndex'] as int? ?? 0,
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class NotificationService {
  static const _storageKey = 'ask_the_village_notifications';
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<VillageNotification>> load() async {
    var stored = await _preferences.getStringList(_storageKey);
    if (stored == null || stored.isEmpty) {
      final now = DateTime.now();
      final seeded = [
        VillageNotification(
          id: 'welcome-reply',
          title: 'Someone supported your question',
          message: 'A Village member left a thoughtful reply.',
          createdAt: now.subtract(const Duration(minutes: 12)),
          destinationIndex: 3,
        ),
        VillageNotification(
          id: 'circle-request',
          title: 'New Circle request',
          message: '@MoeSupport would like to join your trusted circle.',
          createdAt: now.subtract(const Duration(hours: 1)),
          destinationIndex: 1,
        ),
        VillageNotification(
          id: 'check-in',
          title: 'Your daily check-in is ready',
          message: 'Take a quiet moment to record how you feel today.',
          createdAt: now.subtract(const Duration(hours: 3)),
          destinationIndex: 0,
        ),
      ];
      await save(seeded);
      return seeded;
    }

    final notifications = <VillageNotification>[];
    for (final item in stored) {
      try {
        notifications.add(
          VillageNotification.fromJson(
            jsonDecode(item) as Map<String, dynamic>,
          ),
        );
      } on Object {
        // Keep valid notifications if one stored item is damaged.
      }
    }
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _updateUnreadCount(notifications);
    return notifications;
  }

  Future<void> save(List<VillageNotification> notifications) async {
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
    await save(updated);
    return updated;
  }

  Future<List<VillageNotification>> markAllRead(
    List<VillageNotification> notifications,
  ) async {
    final updated =
        notifications.map((item) => item.copyWith(isRead: true)).toList();
    await save(updated);
    return updated;
  }

  void _updateUnreadCount(List<VillageNotification> notifications) {
    unreadCount.value = notifications.where((item) => !item.isRead).length;
  }
}
