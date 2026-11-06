typedef DirectoryRead = Future<Map<String, dynamic>?> Function(String key);
typedef DirectorySearch = Future<List<Map<String, dynamic>>> Function(String prefix);

class DirectoryMember {
  const DirectoryMember({required this.uid, required this.username});
  final String uid;
  final String username;
}

/// Searches only public handles, never private user records or anonymous aliases.
class UsernameDirectory {
  const UsernameDirectory({
    required this.readClaim,
    required this.readProfile,
    required this.searchProfiles,
  });

  final DirectoryRead readClaim;
  final DirectoryRead readProfile;
  final DirectorySearch searchProfiles;

  static String normalize(String value) =>
      value.trim().replaceFirst(RegExp(r'^@+'), '').toLowerCase();

  Future<DirectoryMember?> findExact(String value) async {
    final query = normalize(value);
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(query)) return null;
    final claim = await readClaim(query);
    final uid = claim?['uid'];
    if (uid is! String || uid.isEmpty) return null;
    final profile = await readProfile(uid);
    // A username reservation remains usable while an older public profile
    // is repaired. Do not require the optional avatar document to exist.
    final username = profile?['username'] ?? claim?['username'] ?? query;
    if (username is! String || username.isEmpty) return null;
    return DirectoryMember(uid: uid, username: username);
  }

  Future<List<DirectoryMember>> search(String value, {String? excludeUid}) async {
    final query = normalize(value);
    if (!RegExp(r'^[a-z0-9_]{2,20}$').hasMatch(query)) return const [];
    final exact = await findExact(query);
    final profiles = await searchProfiles(query);
    final members = <String, DirectoryMember>{};
    if (exact != null && exact.uid != excludeUid) {
      members[exact.uid] = exact;
    }
    for (final profile in profiles) {
      final uid = profile['uid'];
      final username = profile['username'];
      if (uid is! String || uid.isEmpty || uid == excludeUid ||
          username is! String || !username.toLowerCase().startsWith(query)) {
        continue;
      }
      members.putIfAbsent(uid, () => DirectoryMember(uid: uid, username: username));
    }
    return members.values.take(20).toList();
  }
}
