import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'community_safety_screen.dart';
import 'legal_screen.dart';
import 'profile_screen.dart';
import 'village_admin_screen.dart';

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
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    final values = await Future.wait([
      preferences.getBool('setting_reply_notifications'),
      preferences.getBool('setting_circle_notifications'),
      preferences.getBool('setting_checkin_notifications'),
    ]);
    if (!mounted) return;
    setState(() { replies = values[0] ?? true; circleRequests = values[1] ?? true; checkInReminders = values[2] ?? true; loading = false; });
  }

  Future<void> update(String key, bool value) => preferences.setBool(key, value);

  Widget section(String title, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: GoogleFonts.playfairDisplay(color: sage, fontSize: 23, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8), child, const SizedBox(height: 22),
  ]);

  Widget card(Widget child, {Color? color}) => Card(elevation: 0, color: color ?? Colors.white.withValues(alpha: .58), shape: RoundedRectangleBorder(side: const BorderSide(color: line), borderRadius: BorderRadius.circular(18)), child: child);

  Widget settingSwitch(String title, String subtitle, bool value, ValueChanged<bool> changed) => SwitchListTile(title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), value: value, activeThumbColor: sage, onChanged: changed);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(backgroundColor: cream, title: Text('Settings', style: GoogleFonts.playfairDisplay(color: sage, fontSize: 28, fontWeight: FontWeight.w600))),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          section('Village management', card(ListTile(
            leading: const CircleAvatar(backgroundColor: paleSage, child: Icon(Icons.admin_panel_settings_outlined, color: sage)),
            title: const Text('Village Admin', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text('Create and edit communities, resources and events without touching code.'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VillageAdminScreen())),
          ), color: paleSage)),
          section('Notifications', card(Column(children: [
            settingSwitch('Replies and support', 'Updates on your Village posts and comments.', replies, (v) { setState(() => replies = v); update('setting_reply_notifications', v); }),
            const Divider(height: 1),
            settingSwitch('Circle requests', 'Requests and activity from trusted people.', circleRequests, (v) { setState(() => circleRequests = v); update('setting_circle_notifications', v); }),
            const Divider(height: 1),
            settingSwitch('Daily check-in reminder', 'A gentle reminder to record how you feel.', checkInReminders, (v) { setState(() => checkInReminders = v); update('setting_checkin_notifications', v); }),
          ]))),
          section('Privacy & legal', card(Column(children: [
            ListTile(leading: const Icon(Icons.privacy_tip_outlined, color: sage), title: const Text('Privacy Policy'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LegalScreen(document: LegalDocument.privacy)))),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.description_outlined, color: sage), title: const Text('Terms of Use'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const LegalScreen(document: LegalDocument.terms)))),
          ]))),
          section('Account', card(ListTile(
            leading: const Icon(Icons.person_outline_rounded, color: sage),
            title: const Text('Profile and account', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Username, email, password, blocked accounts and sign out.'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
          ), color: paleSage)),
          section('Community', card(ListTile(
            leading: const Icon(Icons.shield_outlined, color: sage),
            title: const Text('Community and safety', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Guidelines, privacy reminders and safety tools.'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const CommunitySafetyScreen())),
          ))),
        ],
      ),
    );
  }
}