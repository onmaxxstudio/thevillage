import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/personalization_service.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key, this.onComplete});
  final ValueChanged<OnboardingDestination>? onComplete;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class OnboardingDestination {
  const OnboardingDestination.explore()
      : startAsking = false, communityId = null, communityName = null;
  final bool startAsking;
  final String? communityId;
  final String? communityName;
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const blush = Color(0xFFF3E2DD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final service = PersonalizationService();
  int step = 0;
  bool loading = true;
  bool saving = false;
  final Set<String> goals = {};
  final Set<String> topics = {};

  static const goalOptions = <(String, String, IconData)>[
    ('Someone who gets it', 'Connect with people who understand where you are.', Icons.chat_bubble_outline_rounded),
    ('Real advice', 'Get perspective from people who have actually lived it.', Icons.lightbulb_outline_rounded),
    ('My kind of people', 'Find conversations and communities that feel like you.', Icons.groups_2_outlined),
    ('A place to help', 'Share what you have learned with someone who needs it.', Icons.volunteer_activism_outlined),
    ('I’m just looking around', 'Explore the Village at your own pace.', Icons.explore_outlined),
  ];

  static const topicOptions = <(String, String, IconData)>[
    ('Relationships', 'Relationships', Icons.favorite_border_rounded),
    ('Motherhood', 'Parenting', Icons.family_restroom_rounded),
    ('Men’s support', 'Men', Icons.man_rounded),
    ('Women’s support', 'Women', Icons.woman_rounded),
    ('Faith', 'Faith', Icons.auto_awesome_outlined),
    ('Friendship', 'Friendship', Icons.people_outline_rounded),
    ('Career & purpose', 'Work & Money', Icons.work_outline_rounded),
    ('Mental wellness', 'Life & Wellness', Icons.spa_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await service.load();
    if (!mounted) return;
    if (saved.completed) topics.addAll(saved.interests);
    setState(() => loading = false);
  }

  void _toggleGoal(String value) {
    setState(() {
      if (goals.contains(value)) {
        goals.remove(value);
      } else if (goals.length < 2) {
        goals.add(value);
      }
    });
  }

  void _toggleTopic(String value) {
    setState(() {
      if (topics.contains(value)) {
        topics.remove(value);
      } else if (topics.length < 3) {
        topics.add(value);
      }
    });
  }

  Future<void> _finish() async {
    if (saving) return;
    setState(() => saving = true);
    await service.save(VillagePersonalization(
      identity: '',
      interests: topics.toList(),
      periodTracking: false,
      completed: true,
    ));
    if (!mounted) return;
    widget.onComplete?.call(const OnboardingDestination.explore());
    if (widget.onComplete == null) Navigator.of(context).pop(true);
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        children: [
          Image.asset('assets/images/welcome_branch.png', height: 22),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Ask the Village',
              style: GoogleFonts.playfairDisplay(
                color: sage,
                fontSize: 31,
                height: 1,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Real People. Real Support. Real Answers.',
            style: GoogleFonts.inter(fontSize: 10, color: ink),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(child: CircularProgressIndicator(color: sage)),
      );
    }
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              children: [
                _header(),
                Expanded(child: step == 0 ? _goalStep() : _topicStep()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
      children: [
        Text(
          'What are you hoping to find here?',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose up to 2. This helps us show you more of what matters to you.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ink, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 22),
        for (final option in goalOptions) ...[
          _choiceCard(
            title: option.$1,
            subtitle: option.$2,
            icon: option.$3,
            selected: goals.contains(option.$1),
            onTap: () => _toggleGoal(option.$1),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => setState(() => step = 1),
            style: FilledButton.styleFrom(
              backgroundColor: sage,
              shape: const StadiumBorder(),
            ),
            child: const Text('Continue  →', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => step = 1),
          child: const Text('Skip for now', style: TextStyle(color: sage, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _topicStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => setState(() => step = 0),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 22),
          ),
        ),
        Text(
          'Make the Village yours.',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 32,
            height: 1.08,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose up to 3 topics to see more of what you care about.',
          textAlign: TextAlign.center,
          style: TextStyle(color: ink, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 22),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: [
            for (final option in topicOptions)
              _topicCard(
                title: option.$2,
                icon: option.$3,
                selected: topics.contains(option.$1),
                onTap: () => _toggleTopic(option.$1),
              ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: saving ? null : _finish,
            style: FilledButton.styleFrom(
              backgroundColor: sage,
              shape: const StadiumBorder(),
            ),
            child: saving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enter the Village  →', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
        ),
        TextButton(
          onPressed: saving ? null : _finish,
          child: const Text('Skip for now', style: TextStyle(color: sage, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _choiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? paleSage : Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? sage : line, width: selected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: selected ? sage : blush,
              child: Icon(icon, color: selected ? Colors.white : sage),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: ink, fontSize: 15.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF5F665F), fontSize: 12.5, height: 1.3)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? sage : const Color(0xFFA8ADA7)),
          ],
        ),
      ),
    );
  }

  Widget _topicCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? paleSage : Colors.white.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? sage : line, width: selected ? 1.8 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? sage : gold, size: 29),
            const SizedBox(height: 7),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
