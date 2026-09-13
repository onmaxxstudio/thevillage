import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_moderation_service.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  final service = AdminModerationService();
  int tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: cream,
          title: Text(
            'Moderation',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('All Posts'),
                    icon: Icon(Icons.forum_outlined),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Reports'),
                    icon: Icon(Icons.flag_outlined),
                  ),
                ],
                selected: {tab},
                onSelectionChanged: (value) => setState(() => tab = value.first),
              ),
            ),
            Expanded(child: tab == 0 ? _posts() : _reports()),
          ],
        ),
      );

  Widget _posts() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchPosts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No Village posts yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final data = docs[index].data();
              return Card(
                child: ListTile(
                  title: Text((data['question'] ?? 'Untitled post').toString()),
                  subtitle: Text(
                    '${data['author'] ?? 'Village member'} • ${data['category'] ?? 'Other'}',
                  ),
                ),
              );
            },
          );
        },
      );

  Widget _reports() => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.watchReports(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _error(snapshot.error);
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No reports to review.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final doc = docs[index];
              final data = doc.data();
              final status = (data['status'] ?? 'open').toString();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(data['targetType'] ?? 'content').toString().toUpperCase()} • ${data['reason'] ?? 'Report'}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if ((data['details'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text((data['details']).toString()),
                      ],
                      const SizedBox(height: 8),
                      Text('Status: $status'),
                      if (status == 'open') ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () => _setStatus(doc.id, 'dismissed'),
                              child: const Text('Dismiss'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: sage),
                              onPressed: () => _setStatus(doc.id, 'resolved'),
                              child: const Text('Resolve'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

  Future<void> _setStatus(String id, String status) async {
    try {
      await service.setReportStatus(id, status);
      _snack(status == 'resolved' ? 'Report resolved.' : 'Report dismissed.');
    } on FirebaseException catch (error) {
      _snack('Could not update report: ${error.message ?? error.code}');
    }
  }

  Widget _error(Object? error) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Moderation needs admin Firestore permission before it can load.\n\n$error',
        ),
      );

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
