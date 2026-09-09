import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityHubService {
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
