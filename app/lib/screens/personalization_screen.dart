import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/community_hub_service.dart';
import '../services/personalization_service.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key, this.onComplete});

  final ValueChanged<OnboardingDestination>? onComplete;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
}

class OnboardingDestination {
  const OnboardingDestination.ask(this.communityId, this.communityName) : startAsking = true;
  const OnboardingDestination.explore() : startAsking = false, communityId = null, communityName = null;
  final bool startAsking;
  final String? communityId;
  final String? communityName;
}

class _RecommendedSpace {
  const _RecommendedSpace(this.id, this.name, this.detail, this.icon);
  final String id;
  final String name;
  final String detail;
  final IconData icon;
}

class _PersonalizationScreenState extends State<PersonalizationScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final service = PersonalizationService();
  String? identity;
  bool? periodTracking;
  Set<String> interests = {};
  bool loading = true;
  bool saving = false;
  bool showingNextStep = false;

  static const interestOptions = <(String, String, IconData)>[
    ('Women’s support', 'Women', Icons.woman_rounded),
    ('Men’s support', 'Men', Icons.man_rounded),
    ('Relationships', 'Relationships', Icons.favorite_border_rounded),
    ('Fatherhood', 'Fatherhood', Icons.family_restroom_rounded),
    ('Motherhood', 'Motherhood', Icons.child_care_rounded),
    ('Mental wellness', 'Mental wellness', Icons.spa_outlined),
    ('Career & purpose', 'Career & purpose', Icons.work_outline_rounded),
    ('Friendship', 'Friendship', Icons.people_outline_rounded),
    ('Family', 'Family', Icons.home_outlined),
    ('Grief & healing', 'Grief & healing', Icons.healing_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await service.load();
    if (!mounted) return;
    setState(() {
      if (saved.completed) {
        identity = saved.identity;
        interests = saved.interests.toSet();
        periodTracking = saved.periodTracking;
      }
      loading = false;
    });
  }

  Future<void> _save() async {
    if (interests.isEmpty || saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose at least one topic so we can point you to the right spaces.')),
      );
      return;
    }
    setState(() => saving = true);
    await service.save(VillagePersonalization(
      identity: '',
      interests: interests.toList(),
      periodTracking: false,
      completed: true,
    ));
    if (!mounted) return;
    if (widget.onComplete != null) {
      await _joinRecommendedSpaces();
      if (!mounted) return;
      setState(() => showingNextStep = true);
    } else {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(child: CircularProgressIndicator(color: sage)),
      );
    }
    if (showingNextStep) return _nextStep();
    return Scaffold(
      backgroundColor: cream,
      appBar: widget.onComplete == null
          ? AppBar(backgroundColor: cream, title: const Text('Personalize your Village'))
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
              children: [
                const Icon(Icons.diversity_3_outlined, color: gold, size: 34),
                const SizedBox(height: 8),
                Text(
                  'Find your place in the Village.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: sage,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Start with what feels most important right now. You can change this anytime.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: ink, fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 26),
                _question(
                  number: '1',
                  title: 'What brings you here right now?',
                  subtitle: 'Choose up to two things that feel most important today.',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in interestOptions)
                        FilterChip(
                          avatar: Icon(option.$3, size: 17, color: interests.contains(option.$1) ? Colors.white : sage),
                          label: Text(option.$2),
                          selected: interests.contains(option.$1),
                          onSelected: (selected) => setState(() {
                            if (selected && (interests.length < 2 || interests.contains(option.$1))) {
                              interests.add(option.$1);
                            } else if (!selected) {
                              interests.remove(option.$1);
                            }
                          }),
                          selectedColor: sage,
                          labelStyle: TextStyle(
                            color: interests.contains(option.$1) ? Colors.white : ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 55,
                  child: FilledButton(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: sage,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: saving
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Save My Village', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'You can update your spaces anytime.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF666C66)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_RecommendedSpace> get _recommendedSpaces {
    final spaces = <_RecommendedSpace>[];
    void add(String id, String name, String detail, IconData icon) {
      if (spaces.every((space) => space.id != id) && spaces.length < 2) {
        spaces.add(_RecommendedSpace(id, name, detail, icon));
      }
    }
    if (identity == 'woman') add('women', 'Women', 'Support and perspective through every season.', Icons.woman_rounded);
    if (identity == 'man') add('men', 'Men', 'Honest support for purpose, relationships, and wellbeing.', Icons.man_rounded);
    for (final interest in interests) {
      switch (interest) {
        case 'Women’s support': add('women', 'Women', 'Support and perspective through every season.', Icons.woman_rounded); break;
        case 'Men’s support': add('men', 'Men', 'Honest support for purpose, relationships, and wellbeing.', Icons.man_rounded); break;
        case 'Motherhood': add('moms', 'Moms', 'Real talk and practical support for motherhood.', Icons.child_care_rounded); break;
        case 'Fatherhood': add('men', 'Men', 'Honest support for purpose, relationships, and wellbeing.', Icons.man_rounded); break;
        case 'Relationships': add('relationships', 'Relationships', 'For the conversations you cannot always have with people you know.', Icons.favorite_border_rounded); break;
        case 'Mental wellness': add('wellness', 'Wellness', 'Gentle support for your emotional wellbeing.', Icons.spa_outlined); break;
        case 'Career & purpose': add('career', 'Career & Purpose', 'Work, confidence, growth, and your next move.', Icons.work_outline_rounded); break;
        case 'Friendship': add('friendship', 'Friendship', 'Navigate closeness, change, conflict, and connection.', Icons.people_outline_rounded); break;
        case 'Family': add('caregivers', 'Caregivers', 'Care and understanding for people who care for others.', Icons.home_outlined); break;
        case 'Grief & healing': add('grief', 'Grief & Healing', 'A softer place for loss, remembrance, and healing.', Icons.healing_outlined); break;
      }
    }
    add('relationships', 'Relationships', 'For the conversations you cannot always have with people you know.', Icons.favorite_border_rounded);
    add('wellness', 'Wellness', 'Gentle support for your emotional wellbeing.', Icons.spa_outlined);
    return spaces;
  }

  Future<void> _joinRecommendedSpaces() async {
    final hub = CommunityHubService();
    final joined = await hub.joinedCommunities();
    joined.addAll(_recommendedSpaces.map((space) => space.id));
    await hub.saveJoinedCommunities(joined);
    for (final space in _recommendedSpaces) {
      await hub.setCommunityMembership(space.id, true);
    }
  }

  Widget _nextStep() {
    final spaces = _recommendedSpaces;
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(Icons.favorite_rounded, color: gold, size: 34),
                  const SizedBox(height: 13),
                  Text('You belong here.', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(color: sage, fontSize: 35, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('We saved two spaces to help you begin. You can change them anytime.', textAlign: TextAlign.center, style: TextStyle(color: ink, fontSize: 15, height: 1.45)),
                  const SizedBox(height: 24),
                  for (final space in spaces) ...[
                    Container(
                      padding: const EdgeInsets.all(15),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), border: Border.all(color: line), borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: paleSage, child: Icon(space.icon, color: sage)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(space.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 2), Text(space.detail, style: const TextStyle(fontSize: 12.5, height: 1.32))])),
                        const Icon(Icons.check_circle_rounded, color: sage),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 15),
                  SizedBox(height: 55, child: FilledButton.icon(onPressed: () => widget.onComplete!(OnboardingDestination.ask(spaces.first.id, spaces.first.name)), style: FilledButton.styleFrom(backgroundColor: sage, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), icon: const Icon(Icons.edit_note_rounded), label: const Text('Ask your first question', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)))),
                  const SizedBox(height: 9),
                  TextButton(onPressed: () => widget.onComplete!(const OnboardingDestination.explore()), child: const Text('Explore my spaces', style: TextStyle(color: sage, fontWeight: FontWeight.w800))),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodChoice(String label, bool value) {
    final selected = periodTracking == value;
    return InkWell(
      onTap: () => setState(() => periodTracking = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? paleSage : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? sage : line, width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: sage, size: 20),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _question({
    required String number,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, backgroundColor: paleSage, child: Text(number, style: const TextStyle(color: sage, fontWeight: FontWeight.w900))),
              const SizedBox(width: 9),
              Expanded(child: Text(title, style: GoogleFonts.playfairDisplay(fontSize: 20, color: ink, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12.5, color: Color(0xFF666C66))),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }
}
