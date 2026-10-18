import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ask_village_screen.dart';
import 'settings_screen.dart';
import 'write_freely_screen.dart';
import '../services/private_journal_service.dart';
import 'my_space_tools_screen.dart';

class MySpaceScreen extends StatefulWidget {
  const MySpaceScreen({super.key});

  @override
  State<MySpaceScreen> createState() => _MySpaceScreenState();
}

class _MySpaceScreenState extends State<MySpaceScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const green = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE7DED1);

  final text = TextEditingController();
  final search = TextEditingController();
  final libraryKey = GlobalKey();
  String prompt = '';
  String? editingId;
  bool saving = false;
  bool writing = false;
  String? editorEntryType;
  bool? editorJournalPromptCompleted;
  DateTime? reflectionDate;
  String searchText = '';
  String selectedFilter = 'All';

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
    return uid == null
        ? null
        : FirebaseFirestore.instance
            .collection('private_journals')
            .doc(uid)
            .collection('entries');
  }

  Widget _buildEditorRoute(
    BuildContext routeContext,
    PrivateJournalService journal, {
    PrivateJournalDraft? draft,
  }) {
    // iOS Safari can report a stale keyboard inset on a newly pushed route.
    // That can collapse the editor viewport before the user focuses a field.
    final mediaQuery = MediaQuery.of(routeContext);
    return MediaQuery(
      data: mediaQuery.copyWith(viewInsets: EdgeInsets.zero),
      child: WriteFreelyEditorScreen(journal: journal, draft: draft),
    );
  }

  Future<void> openWriteFreely({bool continueExisting = false}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to use your private journal.')),
      );
      return;
    }
    final journal = PrivateJournalService(uid: uid);
    // Clear focus from the previous page before pushing the editor. Safari can
    // preserve a stale keyboard inset across nested Navigator routes.
    FocusManager.instance.primaryFocus?.unfocus();

    // Opening the editor should never depend on a Firestore read finishing.
    // The editor restores a draft in the background after its UI is visible.
    if (!continueExisting) {
      await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
        builder: (routeContext) => _buildEditorRoute(routeContext, journal),
      ));
      return;
    }

    try {
      final draft = await journal.loadDraft().timeout(const Duration(seconds: 3));
      if (!mounted) return;
      if (draft?.hasContent == true) {
        await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
          builder: (routeContext) => _buildEditorRoute(routeContext, journal, draft: draft),
        ));
        return;
      }
      if (continueExisting) {
        final savedEntries = await journal.loadEntries().timeout(const Duration(seconds: 3));
        if (!mounted) return;
        if (savedEntries.isNotEmpty) {
          await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
            builder: (_) => SavedJournalEntryScreen(
              journal: journal,
              entry: savedEntries.first,
              entries: savedEntries,
              index: 0,
            ),
          ));
          return;
        }
      }
      await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
        builder: (routeContext) => _buildEditorRoute(
          routeContext,
          journal,
          draft: draft ?? const PrivateJournalDraft(
            title: '', body: '', tags: [], attachments: [], entryId: null,
          ),
        ),
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your saved journal could not be checked. The editor is opening so you can keep writing.')),
        );
        await Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
          builder: (routeContext) => _buildEditorRoute(routeContext, journal),
        ));
      }
    }
  }

  @override
  void dispose() {
    text.dispose();
    search.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final collection = entries;
    if (collection == null || text.text.trim().isEmpty || saving) return;
    setState(() => saving = true);
    try {
      final entryType = prompt.toLowerCase().contains('letter')
          ? 'letter'
          : prompt.isEmpty
              ? 'journal'
              : 'guided';
      final data = <String, dynamic>{
        'body': text.text.trim(),
        'prompt': prompt,
        // Store one-off journal prompts as the already-supported "guided"
        // type. The prompt library recognizes these by their prompt text.
        'entryType': editorEntryType == 'journal_prompt'
            ? 'guided'
            : editorEntryType ?? entryType,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (editingId == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['favorite'] = false;
        await collection.add(data);
      } else {
        await collection.doc(editingId).update(data);
      }
      if (!mounted) return;
      final returnToFullPageTool =
          editorEntryType == 'journal_prompt' ||
          editorEntryType == 'gratitude' ||
          editorEntryType == 'letter';
      setState(() {
        editingId = null;
        prompt = '';
        writing = false;
        editorEntryType = null;
        editorJournalPromptCompleted = null;
        reflectionDate = null;
        text.clear();
      });
      if (returnToFullPageTool) {
        Navigator.of(context, rootNavigator: true).pop();
      } else {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved privately to My Space.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> remove(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this reflection?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await entries?.doc(id).delete();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete entry.')),
        );
      }
    }
  }

  Future<void> toggleFavorite(String id, bool favorite) async {
    try {
      await entries?.doc(id).update({'favorite': !favorite});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update favorite.')),
        );
      }
    }
  }

  Future<void> shareExcerpt(String body) async {
    final controller = TextEditingController(
      text: body.length > 1500 ? body.substring(0, 1500) : body,
    );
    final excerpt = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share with the Village?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your original journal entry stays private. Only the text you choose below will be copied into a new Village post. Posting is anonymous by default.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 1500,
              minLines: 3,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Edit what you want to share',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Keep private'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Review post'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || excerpt == null || excerpt.length < 10) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AskVillageScreen(
          initialQuestion: excerpt,
          defaultAnonymous: true,
          initialCategory: 'Mental Wellness',
        ),
      ),
    );
  }

  void startWriting(String value, {QueryDocumentSnapshot<Map<String, dynamic>>? entry, String? entryType}) {
    setState(() {
      prompt = value;
      editingId = entry?.id;
      writing = true;
      editorEntryType = entryType ?? entry?.data()['entryType'] as String?;
      final entryData = entry?.data();
      reflectionDate = entryData == null ? DateTime.now() : entryDate(entryData) ?? DateTime.now();
      editorJournalPromptCompleted = entryData == null
          ? false
          : entryData['journalPromptCompleted'] as bool? ??
                (entryData['entryType'] == 'guided' &&
                    entryData['guidedJourneyId'] == null);
      text.text = entry?.data()['body'] as String? ?? '';
    });

    if (editorEntryType == 'gratitude' ||
        editorEntryType == 'journal_prompt' ||
        editorEntryType == 'letter') {
      final editorPage = switch (editorEntryType) {
        'gratitude' => _gratitudeEditorPage(),
        'journal_prompt' => _journalPromptEditorPage(),
        _ => _letterEditorPage(),
      };
      Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
        builder: (_) => editorPage,
      )).whenComplete(() {
        if (mounted && writing) setState(() => writing = false);
      });
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: _editorCard(),
        ),
      ),
    ).whenComplete(() {
      if (mounted && writing) setState(() => writing = false);
    });
  }

  Widget _gratitudeEditorPage() {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: green,
        centerTitle: true,
        title: Text(
          'Gratitude',
          style: GoogleFonts.playfairDisplay(
            color: green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to gratitude',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt,
                    style: GoogleFonts.playfairDisplay(
                      color: green,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: text,
                      autofocus: false,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      maxLength: 10000,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Start writing here…',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFFFFDF8),
                        contentPadding: const EdgeInsets.all(18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: green, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: Text(saving ? 'Saving…' : 'Save privately'),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _letterEditorPage() {
    final date = reflectionDate ?? DateTime.now();
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(date);
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: green,
        centerTitle: true,
        title: Text(
          'Write a Letter',
          style: GoogleFonts.playfairDisplay(
            color: green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to letters',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt,
                    style: GoogleFonts.playfairDisplay(
                      color: green,
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: Color(0xFF77766F),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Color(0xFF77766F),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: text,
                      autofocus: false,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      maxLength: 10000,
                      textAlignVertical: TextAlignVertical.top,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Write what you want to say…',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFFFFDF8),
                        contentPadding: const EdgeInsets.all(18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: green, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: Text(saving ? 'Saving…' : 'Save privately'),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _journalPromptEditorPage() {
    final date = reflectionDate ?? DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dateLabel = '${months[date.month - 1]} ${date.day}, ${date.year}';

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: green,
        centerTitle: true,
        title: Text(
          'Journal Prompt',
          style: GoogleFonts.playfairDisplay(
            color: green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to prompts',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prompt,
                    style: GoogleFonts.playfairDisplay(
                      color: green,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: Color(0xFF77766F)),
                      const SizedBox(width: 7),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          color: Color(0xFF77766F),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: TextField(
                      controller: text,
                      autofocus: false,
                      expands: true,
                      minLines: null,
                      maxLines: null,
                      maxLength: 10000,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: 'Start writing here…',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFFFFDF8),
                        contentPadding: const EdgeInsets.all(18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(color: green, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: const Icon(Icons.lock_outline_rounded, size: 18),
                      label: Text(saving ? 'Saving…' : 'Save privately'),
                      style: FilledButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void showPromptPicker({String? category}) {
    final available = category == null
        ? prompts.entries.toList()
        : prompts.entries.where((item) => item.key == category).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .72,
          minChildSize: .42,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                category == null ? 'Find a prompt' : '$category reflections',
                style: GoogleFonts.playfairDisplay(
                  color: green,
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              for (final group in available) ...[
                if (category == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Text(
                      group.key,
                      style: const TextStyle(
                        color: green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                for (final question in group.value)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(question),
                    trailing: const Icon(Icons.arrow_forward_rounded, color: green),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      startWriting(question);
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  DateTime? entryDate(Map<String, dynamic> data) {
    final value = data['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String entryKind(Map<String, dynamic> data) {
    final kind = data['entryType'] as String?;
    if (kind != null) {
      if (kind == 'guided' && data['guidedJourneyId'] == null) {
        return 'journal_prompt';
      }
      return kind;
    }
    final value = (data['prompt'] as String? ?? '').toLowerCase();
    if (value.contains('letter')) return 'letter';
    return value.isEmpty ? 'journal' : 'guided';
  }

  String monthLabel(DateTime? date) {
    if (date == null) return 'NEW';
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[date.month - 1];
  }

  Future<void> scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target != null) {
      await Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = entries;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        foregroundColor: green,
        centerTitle: true,
        title: Text(
          'My Space',
          style: GoogleFonts.playfairDisplay(
            color: green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: collection == null
          ? const Center(child: Text('Sign in to open your private journal.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: collection.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Unable to load private entries.'));
                }
                final docs = snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3, bottom: 10),
                          child: Column(children: [
                            Text('My Space', style: GoogleFonts.playfairDisplay(fontSize: 24, color: green, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            const Text('Your space. Your thoughts. Your growth.', style: TextStyle(color: ink, fontSize: 13)),
                          ]),
                        ),
                        _heroBanner(),
                        const SizedBox(height: 12),
                        _featureGrid(),
                        const SizedBox(height: 14),
                        _journalLibrary(docs),
                        const SizedBox(height: 12),
                        _closingQuote(),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _heroBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Preserve the phone composition while giving the hero image more
        // presence on wider tablet and desktop layouts.
        final isWide = constraints.maxWidth >= 600;
        final imageWidth = isWide ? constraints.maxWidth * .42 : 205.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: isWide ? 210 : 190,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFF5E7DA)),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: imageWidth,
                  child: Image.asset(
                    'assets/images/my_space_hero.jpg',
                    fit: BoxFit.cover,
                    alignment: isWide ? Alignment.center : Alignment.topCenter,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: isWide ? [.38, .66, 1] : [.45, .72, 1],
                      colors: const [
                        Color(0xFFF5E7DA),
                        Color(0xCFF5E7DA),
                        Color(0x00F5E7DA),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 8, 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: isWide ? constraints.maxWidth * .54 : 235,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'A safe space\nto be you.',
                            style: GoogleFonts.playfairDisplay(
                              color: green,
                              fontWeight: FontWeight.w500,
                              height: .98,
                              fontSize: isWide ? 34 : 30,
                            ),
                          ),
                          SizedBox(height: isWide ? 10 : 8),
                          Text(
                            'Clearer thoughts. A calmer you.\nA brighter tomorrow.',
                            style: TextStyle(fontSize: isWide ? 14 : 13, color: ink),
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.lock_rounded, size: 14, color: green),
                              SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Your thoughts stay yours. Private by default.',
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.15,
                                    color: ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _continueCard(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final latest = docs.isEmpty ? null : docs.first;
    final data = latest?.data();
    final title = data == null
        ? 'Your story starts here'
        : ((data['prompt'] as String? ?? '').trim().isEmpty
            ? 'Your latest reflection'
            : data['prompt'] as String);
    final detail = data == null
        ? 'A quiet place for everything on your mind.'
        : (data['body'] as String? ?? '').replaceAll('\n', ' ');
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 112,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFE5E8D4)),
            Positioned(
              left: 105,
              top: 0,
              bottom: 0,
              width: 178,
              child: Image.asset('assets/images/my_space_books.jpg', fit: BoxFit.cover),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE5E8D4), Color(0xF2E5E8D4), Color(0x80E5E8D4), Color(0x00E5E8D4)],
                  stops: [0, .34, .62, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Continue where you left off',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(fontSize: 15, color: ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: ink),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => openWriteFreely(continueExisting: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Continue', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureGrid() {
    final features = <_SpaceFeature>[
      _SpaceFeature('Write Freely', Icons.edit_note_rounded, const Color(0xFFF8E4DC), () => openWriteFreely()),
      _SpaceFeature('Guided\nJournaling', Icons.spa_outlined, const Color(0xFFE5EBDD), () => _openTool('guided')),
      _SpaceFeature('Journal\nPrompts', Icons.wb_sunny_outlined, const Color(0xFFF9EBD7), () => _openTool('prompts')),
      _SpaceFeature('Gratitude', Icons.favorite_rounded, const Color(0xFFF8E4DC), () => _openTool('gratitude')),
      _SpaceFeature('Mood\nReflections', Icons.sentiment_satisfied_alt_rounded, const Color(0xFFE5EBDD), () => _openTool('mood')),
      _SpaceFeature('Milestones', Icons.emoji_events_rounded, const Color(0xFFF9EBD7), () => _openTool('milestones')),
      _SpaceFeature('Vision &\nGoals', Icons.track_changes_rounded, const Color(0xFFF8E4DC), () => _openTool('goals')),
      _SpaceFeature('Letters', Icons.mail_outline_rounded, const Color(0xFFE5EBDD), () => _openTool('letters')),
      _SpaceFeature('Saved\nFavorites', Icons.bookmark_border_rounded, const Color(0xFFF9EBD7), () => _openTool('favorites')),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 7,
        mainAxisSpacing: 7,
        childAspectRatio: .96,
      ),
      itemBuilder: (context, index) => _featureCard(features[index]),
    );
  }

  Future<void> _openTool(String mode) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => MySpaceToolsScreen(
        mode: mode,
        onWritePrompt: (value, type) {
          if (!mounted) return;
          startWriting(value, entryType: type);
        },
        onOpenEntry: (entry, {entryType}) {
          if (!mounted) return;
          startWriting(
            entry.data()['prompt'] as String? ?? '',
            entry: entry,
            entryType: entryType,
          );
        },
      ),
    ));
  }

  Widget _featureCard(_SpaceFeature feature) {
    return Material(
      color: feature.color,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: feature.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(feature.icon, color: feature.accent, size: 31),
            const SizedBox(height: 8),
            Text(feature.title, textAlign: TextAlign.center, maxLines: 2,
              style: GoogleFonts.playfairDisplay(color: ink, fontSize: 12.5, height: 1.05, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }

  Widget _editorCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  editingId == null ? 'Write freely' : 'Continue your reflection',
                  style: GoogleFonts.playfairDisplay(
                    color: green,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close editor',
                onPressed: () {
                  setState(() {
                    writing = false;
                    editingId = null;
                    prompt = '';
                    text.clear();
                  });
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (prompt.isNotEmpty) ...[
            Text(prompt, style: const TextStyle(color: green, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: text,
            autofocus: false,
            minLines: 5,
            maxLines: 10,
            maxLength: 10000,
            decoration: InputDecoration(
              hintText: 'Start writing here…',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: saving ? null : save,
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: Text(saving ? 'Saving…' : 'Save privately'),
              style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _journalLibrary(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final visible = docs.where((doc) {
      final data = doc.data();
      final body = data['body'] as String? ?? '';
      final promptText = data['prompt'] as String? ?? '';
      final queryMatch = '$body $promptText'.toLowerCase().contains(searchText);
      final kind = entryKind(data);
      final filterMatch = switch (selectedFilter) {
        'Journal Entries' => kind == 'journal',
        'Guided Prompts' => kind == 'guided',
        'Letters' => kind == 'letter',
        'Favorites' => data['favorite'] == true,
        _ => true,
      };
      return queryMatch && filterMatch;
    }).toList();
    return Container(
      key: libraryKey,
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E8DC)),
        boxShadow: [BoxShadow(color: ink.withValues(alpha: .035), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: green, size: 30),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Journal Library',
                      style: GoogleFonts.playfairDisplay(
                        color: ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'All your entries, letters and reflections in one place.',
                      maxLines: 2,
                      style: TextStyle(color: Color(0xFF5F625D), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => MyEntriesScreen(journal: PrivateJournalService(uid: FirebaseAuth.instance.currentUser!.uid)),
                )),
                style: TextButton.styleFrom(foregroundColor: ink, padding: const EdgeInsets.symmetric(horizontal: 5)),
                child: const Text('My Journal  →', style: TextStyle(fontSize: 11.5)),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: search,
                  onChanged: (value) => setState(() => searchText = value.toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    hintText: 'Search your reflections…',
                    hintStyle: const TextStyle(fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: cream,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide(color: line)),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Container(
                height: 43,
                width: 43,
                decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(12), border: Border.all(color: line)),
                child: IconButton(
                  tooltip: 'Show favorites',
                  onPressed: () => setState(() => selectedFilter = selectedFilter == 'Favorites' ? 'All' : 'Favorites'),
                  icon: Icon(selectedFilter == 'Favorites' ? Icons.filter_list_off_rounded : Icons.filter_list_rounded, size: 20, color: ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Journal Entries', 'Guided Prompts', 'Letters', 'Favorites'].map((label) {
                final selected = selectedFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.white : ink)),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => selectedFilter = label),
                    selectedColor: green,
                    backgroundColor: cream,
                    side: BorderSide(color: selected ? green : line),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Recent Entries', style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => _openTool('insights'),
                style: TextButton.styleFrom(foregroundColor: green, padding: const EdgeInsets.symmetric(horizontal: 4)),
                child: const Text('Insights', style: TextStyle(fontSize: 11)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => MyEntriesScreen(journal: PrivateJournalService(uid: FirebaseAuth.instance.currentUser!.uid)),
                )),
                style: TextButton.styleFrom(foregroundColor: ink, padding: EdgeInsets.zero),
                child: const Text('See All →', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
              child: Text(
                docs.isEmpty ? 'Your journal is ready whenever you are.' : 'No entries match this view yet.',
                style: const TextStyle(color: Color(0xFF686B65), fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visible.length > 6 ? 6 : visible.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (context, index) => _entryCard(visible[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final date = entryDate(data);
    final title = (data['prompt'] as String? ?? '').trim().isEmpty
        ? 'Personal reflection'
        : data['prompt'] as String;
    final kind = entryKind(data);
    final tag = kind == 'letter' ? 'Letter' : kind == 'guided' ? 'Growth' : 'Reflection';
    final tagColor = kind == 'letter' ? const Color(0xFFC15F61) : kind == 'guided' ? green : const Color(0xFFB77C29);
    return InkWell(
      onTap: () => startWriting(data['prompt'] as String? ?? '', entry: doc),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 147,
        padding: const EdgeInsets.fromLTRB(9, 7, 7, 7),
        decoration: BoxDecoration(
          color: kind == 'letter' ? const Color(0xFFFFEFEB) : const Color(0xFFFFF8ED),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFF0E5D8)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 31,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(monthLabel(date), style: const TextStyle(fontSize: 8, letterSpacing: .4, color: Color(0xFF62645F))),
                  Text('${date?.day ?? '—'}', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, height: 1.1)),
                ],
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    heightFactor: .8,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 140),
                      iconSize: 16,
                      onSelected: (action) {
                        if (action == 'favorite') toggleFavorite(doc.id, data['favorite'] == true);
                        if (action == 'share') shareExcerpt(data['body'] as String? ?? '');
                        if (action == 'delete') remove(doc.id);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'favorite', child: Text(data['favorite'] == true ? 'Remove favorite' : 'Add to favorites')),
                        const PopupMenuItem(value: 'share', child: Text('Review excerpt to share')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete private entry')),
                      ],
                    ),
                  ),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.playfairDisplay(fontSize: 11, height: 1.05, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Expanded(
                    child: Text(data['body'] as String? ?? '', maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, height: 1.12, color: Color(0xFF53564F))),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(color: tagColor.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)),
                    child: Text(tag, style: TextStyle(fontSize: 9, color: tagColor, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _closingQuote() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(
        height: 92,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Row(
              children: [
                Expanded(child: Image.asset('assets/images/my_space_quote_leaves.jpg', fit: BoxFit.cover)),
                Expanded(child: Image.asset('assets/images/my_space_quote_mountains.jpg', fit: BoxFit.cover)),
              ],
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0x004B5C41), Color(0xAFFFFAF1), Color(0x004B5C41)]),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '“Your story is still unfolding,\nand every chapter matters.”',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    height: 1.15,
                    fontStyle: FontStyle.italic,
                    color: ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceFeature {
  const _SpaceFeature(this.title, this.icon, this.color, this.onTap);

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  Color get accent => switch (title.replaceAll('\n', ' ')) {
        'Write Freely' => const Color(0xFF355C3B),
        'Guided Journaling' => const Color(0xFF527657),
        'Journal Prompts' => const Color(0xFFB77C29),
        'Gratitude' => const Color(0xFFBE615F),
        'Mood Reflections' => const Color(0xFF39765D),
        'Milestones' => const Color(0xFFB77C29),
        'Vision & Goals' => const Color(0xFFB56054),
        'Letters' => const Color(0xFF355C3B),
        _ => const Color(0xFF355C3B),
      };
}
