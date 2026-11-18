import 'package:flutter/material.dart';
import '../services/daily_village_question_service.dart';
import 'daily_village_question_screen.dart';

class VillageQuestionHistoryScreen extends StatelessWidget {
  const VillageQuestionHistoryScreen({super.key, required this.saved});
  final bool saved;
  @override
  Widget build(BuildContext context) {
    final service = DailyVillageQuestionService();
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF1),
      appBar: AppBar(title: Text(saved ? 'Saved Perspectives' : 'Past Village Questions'),
        backgroundColor: const Color(0xFFFFFAF1)),
      body: StreamBuilder(
        stream: saved ? service.watchSavedPerspectives() : service.watchArchive(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Unable to load history. Please try again.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text(saved ? 'No saved perspectives yet.' : 'Past questions will appear here.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16), itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final date = saved ? (data['date'] as String? ?? '') : doc.id;
              return Card(child: ListTile(
                title: Text(saved ? (data['body'] as String? ?? '') : (data['question'] as String? ?? '')),
                subtitle: Text(date),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => DailyVillageQuestionScreen(dateKey: date))),
              ));
            },
          );
        },
      ),
    );
  }
}
