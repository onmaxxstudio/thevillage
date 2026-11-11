import 'package:flutter/material.dart';

/// An additive dashboard: existing journals and tools keep their original routes.
class GrowthStudioDashboard extends StatelessWidget {
  const GrowthStudioDashboard({
    super.key,
    required this.entries,
    required this.onOpenTool,
    required this.onMembership,
  });

  final List<Map<String, dynamic>> entries;
  final void Function(String) onOpenTool;
  final VoidCallback onMembership;
  static const forest = Color(0xFF123D29);
  static const gold = Color(0xFFE8C778);
  static const cream = Color(0xFFFFFAF1);

  TextStyle _heading(double size, [Color color = cream]) => TextStyle(
    fontFamily: 'VillagePlusDisplay',
    fontSize: size,
    color: color,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final moods = entries.where((e) => e['entryType'] == 'mood').length;
    final milestones = entries
        .where((e) => e['entryType'] == 'milestone')
        .length;
    final journeys = entries
        .where(
          (e) => e['entryType'] == 'guided' && e['guidedJourneyId'] is String,
        )
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [forest, Color(0xFF082719)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: gold.withValues(alpha: .6)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220B2D1D),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _badge('YOUR GROWTH STUDIO')),
              const SizedBox(height: 16),
              Text(
                'Your growth, unfolding',
                textAlign: TextAlign.center,
                style: _heading(30),
              ),
              const SizedBox(height: 8),
              const Text(
                'A little space to reflect, reconnect, and take your next step.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cream, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF294D33),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gold.withValues(alpha: .35)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'THIS WEEK’S INVITATION',
                            style: TextStyle(
                              color: gold,
                              fontSize: 11,
                              letterSpacing: 1.6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Make room for yourself', style: _heading(23)),
                          const SizedBox(height: 8),
                          const Text(
                            'What is one small thing you need this week?',
                            style: TextStyle(color: cream, height: 1.5),
                          ),
                          TextButton(
                            onPressed: () => onOpenTool('goals'),
                            style: TextButton.styleFrom(
                              foregroundColor: gold,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text('Choose your focus →'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ExcludeSemantics(
                      child: Image.asset(
                        'assets/images/welcome_branch.png',
                        width: 58,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 560 ? 3 : 1;
                  final width =
                      (constraints.maxWidth - 10 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: width,
                        child: _progressCard(
                          Icons.insights_outlined,
                          'Mood reflections',
                          moods == 0
                              ? 'Start with how you feel today.'
                              : '$moods saved ${moods == 1 ? 'reflection' : 'reflections'}',
                          'mood',
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _progressCard(
                          Icons.emoji_events_outlined,
                          'Your milestones',
                          milestones == 0
                              ? 'Small wins belong here, too.'
                              : '$milestones saved ${milestones == 1 ? 'milestone' : 'milestones'}',
                          'milestones',
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: _progressCard(
                          Icons.auto_stories_outlined,
                          journeys == 0 ? 'Begin a journey' : 'Your journeys',
                          journeys == 0
                              ? 'Explore at your own pace.'
                              : '$journeys saved journey ${journeys == 1 ? 'entry' : 'entries'}',
                          'guided',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          'Your next chapter',
          textAlign: TextAlign.center,
          style: _heading(29, forest),
        ),
        const SizedBox(height: 8),
        Center(child: _badge('VILLAGE PLUS · COMING SOON')),
        const SizedBox(height: 10),
        const Text(
          'A preview of deeper journeys. Your current guided journals stay available.',
          textAlign: TextAlign.center,
          style: TextStyle(color: forest, height: 1.5),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            const books = [
              (
                'Boundaries',
                'Make space for what matters.',
                Color(0xFF284632),
                'my_space_growth.jpg',
              ),
              (
                'Starting Over',
                'Begin your next chapter.',
                Color(0xFF985735),
                'my_space_journey.jpg',
              ),
              (
                'Finding Myself Again',
                'Reconnect with who you are.',
                Color(0xFF967129),
                'my_space_reflection.jpg',
              ),
            ];
            final columns = constraints.maxWidth < 480 ? 1 : 3;
            final width = (constraints.maxWidth - 14 * (columns - 1)) / columns;
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final book in books)
                  SizedBox(
                    width: width,
                    child: _book(context, book.$1, book.$2, book.$3, book.$4),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: onMembership,
          style: OutlinedButton.styleFrom(
            foregroundColor: forest,
            side: const BorderSide(color: Color(0xFFC6A65F)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          icon: const Icon(Icons.workspace_premium_outlined),
          label: const Text(
            r'Explore Village Plus · $4.99/month',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    decoration: BoxDecoration(
      color: gold,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: forest,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );

  Widget _progressCard(
    IconData icon,
    String title,
    String detail,
    String mode,
  ) => Material(
    color: const Color(0xFF214530),
    borderRadius: BorderRadius.circular(15),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => onOpenTool(mode),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: gold, size: 24),
            const SizedBox(height: 10),
            Text(title, style: _heading(19)),
            const SizedBox(height: 8),
            Text(detail, style: const TextStyle(color: cream, height: 1.4)),
            const SizedBox(height: 12),
            const Icon(Icons.arrow_forward_rounded, color: gold, size: 18),
          ],
        ),
      ),
    ),
  );

  Widget _book(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    String asset,
  ) => Material(
    color: color,
    borderRadius: BorderRadius.circular(12),
    elevation: 3,
    shadowColor: const Color(0x443F2E15),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _preview(context, title, subtitle),
      child: Container(
        constraints: const BoxConstraints(minHeight: 235),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: gold.withValues(alpha: .4), width: 7),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: .2,
                child: Image.asset(
                  'assets/images/$asset',
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.eco_outlined, color: gold),
                  const SizedBox(height: 18),
                  Text(title, textAlign: TextAlign.center, style: _heading(25)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: SizedBox(width: 38, child: Divider(color: gold)),
                  ),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: cream, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'VIEW PREVIEW',
                    style: TextStyle(
                      color: gold,
                      fontSize: 10,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _preview(BuildContext context, String title, String subtitle) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: _heading(28, forest)),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: const TextStyle(color: forest, fontSize: 17),
              ),
              const SizedBox(height: 12),
              const Text(
                'This exclusive Village Plus journey is coming soon. You can keep exploring all of your existing guided journaling tools today.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onOpenTool('guided');
                },
                style: FilledButton.styleFrom(backgroundColor: forest),
                child: const Text('Explore current guided journals'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onMembership();
                },
                child: const Text('About Village Plus'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
