import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  String get _storageKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'signed_out';
    return 'ask_the_village_mood_history_$uid';
  }

  bool get _cloudReady =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  CollectionReference<Map<String, dynamic>> get _items {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('check_ins')
        .doc(uid)
        .collection('items');
  }

  Future<List<MoodCheckIn>> load() async {
    if (_cloudReady) {
      try {
        final snapshot = await _items
            .orderBy('createdAt', descending: true)
            .limit(370)
            .get();
        final checkIns = snapshot.docs.map((document) {
          final data = document.data();
          final rawCreatedAt = data['createdAt'];
          return MoodCheckIn.fromJson({
            ...data,
            'createdAt': rawCreatedAt is Timestamp
                ? rawCreatedAt.toDate().toIso8601String()
                : rawCreatedAt,
          });
        }).toList();
        await _saveLocal(checkIns);
        return checkIns;
      } on FirebaseException {
        // Use this account's private device cache while offline.
      }
    }

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

  Future<void> _saveLocal(List<MoodCheckIn> history) {
    return _preferences.setStringList(
      _storageKey,
      history.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
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
    await _saveLocal(history);
    if (_cloudReady) {
      final dayId =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      try {
        await _items.doc(dayId).set({
          'mood': mood,
          'details': details.trim(),
          'periodStarted': periodStarted,
          'healthNotes': healthNotes.trim(),
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } on FirebaseException {
        // The private device copy is retained and can be replaced after sync.
      }
    }
    return history;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
