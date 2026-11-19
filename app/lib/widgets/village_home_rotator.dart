import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/daily_village_question_service.dart';
import '../screens/daily_village_question_screen.dart';
import 'village_plus_banner.dart';
import 'village_plus_photo.dart';

/// Keeps the existing Village Plus banner untouched and uses its exact
/// intrinsic footprint for the alternative daily question.
class VillageHomeRotator extends StatefulWidget {
  const VillageHomeRotator({super.key, required this.isPlusMember});
  final bool isPlusMember;
  @override
  State<VillageHomeRotator> createState() => _VillageHomeRotatorState();
}

class _VillageHomeRotatorState extends State<VillageHomeRotator> {
  Timer? _timer;
  bool _question = true;
  static const forest = Color(0xFF073C24);
  static const gold = Color(0xFFE8C575);

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant VillageHomeRotator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlusMember != widget.isPlusMember) {
      _question = true;
      _restart();
    }
  }

  void _restart() {
    _timer?.cancel();
    if (!widget.isPlusMember) {
      _timer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted) setState(() => _question = !_question);
      });
    }
  }

  void _switch() {
    if (widget.isPlusMember) return;
    setState(() => _question = !_question);
    _restart();
  }

  DateTime _easternNow() {
    final utc = DateTime.now().toUtc();
    int sunday(int month, int nth) {
      final first = DateTime.utc(utc.year, month, 1);
      return 1 + (7 - first.weekday) % 7 + (nth - 1) * 7;
    }
    final start = DateTime.utc(utc.year, 3, sunday(3, 2), 7);
    final end = DateTime.utc(utc.year, 11, sunday(11, 1), 6);
    final hours = !utc.isBefore(start) && utc.isBefore(end) ? 4 : 5;
    return utc.subtract(Duration(hours: hours));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showQuestion = widget.isPlusMember || _question;
    final date = DailyVillageQuestionService.dateKey(_easternNow());
    return Stack(children: [
      // Existing banner defines height and is never visually altered.
      Opacity(
        opacity: showQuestion ? 0 : 1,
        child: IgnorePointer(
          ignoring: showQuestion,
          child: const VillagePlusBanner(),
        ),
      ),
      if (showQuestion)
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Material(
              color: forest,
              child: InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => DailyVillageQuestionScreen(dateKey: date),
                )),
                child: LayoutBuilder(builder: (context, bounds) {
                  final compact = bounds.maxWidth < 470;
                  return Stack(children: [
                    const Positioned.fill(child: DecoratedBox(
                      decoration: BoxDecoration(gradient: LinearGradient(
                        colors: [Color(0xFF214A30), forest, Color(0xFF062B1C)],
                      )),
                    )),
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      width: compact ? bounds.maxWidth * .22 : 150,
                      child: const VillagePlusPhoto(),
                    ),
                    Positioned(
                      left: 0, top: 0, bottom: 0,
                      width: compact ? bounds.maxWidth * .30 : 190,
                      child: const DecoratedBox(decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Color(0x0007351F), Color(0xFF103B25),
                        ]),
                      )),
                    ),
                    Positioned(
                      right: 0, bottom: 0, left: 0,
                      child: IgnorePointer(child: CustomPaint(
                        size: const Size(double.infinity, 18),
                        painter: _QuestionGoldWave(),
                      )),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 54 : 126, 5, compact ? 9 : 20, 16),
                      child: Row(children: [
                        Expanded(
                          flex: compact ? 8 : 7,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 2),
                                decoration: BoxDecoration(
                                  color: gold,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text('TODAY’S',
                                  style: TextStyle(color: forest, fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('Village Question',
                                  style: TextStyle(
                                    fontFamily: 'VillagePlusDisplay',
                                    color: Colors.white,
                                    fontSize: compact ? 20 : 34,
                                    fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(height: 2),
                              Flexible(child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                stream: DailyVillageQuestionService().watchQuestion(date),
                                builder: (context, snapshot) {
                                  final data = snapshot.data?.data();
                                  final question = (data?['question'] ??
                                      data?['text'] ?? data?['prompt']) as String?;
                                  final published = data?['status'] == 'published';
                                  return Text(
                                    published && question != null && question.trim().isNotEmpty
                                        ? question : 'Come with a question. Leave with a perspective.',
                                    maxLines: compact ? 3 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white,
                                      fontSize: compact ? 11 : 16, height: 1.1),
                                  );
                                },
                              )),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8E9),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Share Your Perspective',
                                        style: TextStyle(color: forest,
                                          fontSize: compact ? 10 : 13,
                                          fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 5),
                                      const Icon(Icons.arrow_forward,
                                        color: forest, size: 14),
                                    ]),
                                ),
                              ),

                            ],
                          ),
                        ),
                        Container(
                          width: 1, height: bounds.maxHeight * .55,
                          margin: EdgeInsets.symmetric(
                            horizontal: compact ? 7 : 20),
                          color: gold.withValues(alpha: .8),
                        ),
                        Expanded(
                          flex: compact ? 2 : 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.groups_rounded,
                                color: gold, size: 34),
                              const SizedBox(height: 7),
                              Text('Come with a question. Leave with a perspective.',
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white,
                                  fontSize: compact ? 9 : 14, height: 1.2)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ),
      if (!widget.isPlusMember)
        Positioned(
          left: 0,
          right: 0,
          bottom: 5,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final isQuestionDot in [false, true])
                  Semantics(
                    button: true,
                    label: isQuestionDot
                        ? 'Show today’s Village Question'
                        : 'Show Village Plus',
                    selected: showQuestion == isQuestionDot,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (showQuestion != isQuestionDot) _switch();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: showQuestion == isQuestionDot
                                ? gold : Colors.white.withValues(alpha: .5),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .75),
                              width: .7,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
    ]);
  }
}

class _QuestionGoldWave extends CustomPainter {
  const _QuestionGoldWave();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .38, size.height)
      ..quadraticBezierTo(size.width * .67, -8,
          size.width, size.height * .65);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFE8C575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
