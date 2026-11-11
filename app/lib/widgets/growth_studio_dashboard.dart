import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'growth_reference_art.dart';

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
  static const cream = Color(0xFFFFF7E8);
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
      final large = MediaQuery.textScalerOf(context).scale(14) > 19;
      final moods = entries.where((e) => e['entryType'] == 'mood').toList();
      final milestones = entries
          .where((e) => e['entryType'] == 'milestone')
          .toList();
      final journeys = entries
          .where(
            (e) => e['entryType'] == 'guided' && e['guidedJourneyId'] is String,
          )
          .toList();
      final gap = wide ? 12.0 : 5.0;
      final padding = wide ? 22.0 : 10.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: EdgeInsets.fromLTRB(padding, 26, padding, padding),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF174826), Color(0xFF082B19)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: gold, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x253C2F0C),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: gold.withValues(alpha: .7),
                            indent: 12,
                            endIndent: 12,
                          ),
                        ),
                        Flexible(
                          flex: 4,
                          child: Text(
                            'Your growth, unfolding',
                            textAlign: TextAlign.center,
                            style: _heading(wide ? 36 : 19),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: gold.withValues(alpha: .7),
                            indent: 12,
                            endIndent: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: wide ? 115 : 0),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text:
                                  'A premium addition to your Ask the Village experience, with deeper insights, progress tracking, and curated journeys — while ',
                            ),
                            TextSpan(
                              text:
                                  'all of your existing free tools remain available, just as always.',
                              style: const TextStyle(
                                color: gold,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: cream,
                          fontSize: wide ? 15 : 10,
                          height: 1.35,
                        ),
                      ),
                    ),
                    SizedBox(height: wide ? 16 : 10),
                    _focus(context, wide),
                    SizedBox(height: gap),
                    if (large) ...[
                      _moodCard(context, moods, wide),
                      SizedBox(height: gap),
                      _milestoneCard(context, milestones, wide),
                      SizedBox(height: gap),
                      _journeyCard(context, journeys, wide),
                    ] else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _moodCard(context, moods, wide)),
                            SizedBox(width: gap),
                            Expanded(
                              child: _milestoneCard(context, milestones, wide),
                            ),
                            SizedBox(width: gap),
                            Expanded(
                              child: _journeyCard(context, journeys, wide),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (wide) ...[
                Positioned(
                  left: 10,
                  top: 37,
                  width: 130,
                  height: 105,
                  child: IgnorePointer(
                    child: _cornerArt(const Rect.fromLTWH(48, 178, 130, 105)),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 45,
                  width: 106,
                  height: 100,
                  child: IgnorePointer(
                    child: _cornerArt(const Rect.fromLTWH(870, 188, 106, 100)),
                  ),
                ),
              ],
              _badge('VILLAGE PLUS', wide: wide),
            ],
          ),
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
              if (wide) ...[
                Positioned(
                  left: 0,
                  top: -65,
                  bottom: 0,
                  width: 105,
                  child: IgnorePointer(
                    child: _cornerArt(const Rect.fromLTWH(0, 650, 120, 320)),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: -65,
                  bottom: 0,
                  width: 105,
                  child: IgnorePointer(
                    child: _cornerArt(const Rect.fromLTWH(904, 650, 120, 320)),
                  ),
                ),
              ],
              Padding(
                padding: EdgeInsets.symmetric(horizontal: wide ? 104 : 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) SizedBox(width: wide ? 30 : 12),
                      Expanded(child: _book(context, i)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onMembership,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: gold,
                      indent: wide ? 90 : 30,
                      endIndent: 10,
                    ),
                  ),
                  Icon(
                    Icons.eco_outlined,
                    color: const Color(0xFF92934C),
                    size: wide ? 23 : 17,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    flex: 3,
                    child: Text(
                      r'Village Plus · $4.99/month',
                      textAlign: TextAlign.center,
                      style: _heading(wide ? 20 : 14, forest),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.eco_outlined,
                    color: const Color(0xFF92934C),
                    size: wide ? 23 : 17,
                  ),
                  Expanded(
                    child: Divider(
                      color: gold,
                      indent: 10,
                      endIndent: wide ? 90 : 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _cornerArt(Rect region) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) => const RadialGradient(
      radius: .5,
      colors: [Colors.white, Colors.white, Colors.transparent],
      stops: [0, .4, 1],
    ).createShader(bounds),
    child: GrowthReferenceArt(region: region),
  );

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
      Flexible(
        flex: 3,
        child: Text(
          title,
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

  Widget _focus(BuildContext context, bool wide) => Semantics(
    button: true,
    label: 'Weekly focus. Make room for yourself. Choose your focus.',
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onOpenTool('goals'),
        child: const GrowthReferenceArt(
          region: Rect.fromLTWH(64, 306, 896, 126),
        ),
      ),
    ),
  );

  Widget _panel({
    required Widget child,
    required VoidCallback onTap,
    EdgeInsets? padding,
  }) => Material(
    color: const Color(0xFF193F27),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: const BorderSide(color: Color(0xFFB9AB6C), width: .8),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 154),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    ),
  );

  Widget _cardTitle(IconData icon, String title, bool wide) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: gold, size: wide ? 20 : 14),
      const SizedBox(width: 5),
      Expanded(child: Text(title, style: _heading(wide ? 17 : 11))),
    ],
  );

  Widget _moodCard(
    BuildContext context,
    List<Map<String, dynamic>> moods,
    bool wide,
  ) {
    const scores = {
      'Happy': 5.0,
      'Calm': 4.0,
      'Grateful': 5.0,
      'Overwhelmed': 2.0,
      'Sad': 1.0,
      'Anxious': 2.0,
      'Motivated': 4.0,
      'Hopeful': 4.0,
      'Tired': 2.0,
      'Angry': 1.0,
    };
    final values = moods.reversed
        .map((e) => scores[e['mood']])
        .whereType<double>()
        .toList();
    final shown = values.length > 7
        ? values.sublist(values.length - 7)
        : values;
    return _panel(
      onTap: () => onOpenTool('mood'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(Icons.trending_up, 'Mood history', wide),
          const SizedBox(height: 7),
          if (shown.isNotEmpty)
            SizedBox(
              height: wide ? 62 : 36,
              width: double.infinity,
              child: CustomPaint(painter: _MoodPainter(shown)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Your check-ins appear here.',
                style: TextStyle(
                  color: cream,
                  fontSize: wide ? 12 : 9,
                  height: 1.3,
                ),
              ),
            ),
          const SizedBox(height: 5),
          Text(
            '${moods.length} saved ${moods.length == 1 ? 'reflection' : 'reflections'}',
            style: TextStyle(color: cream, fontSize: wide ? 11 : 9),
          ),
        ],
      ),
    );
  }

  Widget _milestoneCard(
    BuildContext context,
    List<Map<String, dynamic>> items,
    bool wide,
  ) => _panel(
    onTap: () => onOpenTool('milestones'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cardTitle(Icons.emoji_events_outlined, 'Your milestones', wide),
        const SizedBox(height: 8),
        for (final item in items.take(2))
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: gold, size: wide ? 17 : 11),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    (item['title'] as String?) ?? 'A small win',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cream,
                      fontSize: wide ? 12 : 9,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (items.isEmpty)
          Text(
            'Celebrate your next small win.',
            style: TextStyle(color: cream, fontSize: wide ? 12 : 9),
          ),
        const SizedBox(height: 4),
        Text(
          '${items.length} saved ${items.length == 1 ? 'milestone' : 'milestones'}',
          style: TextStyle(color: gold, fontSize: wide ? 10 : 8),
        ),
      ],
    ),
  );

  Widget _journeyCard(
    BuildContext context,
    List<Map<String, dynamic>> items,
    bool wide,
  ) {
    final entry = items.isEmpty ? null : items.first;
    final answers = entry?['guidedJourneyAnswers'];
    final progress = answers is List && answers.isNotEmpty
        ? answers.where((a) => a is String && a.trim().isNotEmpty).length /
              answers.length
        : null;
    return _panel(
      onTap: () => onOpenTool('guided'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            Icons.auto_stories_outlined,
            'Continue your journey',
            wide,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: wide ? 50 : 23,
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  child: GrowthReferenceArt(
                    region: Rect.fromLTWH(658, 492, 83, 82),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  entry == null
                      ? 'Choose your next chapter'
                      : (entry['title'] as String? ?? 'Your saved journey'),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _heading(wide ? 16 : 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          if (progress != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: wide ? 7 : 4,
                color: gold,
                backgroundColor: const Color(0xFF64825B),
              ),
            )
          else
            Text(
              items.isEmpty
                  ? 'Explore at your own pace.'
                  : '${items.length} saved journey ${items.length == 1 ? 'entry' : 'entries'}',
              style: TextStyle(color: cream, fontSize: wide ? 10 : 8),
            ),
        ],
      ),
    );
  }

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

class _MoodPainter extends CustomPainter {
  const _MoodPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x336E925E)
      ..strokeWidth = .5;
    for (var i = 0; i < 3; i++) {
      final y = size.height * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1
              ? size.width / 2
              : size.width * i / (values.length - 1),
          size.height * (1 - (values[i] - 1) / 4) * .85 + size.height * .08,
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final fill = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x777EA14A), Color(0x007EA14A)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = GrowthStudioDashboard.gold
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
    for (final point in points) {
      canvas.drawCircle(
        point,
        math.min(3, size.width / 35),
        Paint()..color = GrowthStudioDashboard.gold,
      );
    }
  }

  @override
  bool shouldRepaint(_MoodPainter oldDelegate) => oldDelegate.values != values;
}
