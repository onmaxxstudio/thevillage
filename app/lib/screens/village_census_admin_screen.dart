import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/admin_access_service.dart';
import '../services/village_census_service.dart';

class VillageCensusAdminScreen extends StatefulWidget {
  const VillageCensusAdminScreen({super.key});
  @override
  State<VillageCensusAdminScreen> createState() => _VillageCensusAdminScreenState();
}
class _VillageCensusAdminScreenState extends State<VillageCensusAdminScreen> {
  final service = VillageCensusService();
  final access = AdminAccessService();
  final question = TextEditingController();
  final choices = TextEditingController(text: 'Yes\nNo');
  final date = TextEditingController();
  final category = TextEditingController(text: 'Community');
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final d = DateTime.now();
    date.text = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
  @override
  void dispose() { question.dispose(); choices.dispose(); date.dispose(); category.dispose(); super.dispose(); }
  Future<void> add() async {
    final options = choices.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (question.text.trim().isEmpty || options.length < 2 || options.length > 4 ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date.text)) return;
    setState(() => saving = true);
    try {
      final id = '${date.text}_${DateTime.now().microsecondsSinceEpoch}';
      await service.createQuestion(id: id, text: question.text, options: options, dateKey: date.text, category: category.text);
      question.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved. Publish when ready.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to save question.')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: access.isCurrentUserAdmin(),
    builder: (context, allowed) {
      if (!allowed.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      if (allowed.data != true) return const Scaffold(body: Center(child: Text('Admin access required')));
      return Scaffold(
        appBar: AppBar(title: const Text('Census Insights')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Create a daily question', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(controller: question, decoration: const InputDecoration(labelText: 'Question')),
          TextField(controller: choices, maxLines: 4, decoration: const InputDecoration(labelText: 'Answers (one per line)')),
          TextField(controller: date, decoration: const InputDecoration(labelText: 'Date YYYY-MM-DD')),
          TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
          const SizedBox(height: 12),
          FilledButton(onPressed: saving ? null : add, child: const Text('Save question draft')),
          const Divider(height: 36),
          const Text('Question history and results', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: service.watchQuestions(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Unable to load questions: ${snapshot.error}');
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Text('No census questions yet.');
              return Column(children: [
                for (final doc in snapshot.data!.docs)
                  Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${doc.data()['dateKey']} · ${doc.data()['category']}', style: const TextStyle(fontSize: 12)),
                      Text('${doc.data()['text']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Status: ${doc.data()['status']}'),
                      if (doc.data()['status'] == 'draft')
                        TextButton(onPressed: () async {
                          await service.publishQuestion(doc.id);
                        }, child: const Text('Publish')),
                      FutureBuilder<Map<String, int>>(
                        future: service.countVotes(doc.id, List<String>.from(doc.data()['options'] ?? [])),
                        builder: (context, counts) {
                          if (!counts.hasData) return const Text('Loading vote totals…');
                          final total = counts.data!.values.fold<int>(0, (a,b) => a+b);
                          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Total votes: $total'),
                            for (final entry in counts.data!.entries)
                              Text('${entry.key}: ${entry.value} (${total == 0 ? 0 : (100*entry.value/total).round()}%)'),
                          ]);
                        },
                      ),
                    ],
                  ))),
              ]);
            },
          ),
        ]),
      );
    },
  );
}
