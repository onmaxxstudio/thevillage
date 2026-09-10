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
