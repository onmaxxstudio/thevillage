import 'package:flutter/material.dart';

/// Premium-only experiences are distinct from the free tools below this panel.
/// Buttons show previews until enrollment and the event schedule are available.
class VillagePlusPremiumSection extends StatelessWidget {
  const VillagePlusPremiumSection({super.key, required this.onMembership});
  final VoidCallback onMembership;
  static const green = Color(0xFF003B23);
  static const gold = Color(0xFFE6C579);
  static const cream = Color(0xFFFFFAF1);
  TextStyle _title(double size) => TextStyle(
    fontFamily: 'VillagePlusDisplay',
    fontSize: size,
    color: cream,
    height: 1.12,
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 600;
      final large = MediaQuery.textScalerOf(context).scale(14) > 19;
      final stacked = !wide || large;
      final padding = wide ? 20.0 : 14.0;
      final cards = <Widget>[
        _experience(
          context,
          wide,
          0,
          Icons.groups_outlined,
          'Monthly Event',
          'Finding Your Balance\nNov 25 • Live + replay',
          'View Event',
        ),
        _experience(
          context,
          wide,
          1,
          Icons.spa_outlined,
          'Monthly Focus',
          'Building boundaries + weekly reflections.',
          'Explore Focus',
        ),
        _experience(
          context,
          wide,
          2,
          Icons.auto_stories_outlined,
          'Guided Pathways',
          'Self-paced programs.',
          'Explore',
        ),
      ];
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            key: const ValueKey('village-plus-premium-section'),
            margin: EdgeInsets.only(
              top: large ? MediaQuery.textScalerOf(context).scale(44) : 12,
            ),
            padding: EdgeInsets.fromLTRB(padding, 44, padding, padding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00492B), Color(0xFF002916)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33372C13),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stacked) ...[
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    cards[i],
                  ],
                ] else
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: cards[i]),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE88A), Color(0xFFF2C649)],
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_outlined,
                  color: Color(0xFF092E1D),
                  size: 24,
                ),
                SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'VILLAGE PLUS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF092E1D),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      );
    },
  );

  Widget _experience(
    BuildContext context,
    bool wide,
    int index,
    IconData icon,
    String title,
    String description,
    String action,
  ) => Container(
    decoration: BoxDecoration(
      color: green,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: gold, width: 1),
    ),
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: gold, size: wide ? 28 : 28),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: _title(wide ? 21 : 22))),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            description,
            style: TextStyle(
              color: cream,
              fontSize: wide ? 16 : 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          _button(
            context,
            ['monthly-event', 'monthly-focus', 'guided-pathways'][index],
            action,
            index + 1,
          ),
        ],
      ),
    ),
  );

  Widget _button(
    BuildContext context,
    String key,
    String text,
    int experience,
  ) => FilledButton(
    key: ValueKey('plus-$key'),
    onPressed: () => _preview(context, experience),
    style: FilledButton.styleFrom(
      backgroundColor: gold,
      foregroundColor: const Color(0xFF082A1A),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right, size: 18),
      ],
    ),
  );

  void _preview(BuildContext context, int experience) {
    const titles = [
      'Making Room for Yourself',
      'Monthly Event',
      'Monthly Focus',
      'Guided Pathways',
    ];
    const details = [
      'A live gathering, guided reflection, and practical tools to help you reset and refocus. Dates and RSVP details will appear here when this experience opens.',
      'Member workshops, replays, a monthly challenge, and resources around one meaningful theme. This month’s schedule will appear here when membership opens.',
      'A monthly topic with weekly reflections and practical activities. The first topic and its resources will appear here when available.',
      'Exclusive 21-day programs with deeper journaling and progress tracking. Explore a meaningful focus over three weeks when this member experience opens.',
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cream,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'VILLAGE PLUS · COMING SOON',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titles[experience],
                style: TextStyle(
                  fontFamily: 'VillagePlusDisplay',
                  fontSize: 28,
                  color: green,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                details[experience],
                style: const TextStyle(fontSize: 15, height: 1.5, color: green),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onMembership();
                },
                style: FilledButton.styleFrom(backgroundColor: green),
                child: const Text('Explore Village Plus'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Back to Growth Studio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
