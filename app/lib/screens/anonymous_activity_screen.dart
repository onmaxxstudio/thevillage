import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Only public anonymous content is shown. No account/profile lookup occurs.
class AnonymousActivityScreen extends StatelessWidget {
  const AnonymousActivityScreen({super.key, required this.name});
  final String name;

  Future<List<Map<String, dynamic>>> _load() async {
    final db = FirebaseFirestore.instance;
    final claim = await db.collection('anonymous_names').doc(name).get();
    final legacy = claim.data()?['legacyName'];
    final names = {name, if (legacy is String && legacy.isNotEmpty) legacy};
    final snapshot = await db.collection('village_posts').get();
    final items = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final post = doc.data();
      if (names.contains(post['author'])) {
        items.add({'kind': 'Post', 'text': post['question'], 'createdAt': post['createdAt']});
      }
      for (final reply in (post['replies'] as List? ?? const [])) {
        if (reply is Map && names.contains(reply['author'])) {
          items.add({'kind': 'Comment', 'text': reply['text'], 'createdAt': reply['createdAt']});
        }
      }
    }
    items.sort((a, b) => _time(b['createdAt']).compareTo(_time(a['createdAt'])));
    return items;
  }

  static DateTime _time(dynamic value) => value is Timestamp ? value.toDate() : DateTime.tryParse('$value') ?? DateTime(1970);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Anonymous activity')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: TextButton(onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => AnonymousActivityScreen(name: name))), child: const Text('Could not load activity. Retry')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        return ListView(padding: const EdgeInsets.all(20), children: [
          SelectableText(name, style: Theme.of(context).textTheme.titleLarge),
          const Text('Posts and comments shared under this anonymous name.'),
          const SizedBox(height: 16),
          if (items.isEmpty) const Text('No anonymous activity yet.'),
          for (final item in items) Card(child: ListTile(title: Text('${item['kind']}'), subtitle: Text('${item['text']}'))),
        ]);
      },
    ),
  );
}
