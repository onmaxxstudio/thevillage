import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Shows only anonymous content; never looks up a public member profile.
class AnonymousActivityScreen extends StatefulWidget {
  const AnonymousActivityScreen({super.key, required this.name, this.isOwner = false});
  final String name;
  final bool isOwner;

  @override
  State<AnonymousActivityScreen> createState() => _AnonymousActivityScreenState();
}

class _AnonymousActivityScreenState extends State<AnonymousActivityScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF496B4F);
  late Future<List<Map<String, dynamic>>> activity;

  @override
  void initState() {
    super.initState();
    activity = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final db = FirebaseFirestore.instance;
    final claim = await db.collection('anonymous_names').doc(widget.name).get();
    final legacy = claim.data()?['legacyName'];
    final names = {widget.name, if (legacy is String && legacy.isNotEmpty) legacy};
    final snapshot = await db.collection('village_posts').get();
    final items = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final post = doc.data();
      if (names.contains(post['author'])) {
        items.add({'kind': 'Post', 'text': post['question'], 'createdAt': post['createdAt']});
      }
      for (final reply in (post['replies'] as List? ?? const [])) {
        if (reply is Map && names.contains(reply['author'])) {
          items.add({'kind': 'Comment', 'text': reply['text'],
            'question': post['question'], 'createdAt': reply['createdAt']});
        }
      }
    }
    items.sort((a, b) => _time(b['createdAt']).compareTo(_time(a['createdAt'])));
    return items;
  }

  static DateTime _time(dynamic value) => value is Timestamp
      ? value.toDate() : DateTime.tryParse('$value') ?? DateTime(1970);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => activity = next);
    await next;
  }

  Widget _items(List<Map<String, dynamic>> items, String kind) {
    final filtered = items.where((item) => item['kind'] == kind).toList();
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          if (filtered.isEmpty) Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Text(kind == 'Post' ? 'No anonymous posts yet.' : 'No anonymous comments yet.',
              textAlign: TextAlign.center),
          ),
          for (final item in filtered) Card(
            color: const Color(0xFFFFFDF8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(MaterialLocalizations.of(context).formatMediumDate(_time(item['createdAt']).toLocal()),
                  style: const TextStyle(fontSize: 12, color: sage)),
                const SizedBox(height: 9),
                SelectableText('${item['text']}', style: const TextStyle(fontSize: 15, height: 1.45)),
                if (item['question'] != null) ...[
                  const Divider(height: 24),
                  const Text('In response to', style: TextStyle(fontSize: 12, color: sage, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${item['question']}', style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: cream,
      appBar: AppBar(backgroundColor: cream,
        title: Text(widget.isOwner ? 'My Anonymous Activity' : 'Anonymous Activity')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: activity,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: TextButton.icon(
              onPressed: () => setState(() => activity = _load()),
              icon: const Icon(Icons.refresh), label: const Text('Could not load activity. Retry')));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final items = snapshot.data!;
            final posts = items.where((item) => item['kind'] == 'Post').length;
            final comments = items.length - posts;
            return Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(18, 12, 18, 14), child: Column(children: [
                const Icon(Icons.visibility_off_outlined, color: sage, size: 28),
                const SizedBox(height: 8),
                SelectableText(widget.name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: sage)),
                const SizedBox(height: 6),
                Text(widget.isOwner ? 'Review what you have shared under your anonymous name.'
                  : 'Posts and comments shared under this anonymous name.', textAlign: TextAlign.center),
              ])),
              TabBar(labelColor: sage, indicatorColor: sage, tabs: [
                Tab(text: 'Posts ($posts)'), Tab(text: 'Comments ($comments)'),
              ]),
              Expanded(child: TabBarView(children: [_items(items, 'Post'), _items(items, 'Comment')])),
            ]);
          },
        ),
      )),
    ),
  );
}
