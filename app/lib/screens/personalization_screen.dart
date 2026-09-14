import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/personalization_service.dart';

class PersonalizationScreen extends StatefulWidget {
  const PersonalizationScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<PersonalizationScreen> createState() => _PersonalizationScreenState();
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

  static const identityOptions = <(String, String, IconData)>[
    ('woman', 'Woman', Icons.female_rounded),
    ('man', 'Man', Icons.male_rounded),
    ('prefer_not_to_say', 'Prefer not to say', Icons.person_outline_rounded),
  ];

  static const interestOptions = <(String, String, IconData)>[
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
    if (identity == null || interests.isEmpty || periodTracking == null || saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an identity, at least one topic, and a period-tracking preference.')),
      );
      return;
    }
    setState(() => saving = true);
    await service.save(VillagePersonalization(
      identity: identity!,
      interests: interests.toList(),
      periodTracking: periodTracking!,
      completed: true,
    ));
    if (!mounted) return;
    if (widget.onComplete != null) {
      widget.onComplete!();
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
                  'Make the Village yours.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    color: sage,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Your answers shape what we recommend. Every shared community will still be open to you.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: ink, fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 26),
                _question(
                  number: '1',
                  title: 'How do you identify?',
                  subtitle: 'This helps us recommend spaces that feel relevant.',
                  child: Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final option in identityOptions)
                        ChoiceChip(
                          avatar: Icon(option.$3, size: 18, color: identity == option.$1 ? Colors.white : sage),
                          label: Text(option.$2),
                          selected: identity == option.$1,
                          onSelected: (_) => setState(() => identity = option.$1),
                          selectedColor: sage,
                          labelStyle: TextStyle(
                            color: identity == option.$1 ? Colors.white : ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _question(
                  number: '2',
                  title: 'What would you like support with?',
                  subtitle: 'Choose as many as you want.',
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
                            selected ? interests.add(option.$1) : interests.remove(option.$1);
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
                const SizedBox(height: 16),
                _question(
                  number: '3',
                  title: 'Would you like period tracking?',
                  subtitle: 'This is separate from identity and can be changed anytime.',
                  child: Row(
                    children: [
                      Expanded(child: _periodChoice('Yes', true)),
                      const SizedBox(width: 10),
                      Expanded(child: _periodChoice('No', false)),
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
                  'These preferences are private and can be updated in Settings.',
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
