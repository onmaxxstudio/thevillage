import 'package:flutter/material.dart';
import 'growth_reference_art.dart';
import 'growth_studio_dashboard.dart';

/// Keeps the approved 1024-wide composition proportional at every screen width.
/// Larger accessibility text uses the native responsive layout instead.
class GrowthStudioExperience extends StatelessWidget {
  const GrowthStudioExperience({
    super.key,
    required this.entries,
    required this.onOpenTool,
    required this.onWrite,
    required this.onMembership,
    required this.onBack,
    required this.onSettings,
  });
  final List<Map<String, dynamic>> entries;
  final void Function(String) onOpenTool;
  final VoidCallback onWrite, onMembership, onBack, onSettings;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final large = MediaQuery.textScalerOf(context).scale(14) > 19;
      final phone = constraints.maxWidth < 600;
      final width = large ? constraints.maxWidth : (phone ? 720.0 : 1024.0);
      final content = SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF9EC), Color(0xFFFAEDD7)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  const GrowthReferenceArt(
                    region: Rect.fromLTWH(0, 0, 1024, 143),
                    label: 'Ask the Village. Growth Studio',
                  ),
                  Positioned(
                    left: 14,
                    bottom: 8,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: GrowthStudioDashboard.forest,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 8,
                    child: IconButton(
                      tooltip: 'Settings',
                      onPressed: onSettings,
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: GrowthStudioDashboard.forest,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: large ? 12 : (phone ? 20 : 38)),
                child: GrowthStudioDashboard(
                  entries: entries,
                  onOpenTool: onOpenTool,
                  onMembership: onMembership,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.eco_outlined,
                    color: Color(0xFF8B9454),
                    size: 30,
                  ),
                  const SizedBox(width: 18),
                  Flexible(
                    child: Text(
                      'Your everyday tools',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'VillagePlusDisplay',
                        color: GrowthStudioDashboard.forest,
                        fontSize: large ? 25 : 40,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  const Icon(
                    Icons.eco_outlined,
                    color: Color(0xFF8B9454),
                    size: 30,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Still here. Always yours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF576440),
                  fontSize: large ? 14 : 19,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  large ? 12 : 35,
                  0,
                  large ? 12 : 35,
                  28,
                ),
                child: _tools(context, large),
              ),
            ],
          ),
        ),
      );
      if (large) return content;
      return FittedBox(
        fit: BoxFit.fitWidth,
        alignment: Alignment.topCenter,
        child: content,
      );
    },
  );

  Widget _tools(BuildContext context, bool large) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = large ? 1 : 2;
      final phone = MediaQuery.sizeOf(context).width < 600;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      const tools = [
        (
          'Write Freely',
          'A quiet space to get your thoughts, feelings, and ideas out.',
          Icons.edit_note_outlined,
          'write',
        ),
        (
          'Journal Prompts',
          'Thoughtful questions to help you reflect.',
          Icons.lightbulb_outline,
          'prompts',
        ),
        (
          'Guided Journaling',
          'Structured support for deeper clarity.',
          Icons.auto_stories_outlined,
          'guided',
        ),
        (
          'Gratitude',
          'Notice and celebrate what’s good today.',
          Icons.favorite_border,
          'gratitude',
        ),
        (
          'Mood Reflections',
          'Check in, process, and see your patterns.',
          Icons.spa_outlined,
          'mood',
        ),
        (
          'Milestones',
          'Track your progress and inner wins.',
          Icons.emoji_events_outlined,
          'milestones',
        ),
        (
          'Vision & Goals',
          'Get clear on what you want and take small steps.',
          Icons.track_changes,
          'goals',
        ),
        (
          'Letters',
          'Write to yourself, your past, or your future.',
          Icons.mail_outline,
          'letters',
        ),
        (
          'Budget',
          'A simple space to plan, track, and feel more in control.',
          Icons.account_balance_outlined,
          'budget',
        ),
      ];
      Widget card(int i) => Material(
        color: const Color(0xFFFFF4DF),
        elevation: 2,
        shadowColor: const Color(0x33412E16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD9C5A2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('growth-tool-${tools[i].$4}'),
          onTap: () => i == 0 ? onWrite() : onOpenTool(tools[i].$4),
          child: Stack(
            children: [
              if (i == 0)
                const Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 185,
                  child: GrowthReferenceArt(
                    region: Rect.fromLTWH(810, 1118, 180, 77),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: large ? 12 : 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      tools[i].$3,
                      color: const Color(0xFF71804C),
                      size: large ? 25 : 42,
                    ),
                    const SizedBox(width: 18),
                    if (i == 0) ...[
                      Container(
                        width: 1,
                        height: 45,
                        color: const Color(0xFFD8B971),
                      ),
                      const SizedBox(width: 30),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tools[i].$1,
                            style: TextStyle(
                              fontFamily: 'VillagePlusDisplay',
                              color: const Color(0xFF112719),
                              fontSize: large ? 18 : (phone ? 26 : 22),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tools[i].$2,
                            style: TextStyle(
                              color: const Color(0xFF172019),
                              fontSize: large ? 12 : (phone ? 18 : 14),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      return Column(
        children: [
          SizedBox(width: double.infinity, child: card(0)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 1; i < tools.length; i++)
                SizedBox(width: width, child: card(i)),
            ],
          ),
        ],
      );
    },
  );
}
