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
  final _scrollController = ScrollController();
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
    _scrollController.dispose();
    super.dispose();
  }

  static const ink = Color(0xFF133B29);
  static const border = Color(0xFFE0D4BC);
  static const softGreen = Color(0xFFE6EBD5);
  final _practiceChecked = <int>{};
  int _section = 0;

  Widget _heading(String value, {double size = 26}) => Text(value,
    style: TextStyle(fontFamily: 'VillagePlusDisplay', fontSize: size,
      fontWeight: FontWeight.bold, color: green, height: 1.15));

  Widget _panel(Widget child, {Color color = cream, EdgeInsets? padding}) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(23),
      border: Border.all(color: border),
      boxShadow: const [BoxShadow(color: Color(0x160E3020), blurRadius: 12, offset: Offset(0, 4))]),
    child: child,
  );

  Widget _feature(IconData icon, String title, String subtitle) => Expanded(child: Column(children: [
    Container(width: 56, height: 56,
      decoration: BoxDecoration(color: pale, shape: BoxShape.circle, border: Border.all(color: gold)),
      child: Icon(icon, size: 30, color: green)),
    const SizedBox(height: 6),
    _heading(title, size: 20),
    Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: ink, fontSize: 13)),
  ]));

  Widget _heroCopy(bool wide) => Padding(
    padding: const EdgeInsets.all(26),
    child: Column(mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('VILLAGE PLUS  •  MONTHLY FOCUS', style: TextStyle(color: ink,
        fontWeight: FontWeight.w600, letterSpacing: 1.1, fontSize: 13)),
      const SizedBox(height: 8),
      _heading('Building Boundaries', size: wide ? 42 : 34),
      Container(margin: const EdgeInsets.symmetric(vertical: 9), width: 130, height: 4,
        decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(8))),
      const Text('A month of clarity, courage, and consistency. Learn to set, speak, and maintain healthy boundaries that protect your energy and keep you connected to what matters.',
        style: TextStyle(color: ink, height: 1.45, fontSize: 15)),
    ]),
  );

  Widget _hero(bool wide) => Container(
    decoration: BoxDecoration(color: cream, borderRadius: BorderRadius.circular(22)),
    clipBehavior: Clip.antiAlias,
    child: wide ? Row(children: [
      Expanded(child: _heroCopy(true)),
      Expanded(child: Image.asset('assets/images/monthly_focus_hero.jpg',
        height: 340, fit: BoxFit.cover)),
    ]) : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Image.asset('assets/images/monthly_focus_hero.jpg', height: 190, fit: BoxFit.cover),
      _heroCopy(false),
    ]),
  );

  Widget _focusCard() => _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('This Month’s Focus'),
    const SizedBox(height: 16),
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.spa_outlined, color: Color(0xFFB58B32), size: 42),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading('What is a Boundary?', size: 21),
        const SizedBox(height: 5),
        const Text('A clear limit around what you can do, accept, or share. It protects your time, energy, values, and peace — and helps you stay connected to what matters most.',
          style: TextStyle(color: ink, height: 1.45)),
      ])),
    ]),
    if (_section == 3) ...[
      const SizedBox(height: 12),
      const Text('A boundary describes your own actions; it does not control someone else’s response.',
        style: TextStyle(color: ink, height: 1.4)),
    ],
  ]));

  Widget _progressCard() {
    final progress = _completed.length / 4;
    return _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Your Monthly Progress', style: TextStyle(
        fontFamily: 'VillagePlusDisplay', fontSize: 25,
        fontWeight: FontWeight.bold, color: cream)),
      const SizedBox(height: 16),
      Row(children: [
        SizedBox(width: 112, height: 112, child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 11,
            backgroundColor: const Color(0xFF587C56), color: gold, strokeCap: StrokeCap.round)),
          Text('${(progress * 100).round()}%', style: const TextStyle(color: cream, fontSize: 25, fontWeight: FontWeight.bold)),
        ])),
        const SizedBox(width: 22),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 1; i <= 4; i++) Padding(padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              Icon(_completed.contains(i) ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _completed.contains(i) ? gold : cream, size: 21),
              const SizedBox(width: 9),
              Flexible(child: Text('Week $i${_completed.contains(i) ? ' Complete' : ''}',
                style: const TextStyle(color: cream))),
            ])),
        ])),
      ]),
    ]), color: green);
  }

  Widget _journeyCard() => _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _heading('Your 4-Week Journey'),
    const SizedBox(height: 14),
    for (var i = 0; i < weeks.length; i++) Padding(
      padding: const EdgeInsets.only(bottom: 8), child: Material(
        color: _selectedWeek == i ? softGreen : pale,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(key: ValueKey('monthly-focus-week-${i + 1}'),
          borderRadius: BorderRadius.circular(17),
          onTap: () => setState(() { _selectedWeek = i; _practiceChecked.clear(); }),
          child: Container(padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(17)),
            child: Row(children: [
              CircleAvatar(radius: 27, backgroundColor: cream,
                child: Icon([Icons.eco_outlined, Icons.campaign_outlined, Icons.shield_outlined, Icons.self_improvement][i],
                  color: green)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _heading('Week ${i + 1}: ${weeks[i].title}', size: 17),
                const SizedBox(height: 3),
                Text(weeks[i].intention, style: const TextStyle(fontSize: 12, color: ink)),
              ])),
              Icon(_completed.contains(i + 1) ? Icons.check_circle : Icons.chevron_right,
                color: green),
            ])),
          ),
      )),
  ]));

  Widget _journalCard() => _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.menu_book_outlined, color: green), const SizedBox(width: 9),
      Expanded(child: _heading('Journal Reflection'))]),
    const SizedBox(height: 13),
    Text('Week ${_selectedWeek + 1}  •  Reflection Prompt',
      style: const TextStyle(color: ink, fontSize: 17)),
    const SizedBox(height: 8),
    Container(width: double.infinity, padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: softGreen, borderRadius: BorderRadius.circular(13)),
      child: Text('“${weeks[_selectedWeek].journal}”',
        style: const TextStyle(fontStyle: FontStyle.italic, color: ink, height: 1.4))),
    const SizedBox(height: 14),
    TextField(key: ValueKey('monthly-focus-journal-${_selectedWeek + 1}'),
      controller: _entries[_selectedWeek], maxLength: 1000, minLines: 4, maxLines: 6,
      decoration: InputDecoration(hintText: 'Write your thoughts here...',
        filled: true, fillColor: cream, border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)))),
    if (!_authorized) const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text('Preview entry · You can write here, but this draft will disappear when you leave. Join Village Plus to save private reflections.',
        style: TextStyle(color: ink, fontSize: 12)),
    ),
    if (_savedWeek == _selectedWeek + 1)
      const Text('Saved to your private journal.', style: TextStyle(color: green)),
    if (_authorized) Align(alignment: Alignment.centerRight, child: Wrap(spacing: 8, runSpacing: 7, children: [
      OutlinedButton.icon(onPressed: _saving.isNotEmpty || _loading ? null : () => _save(_selectedWeek + 1),
        icon: const Icon(Icons.save_outlined), label: const Text('Save Reflection')),
      FilledButton.icon(onPressed: _saving.isNotEmpty || _loading ? null : () => _save(_selectedWeek + 1, markComplete: true),
        icon: const Icon(Icons.check_circle_outline),
        label: Text(_completed.contains(_selectedWeek + 1) ? 'Completed' : 'Mark Week Complete')),
    ])),
  ]));

  Widget _practiceCard() => _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.track_changes, color: green), const SizedBox(width: 8),
      Expanded(child: _heading('This Week’s Practice', size: 23))]),
    const SizedBox(height: 8),
    Text(weeks[_selectedWeek].activity, style: const TextStyle(color: ink, height: 1.4)),
    for (final (index, label) in <String>[
      'Notice when your boundary is tested.',
      'Write one clear boundary you need.',
      'Practice saying it with kindness.',
      'Reflect on how it felt and what you learned.',
    ].indexed) CheckboxListTile(
      dense: true, contentPadding: EdgeInsets.zero,
      value: _practiceChecked.contains(index),
      onChanged: (v) => setState(() { if (v == true) { _practiceChecked.add(index); } else { _practiceChecked.remove(index); } }),
      title: Text(label, style: const TextStyle(color: ink, fontSize: 13)),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: green,
    ),
    if (!_authorized) const Text('Preview checks are temporary and reset when you leave this page or change weeks.',
      style: TextStyle(fontSize: 12, color: ink)),
    if (_authorized) const Text('Use Mark Week Complete to save your weekly progress.',
      style: TextStyle(fontSize: 12, color: ink)),
  ]));

  Widget _insightCard() => _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.lightbulb_outline, color: gold), const SizedBox(width: 8),
      Expanded(child: Text('Weekly Insight', style: TextStyle(fontFamily: 'VillagePlusDisplay',
        fontSize: 24, fontWeight: FontWeight.bold, color: cream)))]),
    const SizedBox(height: 14),
    Text('“${weeks[_selectedWeek].thought}”',
      style: const TextStyle(color: cream, fontSize: 17, height: 1.5)),
    const SizedBox(height: 12),
    Container(width: 110, height: 3, color: gold),
  ]), color: green);

  Widget _sectionTabs(bool wide) {
    const labels = ['My Journey', 'Weekly Plan', 'Journal Entries', 'Insights & Tools'];
    const icons = [Icons.menu_book_outlined, Icons.calendar_month_outlined,
      Icons.article_outlined, Icons.auto_awesome_outlined];
    return Wrap(spacing: 10, runSpacing: 9, children: [
      for (var i = 0; i < labels.length; i++) SizedBox(
        width: wide ? 220 : null,
        child: OutlinedButton.icon(onPressed: () => setState(() => _section = i),
          style: OutlinedButton.styleFrom(backgroundColor: _section == i ? green : pale,
            foregroundColor: _section == i ? cream : green,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            side: BorderSide(color: _section == i ? gold : border)),
          icon: Icon(icons[i], size: 21), label: Text(labels[i])),
      ),
    ]);
  }

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
    return Scaffold(backgroundColor: cream,
      appBar: AppBar(title: Text('Monthly Focus', style: TextStyle(
          fontFamily: 'VillagePlusDisplay', fontWeight: FontWeight.bold, color: green)),
        centerTitle: true, backgroundColor: cream, foregroundColor: green,
        actions: [IconButton(tooltip: 'Past topics', onPressed: () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(_scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
          }
        }, icon: const Icon(Icons.bookmark_border))]),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 780;
        Widget pair(Widget a, Widget b) => wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)])
          : Column(children: [a, const SizedBox(height: 16), b]);
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(controller: _scrollController,
            padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 6, wide ? 24 : 16, 42), children: [
            if (_preview && !_authorized) Padding(padding: const EdgeInsets.only(bottom: 12),
              child: _panel(const Text('Preview only · Explore all four weeks. Private journal saving and progress are available with Village Plus.',
                style: TextStyle(color: green)))),
            _hero(wide),
            const SizedBox(height: 14),
            Row(children: [
              _feature(Icons.menu_book_outlined, 'Learn', 'Understand the topic'),
              _feature(Icons.edit_outlined, 'Reflect', 'Journal & process'),
              _feature(Icons.track_changes, 'Practice', 'Take weekly action'),
              _feature(Icons.bar_chart, 'Grow', 'Build lasting change'),
            ]),
            const SizedBox(height: 20),
            pair(_focusCard(), _progressCard()),
            const SizedBox(height: 16),
            _sectionTabs(wide),
            const SizedBox(height: 16),
            pair(_journeyCard(), _journalCard()),
            const SizedBox(height: 16),
            pair(_practiceCard(), _insightCard()),
            const SizedBox(height: 16),
            _panel(Row(children: [const Icon(Icons.flag_outlined, color: green),
              const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _heading('Month’s Goal', size: 21),
                const Text('End this month with greater clarity, stronger boundaries, and more peace in your daily life.',
                  style: TextStyle(color: ink, height: 1.4)),
              ])), const SizedBox(width: 8),
              if (_authorized) OutlinedButton(onPressed: () => setState(() => _section = 1),
                child: const Text('Set My Intention'))])),
            if (_loading) const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
            if (_error != null) Padding(padding: const EdgeInsets.all(12),
              child: Text(_error!, style: const TextStyle(color: Colors.red))),
            const SizedBox(height: 18),
            _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _heading('Past Monthly Focus Topics'),
              const SizedBox(height: 8),
              if (DateTime.now().isBefore(DateTime(2026, 12)))
                const Text('Past topics will appear here after a new monthly topic is published.',
                  style: TextStyle(color: ink, height: 1.5))
              else ListTile(title: const Text('November 2026 · Building Boundaries'),
                subtitle: Text('${_completed.length} of 4 weeks complete'),
                onTap: () => setState(() => _monthKey = publishedMonth)),
            ])),
          ])));
      }),
    );
  }
}
