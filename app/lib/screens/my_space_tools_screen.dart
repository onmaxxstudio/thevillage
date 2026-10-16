import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/private_journal_service.dart';
import 'write_freely_screen.dart';

const _cream = Color(0xFFFFFAF1);
const _paper = Color(0xFFFFFDF8);
const _green = Color(0xFF355C3B);
const _ink = Color(0xFF28332B);
const _sage = Color(0xFFE7EBDD);
const _line = Color(0xFFE7DED1);

const _promptGroups = <String, List<String>>{
  'Get to Know You': [
    'What parts of yourself feel most like home?',
    'What do you wish people understood about you?',
    'When do you feel most at ease being yourself?',
    'What are you learning to accept about yourself?',
    'What does a good day look like for you now?',
    'What is one thing you want to make more room for?',
  ],
  'Heal & Let Go': [
    'What are you ready to set down, even a little?',
    'What would you say to the version of you who was hurting?',
    'What boundary would help you feel safer?',
    'What is one thing you can forgive yourself for today?',
    'What feeling needs your attention instead of your judgment?',
    'What does healing look like in this season of your life?',
  ],
  'Relationships': [
    'What helps you feel seen and cared for?',
    'What conversation would bring more understanding?',
    'What do you need more of in your closest relationships?',
    'What boundary would protect a connection you value?',
    'How do you want to show up when a conversation gets hard?',
    'What does mutual effort look like to you?',
  ],
  'Growth Mindset': [
    'What small step would move you toward a life you want?',
    'What did a recent challenge teach you about your strengths?',
    'Where are you being more capable than you give yourself credit for?',
    'What would you try if you did not need to get it perfect?',
    'What habit is helping the person you are becoming?',
    'What is one lesson you want to carry forward?',
  ],
  'Faith & Purpose': [
    'What gives you a sense of purpose lately?',
    'Where have you found hope in an ordinary moment?',
    'What value do you want your choices to reflect?',
    'What helps you reconnect with what matters most?',
    'What are you trusting yourself to learn over time?',
    'What does a meaningful life feel like to you?',
  ],
  'Everyday Life': [
    'What moment from today do you want to remember?',
    'What is taking up the most space in your mind?',
    'What do you need tomorrow to feel a little lighter?',
    'What made you smile this week?',
    'What can wait while you take care of yourself?',
    'What are you looking forward to, even slightly?',
  ],
};

const _moods = <String, String>{
  'Happy': '😊',
  'Calm': '😌',
  'Grateful': '🥰',
  'Overwhelmed': '😵‍💫',
  'Sad': '😔',
  'Anxious': '😟',
  'Motivated': '💪',
  'Hopeful': '🌱',
  'Tired': '😴',
  'Angry': '😠',
};
const _moodTags = [
  'Self Love',
  'Healing',
  'Growth',
  'Boundaries',
  'Faith',
  'Relationships',
  'Work',
  'Family',
  'Letting Go',
];

class MySpaceToolsScreen extends StatefulWidget {
  const MySpaceToolsScreen({
    required this.mode,
    required this.onWritePrompt,
    super.key,
  });
  final String mode;
  final void Function(String prompt, String entryType) onWritePrompt;

  @override
  State<MySpaceToolsScreen> createState() => _MySpaceToolsScreenState();
}

