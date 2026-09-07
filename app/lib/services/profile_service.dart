import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VillageProfile {
  const VillageProfile({
    required this.uid,
    required this.username,
    required this.email,
  });

  final String uid;
  final String username;
  final String email;
}

class UsernameLookup {
  const UsernameLookup({
    required this.uid,
    required this.username,
    required this.email,
  });

  final String uid;
  final String username;
  final String email;

  dynamic operator [](String key) {
    switch (key) {
      case 'uid':
        return uid;
      case 'username':
        return username;
      case 'email':
        return email;
      default:
        return null;
    }
  }

  @override
  String toString() => username;
}

class BlockedAccount {
  const BlockedAccount({required this.uid, required this.username});

  final String uid;
  final String username;
}

class ProfileService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('You must be signed in.');
    return user;
  }

  /// Backward-compatible helper used by Village posts and questions.
  static Future<String?> currentUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName?.trim();
    return username == null || username.isEmpty ? null : username;
  }

  /// Backward-compatible helper used by the Circle username search.
  ///
  /// Firebase Authentication cannot search every account by display name, so
  /// this safely resolves the signed-in member while keeping existing screens
  /// working. A server-side username directory can be connected later.
  static Future<dynamic> findUsername(String value) async {
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return null;

    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName?.trim() ?? '';
    if (user == null || username.toLowerCase() != query) return null;

    return UsernameLookup(
      uid: user.uid,
      username: username,
      email: user.email ?? '',
    );
  }

  Future<VillageProfile> loadProfile() async {
    final user = _user;
    await user.reload();
    final refreshedUser = _auth.currentUser ?? user;
    return VillageProfile(
      uid: refreshedUser.uid,
      username: refreshedUser.displayName?.trim() ?? '',
      email: refreshedUser.email ?? '',
    );
  }

  Future<void> updateUsername(String value) async {
    final username = value.trim();
    if (!RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(username)) {
      throw const ProfileValidationException(
        'Use 3–20 letters, numbers, or underscores.',
      );
    }
    await _user.updateDisplayName(username);
    await _user.reload();
  }

  Future<void> requestEmailChange(String newEmail) async {
    final email = newEmail.trim();
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      throw const ProfileValidationException('Enter a valid email address.');
    }
    await _user.verifyBeforeUpdateEmail(email);
  }

  Future<void> sendPasswordReset() async {
    final email = _user.email;
    if (email == null || email.isEmpty) {
      throw const ProfileValidationException(
        'This account does not use an email password.',
      );
    }
    await _auth.sendPasswordResetEmail(email: email);
  }

  String get _blockedKey => 'blocked_accounts_${_user.uid}';

  Future<List<BlockedAccount>> blockedAccounts() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_blockedKey) ?? const <String>[];
    return saved.map((entry) {
      final separator = entry.indexOf('|');
      if (separator == -1) {
        return BlockedAccount(uid: entry, username: 'Village member');
      }
      return BlockedAccount(
        uid: entry.substring(0, separator),
        username: entry.substring(separator + 1),
      );
    }).toList();
  }

  Future<void> unblock(String blockedUserId) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getStringList(_blockedKey) ?? <String>[];
    saved.removeWhere(
      (entry) => entry == blockedUserId || entry.startsWith('$blockedUserId|'),
    );
    await preferences.setStringList(_blockedKey, saved);
  }

  Future<void> deleteAccount() => _user.delete();
}

class ProfileValidationException implements Exception {
  const ProfileValidationException(this.message);
  final String message;
}
