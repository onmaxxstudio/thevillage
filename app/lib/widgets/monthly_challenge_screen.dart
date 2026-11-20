import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Published challenges are immutable so saved days remain meaningful later.
class ChallengeDay {
  const ChallengeDay(this.action, this.prompt);
  final String action, prompt;
}

const novemberChallenge = <ChallengeDay>[
  ChallengeDay('Write down one thing you need today.', 'What would change if I took this need seriously?'),
  ChallengeDay('Give yourself ten minutes without an obligation.', 'How did it feel to pause without earning it?'),
  ChallengeDay('Notice one moment you put someone else first.', 'What did I need in that moment?'),
  ChallengeDay('Say one kind thing to yourself aloud.', 'Which words were hardest to believe?'),
  ChallengeDay('Choose one small pleasure just for you.', 'What brings me joy when no one is watching?'),
  ChallengeDay('Make a list of three things that restore you.', 'Which one could I make room for this week?'),
  ChallengeDay('Take a short walk or sit quietly with yourself.', 'What did I notice when I slowed down?'),
  ChallengeDay('Let one unnecessary task wait.', 'What happened when I did less?'),
  ChallengeDay('Name one feeling without judging it.', 'What might this feeling be telling me?'),
  ChallengeDay('Ask for help with one small thing.', 'What made asking easy or difficult?'),
  ChallengeDay('Practice saying “Let me think about it.”', 'Where do I need more time before answering?'),
  ChallengeDay('Set one gentle limit on your time.', 'How did I respond to my own limit?'),
  ChallengeDay('Unfollow or mute one source of pressure.', 'What kind of message do I want more of?'),
  ChallengeDay('Rest for fifteen minutes without multitasking.', 'What beliefs about rest showed up?'),
  ChallengeDay('Write a permission slip for yourself.', 'What am I ready to allow myself to do?'),
  ChallengeDay('Choose a meal or snack you truly enjoy.', 'How can I care for myself in ordinary moments?'),
  ChallengeDay('Celebrate one choice you made for yourself.', 'What did that choice protect or support?'),
  ChallengeDay('Tell someone one honest preference.', 'What was it like to let my preference be known?'),
  ChallengeDay('Make space for a hobby or curiosity.', 'What part of me deserves more attention?'),
  ChallengeDay('Notice when you apologize unnecessarily.', 'What could I say instead next time?'),
  ChallengeDay('Plan one hour this week that belongs to you.', 'What would I like to do with that hour?'),
  ChallengeDay('Release one expectation you have outgrown.', 'Whose expectation was it, and what do I choose now?'),
  ChallengeDay('Say no to one optional request if you need to.', 'How did it feel to honor my capacity?'),
  ChallengeDay('Write down a strength you often overlook.', 'When did this strength help me recently?'),
  ChallengeDay('Spend time with someone who respects your needs.', 'How do I feel in relationships where I can be myself?'),
  ChallengeDay('Take one step toward a personal goal.', 'Why does this goal matter to me?'),
  ChallengeDay('Notice an old pattern without criticizing yourself.', 'What might I try differently next time?'),
  ChallengeDay('Choose a comforting ritual for tonight.', 'What helps me feel safe and grounded?'),
  ChallengeDay('Write a note to the person you are becoming.', 'What do I want my future self to remember?'),
  ChallengeDay('Choose one practice to carry into next month.', 'What did choosing myself teach me?'),
];

class MonthlyChallengeScreen extends StatefulWidget {
  const MonthlyChallengeScreen({super.key, this.membershipVerifier, this.firestore, this.uid});
  final Future<bool> Function()? membershipVerifier;
  final FirebaseFirestore? firestore;
  final String? uid;
  @override
  State<MonthlyChallengeScreen> createState() => _MonthlyChallengeScreenState();
}