class _MySpaceToolsScreenState extends State<MySpaceToolsScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  CollectionReference<Map<String, dynamic>>? get _entries {
    final uid = _uid;
    return uid == null
        ? null
        : FirebaseFirestore.instance
              .collection('private_journals')
              .doc(uid)
              .collection('entries');
  }

  CollectionReference<Map<String, dynamic>>? get _savedPrompts {
    final uid = _uid;
    return uid == null
        ? null
        : FirebaseFirestore.instance
              .collection('private_journals')
              .doc(uid)
              .collection('saved_prompts');
  }

  String get _title => switch (widget.mode) {
    'guided' => 'Guided Journaling',
    'prompts' => 'Journal Prompts',
    'gratitude' => 'Gratitude',
    'mood' => 'Mood Reflections',
    'milestones' => 'Milestones',
    'goals' => 'Vision & Goals',
    'letters' => 'Letters',
    'favorites' => 'Saved Favorites',
    'insights' => 'Journal Insights',
    'journal' => 'My Journal',
    _ => 'My Space',
  };

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 760;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back to My Space',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          _title,
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (widget.mode != 'guided' &&
              widget.mode != 'prompts' &&
              widget.mode != 'mood' &&
              widget.mode != 'milestones' &&
              widget.mode != 'goals' &&
              widget.mode != 'letters')
            IconButton(
              tooltip: 'Journal insights',
              onPressed: () => _open('insights'),
              icon: const Icon(Icons.insights_outlined),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _uid == null
          ? const Center(child: Text('Sign in to use your private journal.'))
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: wide ? 900 : 680),
                child: switch (widget.mode) {
                  'guided' => _guidedJourneyLibrary(),
                  'prompts' => _promptExperience(guided: false),
                  'gratitude' => _gratitude(),
                  'mood' => _mood(),
                  'milestones' => _recordList('milestone'),
                  'goals' => _recordList('goal'),
                  'letters' => _letters(),
                  'favorites' => _recordList('favorites'),
                  'insights' => _insights(),
                  'journal' => _recordList('all'),
                  _ => _promptExperience(guided: false),
                },
              ),
            ),
    );
  }

  void _open(String mode) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          MySpaceToolsScreen(mode: mode, onWritePrompt: widget.onWritePrompt),
    ),
  );

  Widget _topIntro(String subtitle) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Text(
      subtitle,
      style: const TextStyle(
        color: Color(0xFF5F625D),
        fontSize: 14,
        height: 1.35,
      ),
    ),
  );

  Widget _guidedJourneyLibrary() => _GuidedJourneyLibrary(
    entries: _entries,
    journeys: _guidedJourneys,
  );

  Widget _promptExperience({required bool guided}) {
    final categories = guided
        ? _promptGroups.keys.where((key) => key != 'Everyday Life').toList()
        : _promptGroups.keys.toList();
    return _PromptLibrary(
      categories: categories,
      savedPrompts: _savedPrompts,
      entries: _entries,
      onWrite: (prompt) {
        Navigator.pop(context);
        widget.onWritePrompt(prompt, 'guided');
      },
      onToggleFavorite: _togglePrompt,
      intro: guided
          ? 'Choose a gentle path and take the questions at your own pace.'
          : 'Find a question for the season you are in. Search, save, and return whenever you like.',
    );
  }

  Future<void> _togglePrompt(String prompt, String category, bool saved) async {
    final ref = _savedPrompts?.doc(base64Url.encode(utf8.encode(prompt)));
    if (ref == null) return;
    try {
      if (saved) {
        await ref.delete();
      } else {
        await ref.set({
          'prompt': prompt,
          'category': category,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      if (mounted) _message('Could not update saved prompts.');
    }
  }

  Widget _gratitude() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
    children: [
      _topIntro('Notice the good in your day, without needing it to be big.'),
      _wideAction(
        'Add a gratitude note',
        Icons.add_rounded,
        () => widget.onWritePrompt(
          'What is one thing you appreciate today?',
          'gratitude',
        ),
      ),
      const SizedBox(height: 10),
      _streamEntries(
        types: const {'gratitude'},
        emptyTitle: 'Your gratitude pages will gather here.',
        showActions: true,
      ),
    ],
  );

  Widget _mood() =>
      _MoodComposer(onSaved: _message, entries: _entries, uid: _uid!);

  Widget _letters() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
    children: [
      _topIntro(
        'Write privately to yourself or someone else. Nothing is sent automatically.',
      ),
      for (final item in const [
        (
          'A Letter to My Future Self',
          'A reminder of how far you have come and where you are going.',
          Icons.mark_email_unread_outlined,
        ),
        (
          'A Letter to Let Go',
          'Release what you no longer want to carry.',
          Icons.spa_outlined,
        ),
        (
          'A Letter to Someone Else',
          'Say what is on your heart. It stays here unless you choose otherwise.',
          Icons.mail_outline_rounded,
        ),
        (
          'A Custom Letter',
          'Choose your own recipient, reason, and words.',
          Icons.edit_note_rounded,
        ),
      ])
        _surface(
          margin: const EdgeInsets.only(bottom: 9),
          child: ListTile(
            leading: Icon(item.$3, color: _green, size: 28),
            title: Text(
              item.$1,
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(item.$2),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _green,
            ),
            onTap: () => widget.onWritePrompt(item.$1, 'letter'),
          ),
        ),
      const SizedBox(height: 10),
      _streamEntries(
        types: const {'letter'},
        emptyTitle: 'Your private letters will appear here.',
        showActions: true,
      ),
    ],
  );

  Widget _recordList(String kind) {
    final title = kind == 'milestone'
        ? 'Small steps deserve to be celebrated.'
        : kind == 'goal'
        ? 'Shape a vision, then move toward it one step at a time.'
        : kind == 'favorites'
        ? 'The pages and moments you want to keep close.'
        : 'Your writing, gathered in one private place.';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _topIntro(title),
        if (kind == 'milestone')
          _wideAction('Add a milestone', Icons.add_rounded, _addMilestone),
        if (kind == 'goal')
          _wideAction('Create a personal goal', Icons.add_rounded, _addGoal),
        const SizedBox(height: 10),
        _streamEntries(
          types: kind == 'favorites'
              ? null
              : kind == 'all'
              ? null
              : {kind},
          favoritesOnly: kind == 'favorites',
          emptyTitle: kind == 'favorites'
              ? 'Save an entry with the bookmark to find it here.'
              : kind == 'goal'
              ? 'Your goals will grow here.'
              : kind == 'milestone'
              ? 'Your milestones will appear here.'
              : 'Your journal is ready whenever you are.',
          showActions: true,
        ),
        if (kind == 'favorites') ...[
          const SizedBox(height: 8),
          Text(
            'Saved prompts',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              color: _green,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _savedPromptList(),
        ],
      ],
    );
  }

  Widget _savedPromptList() {
    final saved = _savedPrompts;
    if (saved == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: saved.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return const Text('Saved prompts could not be loaded.');
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator(color: _green));
        if (snapshot.data!.docs.isEmpty)
          return _surface(
            child: const Text(
              'Save a question from Journal Prompts to keep it here.',
              style: TextStyle(color: Color(0xFF74766F)),
            ),
          );
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data();
            final prompt = data['prompt'] as String? ?? '';
            final category = data['category'] as String? ?? 'Saved prompt';
            return _surface(
              margin: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => widget.onWritePrompt(prompt, 'guided'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              color: _ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category,
                            style: const TextStyle(color: _green, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove saved prompt',
                    onPressed: () => _togglePrompt(prompt, category, true),
                    icon: const Icon(Icons.bookmark_rounded, color: _green),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _streamEntries({
    Set<String>? types,
    required String emptyTitle,
    bool favoritesOnly = false,
    bool showActions = false,
  }) {
    final collection = _entries;
    if (collection == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _surface(
            child: const Text(
              'Your private entries could not be loaded. Check your connection and try again.',
            ),
          );
        if (!snapshot.hasData)
          return const Padding(
            padding: EdgeInsets.all(26),
            child: Center(child: CircularProgressIndicator(color: _green)),
          );
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data();
          final type = data['entryType'] as String? ?? 'journal';
          return (types == null || types.contains(type)) &&
              (!favoritesOnly || data['favorite'] == true);
        }).toList();
        if (docs.isEmpty)
          return _surface(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Center(
                child: Text(
                  emptyTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF74766F)),
                ),
              ),
            ),
          );
        return Column(
          children: docs
              .map((doc) => _recordTile(doc, showActions: showActions))
              .toList(),
        );
      },
    );
  }

  Widget _recordTile(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool showActions,
  }) {
    final data = doc.data();
    final favorite = data['favorite'] == true;
    final body = data['body'] as String? ?? '';
    final type = data['entryType'] as String? ?? 'journal';
    final stamp = type == 'milestone'
        ? (data['milestoneDate'] ?? data['createdAt'])
        : data['createdAt'];
    final date = stamp is Timestamp ? stamp.toDate() : DateTime.now();
    final title = (data['title'] as String? ?? '').trim().isEmpty
        ? (data['prompt'] as String? ?? 'A page from your journal')
        : data['title'] as String;
    return _surface(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF5EADB),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _month(date.month),
                  style: const TextStyle(fontSize: 9, color: _green),
                ),
                Text(
                  '${date.day}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 19,
                    color: _green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () => _openEntry(doc),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body.replaceAll('\n', ' '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: Color(0xFF5E615B),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    type == 'goal' && data['goalProgress'] is int
                        ? 'Goal · ${data['goalProgress']}% complete'
                        : type[0].toUpperCase() + type.substring(1),
                    style: const TextStyle(
                      fontSize: 10,
                      color: _green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showActions)
            IconButton(
              tooltip: favorite ? 'Remove favorite' : 'Save favorite',
              onPressed: () => _toggleFavorite(doc.reference, favorite),
              icon: Icon(
                favorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: favorite ? _green : const Color(0xFF8A8D84),
              ),
            ),
          if (type == 'goal' || type == 'milestone')
            PopupMenuButton<String>(
              onSelected: (action) {
                if (type == 'goal' && action == 'progress')
                  _changeProgress(doc);
                else if (type == 'milestone' && action == 'edit')
                  _editMilestone(doc);
                else
                  _delete(doc);
              },
              itemBuilder: (_) => type == 'goal'
                  ? const [
                      PopupMenuItem(
                        value: 'progress',
                        child: Text('Update progress'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete goal'),
                      ),
                    ]
                  : const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit milestone'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete milestone'),
                      ),
                    ],
            ),
        ],
      ),
    );
  }

  Future<void> _openEntry(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    final values = await _entries!.orderBy('createdAt', descending: true).get();
    if (!mounted) return;
    final journal = PrivateJournalService(uid: uid);
    final mapped = values.docs
        .map((item) => PrivateJournalEntry.fromDocument(item))
        .toList();
    final idx = mapped.indexWhere((entry) => entry.id == doc.id);
    if (idx < 0) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SavedJournalEntryScreen(
          journal: journal,
          entry: mapped[idx],
          entries: mapped,
          index: idx,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    DocumentReference<Map<String, dynamic>> ref,
    bool current,
  ) async {
    try {
      await ref.update({
        'favorite': !current,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      _message('Could not update this favorite.');
    }
  }

  Future<void> _addMilestone() async {
    final title = TextEditingController();
    final description = TextEditingController();
    DateTime date = DateTime.now();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: _paper,
          title: Text(
            'Celebrate a milestone',
            style: GoogleFonts.playfairDisplay(color: _green),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'What did you do?',
                  ),
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'A few words about it (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () async {
                    final next = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (next != null) setDialog(() => date = next);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${date.month}/${date.day}/${date.year}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save milestone'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      await _saveRecord(
        type: 'milestone',
        title: title.text.trim(),
        body: description.text.trim().isEmpty
            ? title.text.trim()
            : description.text.trim(),
        extra: {
          'milestoneDate': Timestamp.fromDate(date),
          'milestoneIcon': '🌱',
        },
      );
    }
    title.dispose();
    description.dispose();
  }

  Future<void> _addGoal() async {
    final title = TextEditingController();
    final steps = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _paper,
        title: Text(
          'Set a personal goal',
          style: GoogleFonts.playfairDisplay(color: _green),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'What do you want to work toward?',
              ),
            ),
            TextField(
              controller: steps,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'First action steps (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save goal'),
          ),
        ],
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      await _saveRecord(
        type: 'goal',
        title: title.text.trim(),
        body: steps.text.trim().isEmpty ? title.text.trim() : steps.text.trim(),
        extra: {
          'goalProgress': 0,
          'actionSteps': steps.text
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .toList(),
        },
      );
    }
    title.dispose();
    steps.dispose();
  }

  Future<void> _changeProgress(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final current = doc.data()['goalProgress'] is int
        ? doc.data()['goalProgress'] as int
        : 0;
    var value = current.toDouble();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: _paper,
          title: const Text('Update your progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: value,
                min: 0,
                max: 100,
                divisions: 10,
                activeColor: _green,
                onChanged: (v) => setDialog(() => value = v),
              ),
              Text('${value.round()}% complete'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (result == true) {
      try {
        await doc.reference.update({
          'goalProgress': value.round(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        _message('Could not update goal progress.');
      }
    }
  }

  Future<void> _delete(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final okay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete this ${doc.data()['entryType'] == 'milestone' ? 'milestone' : 'goal'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (okay == true) {
      try {
        await doc.reference.delete();
      } catch (_) {
        _message('Could not delete this item.');
      }
    }
  }

  Future<void> _editMilestone(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final title = TextEditingController(text: data['title'] as String? ?? '');
    final description = TextEditingController(
      text: data['body'] as String? ?? '',
    );
    final value = data['milestoneDate'];
    var date = value is Timestamp ? value.toDate() : DateTime.now();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: _paper,
          title: Text(
            'Edit milestone',
            style: GoogleFonts.playfairDisplay(color: _green),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'What did you do?',
                  ),
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final next = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (next != null) setDialog(() => date = next);
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('${date.month}/${date.day}/${date.year}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      try {
        await doc.reference.update({
          'title': title.text.trim(),
          'body': description.text.trim().isEmpty
              ? title.text.trim()
              : description.text.trim(),
          'milestoneDate': Timestamp.fromDate(date),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {
        _message('Could not update this milestone.');
      }
    }
    title.dispose();
    description.dispose();
  }

  Future<void> _saveRecord({
    required String type,
    required String title,
    required String body,
    List<String> tags = const [],
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      await _entries!.add({
        'title': title,
        'body': body,
        'prompt': '',
        'entryType': type,
        'tags': tags,
        'attachments': <String>[],
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...extra,
      });
    } catch (_) {
      _message('Could not save. Please try again.');
    }
  }

  Widget _insights() => _JournalInsights(entries: _entries);

  Widget _wideAction(String text, IconData icon, VoidCallback onTap) =>
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(text),
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
  Widget _surface({required Widget child, EdgeInsetsGeometry? margin}) =>
      Container(
        margin: margin,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _line),
        ),
        child: child,
      );
  void _message(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _GuidedJourney {
  const _GuidedJourney({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.steps,
  });

  final String id;
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final List<String> steps;
}

const _guidedJourneys = <_GuidedJourney>[
  _GuidedJourney(
    id: 'know-yourself',
    title: 'Getting to Know Yourself',
    subtitle: 'Reconnect with who you are and what you need.',
    category: 'Self-Discovery',
    icon: Icons.self_improvement_rounded,
    steps: [
      'When do you feel most like yourself?',
      'What part of you has been asking for more attention?',
      'What do you need more of in this season of your life?',
      'What is one kind promise you can make to yourself this week?',
    ],
  ),
  _GuidedJourney(
    id: 'stress-reset',
    title: 'A Gentle Stress Reset',
    subtitle: 'Sort through what feels heavy and find one next step.',
    category: 'Stress & Calm',
    icon: Icons.spa_outlined,
    steps: [
      'What is taking up the most space in your mind right now?',
      'Which part of this is within your control today?',
      'What can wait, be shared, or be set down for now?',
      'What is one small thing that would help you feel steadier?',
    ],
  ),
  _GuidedJourney(
    id: 'healing-release',
    title: 'Making Room to Heal',
    subtitle: 'Listen to what needs care, at your own pace.',
    category: 'Healing',
    icon: Icons.local_florist_outlined,
    steps: [
      'What feeling have you been carrying lately?',
      'What do you wish someone understood about it?',
      'What boundary, support, or comfort would help you feel safer?',
      'What are you ready to release, even a little?',
    ],
  ),
  _GuidedJourney(
    id: 'relationship-clarity',
    title: 'Relationship Clarity',
    subtitle: 'Name what matters to you and what you want to communicate.',
    category: 'Relationships',
    icon: Icons.favorite_border_rounded,
    steps: [
      'When do you feel most seen and cared for in this relationship?',
      'What need or concern have you been holding back?',
      'What would you like the other person to understand?',
      'What is one honest, respectful next step you can take?',
    ],
  ),
  _GuidedJourney(
    id: 'self-trust',
    title: 'Building Self-Trust',
    subtitle: 'Notice your strengths and practice listening to yourself.',
    category: 'Confidence',
    icon: Icons.verified_user_outlined,
    steps: [
      'What is a hard thing you have already made it through?',
      'What did that experience show you about your strengths?',
      'Where might you be ignoring your own needs or instincts?',
      'What small choice could help you trust yourself more?',
    ],
  ),
  _GuidedJourney(
    id: 'next-chapter',
    title: 'Imagining Your Next Chapter',
    subtitle: 'Turn what matters to you into a gentle, realistic next step.',
    category: 'Growth & Purpose',
    icon: Icons.wb_sunny_outlined,
    steps: [
      'What do you want more room for in your life?',
      'Which values do you want your choices to reflect?',
      'What is one thing you would like to try, learn, or change?',
      'What is the smallest first step you can take this week?',
    ],
  ),

  _GuidedJourney(
    id: 'things-i-never-said',
    title: 'The Things I Never Said',
    subtitle: 'Give unspoken thoughts a private place to land.',
    category: 'Healing & Letting Go',
    icon: Icons.mark_email_unread_outlined,
    steps: [
      'What truth or conversation keeps returning to your mind?',
      'What made it difficult to say those words at the time?',
      'What did you hope the other person would understand?',
      'What would you like to say to yourself now?',
    ],
  ),
  _GuidedJourney(
    id: 'learning-to-let-go',
    title: 'Learning to Let Go',
    subtitle: 'Explore what you may be ready to loosen, at your own pace.',
    category: 'Healing & Letting Go',
    icon: Icons.air_outlined,
    steps: [
      'What thought, role, or expectation feels hard to release?',
      'What has holding on helped you feel or avoid?',
      'What part of this situation is outside your control?',
      'What would you like to make room for instead?',
    ],
  ),
  _GuidedJourney(
    id: 'forgiving-myself',
    title: 'Forgiving Myself',
    subtitle: 'Meet regret with honesty, responsibility, and self-respect.',
    category: 'Healing & Letting Go',
    icon: Icons.favorite_border_rounded,
    steps: [
      'What choice or moment do you wish you could revisit?',
      'What was happening in your life when you made that choice?',
      'Is there a repair or lesson available to you now?',
      'What would a fair and compassionate message to yourself sound like?',
    ],
  ),
  _GuidedJourney(
    id: 'breaking-emotional-patterns',
    title: 'Breaking Emotional Patterns',
    subtitle: 'Notice familiar reactions and explore more supportive choices.',
    category: 'Healing & Letting Go',
    icon: Icons.loop_rounded,
    steps: [
      'What situation tends to bring out a reaction you later question?',
      'What is the first sign that this familiar pattern is beginning?',
      'What might this reaction be trying to protect?',
      'What different response would you like to practice next time?',
    ],
  ),
  _GuidedJourney(
    id: 'who-am-i-becoming',
    title: 'Who Am I Becoming?',
    subtitle: 'Notice the values and choices shaping your next chapter.',
    category: 'Self-Discovery & Identity',
    icon: Icons.wb_sunny_outlined,
    steps: [
      'What feels different about you compared with a year ago?',
      'Which values do you want your next choices to reflect?',
      'What quality would you like to practice more often?',
      'What small choice this week would move you in that direction?',
    ],
  ),
  _GuidedJourney(
    id: 'person-behind-expectations',
    title: 'The Person Behind the Expectations',
    subtitle: 'Separate your own voice from the roles and pressures around you.',
    category: 'Self-Discovery & Identity',
    icon: Icons.person_outline_rounded,
    steps: [
      'Which expectation feels loudest in your life right now?',
      'What do you want when you set other people’s evaluations aside?',
      'What has this expectation given you, and what has it asked of you?',
      'How would you describe yourself beyond your roles and duties?',
    ],
  ),
  _GuidedJourney(
    id: 'rediscovering-my-joy',
    title: 'Rediscovering My Joy',
    subtitle: 'Make room for moments and activities that bring you alive.',
    category: 'Self-Discovery & Identity',
    icon: Icons.local_florist_outlined,
    steps: [
      'When did you last feel lighter or absorbed in a moment?',
      'What did you enjoy before life became so full?',
      'What most often makes it hard to make room for joy?',
      'What small, realistic activity could bring you pleasure this week?',
    ],
  ),
  _GuidedJourney(
    id: 'understanding-my-values',
    title: 'Understanding My Values',
    subtitle: 'Clarify what matters to you and how it shows up in daily life.',
    category: 'Self-Discovery & Identity',
    icon: Icons.explore_outlined,
    steps: [
      'When have you recently felt proud of how you handled a situation?',
      'What value were you honoring in that moment?',
      'Which value has been getting less space than you would like?',
      'What everyday action could help you live closer to it?',
    ],
  ),
  _GuidedJourney(
    id: 'understanding-my-emotions',
    title: 'Understanding My Emotions',
    subtitle: 'Get curious about feelings without judging yourself for having them.',
    category: 'Emotional Wellness',
    icon: Icons.mood_outlined,
    steps: [
      'Which emotion has been most present for you lately?',
      'What was happening when you first noticed it?',
      'What might this feeling need you to notice or care for?',
      'What is one safe, realistic way to respond to that need?',
    ],
  ),
  _GuidedJourney(
    id: 'when-life-feels-overwhelming',
    title: 'When Life Feels Overwhelming',
    subtitle: 'Sort what needs attention from what can wait or be shared.',
    category: 'Emotional Wellness',
    icon: Icons.cloud_outlined,
    steps: [
      'What demands or worries are crowding your mind right now?',
      'Which one truly needs your attention first?',
      'What responsibility could be shared, postponed, or returned?',
      'What is the smallest useful next step you can take?',
    ],
  ),
  _GuidedJourney(
    id: 'making-peace-with-my-past',
    title: 'Making Peace With My Past',
    subtitle: 'Reflect on what came before while staying connected to today.',
    category: 'Emotional Wellness',
    icon: Icons.history_rounded,
    steps: [
      'Which past chapter has been on your mind lately?',
      'What would you like to acknowledge about the person you were then?',
      'What part of that story still feels unresolved?',
      'What present-day detail can remind you that you are here now?',
    ],
  ),
  _GuidedJourney(
    id: 'finding-calm-in-chaos',
    title: 'Finding Calm in the Chaos',
    subtitle: 'Find small anchors when life feels noisy or unpredictable.',
    category: 'Emotional Wellness',
    icon: Icons.waves_rounded,
    steps: [
      'What feels most chaotic or uncertain in your life right now?',
      'What is one part of today that is within your influence?',
      'Which place, person, or routine helps you feel steadier?',
      'What small anchor will you return to the next time things feel loud?',
    ],
  ),
  _GuidedJourney(
    id: 'how-i-give-and-receive-love',
    title: 'How I Give and Receive Love',
    subtitle: 'Notice the ways care feels meaningful to you and to others.',
    category: 'Love & Relationships',
    icon: Icons.favorite_border_rounded,
    steps: [
      'When have you recently felt cared for in a way that reached you?',
      'How do you naturally show people they matter to you?',
      'What kind of care is easiest for you to receive?',
      'What could you share with someone close about how care reaches you?',
    ],
  ),
  _GuidedJourney(
    id: 'understanding-my-relationship-patterns',
    title: 'Understanding My Relationship Patterns',
    subtitle: 'Explore familiar habits in connection with curiosity and care.',
    category: 'Love & Relationships',
    icon: Icons.hub_outlined,
    steps: [
      'What situation seems to repeat across more than one relationship?',
      'How do you tend to respond when you feel uncertain or overlooked?',
      'How might that response affect the people around you?',
      'What different response would you like to practice in a familiar moment?',
    ],
  ),
  _GuidedJourney(
    id: 'communicating-my-needs',
    title: 'Learning to Communicate My Needs',
    subtitle: 'Turn what you wish others knew into clear, respectful words.',
    category: 'Love & Relationships',
    icon: Icons.chat_bubble_outline_rounded,
    steps: [
      'What situation has left you wishing someone understood you better?',
      'What need might be underneath that frustration or disappointment?',
      'What specific request would help address that need?',
      'Write one clear, kind sentence you could use to express it.',
    ],
  ),
  _GuidedJourney(
    id: 'when-relationships-change',
    title: 'When Relationships Change',
    subtitle: 'Make space for what is shifting and what matters to you.',
    category: 'Love & Relationships',
    icon: Icons.compare_arrows_rounded,
    steps: [
      'What feels different in a relationship that matters to you?',
      'What part of the relationship do you miss or appreciate?',
      'What hope or worry do you have about what comes next?',
      'What choice can help you care for yourself through this change?',
    ],
  ),
  _GuidedJourney(
    id: 'starting-over',
    title: 'Starting Over',
    subtitle: 'Gather what you have learned and take a first step into what is next.',
    category: 'Life Transitions & Purpose',
    icon: Icons.restart_alt_rounded,
    steps: [
      'What part of your life feels like it has ended or changed shape?',
      'What strength, skill, or support are you bringing into this new chapter?',
      'What would you like to do differently this time?',
      'What is one small step you can take in the next week?',
    ],
  ),
  _GuidedJourney(
    id: 'discovering-my-purpose',
    title: 'Discovering My Purpose',
    subtitle: 'Explore meaning through values, contribution, and everyday choices.',
    category: 'Life Transitions & Purpose',
    icon: Icons.lightbulb_outline_rounded,
    steps: [
      'When have you recently felt that what you were doing mattered?',
      'Which values keep guiding you through difficult choices?',
      'What kind of contribution feels worthwhile and sustainable to you?',
      'What small experiment could help you explore a source of meaning?',
    ],
  ),
  _GuidedJourney(
    id: 'navigating-career-changes',
    title: 'Navigating Career Changes',
    subtitle: 'Reflect on work transitions, strengths, and the conditions you need.',
    category: 'Life Transitions & Purpose',
    icon: Icons.work_outline_rounded,
    steps: [
      'What career or work transition are you navigating right now?',
      'What do you most want your work to provide in this season?',
      'What strength or experience could you carry into a new direction?',
      'What conversation or action would help you explore a next step?',
    ],
  ),
  _GuidedJourney(
    id: 'life-didnt-go-as-planned',
    title: 'When Life Doesn’t Go as Planned',
    subtitle: 'Make room for disappointment while noticing choices still available.',
    category: 'Life Transitions & Purpose',
    icon: Icons.alt_route_rounded,
    steps: [
      'What did you expect to happen that has not happened as planned?',
      'What possibility or future are you grieving?',
      'What part of the situation is still within your influence?',
      'What revised next step could honor what matters to you?',
    ],
  ),
  _GuidedJourney(
    id: 'becoming-more-confident',
    title: 'Becoming More Confident',
    subtitle: 'Build confidence from evidence, practice, and self-respect.',
    category: 'Confidence & Personal Growth',
    icon: Icons.verified_user_outlined,
    steps: [
      'Where do you most wish you trusted your ability or voice?',
      'What have you handled that required courage or persistence?',
      'What does confidence mean to you in everyday life?',
      'What small action could help you practice confidence this week?',
    ],
  ),
  _GuidedJourney(
    id: 'learning-to-trust-myself',
    title: 'Learning to Trust Myself',
    subtitle: 'Reconnect with your judgment and practice following through on your own choices.',
    category: 'Confidence & Personal Growth',
    icon: Icons.self_improvement_rounded,
    steps: [
      'Where do you find yourself second-guessing your own judgment most?',
      'Recall a time you made a choice that felt right for you. What helped?',
      'What information or boundary would help you feel steadier in a current decision?',
      'What small promise could you realistically keep to yourself this week?',
    ],
  ),
  _GuidedJourney(
    id: 'celebrating-small-wins',
    title: 'Celebrating My Small Wins',
    subtitle: 'Notice effort and progress that may have gone unrecognized.',
    category: 'Confidence & Personal Growth',
    icon: Icons.celebration_outlined,
    steps: [
      'What is one thing you did recently that deserves acknowledgment?',
      'What did it take for you to make that progress?',
      'What personal quality helped you along the way?',
      'How would you like to mark or remember this win?',
    ],
  ),
  _GuidedJourney(
    id: 'rewriting-inner-dialogue',
    title: 'Rewriting My Inner Dialogue',
    subtitle: 'Notice your self-talk and practice a more balanced inner voice.',
    category: 'Confidence & Personal Growth',
    icon: Icons.edit_note_rounded,
    steps: [
      'What phrase do you often say to yourself when something goes wrong?',
      'How does that phrase affect your mood or next choice?',
      'What would you say to someone you care about in the same situation?',
      'Write a fairer, more balanced sentence you can practice instead.',
    ],
  ),
];

const _guidedCategoryOrder = <String>[
  'Healing & Letting Go',
  'Self-Discovery & Identity',
  'Emotional Wellness',
  'Love & Relationships',
  'Life Transitions & Purpose',
  'Confidence & Personal Growth',
];

String _guidedCategoryFor(_GuidedJourney journey) => switch (journey.category) {
  'Healing' => 'Healing & Letting Go',
  'Self-Discovery' => 'Self-Discovery & Identity',
  'Stress & Calm' => 'Emotional Wellness',
  'Relationships' => 'Love & Relationships',
  'Confidence' => 'Confidence & Personal Growth',
  'Growth & Purpose' => 'Life Transitions & Purpose',
  _ => journey.category,
};

const _guidedCategoryDetails = <String, (String, IconData)>{
  'Healing & Letting Go': (
    'Make space for what hurt, what you are carrying, and what you may be ready to release.',
    Icons.spa_outlined,
  ),
  'Self-Discovery & Identity': (
    'Reconnect with your preferences, values, joy, and the person you are becoming.',
    Icons.self_improvement_rounded,
  ),
  'Emotional Wellness': (
    'Understand what you are feeling and find steadier ways through demanding seasons.',
    Icons.waves_rounded,
  ),
  'Love & Relationships': (
    'Explore communication, connection, changing relationships, and the care you need.',
    Icons.favorite_border_rounded,
  ),
  'Life Transitions & Purpose': (
    'Reflect on new chapters, work changes, purpose, and the direction you want to take.',
    Icons.explore_outlined,
  ),
  'Confidence & Personal Growth': (
    'Practice self-trust, recognize your progress, and grow a kinder inner voice.',
    Icons.verified_user_outlined,
  ),
};

class _GuidedJourneyLibrary extends StatefulWidget {
  const _GuidedJourneyLibrary({
    required this.entries,
    required this.journeys,
  });

  final CollectionReference<Map<String, dynamic>>? entries;
  final List<_GuidedJourney> journeys;

  @override
  State<_GuidedJourneyLibrary> createState() => _GuidedJourneyLibraryState();
}

class _GuidedJourneyLibraryState extends State<_GuidedJourneyLibrary>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isCompleted(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data['entryType'] != 'guided') return false;
    if (data['guidedJourneyCompleted'] == true) return true;
    final body = data['body'] as String? ?? '';
    return body.isNotEmpty && !RegExp(r'\n—(?:\n|$)').hasMatch(body);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<_GuidedJourney>>{
      for (final category in _guidedCategoryOrder) category: <_GuidedJourney>[],
    };
    for (final journey in widget.journeys) {
      grouped.putIfAbsent(_guidedCategoryFor(journey), () => <_GuidedJourney>[]);
      grouped[_guidedCategoryFor(journey)]!.add(journey);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your Journey Starts Within',
              style: GoogleFonts.playfairDisplay(
                color: _green,
                fontSize: 27,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 5, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'A little guidance. A deeper understanding of yourself.',
              style: TextStyle(color: Color(0xFF5F625D), height: 1.4),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 7, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Choose a topic for this season of your life. Each journey has four reflections you can explore at your own pace.',
              style: TextStyle(color: Color(0xFF5F625D), height: 1.4),
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          labelColor: _green,
          unselectedLabelColor: const Color(0xFF74766F),
          indicatorColor: _green,
          tabs: const [
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: widget.entries?.orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      final unfinished = snapshot.data!.docs
                          .where((doc) => doc.data()['entryType'] == 'guided' && !_isCompleted(doc))
                          .toList();
                      if (unfinished.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saved in progress',
                            style: GoogleFonts.playfairDisplay(
                              color: _green,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          for (final doc in unfinished)
                            _completedJourneyCard(doc, completed: false),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Explore journeys',
                      style: GoogleFonts.playfairDisplay(
                        color: _green,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final category in _guidedCategoryOrder)
                    _categorySection(
                      context,
                      category,
                      grouped[category] ?? const <_GuidedJourney>[],
                      initiallyExpanded: false,
                    ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your reflections are private. Take only the questions that feel useful today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF74766F), fontSize: 11, height: 1.4),
                  ),
                ],
              ),
              _completedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _completedTab() {
    final collection = widget.entries;
    if (collection == null) return const Center(child: Text('Sign in to view completed journeys.'));
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Completed journeys could not be loaded. Check your connection and try again.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final docs = snapshot.data!.docs.where(_isCompleted).toList();
        if (docs.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _paper,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _line),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.auto_awesome_outlined, color: _green, size: 30),
                    SizedBox(height: 9),
                    Text(
                      'Your completed journeys will be kept here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Finish all four reflections in a journey and it will appear in this tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF74766F), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'A place to revisit the thoughts and progress you have already put into words.',
                style: TextStyle(color: Color(0xFF5F625D), height: 1.4),
              ),
            ),
            for (final doc in docs)
              _completedJourneyCard(doc, completed: true),
          ],
        );
      },
    );
  }

  Widget _completedJourneyCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, {required bool completed}) {
    final data = doc.data();
    final title = data['title'] as String? ?? 'Completed journey';
    final body = data['body'] as String? ?? '';
    final stamp = data['createdAt'];
    final date = stamp is Timestamp ? stamp.toDate() : null;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _sage,
          child: Icon(
            completed ? Icons.check_rounded : Icons.edit_outlined,
            color: _green,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.playfairDisplay(color: _ink, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          date == null
              ? (completed ? 'Completed' : 'In progress')
              : '${completed ? 'Completed' : 'In progress'} · ${date.month}/${date.day}/${date.year}',
          style: const TextStyle(color: _green, fontSize: 12),
        ),
        iconColor: _green,
        collapsedIconColor: _green,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(body, style: const TextStyle(color: Color(0xFF5F625D), height: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _categorySection(
    BuildContext context,
    String category,
    List<_GuidedJourney> journeys, {
    required bool initiallyExpanded,
  }) {
    final details = _guidedCategoryDetails[category];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(details?.$2 ?? Icons.auto_awesome_outlined, color: _green),
          ),
          title: Text(
            category,
            style: GoogleFonts.playfairDisplay(
              color: _green,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${journeys.length} ${journeys.length == 1 ? 'journey' : 'journeys'}',
            style: const TextStyle(color: Color(0xFF656961), fontSize: 12),
          ),
          iconColor: _green,
          collapsedIconColor: _green,
          children: [
            if (details != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    details.$1,
                    style: const TextStyle(
                      color: Color(0xFF5F625D),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            for (final journey in journeys)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _journeyCard(context, journey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _journeyCard(BuildContext context, _GuidedJourney journey) => Material(
    color: const Color(0xFFFFFCF7),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _GuidedJourneyScreen(
            journey: journey,
            entries: widget.entries,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(color: _sage, shape: BoxShape.circle),
              child: Icon(journey.icon, color: _green, size: 21),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    journey.title,
                    style: GoogleFonts.playfairDisplay(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    journey.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF656961),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${journey.steps.length} reflections',
                    style: const TextStyle(
                      color: _green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: _green),
          ],
        ),
      ),
    ),
  );
}

}
class _GuidedJourneyScreen extends StatefulWidget {
  const _GuidedJourneyScreen({
    required this.journey,
    required this.entries,
  });

  final _GuidedJourney journey;
  final CollectionReference<Map<String, dynamic>>? entries;

  @override
  State<_GuidedJourneyScreen> createState() => _GuidedJourneyScreenState();
}

class _GuidedJourneyScreenState extends State<_GuidedJourneyScreen> {
  late final List<TextEditingController> _answers;
  int _step = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _answers = List.generate(
      widget.journey.steps.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final answer in _answers) {
      answer.dispose();
    }
    super.dispose();
  }

  Future<void> _saveJourney() async {
    final collection = widget.entries;
    if (collection == null || _saving) return;
    if (_answers.every((answer) => answer.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a few words before saving your journey.')),
      );
      return;
    }
    setState(() => _saving = true);
    final isComplete = _answers.every((answer) => answer.text.trim().isNotEmpty);\n    final body = List.generate(widget.journey.steps.length, (index) {
      final answer = _answers[index].text.trim();
      return '${index + 1}. ${widget.journey.steps[index]}\n${answer.isEmpty ? '—' : answer}';
    }).join('\n\n');
    try {
      await collection.add({
        'title': widget.journey.title,
        'body': body,
        'prompt': 'Guided journey: ${widget.journey.title}',
        'entryType': 'guided',
        'guidedJourneyId': widget.journey.id,\n        'guidedJourneyCompleted': isComplete,
        'tags': [widget.journey.category, 'Guided Journey'],
        'attachments': <String>[],
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your guided reflection was saved privately.')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your guided reflection. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.journey.steps.length;
    final isLast = _step == total - 1;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back to guided journaling',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Step ${_step + 1} of $total',
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                Text(
                  widget.journey.title,
                  style: GoogleFonts.playfairDisplay(
                    color: _green,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.journey.subtitle,
                  style: const TextStyle(color: Color(0xFF5F625D), height: 1.35),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / total,
                    minHeight: 7,
                    backgroundColor: _sage,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: _paper,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REFLECTION ${(_step + 1).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: _green,
                          fontSize: 10,
                          letterSpacing: .9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        widget.journey.steps[_step],
                        style: GoogleFonts.playfairDisplay(
                          color: _ink,
                          fontSize: 21,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _answers[_step],
                        minLines: 7,
                        maxLines: 13,
                        maxLength: 5000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Write whatever feels true. You can take your time.',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: _cream,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: _line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: _line),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => setState(() => _step--),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _green,
                            side: const BorderSide(color: _line),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text('Previous'),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving
                            ? null
                            : isLast
                                ? _saveJourney
                                : () => setState(() => _step++),
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isLast ? 'Save Reflection Privately' : 'Continue'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_rounded, color: _green, size: 13),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Your reflection stays private in My Entries.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF5F625D), fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptLibrary extends StatefulWidget {
  const _PromptLibrary({
    required this.categories,
    required this.savedPrompts,
    required this.entries,
    required this.onWrite,
    required this.onToggleFavorite,
    required this.intro,
  });
  final List<String> categories;
  final CollectionReference<Map<String, dynamic>>? savedPrompts;
  final CollectionReference<Map<String, dynamic>>? entries;
  final ValueChanged<String> onWrite;
  final Future<void> Function(String, String, bool) onToggleFavorite;
  final String intro;
  @override
  State<_PromptLibrary> createState() => _PromptLibraryState();
}

class _PromptLibraryState extends State<_PromptLibrary> {
  String _category = 'All';
  String _query = '';
  bool _favoritesOnly = false;
  bool _unansweredOnly = false;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.entries?.snapshots(),
      builder: (context, entriesSnapshot) {
        final answered = (entriesSnapshot.data?.docs ?? [])
            .map((doc) => doc.data()['prompt'] as String? ?? '')
            .where((item) => item.isNotEmpty)
            .toSet();
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: widget.savedPrompts?.snapshots(),
          builder: (context, savedSnapshot) {
            final saved = (savedSnapshot.data?.docs ?? [])
                .map((doc) => doc.data()['prompt'] as String? ?? '')
                .toSet();
            final filtered = <(String, String)>[];
            for (final category in widget.categories) {
              if (_category != 'All' && _category != category) continue;
              for (final prompt
                  in _promptGroups[category] ?? const <String>[]) {
                if (!prompt.toLowerCase().contains(_query)) continue;
                if (_favoritesOnly && !saved.contains(prompt)) continue;
                if (_unansweredOnly && answered.contains(prompt)) continue;
                filtered.add((category, prompt));
              }
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 24),
              children: [
                Text(
                  widget.intro,
                  style: const TextStyle(color: Color(0xFF5F625D), height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: _green),
                    hintText: 'Search thoughtful questions…',
                    filled: true,
                    fillColor: _paper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _line),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', ...widget.categories]
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(name),
                              selected: _category == name,
                              onSelected: (_) =>
                                  setState(() => _category = name),
                              selectedColor: _green,
                              labelStyle: TextStyle(
                                color: _category == name ? Colors.white : _ink,
                                fontSize: 12,
                              ),
                              backgroundColor: const Color(0xFFF3E9DA),
                              side: BorderSide.none,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Wrap(
                  spacing: 7,
                  children: [
                    FilterChip(
                      label: const Text('Saved'),
                      selected: _favoritesOnly,
                      onSelected: (value) =>
                          setState(() => _favoritesOnly = value),
                    ),
                    FilterChip(
                      label: const Text('Not answered'),
                      selected: _unansweredOnly,
                      onSelected: (value) =>
                          setState(() => _unansweredOnly = value),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (filtered.isEmpty)
                  _softCard(
                    child: const Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No prompts match these filters yet. Adjust your search or choose another category.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF74766F)),
                      ),
                    ),
                  )
                else
                  for (final item in filtered)
                    _promptTile(
                      item.$1,
                      item.$2,
                      saved.contains(item.$2),
                      answered.contains(item.$2),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _promptTile(
    String category,
    String prompt,
    bool saved,
    bool answered,
  ) => _softCard(
    margin: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => widget.onWrite(prompt),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prompt,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$category${answered ? ' · Answered' : ''}',
                  style: const TextStyle(fontSize: 11, color: _green),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: saved ? 'Remove saved prompt' : 'Save prompt',
          onPressed: () => widget.onToggleFavorite(prompt, category, saved),
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: saved ? _green : const Color(0xFF9C7452),
          ),
        ),
      ],
    ),
  );
}

class _MoodComposer extends StatefulWidget {
  const _MoodComposer({
    required this.onSaved,
    required this.entries,
    required this.uid,
  });
  final void Function(String) onSaved;
  final CollectionReference<Map<String, dynamic>>? entries;
  final String uid;
  @override
  State<_MoodComposer> createState() => _MoodComposerState();
}

class _MoodComposerState extends State<_MoodComposer> {
  String? _mood;
  String? _linkedId;
  final Set<String> _tags = {};
  final TextEditingController _note = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _attachment;
  bool _saving = false;
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024)
        throw StateError('Choose an image under 5 MB.');
      final path = await PrivateJournalService(uid: widget.uid)
          .uploadImage(bytes, file.name);
      if (mounted) setState(() => _attachment = path);
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError
                  ? error.message
                  : 'Could not attach that photo.',
            ),
          ),
        );
    }
  }

  Future<void> _save() async {
    if (_mood == null || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.entries!.add({
        'title': 'Mood reflection · $_mood',
        'body': _note.text.trim().isEmpty
            ? 'Mood check-in: $_mood'
            : _note.text.trim(),
        'prompt': 'How are you feeling today?',
        'entryType': 'mood',
        'mood': _mood,
        if (_linkedId != null) 'linkedEntryId': _linkedId,
        'tags': _tags.toList(),
        'attachments': _attachment == null ? <String>[] : [_attachment],
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _note.clear();
      setState(() {
        _mood = null;
        _linkedId = null;
        _tags.clear();
        _attachment = null;
      });
      widget.onSaved('Your mood reflection was saved privately.');
    } catch (_) {
      if (mounted)
        widget.onSaved(
          'Could not save your mood reflection. Please try again.',
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
    children: [
      const Text(
        'How are you feeling today?',
        style: TextStyle(color: Color(0xFF5F625D), fontSize: 14),
      ),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 470 ? 5 : 5;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            childAspectRatio: .86,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            children: _moods.entries
                .map(
                  (item) => InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => setState(() => _mood = item.key),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _mood == item.key
                            ? const Color(0xFFDDE9DA)
                            : const Color(0xFFF5E9DD),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _mood == item.key
                              ? _green
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.value,
                            style: const TextStyle(fontSize: 25),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.key,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 10, color: _ink),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 14),
      const Text(
        'Add tags (up to six, optional)',
        style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
      ),
      const SizedBox(height: 7),
      Wrap(
        spacing: 6,
        runSpacing: 3,
        children: _moodTags
            .map(
              (tag) => FilterChip(
                label: Text(tag, style: const TextStyle(fontSize: 11)),
                selected: _tags.contains(tag),
                selectedColor: const Color(0xFFDDE9DA),
                onSelected: (yes) {
                  if (yes && _tags.length >= 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('You can choose up to six tags.'),
                      ),
                    );
                    return;
                  }
                  setState(() => yes ? _tags.add(tag) : _tags.remove(tag));
                },
              ),
            )
            .toList(),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _note,
        minLines: 3,
        maxLines: 6,
        maxLength: 30000,
        decoration: InputDecoration(
          labelText: 'Would you like to say more?',
          hintText: 'A few words for yourself…',
          filled: true,
          fillColor: _paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: _line),
          ),
        ),
      ),
      if (widget.entries != null)
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: widget.entries!
              .orderBy('createdAt', descending: true)
              .limit(30)
              .snapshots(),
          builder: (context, snapshot) {
            final entries = (snapshot.data?.docs ?? [])
                .where(
                  (doc) =>
                      (doc.data()['entryType'] as String? ?? 'journal') !=
                      'mood',
                )
                .toList();
            if (entries.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DropdownButtonFormField<String?>(
                value: _linkedId,
                decoration: InputDecoration(
                  labelText: 'Link to a journal entry (optional)',
                  filled: true,
                  fillColor: _paper,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No linked entry'),
                  ),
                  ...entries.map(
                    (doc) => DropdownMenuItem<String?>(
                      value: doc.id,
                      child: Text(
                        (doc.data()['title'] as String? ?? '').trim().isEmpty
                            ? (doc.data()['prompt'] as String? ??
                                  'Journal entry')
                            : doc.data()['title'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _linkedId = value),
              ),
            );
          },
        ),
      OutlinedButton.icon(
        onPressed: _attachment == null ? _attach : null,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(
          _attachment == null ? 'Attach a photo (optional)' : 'Photo attached',
        ),
        style: OutlinedButton.styleFrom(foregroundColor: _green),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 48,
        child: FilledButton(
          onPressed: _mood == null || _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
          ),
          child: Text(_saving ? 'Saving…' : 'Save mood reflection'),
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Your reflections are private and never replace your Daily Check-In.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Color(0xFF74766F)),
      ),
      const SizedBox(height: 16),
      Text(
        'Recent mood reflections',
        style: GoogleFonts.playfairDisplay(
          fontSize: 18,
          color: _green,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 7),
      if (widget.entries != null)
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: widget.entries!
              .orderBy('createdAt', descending: true)
              .limit(40)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return const Text(
                'Mood history could not be loaded.',
                style: TextStyle(color: Color(0xFF74766F)),
              );
            if (!snapshot.hasData)
              return const Center(
                child: CircularProgressIndicator(color: _green),
              );
            final moodDocs = snapshot.data!.docs
                .where((doc) => doc.data()['entryType'] == 'mood')
                .take(8)
                .toList();
            if (moodDocs.isEmpty)
              return const Text(
                'Your saved reflections will appear here.',
                style: TextStyle(color: Color(0xFF74766F), fontSize: 12),
              );
            return Column(
              children: moodDocs.map((doc) {
                final data = doc.data();
                return _softCard(
                  margin: const EdgeInsets.only(bottom: 7),
                  child: Row(
                    children: [
                      Text(
                        _moods[data['mood']] ?? '🌿',
                        style: const TextStyle(fontSize: 25),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['mood'] as String? ?? 'Mood reflection',
                              style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              data['body'] as String? ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF62665E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (data['favorite'] == true)
                        const Icon(
                          Icons.bookmark_rounded,
                          color: _green,
                          size: 18,
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
    ],
  );
}

class _JournalInsights extends StatefulWidget {
  const _JournalInsights({required this.entries});
  final CollectionReference<Map<String, dynamic>>? entries;
  @override
  State<_JournalInsights> createState() => _JournalInsightsState();
}

class _JournalInsightsState extends State<_JournalInsights> {
  int _days = 30;
  String _view = 'Mood';
  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: widget.entries?.orderBy('createdAt', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError)
        return const Center(
          child: Text('Insights are temporarily unavailable.'),
        );
      if (!snapshot.hasData)
        return const Center(child: CircularProgressIndicator(color: _green));
      final cutoff = DateTime.now().subtract(Duration(days: _days));
      final docs = snapshot.data!.docs.where((doc) {
        final value = doc.data()['createdAt'];
        return value is Timestamp && value.toDate().isAfter(cutoff);
      }).toList();
      final all = snapshot.data!.docs;
      final moods = docs
          .where((doc) => doc.data()['mood'] is String)
          .map((doc) => doc.data()['mood'] as String)
          .toList();
      final tagCounts = <String, int>{};
      for (final doc in docs) {
        for (final tag
            in (doc.data()['tags'] as List<dynamic>? ?? const [])
                .whereType<String>()) {
          tagCounts.update(tag, (value) => value + 1, ifAbsent: () => 1);
        }
      }
      final activity = List<int>.generate(7, (index) {
        final day = DateTime.now().subtract(Duration(days: 6 - index));
        return docs.where((doc) {
          final value = doc.data()['createdAt'];
          return value is Timestamp &&
              value.toDate().year == day.year &&
              value.toDate().month == day.month &&
              value.toDate().day == day.day;
        }).length;
      });
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text(
            'See your own rhythm over time, with room for every kind of day.',
            style: TextStyle(color: Color(0xFF5F625D), height: 1.35),
          ),
          const SizedBox(height: 12),
          _softCard(
            child: Column(
              children: [
                Row(
                  children: ['Mood', 'Themes', 'Activity']
                      .map(
                        (tab) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ChoiceChip(
                              label: Center(child: Text(tab)),
                              selected: _view == tab,
                              onSelected: (_) => setState(() => _view = tab),
                              selectedColor: _green,
                              labelStyle: TextStyle(
                                color: _view == tab ? Colors.white : _ink,
                              ),
                              backgroundColor: const Color(0xFFE8E8DC),
                              side: BorderSide.none,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final span in [7, 30, 60])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: ChoiceChip(
                          label: Text('$span Days'),
                          selected: _days == span,
                          onSelected: (_) => setState(() => _days = span),
                          selectedColor: const Color(0xFFDDE9DA),
                          labelStyle: const TextStyle(color: _green),
                          side: BorderSide.none,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (docs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'As you add journal entries, your personal patterns will begin to appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF74766F)),
                    ),
                  )
                else if (_view == 'Mood')
                  _moodView(moods)
                else if (_view == 'Themes')
                  _themeView(tagCounts)
                else
                  _activityView(activity, docs.length),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _softCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your journaling activity',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${docs.length} private entr${docs.length == 1 ? 'y' : 'ies'} in the last $_days days${all.isEmpty ? '' : ' · ${all.length} overall'}',
                  style: const TextStyle(
                    color: Color(0xFF62665E),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                _activityView(activity, docs.length),
              ],
            ),
          ),
        ],
      );
    },
  );
  Widget _moodView(List<String> moods) {
    if (moods.isEmpty)
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Mood trends will appear after you save a few Mood Reflections.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF74766F)),
        ),
      );
    final counts = <String, int>{};
    for (final mood in moods) {
      counts.update(mood, (value) => value + 1, ifAbsent: () => 1);
    }
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 150,
          child: CustomPaint(
            size: const Size(double.infinity, 150),
            painter: _MoodChart(moods),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'A feeling that showed up often: ${top.first.key}. Every mood is useful information, not a score.',
          style: const TextStyle(color: Color(0xFF5F625D), fontSize: 12),
        ),
      ],
    );
  }

  Widget _themeView(Map<String, int> counts) {
    if (counts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Add tags to entries to see the themes you return to.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF74766F)),
        ),
      );
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (sum, item) => sum + item.value);
    return Column(
      children: sorted
          .take(6)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(item.key, style: const TextStyle(fontSize: 12)),
                  ),
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: LinearProgressIndicator(
                        value: item.value / sorted.first.value,
                        minHeight: 9,
                        color: const Color(0xFF82A487),
                        backgroundColor: const Color(0xFFEFE8DC),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(item.value / total * 100).round()}%',
                    style: const TextStyle(fontSize: 11, color: _green),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _activityView(List<int> activity, int total) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: 112,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: activity.asMap().entries.map((item) {
            final max = activity.fold<int>(1, (a, b) => a > b ? a : b);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${item.value}',
                      style: const TextStyle(fontSize: 10, color: _green),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 74 * item.value / max + (item.value == 0 ? 3 : 0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF88A58B),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][item.key],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF74766F),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      if (total == 0)
        const Text(
          'Your activity will appear as you write.',
          style: TextStyle(color: Color(0xFF74766F), fontSize: 12),
        ),
    ],
  );
}

