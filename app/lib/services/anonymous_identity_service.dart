import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnonymousIdentityService {
  static bool isAlias(String name) => name.startsWith('Neighbor-');

  static Future<String> currentName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Sign in to post anonymously.');
    final db = FirebaseFirestore.instance;
    final ref = db.collection('anonymous_identities').doc(user.uid);
    return db.runTransaction<String>((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) return existing.data()!['name'] as String;
      final random = Random.secure();
      final token = List.generate(16, (_) => random.nextInt(256)
          .toRadixString(16).padLeft(2, '0')).join();
      final name = 'Neighbor-$token';
      transaction.set(ref, {'name': name});
      return name;
    });
  }
}
