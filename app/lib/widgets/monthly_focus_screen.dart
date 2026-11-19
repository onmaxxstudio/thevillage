import 'package:flutter/material.dart';

class MonthlyFocusScreen extends StatelessWidget {
  const MonthlyFocusScreen({super.key});

  static const green = Color(0xFF003B23);
  static const cream = Color(0xFFFFFAF1);
  static const gold = Color(0xFFE6C579);

  static const weeks = <({
    String title,
    String intention,
    String activity,
    String journal,
    String thought,
  })>[
    (
      title: 'Notice your limits',
      intention: 'Understand where your energy is going.',
      activity: 'For three days, notice one moment when you say yes but mean no. Write down what you felt in your body and what you needed.',
      journal: 'Where in my life do I feel stretched thin? What am I afraid might happen if I ask for space?',
      thought: 'A boundary begins with noticing, before you have to explain anything to anyone.',
    ),
    (
      title: 'Name what you need',
      intention: 'Turn an uneasy feeling into a clear request.',
      activity: 'Choose one small limit. Practice saying: “I can do __, but I cannot do __.” Say it aloud, then try it in a low-pressure moment.',
      journal: 'Which needs have I been minimizing? What would it sound like to state one of them kindly and clearly?',
      thought: 'Can I allow someone to be disappointed without deciding I did something wrong?',
    ),
    (
      title: 'Hold your boundary',
      intention: 'Make room for discomfort without abandoning yourself.',
      activity: 'Use your boundary once this week. If you feel pressured, pause and repeat your answer without adding a long explanation.',
      journal: 'What happened when I held my limit? What felt hard, and what helped me stay grounded?',
      thought: 'Consistency is a practice. One difficult conversation does not define my progress.',
    ),
    (
      title: 'Build a gentler rhythm',
      intention: 'Keep what supports you beyond this month.',
      activity: 'Pick one boundary to carry forward. Put a reminder on your calendar to check how it is working in two weeks.',
      journal: 'What changed in my energy, relationships, or self-trust? Which limit needs adjusting?',
      thought: 'What would caring for myself look like if I made it a regular part of my life?',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(
      title: const Text('Monthly Focus'),
      backgroundColor: cream,
      foregroundColor: green,
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('VILLAGE PLUS · MONTHLY FOCUS',
                      style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 12),
                  Text('Building Boundaries',
                      style: TextStyle(fontFamily: 'VillagePlusDisplay', fontSize: 34, color: cream)),
                  SizedBox(height: 10),
                  Text('Four weeks of small actions and honest reflection to help you protect your energy while staying connected to what matters.',
                      style: TextStyle(color: cream, fontSize: 16, height: 1.45)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < weeks.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: const Color(0xFFFFF4DF),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFD9C5A2)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ExpansionTile(
                    key: ValueKey('monthly-focus-week-${i + 1}'),
                    iconColor: green,
                    collapsedIconColor: green,
                    title: Text('Week ${i + 1} · ${weeks[i].title}',
                        style: const TextStyle(fontFamily: 'VillagePlusDisplay', color: green, fontSize: 22)),
                    subtitle: Text(weeks[i].intention),
                    childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _section('Try this', weeks[i].activity),
                      _section('Journal with this', weeks[i].journal),
                      _section('A thought to carry', weeks[i].thought),
                    ],
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.all(10),
              child: Text('Take these at your own pace. You can revisit any week whenever you need it.',
                  textAlign: TextAlign.center, style: TextStyle(color: green)),
            ),
          ],
        ),
      ),
    ),
  );

  static Widget _section(String heading, String body) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading.toUpperCase(),
            style: const TextStyle(color: green, fontWeight: FontWeight.bold, letterSpacing: 0.7)),
        const SizedBox(height: 5),
        Text(body, style: const TextStyle(color: green, fontSize: 15, height: 1.45)),
      ],
    ),
  );
}
