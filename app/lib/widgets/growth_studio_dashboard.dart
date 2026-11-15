import 'package:flutter/material.dart';
import 'growth_reference_art.dart';
import 'village_plus_premium_section.dart';

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
  static const forest = Color(0xFF103A23);
  static const gold = Color(0xFFE6C579);
  static const cream = Color(0xFFFFFAF1);
  TextStyle _heading(double size, [Color color = cream]) => TextStyle(
    fontFamily: 'VillagePlusDisplay',
    fontSize: size,
    color: color,
    height: 1.12,
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 600;
      final phone = MediaQuery.sizeOf(context).width < 600;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VillagePlusPremiumSection(onMembership: onMembership),
          if (_unfinishedJourney != null) ...[
            const SizedBox(height: 16),
            _continueJourney(wide),
          ],
          SizedBox(height: wide ? 20 : 14),
          _ornamentTitle('Your next chapter', wide),
          const SizedBox(height: 7),
          Center(
            child: _badge(
              'Included with Village Plus',
              wide: wide,
              sentence: true,
            ),
          ),
          SizedBox(height: wide ? 18 : 12),
          Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? (phone ? 20 : 104) : 18,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) SizedBox(width: wide ? (phone ? 24 : 30) : 12),
                      Expanded(child: _book(context, i)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      );
    },
  );

  Map<String, dynamic>? get _unfinishedJourney {
    for (final entry in entries) {
      if (entry['entryType'] != 'guided' ||
          entry['guidedJourneyId'] is! String ||
          entry['guidedJourneyCompleted'] == true)
        continue;
      final answers = entry['guidedJourneyAnswers'];
      if (answers is List &&
          answers.any((a) => a is String && a.trim().isNotEmpty) &&
          answers.any((a) => a is! String || a.trim().isEmpty))
        return entry;
    }
    return null;
  }

  Widget _continueJourney(bool wide) {
    final entry = _unfinishedJourney!;
    final answers = entry['guidedJourneyAnswers'] as List;
    final completed = answers
        .where((a) => a is String && a.trim().isNotEmpty)
        .length;
    return Material(
      color: cream,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: gold),
      ),
      child: InkWell(
        key: const ValueKey('growth-continue'),
        borderRadius: BorderRadius.circular(14),
        onTap: () => onOpenTool('guided'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.auto_stories_outlined, color: forest),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue where you left off',
                      style: _heading(wide ? 23 : 18, forest),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${entry['title'] ?? 'Your guided journal'} · $completed of ${answers.length} reflections saved',
                      style: TextStyle(color: forest, fontSize: wide ? 16 : 12),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: completed / answers.length,
                      color: const Color(0xFF80934E),
                      backgroundColor: const Color(0xFFE8DFC9),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.chevron_right, color: forest),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, {required bool wide, bool sentence = false}) =>
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 20 : 13,
          vertical: wide ? 7 : 5,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF3D68C), Color(0xFFDDB15E)],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: forest,
            letterSpacing: sentence ? 0 : 1,
            fontWeight: sentence ? FontWeight.w500 : FontWeight.bold,
            fontSize: wide ? 14 : 10,
          ),
        ),
      );

  Widget _ornamentTitle(String title, bool wide) => Row(
    children: [
      Expanded(
        child: Divider(
          color: const Color(0xFFC3A05A),
          indent: wide ? 110 : 25,
          endIndent: 12,
        ),
      ),
      Expanded(
        flex: 3,
        child: Text(
          title,
          key: const ValueKey('growth-next-chapter'),
          textAlign: TextAlign.center,
          style: _heading(wide ? 34 : 23, forest),
        ),
      ),
      Expanded(
        child: Divider(
          color: const Color(0xFFC3A05A),
          indent: 12,
          endIndent: wide ? 110 : 25,
        ),
      ),
    ],
  );

  Widget _book(BuildContext context, int index) {
    const titles = ['Boundaries', 'Starting Over', 'Finding Myself Again'];
    const regions = [
      Rect.fromLTWH(143, 728, 222, 245),
      Rect.fromLTWH(403, 728, 222, 245),
      Rect.fromLTWH(664, 728, 222, 245),
    ];
    return Semantics(
      key: ValueKey('growth-book-$index'),
      button: true,
      label: titles[index],
      child: Material(
        color: Colors.transparent,
        elevation: 4,
        borderRadius: BorderRadius.circular(9),
        shadowColor: const Color(0x554B391B),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _preview(context, titles[index]),
          child: GrowthReferenceArt(
            region: regions[index],
            label: titles[index],
          ),
        ),
      ),
    );
  }

  void _preview(
    BuildContext context,
    String title,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cream,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: _heading(28, forest)),
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
