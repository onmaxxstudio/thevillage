import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunitySafetyScreen extends StatelessWidget {
  const CommunitySafetyScreen({super.key});

  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        title: Text(
          'Community & Safety',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 27,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                _hero(),
                const SizedBox(height: 16),
                _section(
                  'How we care for each other',
                  const [
                    ('Listen before fixing',
                        'Honor the kind of support a person requested.'),
                    ('Protect privacy',
                        'Do not share someone else’s name, location, messages, or story.'),
                    ('Respond with care',
                        'No harassment, hate, threats, shaming, scams, or dangerous advice.'),
                    ('Respect boundaries',
                        'No pressure to reply, explain, meet, donate, or move a conversation elsewhere.'),
                  ],
                ),
                const SizedBox(height: 16),
                _section(
                  'Your safety tools',
                  const [
                    ('Report',
                        'Use the three-dot menu on a post to send it for safety review.'),
                    ('Block',
                        'Blocking removes that person’s posts and replies from your view.'),
                    ('Trusted Circle',
                        'Only accept people you know and feel comfortable hearing from privately.'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8BE),
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.health_and_safety_outlined, color: sage),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Ask the Village offers peer support, not emergency, medical, legal, or professional care. If you or someone else may be in immediate danger, contact local emergency services now.',
                          style: TextStyle(height: 1.45, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () =>
                            launchUrl(Uri(scheme: 'tel', path: '988')),
                        icon: const Icon(Icons.call_outlined),
                        label: const Text('Call 988'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            launchUrl(Uri(scheme: 'sms', path: '988')),
                        icon: const Icon(Icons.sms_outlined),
                        label: const Text('Text 988'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => launchUrl(Uri(scheme: 'tel', path: '911')),
                  icon: const Icon(Icons.emergency_outlined),
                  label: const Text('Immediate danger? Call 911'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white, size: 40),
          const SizedBox(height: 9),
          Text(
            'A safe village is built together.',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Real support begins with kindness, consent, privacy, and clear boundaries.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<(String, String)> items) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: paleSage,
                child: Icon(Icons.check_rounded, color: sage, size: 19),
              ),
              title: Text(
                item.$1,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(item.$2),
            ),
            if (item != items.last) const Divider(color: line),
          ],
        ],
      ),
    );
  }
}
