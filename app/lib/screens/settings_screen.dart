import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/village_navigation_scope.dart';
import 'community_safety_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const line = Color(0xFFE3D8C9);

  final preferences = SharedPreferencesAsync();
  bool replies = true;
  bool circleRequests = true;
  bool checkInReminders = true;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final values = await Future.wait([
      preferences.getBool('setting_reply_notifications'),
      preferences.getBool('setting_circle_notifications'),
      preferences.getBool('setting_checkin_notifications'),
    ]);
    if (!mounted) return;
    setState(() {
      replies = values[0] ?? true;
      circleRequests = values[1] ?? true;
      checkInReminders = values[2] ?? true;
      loading = false;
    });
  }

  Future<void> update(String key, bool value) async {
    await preferences.setBool(key, value);
  }

  Widget settingSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      value: value,
      activeThumbColor: sage,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        title: Text(
          'Settings',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              children: [
                Text(
                  'Notifications',
                  style: GoogleFonts.playfairDisplay(
                    color: sage,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Colors.white.withValues(alpha: .58),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      settingSwitch(
                        title: 'Replies and support',
                        subtitle: 'Updates on your Village posts and comments.',
                        value: replies,
                        onChanged: (value) {
                          setState(() => replies = value);
                          update('setting_reply_notifications', value);
                        },
                      ),
                      const Divider(height: 1),
                      settingSwitch(
                        title: 'Circle requests',
                        subtitle: 'Requests and activity from trusted people.',
                        value: circleRequests,
                        onChanged: (value) {
                          setState(() => circleRequests = value);
                          update('setting_circle_notifications', value);
                        },
                      ),
                      const Divider(height: 1),
                      settingSwitch(
                        title: 'Daily check-in reminder',
                        subtitle: 'A gentle reminder to record how you feel.',
                        value: checkInReminders,
                        onChanged: (value) {
                          setState(() => checkInReminders = value);
                          update('setting_checkin_notifications', value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Account',
                  style: GoogleFonts.playfairDisplay(
                    color: sage,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: paleSage,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person_outline_rounded, color: sage),
                    title: const Text(
                      'Profile and account',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Username, email, password, blocked accounts and sign out.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () =>
                        VillageNavigationScope.of(context).onSelect(4),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Community',
                  style: GoogleFonts.playfairDisplay(
                    color: sage,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Colors.white.withValues(alpha: .58),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: line),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.shield_outlined, color: sage),
                    title: const Text(
                      'Community and safety',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Guidelines, privacy reminders and safety tools.',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CommunitySafetyScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
