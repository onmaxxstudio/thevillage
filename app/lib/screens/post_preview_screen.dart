import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/village_navigation_scope.dart';
import '../services/village_post_service.dart';

class VillagePostDraft {
  const VillagePostDraft({
    required this.question,
    required this.category,
    required this.audience,
    required this.anonymous,
    required this.needsSupport,
    required this.supportIntent,
    required this.username,
  });

  final String question;
  final String category;
  final String audience;
  final bool anonymous;
  final bool needsSupport;
  final String supportIntent;
  final String username;
}

class PostPreviewScreen extends StatelessWidget {
  const PostPreviewScreen({super.key, required this.post});

  final VillagePostDraft post;
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF496B4F);
  static const gold = Color(0xFFC8A35E);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  @override
  Widget build(BuildContext context) {
    final name = post.anonymous ? 'Anonymous Neighbor' : '@${post.username}';
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
        title: Text('Preview Your Post', style: GoogleFonts.playfairDisplay(color: ink, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
              children: [
                const Text('This is how others will see it.', textAlign: TextAlign.center),
                const SizedBox(height: 17),
                Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .48), border: Border.all(color: line), borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(17),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFE5E7D9),
                              child: Icon(post.anonymous ? Icons.visibility_off_outlined : Icons.person_rounded, color: sage),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Posting as\n$name', style: const TextStyle(fontWeight: FontWeight.w700))),
                            const Icon(Icons.groups_outlined, color: sage),
                            const SizedBox(width: 7),
                            Text('Audience\n${post.audience}', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(19),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Chip(
                              avatar: const Icon(Icons.favorite_border_rounded, size: 17),
                              label: Text(post.category),
                              side: BorderSide.none,
                              backgroundColor: const Color(0xFFF1EEE4),
                            ),
                            const SizedBox(height: 7),
                            Chip(
                              avatar: const Icon(
                                Icons.volunteer_activism_outlined,
                                size: 17,
                              ),
                              label: Text('Looking for: ${post.supportIntent}'),
                              side: BorderSide.none,
                              backgroundColor: const Color(0xFFE8EBDD),
                            ),
                            const SizedBox(height: 10),
                            Text(post.question, style: const TextStyle(fontSize: 20, height: 1.4, fontWeight: FontWeight.w700)),
                            if (post.needsSupport) ...[
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: const Color(0xFFFFEAE7), borderRadius: BorderRadius.circular(15)),
                                child: const Row(
                                  children: [
                                    Icon(Icons.volunteer_activism_outlined, color: gold),
                                    SizedBox(width: 10),
                                    Expanded(child: Text('Need support today\nThis neighbor could use extra support.', style: TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(color: const Color(0xFFF3F1E8), borderRadius: BorderRadius.circular(18)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.shield_outlined, color: sage), SizedBox(width: 8), Text('A reminder about privacy', style: TextStyle(fontWeight: FontWeight.w700))]),
                      SizedBox(height: 10),
                      Text('• Don’t share names or identifying details.\n• Avoid sharing locations or private information.\n• Be kind. We’re all in this together.', style: TextStyle(height: 1.6)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    await VillagePostService().publish(
                      question: post.question,
                      category: post.category,
                      audience: post.audience,
                      anonymous: post.anonymous,
                      needsSupport: post.needsSupport,
                      supportIntent: post.supportIntent,
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => PostSubmittedScreen(post: post),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.all(17)),
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.send_outlined),
                  label: Text('Post to ${post.audience}'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Edit Post')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PostSubmittedScreen extends StatelessWidget {
  const PostSubmittedScreen({super.key, required this.post});

  final VillagePostDraft post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PostPreviewScreen.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Image.asset('assets/images/welcome_branch.png', height: 40),
                  const SizedBox(height: 20),
                  const CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0xFFE8EBDD),
                    child: Icon(Icons.check_rounded, color: PostPreviewScreen.sage, size: 48),
                  ),
                  const SizedBox(height: 18),
                  Text('Your village heard you.', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(color: PostPreviewScreen.sage, fontSize: 34, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Your post has been shared. You’re never alone here.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .48), border: Border.all(color: PostPreviewScreen.line), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.category, style: const TextStyle(color: PostPreviewScreen.sage, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(
                          'Looking for ${post.supportIntent.toLowerCase()}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 9),
                        Text(post.question, style: const TextStyle(fontSize: 18, height: 1.4, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Text('Shared with ${post.audience}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () =>
                          VillageNavigationScope.of(context).onSelect(3),
                      style: FilledButton.styleFrom(
                        backgroundColor: PostPreviewScreen.sage,
                        padding: const EdgeInsets.all(17),
                      ),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('View in the Village'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          VillageNavigationScope.of(context).onSelect(0),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Return Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
