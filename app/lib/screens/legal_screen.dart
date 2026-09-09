import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LegalDocument { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);

  @override
  Widget build(BuildContext context) {
    final privacy = document == LegalDocument.privacy;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: Text(privacy ? 'Privacy Policy' : 'Terms of Use')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 36),
          children: [
            Text(
              privacy ? 'Your privacy in the Village' : 'Using Ask the Village',
              style: GoogleFonts.playfairDisplay(
                color: sage,
                fontSize: 31,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text('Effective September 9, 2026'),
            const SizedBox(height: 22),
            for (final item in privacy ? _privacySections : _termsSections)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: sage,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(item.$2, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static const _privacySections = [
    ('Information we use', 'We use your sign-in details, username, posts, replies, Circle activity, reports, and settings to operate the app. Your email is private and used for account communication.'),
    ('Private information', 'Daily check-ins and private Circle messages are visible only through your account and the people involved. Do not share another person’s private information.'),
    ('Safety and moderation', 'Reports may be reviewed to protect the community, enforce guidelines, prevent abuse, and respond to valid legal or safety requests.'),
    ('Your choices', 'You can change your username, manage notifications, block accounts, request a copy of your information, and delete your account from Profile.'),
    ('Data protection', 'We use Firebase authentication and database security rules. No online service can promise absolute security, so use a unique password and share only what feels safe.'),
  ];

  static const _termsSections = [
    ('Peer support—not professional care', 'Ask the Village connects people for community support. It does not provide emergency, medical, mental-health, legal, or financial services.'),
    ('Community conduct', 'Do not harass, threaten, shame, discriminate, scam, impersonate, expose private information, or pressure people to meet, pay, or move conversations elsewhere.'),
    ('Your content', 'You are responsible for what you post. You keep ownership of your content and allow the app to display it to the audience you selected.'),
    ('Moderation', 'Content or accounts may be limited or removed when necessary for safety, legal compliance, or enforcement of these terms.'),
    ('Account responsibility', 'Keep your sign-in secure, use accurate account information, and report unauthorized access. You may delete your account from Profile.'),
  ];
}
