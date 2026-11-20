import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MonthlyFocusScreen extends StatefulWidget {
  const MonthlyFocusScreen({super.key, this.membershipVerifier});

  final Future<bool> Function()? membershipVerifier;

  @override
  State<MonthlyFocusScreen> createState() => _MonthlyFocusScreenState();
}

class _MonthlyFocusScreenState extends State<MonthlyFocusScreen> {
  // Add each published month here with its own immutable lessons before release.
  static const publishedMonth = '2026-11';
  static const green = Color(0xFF003B23);
  static const cream = Color(0xFFFFFAF1);
  static const gold = Color(0xFFE6C579);
  static const pale = Color(0xFFFFF4DF);
  static const weeks = <({
    String title,
    String intention,
    String activity,
    String journal,
    String thought,
  })>[
    (
      title: 'Notice your limits',
      intention: 'Understand where your energy is going.',
      activity: 'For three days, notice one moment when you say yes but mean no. Write down what you felt in your body and what you needed.',
      journal: 'Where in my life do I feel stretched thin? What am I afraid might happen if I ask for space?',
      thought: 'A boundary begins with noticing, before you have to explain anything to anyone.',
    ),
    (
      title: 'Name what you need',
      intention: 'Turn an uneasy feeling into a clear request.',
      activity: 'Choose one small limit. Practice saying: “I can do __, but I cannot do __.” Say it aloud, then try it in a low-pressure moment.',
      journal: 'Which needs have I been minimizing? What would it sound like to state one of them kindly and clearly?',
      thought: 'Can I allow someone to be disappointed without deciding I did something wrong?',
    ),
    (
      title: 'Hold your boundary',
      intention: 'Make room for discomfort without abandoning yourself.',
      activity: 'Use your boundary once this week. If you feel pressured, pause and repeat your answer without adding a long explanation.',
      journal: 'What happened when I held my limit? What felt hard, and what helped me stay grounded?',
      thought: 'Consistency is a practice. One difficult conversation does not define my progress.',
    ),
    (
      title: 'Build a gentler rhythm',
      intention: 'Keep what supports you beyond this month.',
      activity: 'Pick one boundary to carry forward. Put a reminder on your calendar to check how it is working in two weeks.',
      journal: 'What changed in my energy, relationships, or self-trust? Which limit needs adjusting?',
      thought: 'What would caring for myself look like if I made it a regular part of my life?',
    ),
  ];

  final _entries = List.generate(4, (_) => TextEditingController());
  final _completed = <int>{};
  final _saving = <int>{};
  int? _savedWeek;
  int _selectedWeek = 0;
  bool _loading = true;
  bool _authorized = false;
  bool _preview = false;
  bool _checkingAccess = true;
  String? _error;

  String _monthKey = publishedMonth;

