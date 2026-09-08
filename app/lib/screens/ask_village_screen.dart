import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/village_navigation_scope.dart';
import 'post_preview_screen.dart';

class AskVillageScreen extends StatefulWidget {
  const AskVillageScreen({super.key});

  @override
  State<AskVillageScreen> createState() => _AskVillageScreenState();
}

class _AskVillageScreenState extends State<AskVillageScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF496B4F);
  static const gold = Color(0xFFC8A35E);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final questionController = TextEditingController();
  bool anonymous = false;
  bool needsSupport = false;
  String audience = 'The Village';
  String category = 'Relationships';

  static const categories = [
    'Relationships',
    'Mental Health',
    'Parenting',
    'Life & Growth',
    'Friendship',
    'Work & School',
    'Other',
  ];

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  void preview() {
    final question = questionController.text.trim();
    if (question.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a little more before previewing.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostPreviewScreen(
          post: VillagePostDraft(
            question: question,
            category: category,
            audience: audience,
            anonymous: anonymous,
            needsSupport: needsSupport,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: IconButton(
          onPressed: () =>
              VillageNavigationScope.of(context).onSelect(0),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          children: [
            Image.asset('assets/images/welcome_branch.png', height: 20),
            Text(
              'Ask the Village',
              style: GoogleFonts.playfairDisplay(
                color: sage,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => _notice('Drafts'),
            icon: const Icon(Icons.note_alt_outlined),
            label: const Text('Drafts'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                _section(
                  title: 'How would you like to ask?',
                  subtitle: 'You’re in control. Choose how you show up.',
                  child: Row(
                    children: [
                      Expanded(
                        child: _choiceCard(
                          selected: !anonymous,
                          icon: Icons.person_rounded,
                          title: 'Use my username',
                          subtitle: '@KindHeart',
                          onTap: () => setState(() => anonymous = false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _choiceCard(
                          selected: anonymous,
                          icon: Icons.visibility_off_outlined,
                          title: 'Anonymous Neighbor',
                          subtitle: 'Share anonymously',
                          onTap: () => setState(() => anonymous = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'Who can see your post?',
                  subtitle: 'You choose your audience.',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final option in ['My Circle', 'The Village', 'Both'])
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: _smallChoice(
                                  option,
                                  audience == option,
                                  () => setState(() => audience = option),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1DE),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Need Support Today?', style: TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: const Text('Let neighbors know you could use extra support.'),
                          secondary: const Icon(Icons.volunteer_activism_outlined, color: gold, size: 34),
                          activeThumbColor: sage,
                          value: needsSupport,
                          onChanged: (value) => setState(() => needsSupport = value),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'What’s your post about?',
                  subtitle: 'Choose the category that fits best.',
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final item in categories)
                        ChoiceChip(
                          label: Text(item),
                          selected: category == item,
                          selectedColor: const Color(0xFFE8EBDD),
                          side: BorderSide(color: category == item ? sage : line),
                          onSelected: (_) => setState(() => category = item),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _section(
                  title: 'What’s on your mind?',
                  subtitle: 'There’s no perfect way to ask. Just start where you are.',
                  child: Column(
                    children: [
                      TextField(
                        controller: questionController,
                        maxLength: 1500,
                        minLines: 6,
                        maxLines: 10,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Write your question or share what’s going on…',
                          filled: true,
                          fillColor: cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: line),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: sage, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _helper(Icons.auto_awesome_outlined, 'Help me find\nthe words'),
                          _helper(Icons.lightbulb_outline_rounded, 'Tips for a\ngreat post'),
                          _helper(Icons.content_copy_outlined, 'Examples from\nthe Village'),
                        ],
                      ),
                      const SizedBox(height: 13),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _attachment(Icons.photo_outlined, 'Photo'),
                          _attachment(Icons.videocam_outlined, 'Video'),
                          _attachment(Icons.mic_none_rounded, 'Voice'),
                          _attachment(Icons.poll_outlined, 'Poll'),
                          _attachment(Icons.location_on_outlined, 'Location'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F1E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, color: sage),
                      SizedBox(width: 10),
                      Expanded(child: Text('Your privacy matters. Never share private identifying information.')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _notice('Your draft'),
                        icon: const Icon(Icons.bookmark_border_rounded),
                        label: const Text('Save Draft'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: preview,
                        style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.all(16)),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Preview Post'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({required String title, required String subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .38),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12.5)),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _choiceCard({required bool selected, required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F3E9) : cream,
          border: Border.all(color: selected ? sage : line, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(backgroundColor: const Color(0xFFE5E7D9), child: Icon(icon, color: sage)),
                  const SizedBox(height: 9),
                  Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            if (selected) const Positioned(right: 0, top: 0, child: Icon(Icons.check_circle, color: sage)),
          ],
        ),
      ),
    );
  }

  Widget _smallChoice(String title, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 89,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F3E9) : cream,
          border: Border.all(color: selected ? sage : line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, color: selected ? sage : gold),
            const SizedBox(height: 4),
            FittedBox(child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  Widget _helper(IconData icon, String text) {
    return Expanded(
      child: InkWell(
        onTap: () => _notice(text.replaceAll('\n', ' ')),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Column(children: [Icon(icon, color: gold, size: 21), Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))]),
        ),
      ),
    );
  }

  Widget _attachment(IconData icon, String label) {
    return InkWell(
      onTap: () => _notice(label),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(children: [Icon(icon, color: sage), Text(label, style: const TextStyle(fontSize: 9.5))]),
      ),
    );
  }

  void _notice(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature will be available as we build the next features.')));
  }
}
