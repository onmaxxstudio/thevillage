import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class VillagePersonalization {
  const VillagePersonalization({
    required this.identity,
    required this.interests,
    required this.periodTracking,
    required this.completed,
  });

  const VillagePersonalization.empty()
      : identity = '',
        interests = const <String>[],
        periodTracking = false,
        completed = false;

  final String identity;
  final List<String> interests;
  final bool periodTracking;
  final bool completed;

  bool get isMan => identity == 'man';
  bool get isWoman => identity == 'woman';

  Map<String, Object?> toMap() => {
        'identity': identity,
        'interests': interests,
        'periodTracking': periodTracking,
        'personalizationComplete': completed,
      };

  factory VillagePersonalization.fromMap(Map<String, dynamic> data) {
    return VillagePersonalization(
      identity: data['identity'] as String? ?? '',
      interests: (data['interests'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      periodTracking: data['periodTracking'] as bool? ?? false,
      completed: data['personalizationComplete'] as bool? ?? false,
    );
  }
}

class PersonalizationService {
  static final ValueNotifier<VillagePersonalization?> notifier =
      ValueNotifier<VillagePersonalization?>(null);

  String get _ownerId => FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  String get _key => 'village_personalization_$_ownerId';

  Future<VillagePersonalization> load() async {
    final preferences = await SharedPreferences.getInstance();
    final identity = preferences.getString('${_key}_identity') ?? '';
    final interests = preferences.getStringList('${_key}_interests') ?? const <String>[];
    final hasLocal = preferences.getBool('${_key}_complete') ?? false;
    final local = VillagePersonalization(
      identity: identity,
      interests: interests,
      periodTracking: preferences.getBool('${_key}_period') ?? false,
      completed: hasLocal,
    );
    if (hasLocal) {
      notifier.value = local;
      return local;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null && Firebase.apps.isNotEmpty) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final cloud = VillagePersonalization.fromMap(snapshot.data() ?? const {});
        if (cloud.completed) {
          await _saveLocal(cloud);
          notifier.value = cloud;
          return cloud;
        }
      } on Object {
        // Local personalization keeps the experience working offline.
      }
    }
    notifier.value = local;
    return local;
  }

  Future<void> save(VillagePersonalization value) async {
    await _saveLocal(value);
    notifier.value = value;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || Firebase.apps.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {...value.toMap(), 'personalizationUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } on Object {
      // The local choice is immediately effective while cloud sync is unavailable.
    }
  }

  Future<void> _saveLocal(VillagePersonalization value) async {
    final preferences = await SharedPreferences.getInstance();
    await Future.wait([
      preferences.setString('${_key}_identity', value.identity),
      preferences.setStringList('${_key}_interests', value.interests),
      preferences.setBool('${_key}_period', value.periodTracking),
      preferences.setBool('${_key}_complete', value.completed),
    ]);
  }
}
