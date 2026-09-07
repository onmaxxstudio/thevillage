import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final service = ProfileService();
  final usernameController = TextEditingController();
  VillageProfile? profile;
  bool loading = true;
  bool saving = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  Future<void> loadProfile() async {
    try {
      final loaded = await service.loadProfile();
      if (!mounted) return;
      usernameController.text = loaded.username;
      setState(() {
        profile = loaded;
        loading = false;
        loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = messageFor(error);
      });
    }
  }

  Future<void> saveUsername() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await service.updateUsername(usernameController.text);
      if (!mounted) return;
      await loadProfile();
      if (!mounted) return;
      showMessage('Your username was saved.');
    } catch (error) {
      if (mounted) showMessage(messageFor(error));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> requestEmailChange() async {
    final controller = TextEditingController(text: profile?.email ?? '');
    final newEmail = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Change email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New email address',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Send verification'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newEmail == null || newEmail.isEmpty) return;

    try {
      await service.requestEmailChange(newEmail);
      if (mounted) {
        showMessage(
          'Verification sent to $newEmail. Your email changes after verification.',
        );
      }
    } catch (error) {
      if (mounted) showMessage(messageFor(error));
    }
  }

  Future<void> sendPasswordReset() async {
    try {
      await service.sendPasswordReset();
      if (mounted) showMessage('Password reset email sent.');
    } catch (error) {
      if (mounted) showMessage(messageFor(error));
    }
  }

  Future<void> signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently removes your sign-in account and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await service.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (mounted) showMessage(messageFor(error));
    }
  }

  String messageFor(Object error) {
    if (error is UsernameTakenException) {
      return 'That username is already taken. Try another one.';
    }
    if (error is ProfileValidationException) return error.message;
    if (error is FirebaseAuthException &&
        error.code == 'requires-recent-login') {
      return 'For security, sign out, sign back in, and try again.';
    }
    return AuthService.messageFor(error);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 29,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : loadError != null
              ? _ErrorState(message: loadError!, onRetry: loadProfile)
              : SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                        children: [
                          _ProfileHeader(profile: profile!),
                          const SizedBox(height: 18),
                          _sectionTitle('Public profile'),
                          _card(
                            children: [
                              TextField(
                                controller: usernameController,
                                autocorrect: false,
                                maxLength: 20,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Choose your username',
                                  prefixText: '@',
                                  helperText:
                                      '3–20 letters, numbers, or underscores',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 50,
                                child: FilledButton.icon(
                                  onPressed: saving ? null : saveUsername,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: sage,
                                  ),
                                  icon: saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: Text(
                                    saving ? 'Saving...' : 'Save Username',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Private account information'),
                          _card(
                            children: [
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: paleSage,
                                  child: Icon(Icons.mail_outline, color: sage),
                                ),
                                title: const Text('Email'),
                                subtitle: Text(
                                  profile!.email.isEmpty
                                      ? 'No email available'
                                      : profile!.email,
                                ),
                                trailing: TextButton(
                                  onPressed: requestEmailChange,
                                  child: const Text('Change'),
                                ),
                              ),
                              const Divider(color: line),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: paleSage,
                                  child: Icon(Icons.lock_outline, color: sage),
                                ),
                                title: const Text('Password'),
                                subtitle:
                                    const Text('Send a password reset email'),
                                trailing: TextButton(
                                  onPressed: sendPasswordReset,
                                  child: const Text('Reset'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Safety and account'),
                          _card(
                            children: [
                              _actionTile(
                                icon: Icons.block_outlined,
                                title: 'Blocked accounts',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const BlockedAccountsScreen(),
                                  ),
                                ),
                              ),
                              const Divider(color: line),
                              _actionTile(
                                icon: Icons.logout_rounded,
                                title: 'Sign Out',
                                onTap: signOut,
                              ),
                              const Divider(color: line),
                              _actionTile(
                                icon: Icons.delete_outline_rounded,
                                title: 'Delete account',
                                color: Colors.red.shade700,
                                onTap: confirmDeleteAccount,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Your email stays private and is used only for your account and messages sent to you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: sage,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .65),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(children: children),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = sage,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right_rounded, color: color),
      onTap: onTap,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final VillageProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.username.isEmpty ? 'Village Member' : profile.username;
    final initial = name.substring(0, 1).toUpperCase();
    return Column(
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: _ProfileScreenState.paleSage,
          child: Text(
            initial,
            style: GoogleFonts.playfairDisplay(
              color: _ProfileScreenState.sage,
              fontSize: 38,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: GoogleFonts.playfairDisplay(
            color: _ProfileScreenState.ink,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Text('Your Village profile'),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class BlockedAccountsScreen extends StatelessWidget {
  const BlockedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ProfileService();
    return Scaffold(
      backgroundColor: _ProfileScreenState.cream,
      appBar: AppBar(title: const Text('Blocked accounts')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.blockedAccounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Blocked accounts could not be loaded.'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data!.docs;
          if (accounts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'You have not blocked anyone.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(18),
            itemCount: accounts.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final account = accounts[index];
              final username =
                  account.data()['username'] as String? ?? 'Village member';
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: _ProfileScreenState.paleSage,
                  child: Icon(Icons.person_outline),
                ),
                title: Text(username),
                trailing: TextButton(
                  onPressed: () => service.unblock(account.id),
                  child: const Text('Unblock'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
