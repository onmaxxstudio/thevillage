import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MoodCheckIn {
  const MoodCheckIn({
    required this.mood,
    required this.createdAt,
    this.details = '',
    this.periodStarted = false,
    this.healthNotes = '',
  });

  final String mood;
  final DateTime createdAt;
  final String details;
  final bool periodStarted;
  final String healthNotes;

  Map<String, Object> toJson() => {
        'mood': mood,
        'createdAt': createdAt.toIso8601String(),
        'details': details,
        'periodStarted': periodStarted,
        'healthNotes': healthNotes,
      };

  factory MoodCheckIn.fromJson(Map<String, dynamic> json) {
    return MoodCheckIn(
      mood: json['mood'] as String? ?? 'Okay',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      details: json['details'] as String? ?? '',
      periodStarted: json['periodStarted'] as bool? ??
          json['periodStatus'] == 'Started today',
      healthNotes: json['healthNotes'] as String? ?? '',
    );
  }
}

class CheckInService {
  static const _storageKey = 'ask_the_village_mood_history';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<List<MoodCheckIn>> load() async {
    final stored = await _preferences.getStringList(_storageKey) ?? const [];
    final checkIns = <MoodCheckIn>[];
    for (final item in stored) {
      try {
        checkIns.add(
          MoodCheckIn.fromJson(jsonDecode(item) as Map<String, dynamic>),
        );
      } on Object {
        // Ignore a damaged local entry without losing the rest of the history.
      }
    }
    checkIns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return checkIns;
  }

  Future<List<MoodCheckIn>> saveToday({
    required String mood,
    required String details,
    required bool periodStarted,
    required String healthNotes,
  }) async {
    final history = await load();
    final now = DateTime.now();
    history.removeWhere((entry) => _sameDay(entry.createdAt, now));
    history.insert(
      0,
      MoodCheckIn(
        mood: mood,
        createdAt: now,
        details: details.trim(),
        periodStarted: periodStarted,
        healthNotes: healthNotes.trim(),
      ),
    );
    await _preferences.setStringList(
      _storageKey,
      history.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
    return history;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
