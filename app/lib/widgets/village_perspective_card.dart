import 'package:flutter/material.dart';
import '../services/daily_village_question_service.dart';

/// Member-only response actions; helpful marks are one-time and saves are private.
class VillagePerspectiveCard extends StatefulWidget {
  const VillagePerspectiveCard({super.key, required this.date, required this.responseId, required this.body});
  final String date;
  final String responseId;
  final String body;
  @override
  State<VillagePerspectiveCard> createState() => _VillagePerspectiveCardState();
}

class _VillagePerspectiveCardState extends State<VillagePerspectiveCard> {
  final service = DailyVillageQuestionService();
  final replyController = TextEditingController();
  bool expanded = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    if (busy) return;
    setState(() { busy = true; error = null; });
    try {
      await service.postReply(widget.date, widget.responseId, replyController.text);
      replyController.clear();
    } catch (e) {
      if (mounted) setState(() => error = 'Could not post reply. Please try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Village Member', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.body),
        Wrap(spacing: 8, children: [
          StreamBuilder(
            stream: service.watchHelpful(widget.date, widget.responseId),
            builder: (context, snap) => TextButton.icon(
              onPressed: snap.hasData && snap.data!.exists ? null : () async {
                try { await service.markHelpful(widget.date, widget.responseId); }
                catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not mark this response as helpful.'))); }
              },
              icon: const Icon(Icons.favorite_border),
              label: Text(snap.hasData && snap.data!.exists ? 'Helped me' : 'This Helped Me'),
            ),
          ),
          StreamBuilder(
            stream: service.watchSaved(widget.date, widget.responseId),
            builder: (context, snap) => TextButton.icon(
              onPressed: () async {
                try { await service.toggleSaved(widget.date, widget.responseId, widget.body); }
                catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update saved perspective.'))); }
              },
              icon: Icon(snap.hasData && snap.data!.exists ? Icons.bookmark : Icons.bookmark_border),
              label: Text(snap.hasData && snap.data!.exists ? 'Saved' : 'Save'),
            ),
          ),
          TextButton.icon(onPressed: () => setState(() => expanded = !expanded),
            icon: const Icon(Icons.chat_bubble_outline), label: const Text('Replies')),
        ]),
        if (expanded) ...[
          StreamBuilder(
            stream: service.watchReplies(widget.date, widget.responseId),
            builder: (context, snap) {
              if (snap.hasError) return const Text('Replies are unavailable.');
              if (!snap.hasData) return const LinearProgressIndicator();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final reply in snap.data!.docs)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(reply.data()['body'] as String? ?? '')),
              ]);
            },
          ),
          TextField(controller: replyController, maxLength: 1000, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Add a thoughtful reply')),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          Align(alignment: Alignment.centerRight,
            child: TextButton(onPressed: busy ? null : _sendReply, child: const Text('Post reply'))),
        ],
      ]),
    ),
  );
}