class _MonthlyChallengeScreenState extends State<MonthlyChallengeScreen> {
  static const green = Color(0xFF003B23), cream = Color(0xFFFFFAF1), gold = Color(0xFFE6C579);
  final _journal = TextEditingController();
  final _records = <int, Map<String, dynamic>>{};
  int _selected = 1;
  bool _checking = true, _member = false, _saving = false;
  String? _error;
  DocumentReference<Map<String, dynamic>> _day(int day) =>
      (widget.firestore ?? FirebaseFirestore.instance).collection('users')
          .doc(widget.uid ?? FirebaseAuth.instance.currentUser!.uid)
          .collection('monthlyChallenges').doc('2026-11')
          .collection('days').doc(day.toString().padLeft(2, '0'));

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final allowed = widget.membershipVerifier != null
          ? await widget.membershipVerifier!()
          : (await FirebaseAuth.instance.currentUser?.getIdTokenResult(true))?.claims?['villagePlus'] == true;
      if (!mounted) return;
      setState(() { _member = allowed; _checking = false; });
      if (allowed) await _load();
    } catch (_) {
      if (mounted) setState(() { _checking = false; _error = 'Could not verify Village Plus. Please retry.'; });
    }
  }

  Future<void> _load() async {
    try {
      final snapshot = await _day(1).parent.get();
      if (!mounted) return;
      setState(() {
        _records.clear();
        for (final doc in snapshot.docs) {
          final day = int.tryParse(doc.id);
          if (day != null && day >= 1 && day <= 30) _records[day] = doc.data();
        }
        _journal.text = _records[_selected]?['journal'] as String? ?? '';
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your challenge. Please retry.');
    }
  }

  void _select(int day) {
    setState(() {
      _selected = day;
      _journal.text = _records[day]?['journal'] as String? ?? '';
      _error = null;
    });
  }

  Future<void> _save({required bool complete}) async {
    if (_saving) return;
    setState(() { _saving = true; _error = null; });
    final text = _journal.text.trim();
    final completed = complete || _records[_selected]?['completed'] == true;
    try {
      await _day(_selected).set({
        'journal': text,
        'completed': completed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _records[_selected] = {'journal': text, 'completed': completed});
    } catch (_) {
      if (mounted) setState(() => _error = 'Your entry was not saved. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() { _journal.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final count = _records.values.where((entry) => entry['completed'] == true).length;
    final content = _checking
        ? const Center(child: CircularProgressIndicator())
        : !_member
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 40, color: green),
                const SizedBox(height: 12),
                const Text('Monthly Challenge is for Village Plus members.'),
                TextButton(onPressed: () { setState(() => _checking = true); _initialize(); }, child: const Text('Check membership again')),
              ]))
            : ListView(padding: const EdgeInsets.all(18), children: [
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [green, Color(0xFF196340)]),
                  borderRadius: BorderRadius.circular(22)), child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('VILLAGE PLUS  •  NOVEMBER CHALLENGE', style: TextStyle(color: gold, letterSpacing: 1)),
                    SizedBox(height: 12),
                    Text('30 Days of Choosing Yourself', style: TextStyle(color: cream, fontFamily: 'VillagePlusDisplay', fontSize: 32)),
                    SizedBox(height: 8),
                    Text('One small action a day to reconnect with your needs, your voice, and your joy.', style: TextStyle(color: cream, height: 1.4)),
                  ])),
                const SizedBox(height: 18),
                Text('$count of 30 days complete', style: const TextStyle(fontWeight: FontWeight.bold, color: green)),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: count / 30, color: green, backgroundColor: gold),
                const SizedBox(height: 20),
                for (var week = 0; week < 4; week++) ...[
                  Text('Week ${week + 1} · ${['Notice your needs', 'Make room for yourself', 'Speak up for yourself', 'Carry it forward'][week]}',
                    style: const TextStyle(fontFamily: 'VillagePlusDisplay', fontSize: 23, color: green)),
                  if (_records.entries.where((e) => e.key > week * 7 && e.key <= (week == 3 ? 30 : (week + 1) * 7) && e.value['completed'] == true).length == (week == 3 ? 9 : 7))
                    const Chip(avatar: Icon(Icons.emoji_events, color: green), label: Text('Weekly milestone earned')),
                  const SizedBox(height: 8),
                  Wrap(spacing: 7, runSpacing: 7, children: [
                    for (var day = week * 7 + 1; day <= (week == 3 ? 30 : (week + 1) * 7); day++)
                      ChoiceChip(key: ValueKey('challenge-day-$day'), label: Text('Day $day${_records[day]?['completed'] == true ? ' ✓' : ''}'),
                        selected: _selected == day, onSelected: (_) => _select(day)),
                  ]),
                  const SizedBox(height: 18),
                ],
                if (count == 30) const Chip(avatar: Icon(Icons.workspace_premium, color: green), label: Text('Choosing Yourself badge earned')),
                Card(color: const Color(0xFFFFF4DF), child: Padding(padding: const EdgeInsets.all(18), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('Day $_selected', style: const TextStyle(fontFamily: 'VillagePlusDisplay', fontSize: 27, color: green)),
                    const SizedBox(height: 8),
                    Text(novemberChallenge[_selected - 1].action, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 12),
                    Text(novemberChallenge[_selected - 1].prompt),
                    const SizedBox(height: 14),
                    TextField(key: ValueKey('challenge-journal-$_selected'), controller: _journal,
                      maxLines: 5, maxLength: 20000, decoration: const InputDecoration(
                        labelText: 'Private reflection', hintText: 'Write what came up for you…', border: OutlineInputBorder())),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                    Wrap(spacing: 8, children: [
                      OutlinedButton(onPressed: _saving ? null : () => _save(complete: false), child: const Text('Save reflection')),
                      FilledButton(onPressed: _saving ? null : () => _save(complete: true), child: Text(_records[_selected]?['completed'] == true ? 'Completed' : 'Mark day complete')),
                    ]),
                  ]))),
                const SizedBox(height: 24),
                const Text('Previous challenges', style: TextStyle(fontFamily: 'VillagePlusDisplay', fontSize: 25, color: green)),
                if (DateTime.now().isAfter(DateTime(2026, 11, 30)))
                  ListTile(
                    leading: const Icon(Icons.auto_stories, color: green),
                    title: const Text('November 2026 · 30 Days of Choosing Yourself'),
                    subtitle: Text('$count of 30 days completed'),
                    onTap: () => _select(1),
                  )
                else
                  const Text('Past challenges will appear here after their month ends.'),
              ]);
    return Scaffold(backgroundColor: cream, appBar: AppBar(title: const Text('Monthly Challenge'), backgroundColor: cream),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 850), child: content))));
  }
}
