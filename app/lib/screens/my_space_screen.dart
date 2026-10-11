import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ask_village_screen.dart';

class MySpaceScreen extends StatefulWidget {
  const MySpaceScreen({super.key});
  @override
  State<MySpaceScreen> createState() => _MySpaceScreenState();
}

class _MySpaceScreenState extends State<MySpaceScreen> {
  static const green = Color(0xFF355C3B);
  static const cream = Color(0xFFFFFAF1);
  final text = TextEditingController();
  final search = TextEditingController();
  String prompt = '';
  String? editingId;
  bool saving = false;
  String filter = '';
  static const prompts = <String, List<String>>{
    'Stress': ['What is weighing on you today?', 'What can you set down for now?'],
    'Anxiety': ['What is in your control today?', 'What would you tell a worried friend?'],
    'Grief': ['What do you wish you could say?', 'What memory would you like to hold onto?'],
    'Parenting': ['What did parenting teach you this week?'],
    'Relationships': ['What conversation do you need to have?'],
    'Work': ['What drained your energy today?'],
    'Gratitude': ['What small moment mattered today?'],
    'Self-worth': ['What strength have you overlooked?'],
  };
  CollectionReference<Map<String, dynamic>>? get entries {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : FirebaseFirestore.instance.collection('private_journals').doc(uid).collection('entries');
  }
  @override
  void dispose() { text.dispose(); search.dispose(); super.dispose(); }
  Future<void> save() async {
    final collection = entries;
    if (collection == null || text.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      final data = <String, dynamic>{'body': text.text.trim(), 'prompt': prompt, 'updatedAt': FieldValue.serverTimestamp()};
      if (editingId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        await collection.add(data);
      } else {
        await collection.doc(editingId).update(data);
      }
      if (!mounted) return;
      setState(() { editingId = null; prompt = ''; text.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved privately to My Space.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Please try again.')));
    } finally { if (mounted) setState(() => saving = false); }
  }
  Future<void> remove(String id) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete this reflection?'),
      content: const Text('This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))],
    ));
    if (confirmed != true) return;
    try { await entries?.doc(id).delete(); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete entry.'))); }
  }
  Future<void> shareExcerpt(String body) async {
    final controller = TextEditingController(text: body.length > 1500 ? body.substring(0, 1500) : body);
    final excerpt = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Share with the Village?'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Your original journal entry stays private. Only the text you choose below will be copied into a new Village post. Posting is anonymous by default.'),
        const SizedBox(height: 12),
        TextField(controller: controller, maxLength: 1500, minLines: 3, maxLines: 7,
          decoration: const InputDecoration(labelText: 'Edit what you want to share', border: OutlineInputBorder())),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Keep private')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('Review post')),
      ],
    ));
    controller.dispose();
    if (!mounted || excerpt == null || excerpt.length < 10) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AskVillageScreen(initialQuestion: excerpt, defaultAnonymous: true, initialCategory: 'Mental Wellness'),
    ));
  }

  void choosePrompt(String value) => setState(() { prompt = value; editingId = null; text.clear(); });
  @override
  Widget build(BuildContext context) {
    final collection = entries;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(backgroundColor: cream, foregroundColor: green, title: Text('My Space', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600))),
      body: collection == null ? const Center(child: Text('Sign in to open your private journal.')) : Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 680), child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Your thoughts. Your space. Your story.', style: GoogleFonts.playfairDisplay(fontSize: 25, color: green)),
            const SizedBox(height: 8),
            const Row(children: [Icon(Icons.lock_outline, size: 16, color: green), SizedBox(width: 6), Expanded(child: Text('Private by default. Only you can see your journal entries.'))]),
            const SizedBox(height: 22),
            Text("What's on your mind today?", style: GoogleFonts.playfairDisplay(fontSize: 23)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(onPressed: () => choosePrompt(''), icon: const Icon(Icons.edit_outlined), label: const Text('Write Freely')),
              OutlinedButton.icon(onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (sheetContext) => SafeArea(child: ListView(shrinkWrap: true, children: [
                const ListTile(title: Text('Find a prompt')),
                ...prompts.entries.expand((group) => [Padding(padding: const EdgeInsets.all(12), child: Text(group.key, style: const TextStyle(fontWeight: FontWeight.bold))), ...group.value.map((p) => ListTile(title: Text(p), onTap: () { choosePrompt(p); Navigator.pop(sheetContext); }))]),
              ]))), icon: const Icon(Icons.lightbulb_outline), label: const Text('Find a Prompt')),
            ]),
            if (prompt.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 16), child: Text(prompt, style: const TextStyle(fontWeight: FontWeight.w600, color: green))),
            const SizedBox(height: 12),
            TextField(controller: text, minLines: 6, maxLines: 12, maxLength: 10000, decoration: InputDecoration(
              hintText: 'Start writing here…', filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            )),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.lock_outline), label: Text(saving ? 'Saving…' : editingId == null ? 'Save privately' : 'Update private entry'), style: FilledButton.styleFrom(backgroundColor: green)),
            const SizedBox(height: 26),
            Text('Your journal history', style: GoogleFonts.playfairDisplay(fontSize: 22, color: green)),
            const SizedBox(height: 10),
            TextField(controller: search, onChanged: (value) => setState(() => filter = value.toLowerCase()), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search your reflections', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: collection.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('Unable to load private entries.');
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs.where((doc) => ('${doc.data()['body'] ?? ''} ${doc.data()['prompt'] ?? ''}').toLowerCase().contains(filter)).toList();
                if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(12), child: Text('No reflections yet. Your space is ready whenever you are.'));
                return Column(children: docs.map((doc) {
                  final data = doc.data();
                  return Card(color: Colors.white, child: ListTile(
                    title: Text((data['prompt'] as String? ?? '').isEmpty ? 'Personal reflection' : data['prompt'] as String, maxLines: 2),
                    subtitle: Text(data['body'] as String? ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                    onTap: () { setState(() { editingId = doc.id; prompt = data['prompt'] as String? ?? ''; text.text = data['body'] as String? ?? ''; }); },
                    trailing: PopupMenuButton<String>(tooltip: 'Entry actions', onSelected: (action) { if (action == 'delete') remove(doc.id); if (action == 'share') shareExcerpt(data['body'] as String? ?? ''); }, itemBuilder: (_) => const [PopupMenuItem(value: 'share', child: Text('Review excerpt to share')), PopupMenuItem(value: 'delete', child: Text('Delete private entry'))]),
                  ));
                }).toList());
              },
            ),
          ],
        )),
      ),
    );
  }
}
