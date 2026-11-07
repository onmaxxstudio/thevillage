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