  DocumentReference<Map<String, dynamic>>? get _record {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(uid)
      .collection('monthlyFocus').doc(_monthKey);
  }

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final user = widget.membershipVerifier == null ? FirebaseAuth.instance.currentUser : null;
      final token = await user?.getIdTokenResult(true);
      if (!mounted) return;
      final authorized = widget.membershipVerifier != null
          ? await widget.membershipVerifier!()
          : token?.claims?['villagePlus'] == true;
      setState(() { _authorized = authorized; _checkingAccess = false; });
      if (authorized) await _load();
    } catch (_) {
      if (mounted) setState(() { _checkingAccess = false; _error = 'Membership could not be verified. Please retry.'; });
    }
  }

  Future<void> _load() async {
    try {
      final snapshot = await _record?.get();
      final data = snapshot?.data() ?? {};
      if (!mounted) return;
      for (var i = 0; i < 4; i++) {
        _entries[i].text = (data['journal${i + 1}'] as String?) ?? '';
      }
      final completed = (data['completedWeeks'] as List<dynamic>?) ?? [];
      setState(() {
        _completed.addAll(completed.whereType<int>().where((n) => n >= 1 && n <= 4));
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error = 'Your saved reflections could not be loaded. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _save(int week, {bool markComplete = false}) async {
    final record = _record;
    if (record == null) {
      setState(() => _error = 'Sign in to save your private reflections.');
      return;
    }
    setState(() { _saving.add(week); _savedWeek = null; _error = null; });
    try {
      final nextCompleted = {..._completed};
      if (markComplete) nextCompleted.add(week);
      await record.set({
        'topic': 'Building Boundaries',
        'journal$week': _entries[week - 1].text.trim(),
        'completedWeeks': nextCompleted.toList()..sort(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) setState(() {
        _completed..clear()..addAll(nextCompleted);
        _savedWeek = week;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving.remove(week));
    }
  }

  @override
  void dispose() {
    for (final controller in _entries) { controller.dispose(); }
    super.dispose();
  }

  Widget _panel({required Widget child, Color color = pale}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDCC9A7))),
    child: child,
  );

  Widget _heading(String value, {double size = 23}) => Text(value,
    style: TextStyle(fontFamily: 'VillagePlusDisplay', fontSize: size, color: green));

  Widget _detail(String title, String body) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: green, fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      Text(body, style: const TextStyle(color: green, height: 1.5)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (!_authorized && !_preview) return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Monthly Focus'), backgroundColor: cream),
      body: Center(child: Padding(padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Monthly Focus is available to Village Plus members.'),
          if (_error != null) Text(_error!),
          TextButton(onPressed: () { setState(() => _checkingAccess = true); _checkAccess(); },
            child: const Text('Check membership again')),
          TextButton(onPressed: () => setState(() { _preview = true; _loading = false; _error = null; }),
            child: const Text('Preview Monthly Focus')),
        ]))));
    final current = weeks[_selectedWeek];
    final progress = _completed.length / 4;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(title: const Text('Monthly Focus'), centerTitle: true,
        backgroundColor: cream, foregroundColor: green),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 40), children: [
          if (_preview && !_authorized) Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _panel(child: const Text(
              'Preview only · Explore all four weeks. Private journal saving and progress are available with Village Plus.',
              style: TextStyle(color: green, height: 1.4),
            )),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF103C29), green]),
              borderRadius: BorderRadius.circular(22)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('VILLAGE PLUS  ·  MONTHLY FOCUS',
                style: TextStyle(color: gold, fontWeight: FontWeight.bold, letterSpacing: 1)),
              SizedBox(height: 12),
              Text('Building Boundaries', style: TextStyle(
                fontFamily: 'VillagePlusDisplay', fontSize: 34, color: cream)),
              SizedBox(height: 10),
              Text('A month of clarity, courage, and consistency. Learn to protect your energy, honor your needs, and stay connected to what matters.',
                style: TextStyle(color: cream, height: 1.5)),
            ]),
          ),
          const SizedBox(height: 18),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final item in [('menu_book', 'Learn'), ('edit', 'Reflect'), ('check', 'Practice'), ('spa', 'Grow')])
              Chip(label: Text(item.$2), backgroundColor: pale,
                labelStyle: const TextStyle(color: green)),
          ]),
          const SizedBox(height: 16),
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _heading('Understand This Month’s Focus'),
            _detail('What is a boundary?',
              'A boundary is a clear limit around what you can do, accept, or share. It can concern your time, energy, body, privacy, money, or relationships.'),
            _detail('What it sounds like',
              '“I need time to think before I commit.”\n“I can talk after work, but I cannot answer during my shift.”'),
            _detail('Why it matters',
              'Healthy boundaries clarify expectations and help you make choices that match your capacity. They describe your own actions, not control someone else’s response.'),
          ])),
          const SizedBox(height: 16),
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: _heading('Your Monthly Progress')),
              Text('${_completed.length} of 4 weeks', style: const TextStyle(color: green)),
            ]),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 9,
              backgroundColor: const Color(0xFFE7DDCA), color: green,
              borderRadius: BorderRadius.circular(10)),
          ])),
          const SizedBox(height: 22),
          _heading('Your 4-Week Journey', size: 27),
          const SizedBox(height: 10),
          // Every week remains accessible; there are no time locks.
          for (var i = 0; i < weeks.length; i++)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(
              key: ValueKey('monthly-focus-week-${i + 1}'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _selectedWeek = i),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _selectedWeek == i ? const Color(0xFFE8EDDC) : pale,
                  border: Border.all(color: _selectedWeek == i ? green : const Color(0xFFDCC9A7)),
                  borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  CircleAvatar(backgroundColor: green, foregroundColor: cream,
                    child: _completed.contains(i + 1)
                      ? const Icon(Icons.check) : Text('${i + 1}')),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Week ${i + 1} · ${weeks[i].title}',
                      style: const TextStyle(color: green, fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(weeks[i].intention, style: const TextStyle(color: green)),
                  ])),
                  const Icon(Icons.chevron_right, color: green),
                ]),
              ),
            )),
          const SizedBox(height: 12),
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('THIS WEEK’S FOCUS', style: TextStyle(color: green.withValues(alpha: 0.8),
              fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 7),
            _heading('Week ${_selectedWeek + 1}: ${current.title}', size: 25),
            _detail('Learn & reflect', current.intention),
            _detail('This week’s practice', current.activity),
            _detail('Thought provocation', current.thought),
            const SizedBox(height: 15),
            _heading('My Private Journal'),
            _detail('Reflection prompt', current.journal),
            const SizedBox(height: 12),
            TextField(key: ValueKey('monthly-focus-journal-${_selectedWeek + 1}'),
              controller: _entries[_selectedWeek], minLines: 4, maxLines: 8,
              readOnly: !_authorized,
              decoration: InputDecoration(hintText: 'Write your thoughts here...',
                filled: true, fillColor: cream,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
            const SizedBox(height: 12),
            if (_savedWeek == _selectedWeek + 1)
              const Text('Saved to your private journal.', style: TextStyle(color: green)),
            if (_authorized) Wrap(spacing: 10, runSpacing: 8, children: [
              FilledButton.icon(
                onPressed: _saving.isNotEmpty || _loading
                  ? null : () => _save(_selectedWeek + 1),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Reflection')),
              OutlinedButton.icon(
                onPressed: _saving.isNotEmpty || _loading
                  ? null : () => _save(_selectedWeek + 1, markComplete: true),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_completed.contains(_selectedWeek + 1)
                  ? 'Completed' : 'Mark Week Complete')),
            ]),
          ])),
          if (_loading) const Padding(padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator())),
          if (_error != null) Padding(padding: const EdgeInsets.all(12),
            child: Text(_error!, style: const TextStyle(color: Colors.red))),
          const SizedBox(height: 16),
          _panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _heading('Past Monthly Focus Topics'),
            const SizedBox(height: 8),
            if (DateTime.now().isBefore(DateTime(2026, 12)))
              const Text('Past topics will appear here after a new monthly topic is published.',
                style: TextStyle(color: green, height: 1.5))
            else ListTile(
              title: const Text('November 2026 · Building Boundaries'),
              subtitle: Text('${_completed.length} of 4 weeks complete'),
              onTap: () => setState(() => _monthKey = publishedMonth),
            ),
          ])),
          const SizedBox(height: 18),
          const Text('Take these at your own pace. You can revisit any week whenever you need it.',
            textAlign: TextAlign.center, style: TextStyle(color: green)),
        ]),
      )),
    );
  }
}
