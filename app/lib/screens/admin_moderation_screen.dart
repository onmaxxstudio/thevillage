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
              final doc = docs[index];
              final data = doc.data();
              return Card(
                child: ListTile(
                  title: Text((data['question'] ?? 'Untitled post').toString()),
                  subtitle: Text(
                    '${data['author'] ?? 'Village member'} • ${data['category'] ?? 'Other'}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Delete post',
                    color: Colors.red.shade700,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _deletePost(doc.id),
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
              final targetType = (data['targetType'] ?? 'content').toString();
              final targetId = (data['targetId'] ?? '').toString();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${targetType.toUpperCase()} • ${data['reason'] ?? 'Report'}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if ((data['details'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text((data['details']).toString()),
                      ],
                      const SizedBox(height: 8),
                      Text('Status: $status'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (status == 'open')
                            OutlinedButton(
                              onPressed: () => _setStatus(doc.id, 'dismissed'),
                              child: const Text('Dismiss'),
                            ),
                          if (status == 'open')
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: sage),
                              onPressed: () => _setStatus(doc.id, 'resolved'),
                              child: const Text('Resolve'),
                            ),
                          if (targetType == 'post' || targetType == 'reply')
                            OutlinedButton(
                              onPressed: () => _deleteReportedTarget(
                                reportId: doc.id,
                                targetType: targetType,
                                targetId: targetId,
                              ),
                              child: Text(
                                targetType == 'post' ? 'Delete Post' : 'Delete Reply',
                              ),
                            ),
                        ],
                      ),
                      if (targetType == 'message') ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Message report ready for admin review.',
                          style: TextStyle(fontSize: 12),
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

  Future<void> _deletePost(String id) async {
    if (!await _confirm('Delete this post?')) return;
    try {
      await service.deletePost(id);
      _snack('Post deleted.');
    } on FirebaseException catch (error) {
      _snack('Could not delete post: ${error.message ?? error.code}');
    }
  }

  Future<void> _deleteReportedTarget({
    required String reportId,
    required String targetType,
    required String targetId,
  }) async {
    if (!await _confirm('Delete reported $targetType?')) return;
    try {
      final removed = await service.deleteReportedTarget(
        targetType: targetType,
        targetId: targetId,
      );
      if (!removed) {
        _snack('That content could not be located.');
        return;
      }
      await service.setReportStatus(reportId, 'resolved');
      _snack('Reported content deleted and report resolved.');
    } on FirebaseException catch (error) {
      _snack('Could not remove content: ${error.message ?? error.code}');
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await service.setReportStatus(id, status);
      _snack(status == 'resolved' ? 'Report resolved.' : 'Report dismissed.');
    } on FirebaseException catch (error) {
      _snack('Could not update report: ${error.message ?? error.code}');
    }
  }

  Future<bool> _confirm(String title) async =>
      (await showDialog<bool>(
        context: context,
        useRootNavigator: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      )) ?? false;

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
