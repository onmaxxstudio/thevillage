import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// About and contact destination shared by the app's navigation drawers.
class AboutContactScreen extends StatelessWidget {
  const AboutContactScreen({super.key});

  static const _sage = Color(0xFF355C3B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFAF1),
        foregroundColor: _sage,
        title: const Text('About & Contact'),
      ),
      body: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF0F1E2), Color(0xFFFFFAF1)]),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(children: [
                      const Icon(Icons.diversity_1_outlined, size: 52, color: _sage),
                      const SizedBox(height: 12),
                      Text('Everyone deserves a village.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: _sage, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      const Text('REAL PEOPLE.  REAL SUPPORT.  REAL ANSWERS.',
                        textAlign: TextAlign.center, style: TextStyle(color: _sage, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.7)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFE0E5D7))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(24)),
                        child: const Text('About Ask the Village', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 20),
                      const Text('Ask the Village is a community where people share, learn, and grow together—because no one should have to navigate life’s different seasons alone.\n\nHere, your neighbors’ experiences become shared wisdom. Learn from their mistakes, find encouragement in their wins, and share the lessons you’ve gathered along the way. Your story might be the support someone else needs.',
                        style: TextStyle(fontSize: 16, height: 1.55, color: Color(0xFF172019))),
                      const SizedBox(height: 18),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _valueChip(Icons.forum_outlined, 'Honest Conversations'),
                        _valueChip(Icons.favorite_border, 'Real Support'),
                        _valueChip(Icons.menu_book_outlined, 'Shared Learning'),
                        _valueChip(Icons.spa_outlined, 'A Welcoming Space'),
                      ]),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFF0F2E9), borderRadius: BorderRadius.circular(20)),
                        child: const Text('We make room for honest conversations, including the topics too often left unspoken. Come with your questions, your struggles, your small victories, and your unfinished chapters.',
                          style: TextStyle(fontSize: 16, height: 1.55, color: Color(0xFF172019))),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(18)),
                        child: const Text('You don’t have to pretend you’re okay just because you’re capable. You deserve support, too.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 17, height: 1.5)),
                      ),
                      const SizedBox(height: 18),
                      const Text('Everyone deserves a village. Welcome to yours.',
                        textAlign: TextAlign.center, style: TextStyle(color: _sage, fontWeight: FontWeight.w600, fontSize: 17)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  const _FounderSection(),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(24)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.mail_outline_rounded, color: Color(0xFFF5E4AC), size: 30),
                        SizedBox(width: 12),
                        Text('Contact Us', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 23)),
                      ]),
                      const SizedBox(height: 12),
                      const Text('Have a question, need technical support, want to share feedback, or interested in partnering with Ask the Village?',
                        style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE4ECD7), foregroundColor: _sage),
                        onPressed: () => _emailSupport(context),
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('support@askthevillage.app'),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(const ClipboardData(text: 'support@askthevillage.app'));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email address copied.')));
                        },
                        icon: const Icon(Icons.copy_outlined, color: Colors.white),
                        label: const Text('Copy email address', style: TextStyle(color: Colors.white)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _valueChip(IconData icon, String title) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: const Color(0xFFF0F2E9), borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: _sage, size: 18), const SizedBox(width: 7),
      Text(title, style: const TextStyle(color: _sage, fontWeight: FontWeight.w600)),
    ]),
  );

  Future<void> _emailSupport(BuildContext context) async {
    try {
      final opened = await launchUrl(
        Uri(scheme: 'mailto', path: 'support@askthevillage.app'),
      );
      if (opened) return;
    } catch (_) {
      // Keep the visible address and copy action available without a mail app.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Unable to open your email app. Copy the email address to contact us.',
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _sage,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF172019),
            ),
          ),
        ],
      ),
    );
  }
}

class _FounderSection extends StatelessWidget {
  const _FounderSection();

  static const _sage = Color(0xFF355C3B);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('founder-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2E9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE3D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Meet the Founder',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _sage,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 550;
              final portrait = SizedBox(
                key: const ValueKey('founder-portrait'),
                width: sideBySide ? 210 : 240,
                height: (sideBySide ? 210 : 240) * 1250 / 1086,
                child: kIsWeb
                    ? Image.network(
                        Uri.base
                            .resolve('assets/assets/images/ariel-founder.webp')
                            .toString(),
                        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                        fit: BoxFit.contain,
                        semanticLabel:
                            'Ariel Mitchell, founder of Ask the Village',
                      )
                    : Image.asset(
                        'assets/images/ariel-founder.webp',
                        fit: BoxFit.contain,
                        semanticLabel:
                            'Ariel Mitchell, founder of Ask the Village',
                      ),
              );
              final message = Column(
                key: const ValueKey('founder-message'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ariel Mitchell',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _sage,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Founder of Ask the Village',
                    style: TextStyle(fontSize: 14, height: 1.5, color: _sage),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    '“I created Ask the Village because I believe no one should '
                    'have to navigate every season of life alone. Sometimes we '
                    'don’t need someone to fix everything. We just need somewhere '
                    'to be heard, understood, and reminded that we’re not alone.”',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.65,
                      color: Color(0xFF172019),
                    ),
                  ),
                ],
              );
              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    portrait,
                    const SizedBox(width: 28),
                    Expanded(child: message),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: portrait),
                  const SizedBox(height: 24),
                  message,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
