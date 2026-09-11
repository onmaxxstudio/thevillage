import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';

class VillageAdminScreen extends StatefulWidget {
  const VillageAdminScreen({super.key});

  @override
  State<VillageAdminScreen> createState() => _VillageAdminScreenState();
}

class _VillageAdminScreenState extends State<VillageAdminScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  final service = AdminContentService();
  int tab = 0;

  String get type => ['communities', 'resources', 'events'][tab];
  String get singular => ['Community', 'Resource', 'Event'][tab];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        foregroundColor: ink,
        title: Text('Village Admin', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: sage,
        foregroundColor: Colors.white,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text('Add $singular'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Run the Village without touching code.', style: GoogleFonts.inter(color: ink, fontSize: 15)),
              const SizedBox(height: 16),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Communities'), icon: Icon(Icons.groups_2_outlined)),
                  ButtonSegment(value: 1, label: Text('Resources'), icon: Icon(Icons.menu_book_outlined)),
                  ButtonSegment(value: 2, label: Text('Events'), icon: Icon(Icons.event_outlined)),
                ],
                selected: {tab},
                onSelectionChanged: (value) => setState(() => tab = value.first),
              ),
            ]),
          ),
        ),
        Expanded(child: _content()),
      ]),
    );
  }

  Widget _content() {
    if (!service.cloudReady) {
      return const Center(child: Text('Firebase is not connected in this preview.'));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      key: ValueKey(type),
      stream: service.watch(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Admin content needs Firestore permission before it can load.\n\n${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(tab == 0 ? Icons.groups_2_outlined : tab == 1 ? Icons.menu_book_outlined : Icons.event_outlined, size: 48, color: sage),
              const SizedBox(height: 14),
              Text('No ${type.toLowerCase()} yet', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Tap “Add $singular” to create one. You can publish, edit, hide, or delete it here.', textAlign: TextAlign.center),
            ]),
          ));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final doc = docs[index];
            final data = doc.data();
            final published = data['published'] == true;
            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: ink.withValues(alpha: .08))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text((data['title'] ?? data['name'] ?? 'Untitled').toString(), style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text((data['description'] ?? data['summary'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: published ? sage.withValues(alpha: .1) : Colors.black.withValues(alpha: .05), borderRadius: BorderRadius.circular(99)), child: Text(published ? 'Published' : 'Draft', style: TextStyle(color: published ? sage : ink, fontWeight: FontWeight.w600))),
                      const Spacer(),
                      Switch(value: published, onChanged: (v) => service.setPublished(type, doc.id, v)),
                    ]),
                  ])),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _openEditor(id: doc.id, existing: data);
                      if (action == 'delete') _confirmDelete(doc.id);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('Delete $singular?'),
      content: const Text('This removes it from the admin content collection. This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (ok == true) await service.delete(type, id);
  }

  Future<void> _openEditor({String? id, Map<String, dynamic>? existing}) async {
    final title = TextEditingController(text: (existing?['title'] ?? existing?['name'] ?? '').toString());
    final description = TextEditingController(text: (existing?['description'] ?? existing?['summary'] ?? '').toString());
    final image = TextEditingController(text: (existing?['imageUrl'] ?? '').toString());
    final community = TextEditingController(text: (existing?['community'] ?? '').toString());
    final date = TextEditingController(text: (existing?['dateTimeLabel'] ?? '').toString());
    final body = TextEditingController(text: (existing?['body'] ?? '').toString());
    bool published = existing?['published'] == true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text(id == null ? 'Add $singular' : 'Edit $singular', style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700))), IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.close))]),
            const SizedBox(height: 8),
            _field(title, tab == 0 ? 'Community name' : '$singular title'),
            _field(description, 'Short description', lines: 3),
            _field(image, 'Cover image URL (optional)'),
            if (tab != 0) _field(community, 'Community / category'),
            if (tab == 1) _field(body, 'Resource content', lines: 8),
            if (tab == 2) _field(date, 'Date & time'),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Publish now'), subtitle: const Text('Turn this off to save as a draft.'), value: published, onChanged: (v) => setSheetState(() => published = v)),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                final values = <String, dynamic>{
                  tab == 0 ? 'name' : 'title': title.text.trim(),
                  'description': description.text.trim(),
                  'imageUrl': image.text.trim(),
                  'published': published,
                  'sortOrder': existing?['sortOrder'] ?? DateTime.now().millisecondsSinceEpoch,
                  if (tab != 0) 'community': community.text.trim(),
                  if (tab == 1) 'body': body.text.trim(),
                  if (tab == 2) 'dateTimeLabel': date.text.trim(),
                };
                await service.save(type: type, id: id, data: values);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              icon: const Icon(Icons.publish_outlined),
              label: Text(published ? 'Publish $singular' : 'Save Draft'),
            )),
          ])),
        );
      }),
    );
  }

  Widget _field(TextEditingController controller, String label, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: TextField(controller: controller, maxLines: lines, decoration: InputDecoration(labelText: label, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none))),
  );
}