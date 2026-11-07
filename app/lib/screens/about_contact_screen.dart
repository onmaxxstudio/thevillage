import 'package:flutter/material.dart';
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.diversity_1_outlined, size: 44, color: _sage),
                const SizedBox(height: 20),
                Text('Everyone deserves a village.',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: _sage, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text('Real people. Real support. Real answers.',
                    style: TextStyle(fontSize: 17, height: 1.5, color: _sage)),
                const SizedBox(height: 28),
                _section(context, 'About Ask the Village',
                    'Ask the Village is a community where people share, learn, and grow together—because no one should have to navigate life’s different seasons alone.\n\n'
                    'Here, your neighbors’ experiences become shared wisdom. Learn from their mistakes, find encouragement in their wins, and share the lessons you’ve gathered along the way. Your story might be the support someone else needs.\n\n'
                    'We make room for honest conversations, including the topics too often left unspoken. Come with your questions, your struggles, your small victories, and your unfinished chapters.\n\n'
                    'You don’t have to pretend you’re okay just because you’re capable. You deserve support, too.\n\n'
                    'Everyone deserves a village. Welcome to yours.'),
                const SizedBox(height: 12),
                const _FounderSection(),
                const Divider(height: 36),
                _section(context, 'Contact us',
                    'Have a question, need technical support, want to share '
                    'feedback, or interested in partnering with Ask the Village?'),
                SelectableText('support@askthevillage.app',
                    style: const TextStyle(fontSize: 16, height: 1.6,
                        color: _sage)),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _sage),
                  onPressed: () => _emailSupport(context),
                  icon: const Icon(Icons.mail_outline_rounded),
                  label: const Text('Email support'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(
                        text: 'support@askthevillage.app'));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email address copied.')),
                    );
                  },
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy email address'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _emailSupport(BuildContext context) async {
    try {
      final opened = await launchUrl(Uri(
        scheme: 'mailto',
        path: 'support@askthevillage.app',
      ));
      if (opened) return;
    } catch (_) {
      // Keep the visible address and copy action available without a mail app.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Unable to open your email app. Copy the email address to contact us.'),
    ));
  }

  Widget _section(BuildContext context, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _sage, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(body, style: const TextStyle(fontSize: 16, height: 1.6,
              color: Color(0xFF172019))),
        ],
      ),
    );
  }
}

/// Kept local to About so the founder layout cannot affect other destinations.
class _FounderSection extends StatelessWidget {
  const _FounderSection();

  @override
  Widget build(BuildContext context) {
    const sage = Color(0xFF355C3B);
    return Container(
      key: const ValueKey('founder-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2E8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD8E1D1)),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final sideBySide = constraints.maxWidth >= 540;
        final photo = SizedBox(
          key: const ValueKey('founder-photo'),
          width: sideBySide ? 210 : 240,
          child: Image.asset(
            'assets/images/ariel-mitchell-founder.png',
            fit: BoxFit.contain,
            semanticLabel: 'Ariel Mitchell, founder of Ask the Village',
          ),
        );
        final message = Column(
          key: const ValueKey('founder-message'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Meet the Founder',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: sage, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const Text('Ariel Mitchell | Founder of Ask the Village',
                style: TextStyle(color: sage, fontSize: 16,
                    fontWeight: FontWeight.w600, height: 1.5)),
            const SizedBox(height: 18),
            const Text(
              '“I created Ask the Village because I believe no one should have to navigate every season of life alone. Sometimes we don’t need someone to fix everything. We just need somewhere to be heard, understood, and reminded that we’re not alone.”',
              style: TextStyle(fontSize: 16, height: 1.65,
                  color: Color(0xFF172019)),
            ),
          ],
        );
        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [photo, const SizedBox(width: 28), Expanded(child: message)],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Center(child: photo), const SizedBox(height: 24), message],
        );
      }),
    );
  }
}
