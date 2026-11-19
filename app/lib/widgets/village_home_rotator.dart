import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/daily_village_question_service.dart';
import '../screens/daily_village_question_screen.dart';
import 'village_plus_banner.dart';

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
                child: Stack(children: [
                  const Positioned.fill(child: DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(
                      colors: [Color(0xFF214A30), forest, Color(0xFF062B1C)],
                    )),
                  )),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 12, 48, 12),
                    child: Row(children: [
                      const Icon(Icons.local_cafe_outlined, color: gold, size: 36),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TODAY’S VILLAGE QUESTION',
                            style: TextStyle(color: gold, fontSize: 11,
                              fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: DailyVillageQuestionService().watchQuestion(date),
                            builder: (context, snapshot) {
                              final data = snapshot.data?.data();
                              final text = (data?['question'] ?? data?['text'] ?? data?['prompt']) as String?;
                              final published = data?['status'] == 'published';
                              return Text(
                                published && text != null && text.trim().isNotEmpty
                                    ? text : 'Come with a question. Leave with a perspective.',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white,
                                  fontSize: 15, fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                          const SizedBox(height: 5),
                          const Text('Share Your Perspective →',
                            style: TextStyle(color: gold, fontSize: 12,
                              fontWeight: FontWeight.w700)),
                        ],
                      )),
                    ]),
                  ),
                ]),
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