class _MoodChart extends CustomPainter {
  _MoodChart(this.moods);
  final List<String> moods;
  @override
  void paint(Canvas canvas, Size size) {
    final scores = moods.reversed
        .map(
          (mood) => switch (mood) {
            'Happy' => 4.8,
            'Grateful' => 4.5,
            'Hopeful' => 4.2,
            'Motivated' => 4.1,
            'Calm' => 3.8,
            'Tired' => 2.7,
            'Overwhelmed' => 2.3,
            'Anxious' => 2.0,
            'Sad' => 1.8,
            _ => 1.5,
          },
        )
        .toList();
    if (scores.isEmpty) return;
    final paint = Paint()
      ..color = const Color(0xFF456E50)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final dx = scores.length == 1
        ? size.width / 2
        : size.width / (scores.length - 1);
    for (var i = 0; i < scores.length; i++) {
      final point = Offset(
        i * dx,
        size.height - 14 - (scores[i] / 5 * (size.height - 30)),
      );
      if (i == 0)
        path.moveTo(point.dx, point.dy);
      else
        path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
    final dot = Paint()..color = const Color(0xFF456E50);
    for (var i = 0; i < scores.length; i++) {
      final point = Offset(
        i * dx,
        size.height - 14 - (scores[i] / 5 * (size.height - 30)),
      );
      canvas.drawCircle(point, 4, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodChart oldDelegate) =>
      oldDelegate.moods != moods;
}

Widget _softCard({required Widget child, EdgeInsetsGeometry? margin}) =>
    Container(
      margin: margin,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _line),
      ),
      child: child,
    );
String _month(int month) => const [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
][month - 1];
