import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.onOpenEntry,
    super.key,
  });
  final String mode;
  final void Function(String prompt, String entryType) onWritePrompt;
  final void Function(
    QueryDocumentSnapshot<Map<String, dynamic>> entry, {
    String? entryType,
  })? onOpenEntry;

  @override
  State<MySpaceToolsScreen> createState() => _MySpaceToolsScreenState();
}

class _MySpaceToolsScreenState extends State<MySpaceToolsScreen> {
  DateTime _selectedBudgetMonth = DateTime(DateTime.now().year, DateTime.now().month);

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

  DocumentReference<Map<String, dynamic>>? get _budgetDocument {
    final uid = _uid;
    return uid == null
        ? null
        : FirebaseFirestore.instance
              .collection('private_journals')
              .doc(uid)
              .collection('budget')
              .doc('${_selectedBudgetMonth.year}-${_selectedBudgetMonth.month.toString().padLeft(2, '0')}');
  }

  DocumentReference<Map<String, dynamic>>? get _legacyBudgetDocument {
    final uid = _uid;
    return uid == null
        ? null
        : FirebaseFirestore.instance
              .collection('private_journals')
              .doc(uid)
              .collection('budget')
              .doc('current');
  }

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'budget') _preserveLegacyBudget();
  }

  Future<void> _preserveLegacyBudget() async {
    final legacy = _legacyBudgetDocument;
    final uid = _uid;
    if (legacy == null || uid == null) return;
    try {
      final values = (await legacy.get()).data();
      if (values == null || values.isEmpty) {
        await _seedBudgetMonthFromPrevious(_selectedBudgetMonth);
        return;
      }
      final expenses = (values['expenses'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      final expensesByMonth = <String, List<Map<String, dynamic>>>{};
      final thisMonth = _selectedBudgetMonth;
      final currentId = '${thisMonth.year}-${thisMonth.month.toString().padLeft(2, '0')}';
      for (final expense in expenses) {
        final date = _budgetDate(expense['date']);
        if (date == null) {
          expensesByMonth.putIfAbsent(currentId, () => []).add(expense);
          continue;
        }
        final id = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        expensesByMonth.putIfAbsent(id, () => []).add(expense);
      }
      expensesByMonth.putIfAbsent(currentId, () => []);
      for (final entry in expensesByMonth.entries) {
        final monthly = FirebaseFirestore.instance
            .collection('private_journals')
            .doc(uid)
            .collection('budget')
            .doc(entry.key);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          if ((await transaction.get(monthly)).exists) return;
          final monthData = entry.key == currentId
              ? values
              : <String, dynamic>{
                  'monthlyIncome': 0,
                  'savingsGoal': 0,
                  'savedAmount': 0,
                  'categories': _defaultBudgetCategories,
                };
          transaction.set(monthly, {
            ...monthData,
            'expenses': entry.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }
      await _seedBudgetMonthFromPrevious(_selectedBudgetMonth);
    } catch (_) {
      // The original record remains available even if the one-time copy fails.
    }
  }

  Future<void> _seedBudgetMonthFromPrevious(DateTime month) async {
    final uid = _uid;
    if (uid == null) return;
    final current = FirebaseFirestore.instance
        .collection('private_journals')
        .doc(uid)
        .collection('budget')
        .doc('${month.year}-${month.month.toString().padLeft(2, '0')}');
    final previousDate = DateTime(month.year, month.month - 1);
    final previousMonth = FirebaseFirestore.instance
        .collection('private_journals')
        .doc(uid)
        .collection('budget')
        .doc('${previousDate.year}-${previousDate.month.toString().padLeft(2, '0')}');
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      if ((await transaction.get(current)).exists) return;
      final previous = (await transaction.get(previousMonth)).data();
      if (previous == null) return;
      transaction.set(current, {
        'monthlyIncome': previous['monthlyIncome'] ?? 0,
        'savingsGoal': previous['savingsGoal'] ?? 0,
        'savedAmount': 0,
        'categories': previous['categories'] ?? _defaultBudgetCategories,
        'expenses': const <Map<String, dynamic>>[],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  void _selectBudgetMonth(DateTime month) {
    setState(() => _selectedBudgetMonth = month);
    final today = DateTime.now();
    final currentMonth = DateTime(today.year, today.month);
    if (DateTime(month.year, month.month).isAfter(currentMonth)) {
      _seedBudgetMonthFromPrevious(month);
    }
  }

  String get _title => switch (widget.mode) {
    'guided' => 'Guided Journaling',
    'prompts' => 'Journal Prompts',
    'gratitude' => 'Gratitude',
    'mood' => 'Mood Reflections',
    'milestones' => 'Milestones',
    'goals' => 'Vision & Goals',
    'letters' => 'Letters',
    'budget' => 'My Budget',
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
                  'budget' => _budget(),
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
      builder: (_) => MySpaceToolsScreen(
        mode: mode,
        onWritePrompt: widget.onWritePrompt,
        onOpenEntry: widget.onOpenEntry,
      ),
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
        widget.onWritePrompt(prompt, guided ? 'guided' : 'journal_prompt');
      },
      onOpenEntry: widget.onOpenEntry,
      onToggleFavorite: _togglePrompt,
      intro: guided
          ? 'Choose a gentle path and take the questions at your own pace.'
          : 'Explore the season you’re in through thoughtful prompts. Save your favorites and return whenever you like.',
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
      if (mounted) {
        _message(saved ? 'Prompt removed from Saved Favorites.' : 'Prompt saved to Saved Favorites.');
      }
    } on FirebaseException catch (error) {
      if (mounted) _message('Could not save prompt (${error.code}). Please try again.');
    } catch (_) {
      if (mounted) _message('Could not save prompt. Please try again.');
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
      _MoodComposer(onSaved: _message, entries: _entries);

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
      const SizedBox(height: 18),
      Text(
        'Recent Letters',
        style: GoogleFonts.playfairDisplay(
          color: _green,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 9),
      _streamEntries(
        types: const {'letter'},
        emptyTitle: 'Your private letters will appear here.',
        showActions: true,
      ),
    ],
  );

  static const _defaultBudgetCategories = <Map<String, dynamic>>[
    {'name': 'Housing', 'planned': 0.0},
    {'name': 'Groceries', 'planned': 0.0},
    {'name': 'Transportation', 'planned': 0.0},
    {'name': 'Bills', 'planned': 0.0},
    {'name': 'Personal', 'planned': 0.0},
    {'name': 'Other', 'planned': 0.0},
  ];

  Widget _budget() {
    final document = _budgetDocument;
    if (document == null) {
      return const Center(child: Text('Sign in to use your private budget.'));
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: document.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Your budget could not be loaded. Check your connection and try again.'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final data = snapshot.data!.data() ?? const <String, dynamic>{};
        final income = _budgetNumber(data['monthlyIncome']);
        final savingsGoal = _budgetNumber(data['savingsGoal']);
        final savedAmount = _budgetNumber(data['savedAmount']);
        final categories = (data['categories'] as List<dynamic>? ?? _defaultBudgetCategories)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final expenses = (data['expenses'] as List<dynamic>? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final month = _selectedBudgetMonth;
        final currentMonth = DateTime.now();
        final monthExpenses = expenses.where((expense) {
          final date = _budgetDate(expense['date']);
          return date == null
              ? month.year == currentMonth.year && month.month == currentMonth.month
              : date.year == month.year && date.month == month.month;
        }).toList()
          ..sort((a, b) => (_budgetDate(b['date']) ?? DateTime(1970))
              .compareTo(_budgetDate(a['date']) ?? DateTime(1970)));
        final spent = monthExpenses.fold<double>(
          0,
          (total, expense) => total + _budgetNumber(expense['amount']),
        );
        final planned = categories.fold<double>(
          0,
          (total, category) => total + _budgetNumber(category['planned']),
        );
        final monthName = MaterialLocalizations.of(context).formatMonthYear(month);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _topIntro('A private place to plan your money, track spending, and make room for what matters.'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE7EBDD), Color(0xFFF5EADB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Previous month',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _selectBudgetMonth(DateTime(month.year, month.month - 1)),
                        icon: const Icon(Icons.chevron_left_rounded, color: _green),
                      ),
                      const Icon(Icons.calendar_month_outlined, color: _green, size: 19),
                      const SizedBox(width: 6),
                      Expanded(child: Text(monthName, style: const TextStyle(color: _green, fontWeight: FontWeight.w700))),
                      IconButton(
                        tooltip: 'Next month',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _selectBudgetMonth(DateTime(month.year, month.month + 1)),
                        icon: const Icon(Icons.chevron_right_rounded, color: _green),
                      ),
                      const SizedBox(width: 4),
                      const Spacer(),
                      const Icon(Icons.lock_outline_rounded, color: _green, size: 16),
                      const SizedBox(width: 4),
                      const Text('Private', style: TextStyle(color: _green, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Left after logged spending', style: TextStyle(color: _ink, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    _budgetMoney(income - spent),
                    style: GoogleFonts.playfairDisplay(
                      color: _green,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _budgetMetric('Monthly income', _budgetMoney(income), () => _editBudgetAmount('Monthly income', income, 'monthlyIncome'))),
                      const SizedBox(width: 10),
                      Expanded(child: _budgetMetric('Spent this month', _budgetMoney(spent), null)),
                    ],
                  ),
                  if (income == 0) ...[
                    const SizedBox(height: 12),
                    const Text('Add your monthly take-home income to see a more useful monthly balance.', style: TextStyle(color: _ink, height: 1.35, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _wideAction('Log an expense', Icons.add_rounded, () => _addBudgetExpense(categories, expenses)),
            const SizedBox(height: 8),
            const Text('Each month keeps its own plan and spending history. Earlier months stay saved and can be revisited.', style: TextStyle(color: Color(0xFF74766F), fontSize: 12, height: 1.35)),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: Text('Your monthly plan', style: GoogleFonts.playfairDisplay(color: _green, fontSize: 21, fontWeight: FontWeight.w700))),
                Text('${categories.length} categories', style: const TextStyle(color: Color(0xFF74766F), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 5),
            Text('Planned total  ${_budgetMoney(planned)}', style: const TextStyle(color: Color(0xFF74766F), fontSize: 13)),
            const SizedBox(height: 10),
            for (var i = 0; i < categories.length; i++)
              _budgetCategoryCard(categories[i], i, categories, monthExpenses),
            const SizedBox(height: 2),
            OutlinedButton.icon(
              onPressed: () => _addBudgetCategory(categories),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add a category'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: const BorderSide(color: Color(0xFFBEC7B6)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            _savingsCard(savingsGoal, savedAmount),
            const SizedBox(height: 20),
            Text('Recent spending', style: GoogleFonts.playfairDisplay(color: _green, fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            if (monthExpenses.isEmpty)
              _surface(
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: _green, size: 22),
                      SizedBox(width: 10),
                      Expanded(child: Text('Expenses you log will show here. Your budget stays private.', style: TextStyle(color: _ink, height: 1.35))),
                    ],
                  ),
                ),
              )
            else
              for (final expense in monthExpenses.take(6))
                _budgetExpenseCard(expense),
            const SizedBox(height: 10),
            const Text('Your budget is private and for personal planning. It does not connect to your bank.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF74766F), fontSize: 12, height: 1.4)),
          ],
        );
      },
    );
  }

  Widget _budgetMetric(String label, String value, VoidCallback? onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _paper.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(13)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF74766F), fontSize: 11)),
          const SizedBox(height: 4),
          Row(children: [Expanded(child: Text(value, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: 15))), if (onTap != null) const Icon(Icons.edit_outlined, color: _green, size: 15)]),
        ],
      ),
    ),
  );

  Widget _budgetCategoryCard(
    Map<String, dynamic> category,
    int index,
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> expenses,
  ) {
    final name = (category['name'] as String? ?? 'Category').trim();
    final target = _budgetNumber(category['planned']);
    final actual = expenses
        .where((expense) => expense['category'] == name)
        .fold<double>(0, (total, expense) => total + _budgetNumber(expense['amount']));
    final progress = target <= 0 ? 0.0 : (actual / target).clamp(0.0, 1.0);
    return _surface(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _editBudgetCategory(index, categories),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.spa_outlined, size: 19, color: _green)),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700))),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(_budgetMoney(target), style: const TextStyle(color: _green, fontWeight: FontWeight.w700)),
                  const Text('planned', style: TextStyle(color: Color(0xFF74766F), fontSize: 10)),
                ]),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF74766F)),
              ],
            ),
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(value: progress, minHeight: 7, backgroundColor: _sage, color: actual > target && target > 0 ? const Color(0xFFB56054) : _green),
            ),
            const SizedBox(height: 5),
            Text('${_budgetMoney(actual)} spent', style: const TextStyle(color: Color(0xFF74766F), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _savingsCard(double goal, double saved) => _surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.savings_outlined, color: _green)),
          const SizedBox(width: 10),
          Expanded(child: Text('Savings goal', style: GoogleFonts.playfairDisplay(color: _green, fontSize: 18, fontWeight: FontWeight.w700))),
          PopupMenuButton<String>(
            tooltip: 'Update savings goal',
            icon: const Icon(Icons.more_horiz_rounded, color: _green),
            onSelected: (value) => _editBudgetAmount(value == 'goal' ? 'Monthly savings goal' : 'Amount saved so far', value == 'goal' ? goal : saved, value == 'goal' ? 'savingsGoal' : 'savedAmount'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'goal', child: Text('Set monthly goal')),
              PopupMenuItem(value: 'saved', child: Text('Update saved amount')),
            ],
          ),
        ]),
        const SizedBox(height: 4),
        Text(goal > 0 ? '${_budgetMoney(saved)} saved of ${_budgetMoney(goal)}' : 'Choose an amount you would like to set aside this month.', style: const TextStyle(color: Color(0xFF74766F), fontSize: 13)),
        if (goal > 0) ...[
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (saved / goal).clamp(0.0, 1.0), minHeight: 8, backgroundColor: _sage, color: _green)),
        ],
      ],
    ),
  );

  Widget _budgetExpenseCard(Map<String, dynamic> expense) {
    final date = _budgetDate(expense['date']);
    final dateLabel = date == null ? '' : MaterialLocalizations.of(context).formatShortDate(date);
    final title = (expense['description'] as String? ?? '').trim();
    final category = (expense['category'] as String? ?? 'Other').trim();
    return _surface(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: _sage, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.receipt_long_outlined, color: _green, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.isEmpty ? category : title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
            Text('$category${dateLabel.isEmpty ? '' : ' · $dateLabel'}', style: const TextStyle(color: Color(0xFF74766F), fontSize: 12)),
          ])),
          const SizedBox(width: 8),
          Text('−${_budgetMoney(_budgetNumber(expense['amount']))}', style: const TextStyle(color: _ink, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _editBudgetAmount(String title, double initial, String field) async {
    final controller = TextEditingController(text: initial == 0 ? '' : initial.toStringAsFixed(2));
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _paper,
        title: Text(title, style: GoogleFonts.playfairDisplay(color: _green, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final parsed = _parseBudgetAmount(controller.text);
            if (parsed != null) Navigator.pop(dialogContext, parsed);
          }, style: FilledButton.styleFrom(backgroundColor: _green), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _writeBudget({field: value});
  }

  Future<void> _editBudgetCategory(int index, List<Map<String, dynamic>> categories) async {
    final category = categories[index];
    final controller = TextEditingController(text: _budgetNumber(category['planned']).toStringAsFixed(2));
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _paper,
        title: Text('Plan for ${category['name']}', style: GoogleFonts.playfairDisplay(color: _green, fontWeight: FontWeight.w700)),
        content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () { final parsed = _parseBudgetAmount(controller.text); if (parsed != null) Navigator.pop(dialogContext, parsed); }, style: FilledButton.styleFrom(backgroundColor: _green), child: const Text('Save plan')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final updated = categories.map((item) => Map<String, dynamic>.from(item)).toList();
    updated[index]['planned'] = value;
    await _writeBudget({'categories': updated});
  }

  Future<void> _addBudgetCategory(List<Map<String, dynamic>> categories) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController(text: '0.00');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _paper,
        title: Text('Add a category', style: GoogleFonts.playfairDisplay(color: _green, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, maxLength: 40, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Category name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monthly plan', prefixText: '\$ ', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () { final name = nameController.text.trim(); final amount = _parseBudgetAmount(amountController.text); if (name.isNotEmpty && amount != null) Navigator.pop(dialogContext, {'name': name, 'planned': amount}); }, style: FilledButton.styleFrom(backgroundColor: _green), child: const Text('Add')),
        ],
      ),
    );
    nameController.dispose();
    amountController.dispose();
    if (result == null) return;
    if (categories.length >= 20) {
      _message('You can have up to 20 budget categories.');
      return;
    }
    if (categories.any((item) => (item['name'] as String? ?? '').toLowerCase() == (result['name'] as String).toLowerCase())) {
      _message('That category already exists.');
      return;
    }
    await _writeBudget({'categories': [...categories, result]});
  }

  Future<void> _addBudgetExpense(List<Map<String, dynamic>> categories, List<Map<String, dynamic>> expenses) async {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final categoryNames = categories.map((item) => (item['name'] as String? ?? '').trim()).where((name) => name.isNotEmpty).toList();
    if (categoryNames.isEmpty) categoryNames.add('Other');
    var selectedCategory = categoryNames.first;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _paper,
          title: Text('Log an expense', style: GoogleFonts.playfairDisplay(color: _green, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: descriptionController, maxLength: 60, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'What was it for?', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$ ', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: categoryNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
              onChanged: (value) { if (value != null) setDialogState(() => selectedCategory = value); },
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () { final amount = _parseBudgetAmount(amountController.text); if (amount != null && amount > 0) Navigator.pop(dialogContext, {'description': descriptionController.text.trim(), 'amount': amount, 'category': selectedCategory}); }, style: FilledButton.styleFrom(backgroundColor: _green), child: const Text('Save expense')),
          ],
        ),
      ),
    );
    descriptionController.dispose();
    amountController.dispose();
    if (result == null) return;
    final today = DateTime.now();
    final month = _selectedBudgetMonth;
    final day = today.day.clamp(1, DateTime(month.year, month.month + 1, 0).day) as int;
    final now = DateTime(month.year, month.month, day, today.hour, today.minute, today.second);
    final updated = [...expenses, {
      'id': now.microsecondsSinceEpoch.toString(),
      'description': result['description'],
      'amount': result['amount'],
      'category': result['category'],
      'date': Timestamp.fromDate(now),
    }];
    await _writeBudget({'expenses': updated.length > 200 ? updated.skip(updated.length - 200).toList() : updated});
  }

  Future<void> _writeBudget(Map<String, dynamic> values) async {
    try {
      await _budgetDocument?.set({...values, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      _message('Could not save budget (${error.code}). Please try again.');
    } catch (_) {
      _message('Could not save your budget. Please try again.');
    }
  }

  double _budgetNumber(Object? value) => value is num ? value.toDouble() : 0;
  DateTime? _budgetDate(Object? value) => value is Timestamp ? value.toDate() : value is DateTime ? value : null;
  double? _parseBudgetAmount(String value) => double.tryParse(value.replaceAll(',', '').replaceAll('\$', '').trim());
  String _budgetMoney(num amount) {
    final absolute = amount.abs();
    return '${amount < 0 ? '−' : ''}\$${absolute.toStringAsFixed(absolute % 1 == 0 ? 0 : 2)}';
  }

  Widget _recordList(String kind) {
    if (kind == 'goal') return _goalList();
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

  Widget _goalDetailSection(String label, String value) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF74766F),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    ),
  );

  Widget _goalList() {
    final collection = _entries;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE7EBDD), Color(0xFFF5EADB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _paper.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.explore_outlined, color: _green, size: 26),
              ),
              const SizedBox(height: 14),
              Text(
                'Your next chapter',
                style: GoogleFonts.playfairDisplay(
                  color: _green,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dream it, give it a first step, and keep growing at your own pace.',
                style: TextStyle(color: _ink, height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _addGoal,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create a goal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Goals you’re growing',
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        if (collection == null)
          const SizedBox.shrink()
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: collection.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _surface(
                  child: const Text('Your goals could not be loaded. Check your connection and try again.'),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(26),
                  child: Center(child: CircularProgressIndicator(color: _green)),
                );
              }
              final docs = snapshot.data!.docs
                  .where((doc) => doc.data()['entryType'] == 'goal')
                  .toList();
              if (docs.isEmpty) {
                return _surface(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                    child: Column(
                      children: [
                        const Icon(Icons.spa_outlined, color: _green, size: 34),
                        const SizedBox(height: 9),
                        Text(
                          'A good place to begin is with one thing you want for yourself.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Your goals and progress will appear here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF74766F), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final title = (data['title'] as String? ?? 'Personal goal').trim();
                  final body = (data['body'] as String? ?? '').trim();
                  final motivation = (data['goalMotivation'] as String? ?? '').trim();
                  final obstacles = (data['goalObstacles'] as String? ?? '').trim();
                  final plan = (data['goalPlan'] as String? ?? '').trim();
                  final progress = data['goalProgress'] is num
                      ? (data['goalProgress'] as num).toDouble().clamp(0, 100)
                      : 0.0;
                  final steps = (data['actionSteps'] as List<dynamic>? ?? const [])
                      .whereType<String>()
                      .where((step) => step.trim().isNotEmpty)
                      .take(2)
                      .toList();
                  final description = (data['goalDescription'] as String? ?? '').trim();
                  final displayBody = description.isNotEmpty
                      ? description
                      : steps.isEmpty
                      ? body
                      : '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _paper,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(color: _line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _sage,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: const Icon(Icons.flag_outlined, color: _green),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? 'Personal goal' : title,
                                    style: GoogleFonts.playfairDisplay(
                                      color: _green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (displayBody.isNotEmpty && displayBody != title) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      displayBody,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF5E615B),
                                        height: 1.35,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Goal actions',
                              onSelected: (action) {
                                if (action == 'progress') {
                                  _changeProgress(doc);
                                } else {
                                  _delete(doc);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'progress',
                                  child: Text('Update progress'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete goal'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (steps.isNotEmpty) ...[
                          const SizedBox(height: 11),
                          const Text(
                            'FIRST STEPS',
                            style: TextStyle(
                              color: Color(0xFF74766F),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 5),
                          for (final step in steps)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('•  ', style: TextStyle(color: _green)),
                                  Expanded(
                                    child: Text(
                                      step,
                                      style: const TextStyle(
                                        color: _ink,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        if (motivation.isNotEmpty)
                          _goalDetailSection('WHY THIS MATTERS', motivation),
                        if (obstacles.isNotEmpty)
                          _goalDetailSection('WHAT MIGHT GET IN THE WAY', obstacles),
                        if (plan.isNotEmpty)
                          _goalDetailSection('HOW I’LL WORK THROUGH IT', plan),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Progress',
                                style: TextStyle(
                                  color: Color(0xFF5E615B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${progress.round()}%',
                              style: const TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            minHeight: 8,
                            backgroundColor: _sage,
                            color: _green,
                          ),
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
                      onTap: () => widget.onWritePrompt(prompt, 'journal_prompt'),
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
              onTap: () {
                if (type == 'milestone') {
                  _openMilestoneDetails(doc);
                } else if (type == 'gratitude') {
                  _openGratitudeDetails(doc);
                } else {
                  _openEntry(doc);
                }
              },
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

  Future<void> _openGratitudeDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _GratitudeDetailsPage(entry: doc),
      ),
    );
  }

  Future<void> _openMilestoneDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MilestoneDetailsPage(entry: doc),
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
    final draft = await Navigator.of(context).push<_MilestoneDraft>(
      MaterialPageRoute<_MilestoneDraft>(
        builder: (_) => const _MilestoneEditorPage(),
      ),
    );
    if (draft == null) return;
    await _saveRecord(
      type: 'milestone',
      title: draft.title,
      body: draft.description.isEmpty ? draft.title : draft.description,
      extra: {
        'milestoneDate': Timestamp.fromDate(draft.date),
        'milestoneIcon': '🌱',
      },
    );
  }

  Future<void> _addGoal() async {
    final draft = await Navigator.of(context).push<_GoalDraft>(
      MaterialPageRoute<_GoalDraft>(
        builder: (_) => const _GoalEditorPage(),
      ),
    );
    if (draft == null) return;
    final steps = draft.steps
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    await _saveRecord(
      type: 'goal',
      title: draft.title,
      body: draft.description.isNotEmpty
          ? draft.description
          : steps.isNotEmpty
          ? steps.join('\n')
          : draft.title,
      extra: {
        'goalProgress': 0,
        'goalMotivation': draft.motivation,
        'goalDescription': draft.description,
        'actionSteps': steps,
        'goalObstacles': draft.barriers,
        'goalPlan': draft.plan,
      },
    );
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
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isCompleted(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data['entryType'] != 'guided' || data['guidedJourneyId'] is! String) {
      return false;
    }
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
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(text: 'Explore'),
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
              _inProgressTab(),
              _completedTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _inProgressTab() {
    final collection = widget.entries;
    if (collection == null) return const Center(child: Text('Sign in to view your in-progress journeys.'));
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: collection.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('In-progress journeys could not be loaded. Check your connection and try again.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _green));
        }
        final docs = snapshot.data!.docs
            .where(
              (doc) =>
                  doc.data()['entryType'] == 'guided' &&
                  doc.data()['guidedJourneyId'] is String &&
                  !_isCompleted(doc),
            )
            .toList();
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
                    Icon(Icons.edit_note_rounded, color: _green, size: 30),
                    SizedBox(height: 9),
                    Text(
                      'Journeys you start will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Your saved reflections will be ready whenever you want to continue.',
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
            for (final doc in docs) _completedJourneyCard(doc, completed: false),
          ],
        );
      },
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

  _GuidedJourney? _journeyForEntry(Map<String, dynamic> data) {
    final id = data['guidedJourneyId'] as String?;
    if (id == null) return null;
    for (final journey in widget.journeys) {
      if (journey.id == id) return journey;
    }
    return null;
  }

  Widget _completedJourneyCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, {required bool completed}) {
    final data = doc.data();
    final journey = _journeyForEntry(data);
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
          if (journey != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => _GuidedJourneyScreen(
                    journey: journey,
                    entries: widget.entries,
                    draft: doc,
                  ),
                )),
                icon: Icon(completed ? Icons.replay_rounded : Icons.edit_note_rounded, size: 18),
                label: Text(completed ? 'Reopen journey' : 'Continue journey'),
                style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
              ),
            ),
          ],
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
class _GuidedJourneyScreen extends StatefulWidget {
  const _GuidedJourneyScreen({
    required this.journey,
    required this.entries,
    this.draft,
  });

  final _GuidedJourney journey;
  final CollectionReference<Map<String, dynamic>>? entries;
  final QueryDocumentSnapshot<Map<String, dynamic>>? draft;

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
    final saved = widget.draft?.data();
    if (saved == null) return;
    final storedAnswers = saved['guidedJourneyAnswers'];
    if (storedAnswers is List) {
      for (var index = 0; index < _answers.length && index < storedAnswers.length; index++) {
        _answers[index].text = storedAnswers[index] as String? ?? '';
      }
      return;
    }
    final body = saved['body'] as String? ?? '';
    var cursor = 0;
    for (var index = 0; index < widget.journey.steps.length; index++) {
      final marker = '${index + 1}. ${widget.journey.steps[index]}\n';
      final start = body.indexOf(marker, cursor);
      if (start < 0) continue;
      final answerStart = start + marker.length;
      var end = body.length;
      if (index + 1 < widget.journey.steps.length) {
        final nextMarker = '${index + 2}. ${widget.journey.steps[index + 1]}\n';
        final nextStart = body.indexOf(nextMarker, answerStart);
        if (nextStart >= 0) end = nextStart;
      }
      final answer = body.substring(answerStart, end).replaceFirst(RegExp(r'\n+$'), '');
      _answers[index].text = answer == '—' ? '' : answer;
      cursor = end;
    }
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
    final isComplete = _answers.every((answer) => answer.text.trim().isNotEmpty);
    final body = List.generate(widget.journey.steps.length, (index) {
      final answer = _answers[index].text.trim();
      return '${index + 1}. ${widget.journey.steps[index]}\n${answer.isEmpty ? '—' : answer}';
    }).join('\n\n');
    try {
      final data = <String, dynamic>{
        'title': widget.journey.title,
        'body': body,
        'guidedJourneyAnswers': _answers.map((answer) => answer.text.trim()).toList(),
        'prompt': 'Guided journey: ${widget.journey.title}',
        'entryType': 'guided',
        'guidedJourneyId': widget.journey.id,
        'guidedJourneyCompleted': isComplete,
        'tags': [widget.journey.category, 'Guided Journey'],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      final draft = widget.draft;
      if (draft == null) {
        data['attachments'] = <String>[];
        data['favorite'] = false;
        data['createdAt'] = FieldValue.serverTimestamp();
        await collection.add(data);
      } else {
        await collection.doc(draft.id).update(data);
      }
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
    this.onOpenEntry,
  });

  final List<String> categories;
  final CollectionReference<Map<String, dynamic>>? savedPrompts;
  final CollectionReference<Map<String, dynamic>>? entries;
  final ValueChanged<String> onWrite;
  final Future<void> Function(String, String, bool) onToggleFavorite;
  final String intro;
  final void Function(
    QueryDocumentSnapshot<Map<String, dynamic>> entry, {
    String? entryType,
  })? onOpenEntry;

  @override
  State<_PromptLibrary> createState() => _PromptLibraryState();
}

class _PromptLibraryState extends State<_PromptLibrary>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final Set<String> _savingPrompts = <String>{};

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String? _categoryFor(String prompt) {
    for (final group in _promptGroups.entries) {
      if (group.value.contains(prompt)) return group.key;
    }
    return null;
  }

  bool _isJournalPromptEntry(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data['entryType'] == 'journal_prompt') return true;
    return data['entryType'] == 'guided' &&
        data['guidedJourneyId'] == null &&
        _categoryFor(data['prompt'] as String? ?? '') != null;
  }

  bool _isCompleted(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data['journalPromptCompleted'] == true) return true;
    // Any saved writing is a completed one-off prompt. This also surfaces
    // older responses that were saved before completion was set automatically.
    final body = data['body'] as String? ?? '';
    if (body.trim().isNotEmpty) return true;
    // Older prompt responses were saved as "guided" without a journey ID.
    return data['entryType'] == 'guided' && data['guidedJourneyId'] == null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.entries?.snapshots(),
      builder: (context, entriesSnapshot) {
        final promptEntries = (entriesSnapshot.data?.docs ?? [])
            .where(_isJournalPromptEntry)
            .toList();
        final answered = promptEntries
            .map((doc) => doc.data()['prompt'] as String? ?? '')
            .where((item) => item.isNotEmpty)
            .toSet();
        final completedPrompts = promptEntries
            .where(_isCompleted)
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
              for (final prompt
                  in _promptGroups[category] ?? const <String>[]) {
                if (!completedPrompts.contains(prompt)) {
                  filtered.add((category, prompt));
                }
              }
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.intro,
                      style: const TextStyle(
                        color: Color(0xFF5F625D),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                TabBar(
                  controller: _tabs,
                  labelColor: _green,
                  unselectedLabelColor: const Color(0xFF74766F),
                  indicatorColor: _green,
                  labelPadding: EdgeInsets.zero,
                  tabs: const [
                    Tab(text: 'Explore'),
                    Tab(text: 'Saved Favorites'),
                    Tab(text: 'Completed'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _exploreTab(filtered, saved, answered),
                      _savedFavoritesTab(savedSnapshot),
                      _promptEntriesTab(promptEntries, completed: true),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _exploreTab(
    List<(String, String)> filtered,
    Set<String> saved,
    Set<String> answered,
  ) {
    final grouped = <String, List<String>>{
      for (final category in widget.categories) category: <String>[],
    };
    for (final item in filtered) {
      grouped.putIfAbsent(item.$1, () => <String>[]).add(item.$2);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        if (filtered.isEmpty)
          _softCard(
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'No prompts are available right now.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF74766F)),
              ),
            ),
          )
        else
          for (final category in widget.categories)
            if ((grouped[category] ?? const <String>[]).isNotEmpty)
              _promptCategorySection(
                context,
                category,
                grouped[category]!,
                saved,
                answered,
              ),
      ],
    );
  }

  Widget _promptCategorySection(
    BuildContext context,
    String category,
    List<String> prompts,
    Set<String> saved,
    Set<String> answered,
  ) {
    final icon = switch (category) {
      'Get to Know You' => Icons.self_improvement_rounded,
      'Heal & Let Go' => Icons.spa_outlined,
      'Relationships' => Icons.favorite_border_rounded,
      'Growth Mindset' => Icons.trending_up,
      'Faith & Purpose' => Icons.explore_outlined,
      _ => Icons.wb_sunny_outlined,
    };
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
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _green),
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
            '${prompts.length} ${prompts.length == 1 ? 'prompt' : 'prompts'}',
            style: const TextStyle(color: Color(0xFF656961), fontSize: 12),
          ),
          iconColor: _green,
          collapsedIconColor: _green,
          children: [
            for (final prompt in prompts)
              _promptTile(
                category,
                prompt,
                saved.contains(prompt),
                answered.contains(prompt),
                _savingPrompts.contains(prompt),
                () => _savePrompt(prompt, category, saved.contains(prompt)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _savedFavoritesTab(
    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
  ) {
    if (snapshot.hasError) {
      return const Center(child: Text('Saved favorites could not be loaded. Check your connection and try again.'));
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator(color: _green));
    }
    final docs = snapshot.data!.docs;
    if (docs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _softCard(
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.bookmark_border_rounded, color: _green, size: 30),
                  SizedBox(height: 9),
                  Text(
                    'Your saved prompt favorites will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Tap a bookmark in Explore to keep a question close and return to it anytime.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF74766F), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final doc in docs)
          Builder(
            builder: (context) {
              final data = doc.data();
              final prompt = data['prompt'] as String? ?? '';
              final category = data['category'] as String? ?? 'Saved prompt';
              final saving = _savingPrompts.contains(prompt);
              return _softCard(
                margin: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: prompt.isEmpty ? null : () => widget.onWrite(prompt),
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
                            Text(category, style: const TextStyle(fontSize: 11, color: _green)),
                            const SizedBox(height: 5),
                            const Text(
                              'Tap to write a reflection',
                              style: TextStyle(fontSize: 11, color: Color(0xFF74766F)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove from Saved Favorites',
                      onPressed: saving ? null : () => _savePrompt(prompt, category, true),
                      icon: saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _green))
                          : const Icon(Icons.bookmark_rounded, color: _green),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _promptEntriesTab(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> entries, {
    required bool completed,
  }) {
    final docs = entries
        .where((doc) => _isCompleted(doc) == completed)
        .toList();
    final emptyText = completed
        ? 'Prompts you mark complete will be kept here. You can reopen any reflection whenever you like.'
        : 'Reflections you save will appear here until you mark them complete.';
    if (docs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _softCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle_outline
                        : Icons.edit_note_rounded,
                    color: _green,
                    size: 30,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    completed
                        ? 'Completed prompts will be kept here.'
                        : 'Your prompt reflections will gather here.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF74766F),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (completed) {
      final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
      for (final doc in docs) {
        final data = doc.data();
        final prompt = data['prompt'] as String? ?? '';
        final category = data['journalPromptCategory'] as String? ??
            _categoryFor(prompt) ??
            'Other Prompts';
        grouped.putIfAbsent(category, () => []).add(doc);
      }
      final orderedCategories = [
        ...widget.categories.where(grouped.containsKey),
        ...grouped.keys.where((category) => !widget.categories.contains(category)),
      ];
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          for (final category in orderedCategories)
            _completedPromptCategorySection(category, grouped[category]!),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (final doc in docs)
          _promptReflectionCard(doc, completed: completed),
      ],
    );
  }

  Widget _completedPromptCategorySection(
    String category,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> entries,
  ) {
    final icon = switch (category) {
      'Get to Know You' => Icons.self_improvement_rounded,
      'Heal & Let Go' => Icons.spa_outlined,
      'Relationships' => Icons.favorite_border_rounded,
      'Growth Mindset' => Icons.trending_up,
      'Faith & Purpose' => Icons.explore_outlined,
      _ => Icons.wb_sunny_outlined,
    };
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
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _sage,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: _green),
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
            '${entries.length} ${entries.length == 1 ? 'prompt' : 'prompts'}',
            style: const TextStyle(color: Color(0xFF656961), fontSize: 12),
          ),
          iconColor: _green,
          collapsedIconColor: _green,
          children: [
            for (final doc in entries)
              _promptReflectionCard(doc, completed: true),
          ],
        ),
      ),
    );
  }

  Widget _promptReflectionCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool completed,
  }) {
    final data = doc.data();
    final prompt = data['prompt'] as String? ?? 'Journal prompt';
    final category = data['journalPromptCategory'] as String? ??
        _categoryFor(prompt) ??
        'Journal Prompt';
    final body = data['body'] as String? ?? '';
    return _softCard(
      margin: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                final openEntry = widget.onOpenEntry;
                if (openEntry != null) {
                  openEntry(doc, entryType: 'journal_prompt');
                } else {
                  widget.onWrite(prompt);
                }
              },
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
                    category,
                    style: const TextStyle(fontSize: 11, color: _green),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5F625D),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (completed)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.check_circle_rounded, color: _green),
            )
          else
            IconButton(
              tooltip: 'Mark prompt completed',
              onPressed: () => _markCompleted(doc),
              icon: const Icon(
                Icons.check_circle_outline_rounded,
                color: _green,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markCompleted(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    try {
      final prompt = doc.data()['prompt'] as String? ?? '';
      final category = _categoryFor(prompt);
      await doc.reference.update({
        'entryType': 'journal_prompt',
        'journalPromptCompleted': true,
        if (category != null) 'journalPromptCategory': category,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update this prompt. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _savePrompt(String prompt, String category, bool saved) async {
    if (_savingPrompts.contains(prompt)) return;
    setState(() => _savingPrompts.add(prompt));
    try {
      await widget.onToggleFavorite(prompt, category, saved);
    } finally {
      if (mounted) setState(() => _savingPrompts.remove(prompt));
    }
  }

  Widget _promptTile(
    String category,
    String prompt,
    bool saved,
    bool answered,
    bool saving,
    VoidCallback onToggle,
  ) =>
      _softCard(
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
              onPressed: saving ? null : onToggle,
              icon: saving
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _green,
                      ),
                    )
                  : Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
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
  });
  final void Function(String) onSaved;
  final CollectionReference<Map<String, dynamic>>? entries;
  @override
  State<_MoodComposer> createState() => _MoodComposerState();
}

class _MoodComposerState extends State<_MoodComposer> {
  String? _mood;
  String? _linkedId;
  final Set<String> _tags = {};
  final TextEditingController _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  String _journalEntryTitle(Map<String, dynamic> data) {
    final title = (data['title'] as String? ?? '').trim();
    if (title.isNotEmpty) return title;
    final prompt = (data['prompt'] as String? ?? '').trim();
    return prompt.isNotEmpty ? prompt : 'Journal entry';
  }

  Future<void> _chooseLinkedEntry(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> entries,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * .76,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a journal entry',
                      style: GoogleFonts.playfairDisplay(
                        color: _green,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select the page you want to connect to this reflection.',
                      style: TextStyle(color: Color(0xFF62665E)),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.link_off_rounded, color: _green),
                title: const Text('No linked entry'),
                subtitle: const Text('Leave this reflection unconnected'),
                trailing: _linkedId == null
                    ? const Icon(Icons.check_circle_rounded, color: _green)
                    : null,
                onTap: () => Navigator.pop(sheetContext, ''),
              ),
              const Divider(height: 1, color: _line),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                  itemCount: entries.length,
                  separatorBuilder: (_context, _index) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final doc = entries[index];
                    final data = doc.data();
                    final title = _journalEntryTitle(data);
                    final type = switch (data['entryType'] as String? ?? 'journal') {
                      'journal_prompt' => 'Journal prompt',
                      'guided' => 'Guided journaling',
                      'gratitude' => 'Gratitude note',
                      'letter' => 'Letter',
                      final value => value[0].toUpperCase() + value.substring(1),
                    };
                    final stamp = data['createdAt'];
                    final date = stamp is Timestamp
                        ? MaterialLocalizations.of(context).formatMediumDate(stamp.toDate())
                        : 'Date unavailable';
                    final preview = (data['body'] as String? ?? '').trim();
                    final isSelected = doc.id == _linkedId;
                    return Material(
                      color: _paper,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? _green : _line,
                          ),
                        ),
                        title: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$type · $date'),
                              if (preview.isNotEmpty)
                                Text(
                                  preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: _green,
                        ),
                        onTap: () => Navigator.pop(sheetContext, doc.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _linkedId = selected.isEmpty ? null : selected);
  }

  Future<void> _save() async {
    final collection = widget.entries;
    if (_mood == null || _saving || collection == null) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'title': 'Mood reflection · $_mood',
        'body': _note.text.trim().isEmpty
            ? 'Mood check-in: $_mood'
            : _note.text.trim(),
        'prompt': 'How are you feeling today?',
        'entryType': 'mood',
        'mood': _mood,
        if (_linkedId != null) 'linkedEntryId': _linkedId,
        'tags': _tags.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await collection.add({
        ...data,
        'favorite': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _note.clear();
      setState(() {
        _mood = null;
        _linkedId = null;
        _tags.clear();
      });
      widget.onSaved('Your mood reflection was saved privately.');
    } catch (_) {
      if (mounted) {
        widget.onSaved(
          'Could not save your mood reflection. Please try again.',
        );
      }
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
            QueryDocumentSnapshot<Map<String, dynamic>>? selectedEntry;
            for (final doc in entries) {
              if (doc.id == _linkedId) {
                selectedEntry = doc;
                break;
              }
            }
            final selectedTitle = selectedEntry == null
                ? 'Choose a journal entry'
                : _journalEntryTitle(selectedEntry.data());
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _chooseLinkedEntry(entries),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Link to a journal entry (optional)',
                    helperText: 'Choose which page this reflection connects to.',
                    filled: true,
                    fillColor: _paper,
                    suffixIcon: const Icon(Icons.expand_more_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: _line),
                    ),
                  ),
                  child: Text(
                    selectedTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedEntry == null ? const Color(0xFF74766F) : _ink,
                      fontWeight: selectedEntry == null
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _MoodReflectionDetailsPage(
                        entry: doc,
                        entries: widget.entries!,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
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
                              const SizedBox(height: 3),
                              const Text(
                                'Tap to view reflection',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF74766F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: _green, size: 16),
                      ],
                    ),
                  ),
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

class _GoalDraft {
  const _GoalDraft({
    required this.title,
    required this.motivation,
    required this.description,
    required this.steps,
    required this.barriers,
    required this.plan,
  });

  final String title;
  final String motivation;
  final String description;
  final String steps;
  final String barriers;
  final String plan;
}

class _GoalEditorPage extends StatefulWidget {
  const _GoalEditorPage();

  @override
  State<_GoalEditorPage> createState() => _GoalEditorPageState();
}

class _GoalEditorPageState extends State<_GoalEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _motivation = TextEditingController();
  final _description = TextEditingController();
  final _steps = TextEditingController();
  final _barriers = TextEditingController();
  final _plan = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _motivation.dispose();
    _description.dispose();
    _steps.dispose();
    _barriers.dispose();
    _plan.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _GoalDraft(
        title: _title.text.trim(),
        motivation: _motivation.text.trim(),
        description: _description.text.trim(),
        steps: _steps.text.trim(),
        barriers: _barriers.text.trim(),
        plan: _plan.text.trim(),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    int minLines = 3,
    int maxLines = 5,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  color: _green,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (!required)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _sage,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Optional',
                  style: TextStyle(color: _green, fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          minLines: minLines,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            alignLabelWithHint: minLines > 1,
            filled: true,
            fillColor: _paper,
            contentPadding: const EdgeInsets.all(15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
          validator: required
              ? (value) => value == null || value.trim().isEmpty
                  ? 'Add a name for your goal.'
                  : null
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 760;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        title: Text(
          'Create a Goal',
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to Vision & Goals',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentMaxWidth = wide ? 680.0 : 560.0;
            final contentWidth = constraints.maxWidth < contentMaxWidth
                ? constraints.maxWidth
                : contentMaxWidth;
            return Center(
              child: SizedBox(
                width: contentWidth,
                height: constraints.maxHeight,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                          children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE7EBDD), Color(0xFFF5EADB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.explore_outlined,
                          color: _green,
                          size: 40,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Make space for what matters',
                                style: GoogleFonts.playfairDisplay(
                                  color: _green,
                                  fontSize: wide ? 25 : 21,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'You don’t have to have it all figured out. Start with what feels important.',
                                style: TextStyle(
                                  color: _ink,
                                  height: 1.4,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _field(
                    label: 'What do you want to work toward?',
                    controller: _title,
                    hint: 'Name your goal',
                    minLines: 1,
                    maxLines: 1,
                    required: true,
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'Why does this goal matter to you?',
                    controller: _motivation,
                    hint: 'What makes this meaningful for you?',
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'Goal description',
                    controller: _description,
                    hint: 'What would this goal look or feel like for you?',
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'Steps you believe you need to take',
                    controller: _steps,
                    hint: 'Write one small step per line',
                    minLines: 4,
                    maxLines: 7,
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'What might get in the way?',
                    controller: _barriers,
                    hint: 'Name any barriers or worries',
                  ),
                  const SizedBox(height: 18),
                  _field(
                    label: 'How will you work through it?',
                    controller: _plan,
                    hint: 'What could help when things feel difficult?',
                  ),
                  const SizedBox(height: 18),
                  _softCard(
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.favorite_border_rounded,
                          color: _green,
                          size: 20,
                        ),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Small steps count. You can update your plan as you grow.',
                            style: TextStyle(
                              color: Color(0xFF5E615B),
                              height: 1.35,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Save goal',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MilestoneDraft {
  const _MilestoneDraft({
    required this.title,
    required this.description,
    required this.date,
  });

  final String title;
  final String description;
  final DateTime date;
}

class _MilestoneEditorPage extends StatefulWidget {
  const _MilestoneEditorPage();

  @override
  State<_MilestoneEditorPage> createState() => _MilestoneEditorPageState();
}

class _MilestoneEditorPageState extends State<_MilestoneEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final next = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (next != null && mounted) setState(() => _date = next);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _MilestoneDraft(
        title: _title.text.trim(),
        description: _description.text.trim(),
        date: _date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 760;
    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        title: Text(
          'New Milestone',
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentMaxWidth = wide ? 680.0 : 560.0;
          final contentWidth = constraints.maxWidth < contentMaxWidth
              ? constraints.maxWidth
              : contentMaxWidth;
          return Center(
            child: SizedBox(
              width: contentWidth,
              height: constraints.maxHeight,
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Celebrate a milestone',
                        style: GoogleFonts.playfairDisplay(
                          color: _green,
                          fontSize: 27,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Take a moment to recognize how far you have come.',
                        style: TextStyle(
                          color: Color(0xFF62665E),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'What did you do?',
                          filled: true,
                          fillColor: _paper,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(color: _line),
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Add a title for your milestone.'
                                : null,
                      ),
                      const SizedBox(height: 10),
                      Material(
                        color: _paper,
                        borderRadius: BorderRadius.circular(15),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(color: _line),
                          ),
                          leading: const Icon(
                            Icons.calendar_today_outlined,
                            color: _green,
                          ),
                          title: const Text('Milestone date'),
                          subtitle: Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(_date),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: _green,
                          ),
                          onTap: _pickDate,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _description,
                          textCapitalization: TextCapitalization.sentences,
                          textAlignVertical: TextAlignVertical.top,
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          maxLength: 10000,
                          decoration: InputDecoration(
                            labelText: 'Write about this moment (optional)',
                            hintText: 'Start writing here…',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: _paper,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: _line),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text(
                            'Save milestone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GratitudeDetailsPage extends StatelessWidget {
  const _GratitudeDetailsPage({required this.entry});

  final QueryDocumentSnapshot<Map<String, dynamic>> entry;

  @override
  Widget build(BuildContext context) {
    final data = entry.data();
    final rawTitle = (data['title'] as String? ?? '').trim();
    final prompt = (data['prompt'] as String? ?? '').trim();
    final question = prompt.isNotEmpty
        ? prompt
        : rawTitle.isNotEmpty
        ? rawTitle
        : 'What is one thing you appreciate today?';
    final body = (data['body'] as String? ?? '').trim();
    final createdAt = data['createdAt'];
    final date = createdAt is Timestamp
        ? createdAt.toDate()
        : createdAt is DateTime
        ? createdAt
        : null;
    final dateLabel = date == null
        ? 'Date unavailable'
        : MaterialLocalizations.of(context).formatMediumDate(date);

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        title: Text(
          'Gratitude',
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to gratitude',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _softCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.favorite_border_rounded,
                          color: _green,
                          size: 29,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gratitude note',
                              style: GoogleFonts.playfairDisplay(
                                color: _green,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                color: Color(0xFF74766F),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _softCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question,
                        style: GoogleFonts.playfairDisplay(
                          color: _green,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(
                        body.isEmpty ? 'No written note was added.' : body,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneDetailsPage extends StatelessWidget {
  const _MilestoneDetailsPage({required this.entry});

  final QueryDocumentSnapshot<Map<String, dynamic>> entry;

  @override
  Widget build(BuildContext context) {
    final data = entry.data();
    final rawTitle = (data['title'] as String? ?? '').trim();
    final title = rawTitle.isEmpty ? 'Milestone' : rawTitle;
    final body = (data['body'] as String? ?? '').trim();
    final milestoneValue = data['milestoneDate'] ?? data['createdAt'];
    final milestoneDate = milestoneValue is Timestamp
        ? milestoneValue.toDate()
        : milestoneValue is DateTime
        ? milestoneValue
        : null;
    final createdValue = data['createdAt'];
    final createdDate = createdValue is Timestamp
        ? createdValue.toDate()
        : createdValue is DateTime
        ? createdValue
        : null;
    final dateLabel = milestoneDate == null
        ? 'Date unavailable'
        : MaterialLocalizations.of(context).formatMediumDate(milestoneDate);
    final savedLabel = createdDate == null
        ? null
        : MaterialLocalizations.of(context).formatMediumDate(createdDate);
    final description = body == title ? '' : body;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        title: Text(
          'Milestone',
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to milestones',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _softCard(
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 58,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _sage,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          data['milestoneIcon'] as String? ?? '🌱',
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.playfairDisplay(
                                color: _green,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                color: Color(0xFF74766F),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _softCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your milestone',
                        style: GoogleFonts.playfairDisplay(
                          color: _green,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        description.isEmpty
                            ? 'No additional details were added.'
                            : description,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (savedLabel != null) ...[
                  const SizedBox(height: 12),
                  _softCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bookmark_added_outlined,
                          color: _green,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          'Saved on $savedLabel',
                          style: const TextStyle(
                            color: Color(0xFF5E615B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodReflectionDetailsPage extends StatelessWidget {
  const _MoodReflectionDetailsPage({
    required this.entry,
    required this.entries,
  });

  final QueryDocumentSnapshot<Map<String, dynamic>> entry;
  final CollectionReference<Map<String, dynamic>> entries;

  @override
  Widget build(BuildContext context) {
    final data = entry.data();
    final mood = data['mood'] as String? ?? 'Mood reflection';
    final body = data['body'] as String? ?? '';
    final tags = (data['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final createdAt = data['createdAt'];
    final date = createdAt is Timestamp
        ? createdAt.toDate()
        : createdAt is DateTime
        ? createdAt
        : null;
    final dateLabel = date == null
        ? 'Date unavailable'
        : MaterialLocalizations.of(context).formatMediumDate(date);
    final linkedId = data['linkedEntryId'] as String?;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _green,
        centerTitle: true,
        title: Text(
          'Mood Reflection',
          style: GoogleFonts.playfairDisplay(
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          tooltip: 'Back to mood reflections',
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _softCard(
                  child: Row(
                    children: [
                      Text(
                        _moods[mood] ?? '🌿',
                        style: const TextStyle(fontSize: 38),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mood,
                              style: GoogleFonts.playfairDisplay(
                                color: _green,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                color: Color(0xFF74766F),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _softCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your reflection',
                        style: GoogleFonts.playfairDisplay(
                          color: _green,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        body.isEmpty ? 'No written note was added.' : body,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _softCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tags',
                          style: GoogleFonts.playfairDisplay(
                            color: _green,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 7,
                          runSpacing: 7,
                          children: tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: _sage,
                                  side: BorderSide.none,
                                  labelStyle: const TextStyle(color: _green),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _softCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked journal entry',
                        style: GoogleFonts.playfairDisplay(
                          color: _green,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (linkedId == null)
                        const Text(
                          'No journal entry was linked.',
                          style: TextStyle(color: Color(0xFF74766F)),
                        )
                      else
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: entries.doc(linkedId).get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text(
                                'The linked entry could not be loaded.',
                                style: TextStyle(color: Color(0xFF74766F)),
                              );
                            }
                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: _green,
                                  ),
                                ),
                              );
                            }
                            final linkedData = snapshot.data!.data();
                            if (linkedData == null) {
                              return const Text(
                                'The linked journal entry is no longer available.',
                                style: TextStyle(color: Color(0xFF74766F)),
                              );
                            }
                            final title =
                                (linkedData['title'] as String? ?? '').trim();
                            final prompt =
                                (linkedData['prompt'] as String? ?? '').trim();
                            final body =
                                (linkedData['body'] as String? ?? '').trim();
                            final linkedTags =
                                (linkedData['tags'] as List<dynamic>? ?? const [])
                                    .whereType<String>()
                                    .toList();
                            final linkedCreatedAt = linkedData['createdAt'];
                            final linkedDate = linkedCreatedAt is Timestamp
                                ? MaterialLocalizations.of(context)
                                    .formatMediumDate(linkedCreatedAt.toDate())
                                : null;
                            final displayTitle = title.isNotEmpty
                                ? title
                                : prompt.isNotEmpty
                                ? prompt
                                : 'Journal entry';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTitle,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                if (linkedDate != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    linkedDate,
                                    style: const TextStyle(
                                      color: Color(0xFF74766F),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (prompt.isNotEmpty && prompt != displayTitle) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Prompt',
                                    style: TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  SelectableText(
                                    prompt,
                                    style: const TextStyle(
                                      color: _ink,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                const Text(
                                  'Full entry',
                                  style: TextStyle(
                                    color: _green,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                SelectableText(
                                  body.isEmpty
                                      ? 'No written response was added.'
                                      : body,
                                  style: const TextStyle(
                                    color: _ink,
                                    height: 1.5,
                                  ),
                                ),
                                if (linkedTags.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tags',
                                    style: TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: linkedTags
                                        .map(
                                          (tag) => Chip(
                                            label: Text(tag),
                                            backgroundColor: _sage,
                                            side: BorderSide.none,
                                            labelStyle: const TextStyle(
                                              color: _green,
                                              fontSize: 11,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                ),
                if (data['favorite'] == true) ...[
                  const SizedBox(height: 12),
                  _softCard(
                    child: const Row(
                      children: [
                        Icon(Icons.bookmark_rounded, color: _green, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Saved to favorites',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
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
