import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityHubService {
  bool get _cloudReady =>
      Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  String get _ownerKey =>
      FirebaseAuth.instance.currentUser?.uid ?? 'signed-out-preview';

  String _key(String type) => 'community_hub.$_ownerKey.$type';


  // Document IDs are canonical slugs: concurrent creates cannot claim the same name.
  static String communitySlug(String name) => name.toLowerCase().trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key('joined'))?.toSet() ?? <String>{};
  }

  Future<void> saveJoinedCommunities(Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();
    await preferences.setStringList(_key('joined'), sorted);
  }

  Future<Map<String, int>> memberCounts(Iterable<String> communityIds) async {
    final ids = communityIds.toList();
    final counts = <String, int>{};
    for (final id in ids) {
      counts[id] = 0;
    }
    if (!_cloudReady) return counts;
    await Future.wait(ids.map((id) async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('community_members')
            .doc(id)
            .collection('members')
            .count()
            .get()
            .timeout(const Duration(seconds: 3));
        counts[id] = snapshot.count ?? 0;
      } on Object {
        // Keep a trustworthy zero rather than inventing a member count.
      }
    }));
    return counts;
  }

  Future<void> setCommunityMembership(String communityId, bool joined) async {
    if (!_cloudReady) return;
    final user = FirebaseAuth.instance.currentUser!;
    final reference = FirebaseFirestore.instance
        .collection('community_members')
        .doc(communityId)
        .collection('members')
        .doc(user.uid);
    try {
      if (joined) {
        await reference.set({
          'uid': user.uid,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await reference.delete();
      }
    } on FirebaseException {
      // Local membership still works when cloud permissions are unavailable.
    }
  }

  Future<Set<String>> savedResources() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key('saved_resources'))?.toSet() ??
        <String>{};
  }

  Future<void> saveResources(Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();
    await preferences.setStringList(_key('saved_resources'), sorted);
  }

  Future<Set<String>> usedSuggestedQuestions() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences
            .getStringList(_key('used_suggested_questions'))
            ?.toSet() ??
        <String>{};
  }

  Future<void> markSuggestedQuestionUsed(String suggestionId) async {
    final preferences = await SharedPreferences.getInstance();
    final used = preferences
            .getStringList(_key('used_suggested_questions'))
            ?.toSet() ??
        <String>{};
    used.add(suggestionId);
    final sorted = used.toList()..sort();
    await preferences.setStringList(
      _key('used_suggested_questions'),
      sorted,
    );
  }

  Future<Set<String>> registeredEvents() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key('registered_events'))?.toSet() ??
        <String>{};
  }

  Future<void> saveRegisteredEvents(Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();
    await preferences.setStringList(_key('registered_events'), sorted);
  }
}
), '');

  Future<List<Map<String, dynamic>>> memberCommunities() async {
    if (!_cloudReady) return [];
    final snapshot = await FirebaseFirestore.instance
        .collection('member_communities').limit(100).get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<void> createMemberCommunity({
    required String name,
    required String description,
    required String purpose,
    required Set<String> reservedSlugs,
  }) async {
    if (!_cloudReady) throw StateError('Sign in to create a community.');
    final slug = communitySlug(name);
    if (slug.length < 3 || slug.length > 40 || reservedSlugs.contains(slug)) {
      throw StateError('This name is unavailable. Try a more specific name.');
    }
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final collection = FirebaseFirestore.instance.collection('member_communities');
    final ref = collection.doc(slug);
    final slots = List.generate(3, (index) => FirebaseFirestore.instance
        .collection('member_community_slots').doc('${uid}_$index'));
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        throw StateError('This community already exists. Join it instead.');
      }
      final usedSlots = <bool>[];
      for (final slot in slots) {
        usedSlots.add((await transaction.get(slot)).exists);
      }
      final available = usedSlots.indexOf(false);
      if (available == -1) {
        throw StateError('You can create up to 3 communities for now.');
      }
      transaction.set(slots[available], {
        'uid': uid,
        'slug': slug,
        'slot': available,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.set(ref, {
        'name': name.trim(),
        'description': description.trim(),
        'purpose': purpose.trim(),
        'creatorUid': uid,
        'slot': available,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    });
  }

  Future<Set<String>> joinedCommunities() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key('joined'))?.toSet() ?? <String>{};
  }

  Future<void> saveJoinedCommunities(Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();
    await preferences.setStringList(_key('joined'), sorted);
  }

  Future<Map<String, int>> memberCounts(Iterable<String> communityIds) async {
    final ids = communityIds.toList();
    final counts = <String, int>{};
    for (final id in ids) {
      counts[id] = 0;
    }
    if (!_cloudReady) return counts;
    await Future.wait(ids.map((id) async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('community_members')
            .doc(id)
            .collection('members')
            .count()
            .get()
            .timeout(const Duration(seconds: 3));
        counts[id] = snapshot.count ?? 0;
      } on Object {
        // Keep a trustworthy zero rather than inventing a member count.
      }
    }));
    return counts;
  }

  Future<void> setCommunityMembership(String communityId, bool joined) async {
    if (!_cloudReady) return;
    final user = FirebaseAuth.instance.currentUser!;
    final reference = FirebaseFirestore.instance
        .collection('community_members')
        .doc(communityId)
        .collection('members')
        .doc(user.uid);
    try {
      if (joined) {
        await reference.set({
          'uid': user.uid,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await reference.delete();
      }
    } on FirebaseException {
      // Local membership still works when cloud permissions are unavailable.
    }
  }

  Future<Set<String>> savedResources() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key('saved_resources'))?.toSet() ??
        <String>{};
  }

  Future<void> saveResources(Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();
    await preferences.setStringList(_key('saved_resources'), sorted);
  }

  Future<Set<String>> usedSuggestedQuestions() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences
            .getStringList(_key('used_suggested_questions'))
            ?.toSet() ??
        <String>{};
  }

  Future<void> markSuggestedQuestionUsed(String suggestionId) async {
    final preferences = await SharedPreferences.getInstance();
    final used = preferences
            .getStringList(_key('used_suggested_questions'))
            ?.toSet() ??
        <String>{};
    used.add(suggestionId);
    final sorted = used.toList()..sort();
    await preferences.setStringList(
      _key('used_suggested_questions'),
      sorted,
    );
  }

  Future<Set<String>> registeredEvents() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key('registered_events'))?.toSet() ??
        <String>{};
  }

  Future<void> saveRegisteredEvents(Set<String> values) async {
    final preferences = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();
    await preferences.setStringList(_key('registered_events'), sorted);
  }
}
