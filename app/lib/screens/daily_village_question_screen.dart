import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void dispose() {
    composer.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (sending) return;
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
      title: const Text('Daily Village Question'),
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
          padding: const EdgeInsets.all(18),
          children: [
            Card(
              color: const Color(0xFFE8EBDD),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TODAY’S VILLAGE QUESTION',
                        style: TextStyle(color: sage, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Come with a question. Leave with a perspective.',
                        style: TextStyle(color: sage, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 16),
                    Text(data['question'] as String? ?? '',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    const Text('One question. Many perspectives. One village.'),
                  ],
                ),
              ),
            ),
            Wrap(spacing: 8, children: [
              TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VillageQuestionHistoryScreen(saved: false))), icon: const Icon(Icons.history), label: const Text('Past Village Questions')),
              TextButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VillageQuestionHistoryScreen(saved: true))), icon: const Icon(Icons.bookmark_outline), label: const Text('Saved Perspectives')),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: composer,
              maxLines: 4,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Share your perspective',
                border: OutlineInputBorder(),
              ),
            ),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: sending ? null : submit,
                child: const Text('Post response'),
              ),
            ),
            const SizedBox(height: 20),
            Text('Village Conversations',
                style: Theme.of(context).textTheme.titleMedium),
            StreamBuilder(
              stream: service.watchResponses(widget.dateKey),
              builder: (context, responses) {
                if (responses.hasError) {
                  return const Text('Unable to load conversations.');
                }
                if (!responses.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (responses.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Be the first to share your perspective.'),
                  );
                }
                return Column(
                  children: [
                    for (final doc in responses.data!.docs)
                      VillagePerspectiveCard(
                        date: widget.dateKey,
                        responseId: doc.id,
                        body: doc.data()['body'] as String? ?? '',
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    ),
  );
}
