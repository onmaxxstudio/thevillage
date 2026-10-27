import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnonymousIdentityService {
  static bool isAlias(String name) => name.startsWith('Neighbor-') ||
      RegExp(r'^[A-Z][a-z]+[A-Z][a-z]+[0-9]{2}$').hasMatch(name);

  static const adjectives = ['Quiet', 'Sunny', 'Kind', 'Brave', 'Cozy', 'Happy',
    'Calm', 'Sweet', 'Fresh', 'Merry', 'Noble', 'Lucky', 'Bold', 'Gentle',
    'Bright', 'Golden', 'Silver', 'Amber', 'Coral', 'Jolly', 'Soft', 'Warm',
    'Wise', 'Proud', 'Peach', 'Royal', 'Lively', 'Minty', 'Dreamy', 'Rosy'];
  static const nouns = ['Willow', 'Robin', 'Maple', 'Fern', 'Bloom', 'Cedar',
    'Daisy', 'Finch', 'River', 'Cloud', 'Otter', 'Panda', 'Koala', 'Lotus',
    'Petal', 'Dove', 'Lark', 'Wren', 'Moss', 'Reed', 'Pearl', 'Star',
    'Moon', 'Sun', 'Sage', 'Clover', 'Breeze', 'Meadow', 'Pebble', 'Swan'];

  static String candidate(Random random) {
    final valid = <String>[
      for (final adjective in adjectives)
        for (final noun in nouns)
          if (adjective.length + noun.length <= 11) '$adjective$noun',
    ];
    return '${valid[random.nextInt(valid.length)]}${random.nextInt(100).toString().padLeft(2, '0')}';
  }

  static Future<String> currentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to post anonymously.');
    final db = FirebaseFirestore.instance;
    final ref = db.collection('anonymous_identities').doc(user.uid);
    final random = Random.secure();
    for (var attempt = 0; attempt < 100; attempt++) {
      final name = candidate(random);
      final result = await db.runTransaction<String?>((transaction) async {
        final existing = await transaction.get(ref);
        final data = existing.data();
        final saved = data?['displayName'] as String? ?? data?['name'] as String?;
        if (saved != null && !saved.startsWith('Neighbor-')) return saved;
        final claim = db.collection('anonymous_names').doc(name);
        if ((await transaction.get(claim)).exists) return null;
        final legacy = data?['name'] as String? ?? '';
        transaction.set(claim, {'legacyName': legacy});
        if (existing.exists) {
          transaction.update(ref, {'displayName': name});
        } else {
          transaction.set(ref, {'name': name});
        }
        return name;
      });
      if (result != null) return result;
    }
    throw StateError('Could not reserve an anonymous name. Please retry.');
  }

  static Future<Map<String, String>> legacyLabels() async {
    final snapshot = await FirebaseFirestore.instance.collection('anonymous_names')
        .where('legacyName', isNotEqualTo: '').get();
    return {for (final doc in snapshot.docs) doc.data()['legacyName'] as String: doc.id};
  }
}
