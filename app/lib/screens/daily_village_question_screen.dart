import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/daily_village_question_service.dart';
import '../widgets/village_perspective_card.dart';
import 'village_question_history_screen.dart';

/// Dedicated page opened from the homepage, within the existing app shell.
class DailyVillageQuestionScreen extends StatefulWidget {
  const DailyVillageQuestionScreen({super.key, required this.dateKey});
  final String dateKey;

  @override
  State<DailyVillageQuestionScreen> createState() =>
      _DailyVillageQuestionScreenState();
}

class _DailyVillageQuestionScreenState
    extends State<DailyVillageQuestionScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  final service = DailyVillageQuestionService();
  final composer = TextEditingController();
  bool sending = false;
  String? error;

  String get displayDate {
    final day = DateTime.tryParse(widget.dateKey);
    if (day == null) return widget.dateKey;
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
      'Saturday', 'Sunday'];
    return '${weekdays[day.weekday - 1]}, ${months[day.month - 1]} ${day.day}';
  }

  @override
  void dispose() {
    composer.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (sending || composer.text.trim().isEmpty) return;
    setState(() { sending = true; error = null; });
    try {
      await service.postResponse(widget.dateKey, composer.text);
      composer.clear();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    appBar: AppBar(
      backgroundColor: cream,
      foregroundColor: sage,
      centerTitle: true,
      title: Text('Ask the Village', style: GoogleFonts.playfairDisplay(
        fontSize: 24, fontWeight: FontWeight.w600)),
      actions: [PopupMenuButton<String>(
        tooltip: 'Question options',
        onSelected: (value) => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => VillageQuestionHistoryScreen(saved: value == 'saved'))),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'history', child: Text('Past Village Questions')),
          PopupMenuItem(value: 'saved', child: Text('Saved Perspectives')),
        ],
      )],
    ),
    body: FirebaseAuth.instance.currentUser == null
      ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, color: sage, size: 32),
                const SizedBox(height: 12),
                const Text('Daily Village Question is free for all registered members.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Please sign in to read and share perspectives.',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        )
      : StreamBuilder(
      stream: service.watchQuestion(widget.dateKey),
      builder: (context, question) {
        if (question.hasError) {
          return const Center(child: Text('Today’s question is unavailable. Please try again later.'));
        }
        if (!question.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = question.data!.data();
        if (data == null || data['status'] != 'published' ||
            data['publishAt'] is! Timestamp ||
            (data['publishAt'] as Timestamp).toDate().isAfter(DateTime.now())) {
          return const Center(child: Text('Today’s question is coming soon.'));
        }
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            Center(child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('D A I L Y   V I L L A G E   Q U E S T I O N',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: sage, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Center(child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFFE7EAD9),
                borderRadius: BorderRadius.circular(24)),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                child: Text(displayDate.toUpperCase(), style: GoogleFonts.inter(
                  color: sage, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600))),
            )),
            const SizedBox(height: 24),
            Text(data['question'] as String? ?? '', textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(color: const Color(0xFF102B24),
                fontSize: 36, height: 1.16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 26),
            Text('Come with a question. Leave with a perspective.',
              textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(
                color: sage, fontSize: 15, fontStyle: FontStyle.italic)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: const Color(0xFFFFFCF6),
                border: Border.all(color: const Color(0xFFE5DFD1)),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Color(0x140D2B20), blurRadius: 18, offset: Offset(0, 8))]),
              child: Column(children: [
                TextField(controller: composer, maxLines: 3, minLines: 2, maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: 'Share your perspective with the Village...',
                    border: InputBorder.none)),
                if (error != null) Align(alignment: Alignment.centerLeft,
                  child: Text(error!, style: const TextStyle(color: Colors.red))),
                Align(alignment: Alignment.centerRight,
                  child: FilledButton(onPressed: sending ? null : submit,
                    style: FilledButton.styleFrom(backgroundColor: sage,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15)),
                    child: Text(sending ? 'Posting...' : 'Post Response'))),
              ]),
            ),
            const SizedBox(height: 32),
            StreamBuilder(
              stream: service.watchResponses(widget.dateKey),
              builder: (context, responses) {
                if (responses.hasError) {
                  return const Text('Unable to load conversations.');
                }
                if (!responses.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = responses.data!.docs;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Flexible(child: Text('Village Responses',
                        style: GoogleFonts.playfairDisplay(color: sage, fontSize: 27,
                          fontWeight: FontWeight.w600))),
                      Text('${docs.length} responses',
                        style: GoogleFonts.inter(color: const Color(0xFF56615D), fontSize: 13)),
                    ]),
                    const SizedBox(height: 16),
                    if (docs.isEmpty) const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('Be the first to share your perspective.')),
                    for (final doc in docs)
                      VillagePerspectiveCard(
                        date: widget.dateKey,
                        responseId: doc.id,
                        body: doc.data()['body'] as String? ?? '',
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Material(color: const Color(0xFFE8EBD9), borderRadius: BorderRadius.circular(18),
              child: ListTile(leading: const Icon(Icons.inventory_2_outlined, color: sage),
                title: Text('Explore Past Village Questions',
                  style: GoogleFonts.playfairDisplay(color: sage, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right, color: sage),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => const VillageQuestionHistoryScreen(saved: false))))),
              ]),
            )),
          ],
        );
      },
    ),
  );
}
