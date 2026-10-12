import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlanMyWeekScreen extends StatefulWidget {
  const PlanMyWeekScreen({super.key});
  @override
  State<PlanMyWeekScreen> createState() => _PlanMyWeekScreenState();
}

class _PlanMyWeekScreenState extends State<PlanMyWeekScreen> {
  static const cream = Color(0xFFFFFAF1), sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019), line = Color(0xFFE6DFD2);
  static const colors = [Color(0xFFE8EBDD), Color(0xFFF5E5E1),
    Color(0xFFF5EDD9), Color(0xFFEDE5F0), Color(0xFFE8F0EC), Color(0xFFF6E9E4)];
  late DateTime weekStart, selectedDay;
  bool loading = true;
  String section = 'Overview', review = '';
  List<Map<String, dynamic>> goals = [], tasks = [], groceries = [];
  Map<String, dynamic> meals = {}, notes = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = _monday(now);
    selectedDay = DateTime(now.year, now.month, now.day);
    _load();
  }

  DateTime _monday(DateTime d) => DateTime(d.year, d.month, d.day)
      .subtract(Duration(days: d.weekday - 1));
  String _key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _weekId => _key(weekStart);
  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection('weekly_plans').doc(_uid).collection('weeks').doc(_weekId);

  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.whereType<Map>().map((v) => Map<String, dynamic>.from(v)).toList()
      : <Map<String, dynamic>>[];

  Future<void> _load() async {
    setState(() => loading = true);
    if (_uid.isEmpty) { setState(() => loading = false); return; }
    try {
      final d = (await _doc.get()).data() ?? {};
      if (!mounted) return;
      setState(() {
        goals = _list(d['goals']); tasks = _list(d['tasks']);
        groceries = _list(d['groceries']);
        meals = Map<String, dynamic>.from(d['meals'] as Map? ?? {});
        notes = Map<String, dynamic>.from(d['notes'] as Map? ?? {});
        review = d['review'] as String? ?? ''; loading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _msg('Could not load this week: ${e.message ?? e.code}');
    }
  }

  Future<void> _save() async {
    if (_uid.isEmpty) { _msg('Sign in to save your weekly plan.'); return; }
    try {
      await _doc.set({'goals': goals, 'tasks': tasks, 'groceries': groceries,
        'meals': meals, 'notes': notes, 'review': review,
        'updatedAt': FieldValue.serverTimestamp()});
    } on FirebaseException catch (e) {
      _msg('Could not save your plan: ${e.message ?? e.code}');
    }
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<String?> _input(String title, {String hint = 'Write here', String initial = ''}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: cream,
      title: Text(title, style: GoogleFonts.playfairDisplay(color: ink)),
      content: TextField(controller: c, autofocus: true, maxLength: 180,
        decoration: InputDecoration(hintText: hint, filled: true,
          fillColor: Colors.white, border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: sage),
          onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
      ],
    ));
  }

  Future<void> _add(List<Map<String, dynamic>> list, String title, {bool task = false}) async {
    final text = await _input(title);
    if (text == null || text.isEmpty) return;
    setState(() => list.add(task
      ? {'title': text, 'day': _key(selectedDay), 'done': false}
      : {'title': text, 'done': false}));
    await _save();
  }

  Future<void> _meal() async {
    final key = _key(selectedDay);
    final value = await _input('Plan meals for ${_weekday(selectedDay)}',
      hint: 'Breakfast, lunch, or dinner', initial: meals[key] as String? ?? '');
    if (value == null) return;
    setState(() { if (value.isEmpty) { meals.remove(key); } else { meals[key] = value; } });
    await _save();
  }

  Future<void> _note() async {
    final key = _key(selectedDay);
    final value = await _input('Note for ${_weekday(selectedDay)}',
      hint: 'A reminder or thought', initial: notes[key] as String? ?? '');
    if (value == null) return;
    setState(() { if (value.isEmpty) { notes.remove(key); } else { notes[key] = value; } });
    await _save();
  }

  Future<void> _review() async {
    final value = await _input('Weekly reflection',
      hint: 'What went well? What would you like to change?', initial: review);
    if (value == null) return;
    setState(() => review = value); await _save();
  }

  Future<void> _toggle(List<Map<String, dynamic>> list, int i) async {
    setState(() => list[i]['done'] = list[i]['done'] != true);
    await _save();
  }
  Future<void> _remove(List<Map<String, dynamic>> list, int i) async {
    setState(() => list.removeAt(i)); await _save();
  }
  void _moveWeek(int n) {
    setState(() {
      weekStart = weekStart.add(Duration(days: n * 7));
      selectedDay = weekStart; section = 'Overview';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final start = weekStart;
    final weekTasks = tasks.where((t) {
      final d = DateTime.tryParse(t['day'] as String? ?? '');
      return d != null && !d.isBefore(start) && d.isBefore(start.add(const Duration(days: 7)));
    }).toList();
    final complete = weekTasks.where((t) => t['done'] == true).length;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(backgroundColor: cream, foregroundColor: ink, elevation: 0,
        title: Text(section == 'Overview' ? 'Plan My Week' : section,
          style: GoogleFonts.playfairDisplay(color: ink, fontWeight: FontWeight.w600)),
        actions: [if (section != 'Overview') IconButton(
          tooltip: 'Planner home', onPressed: () => setState(() => section = 'Overview'),
          icon: const Icon(Icons.home_outlined))]),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: loading ? const Center(child: CircularProgressIndicator(color: sage))
          : ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 16), children: [
            _weekBar(),
            if (section == 'Overview') ...[
              const Text('Create a more organized, balanced week with less stress.'),
              const SizedBox(height: 14),
              _summary(complete, weekTasks.length),
              const SizedBox(height: 16),
              _tiles(),
              const SizedBox(height: 16),
              _days(),
              const SizedBox(height: 12),
              _preview(),
            ] else _section(),
          ]),
      )),
    );
  }

  Widget _weekBar() => Row(children: [
    IconButton(onPressed: () => _moveWeek(-1), icon: const Icon(Icons.chevron_left)),
    Expanded(child: Center(child: Text(
      '${_month(weekStart.month)} ${weekStart.day} – ${_month(weekStart.add(const Duration(days: 6)).month)} ${weekStart.add(const Duration(days: 6)).day}',
      style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.w600)))),
    IconButton(onPressed: () => _moveWeek(1), icon: const Icon(Icons.chevron_right)),
    TextButton(onPressed: () {
      final now = DateTime.now();
      setState(() { weekStart = _monday(now); selectedDay = DateTime(now.year, now.month, now.day); });
      _load();
    }, child: const Text('Today', style: TextStyle(color: sage))),
  ]);

  Widget _summary(int done, int total) => _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: double.infinity, child: FittedBox(
      fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
      child: Text('This Week at a Glance', maxLines: 1, softWrap: false,
        style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w600)))),
    const SizedBox(height: 5), Text('$done of $total tasks completed'),
    const SizedBox(height: 9),
    ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
      value: total == 0 ? 0 : done / total, minHeight: 8, color: sage,
      backgroundColor: const Color(0xFFECE8DE))),
    const SizedBox(height: 12),
    _statGrid(total, goals.length, groceries.length),
  ]));

  Widget _statGrid(int total, int goalCount, int groceryCount) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    const columns = 2;
    return GridView(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: textScale >= 1.2 ? 104 : 88,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _stat(Icons.check_circle_outline, '$total', 'Tasks'),
        _stat(Icons.restaurant_outlined, '${meals.length}', 'Meals planned'),
        _stat(Icons.flag_outlined, '$goalCount', 'Goals'),
        _stat(Icons.shopping_cart_outlined, '$groceryCount', 'Groceries'),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label) => Container(
    width: double.infinity, height: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(13)),
    child: Row(children: [Icon(icon, color: sage, size: 20), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10)),
      ]))]));

  Widget _tiles() {
    const labels = ['Weekly Goals', 'Tasks & Schedule', 'Meal Planner',
      'Grocery List', 'Shared Planning', 'Weekly Review'];
    const desc = ['Set priorities for the week', 'Plan to-dos, appointments, and reminders',
      'Plan meals and build a grocery list', 'Keep shopping items together',
      'Plan together with someone in your circle', 'Reflect and prepare for next week'];
    const icons = [Icons.track_changes, Icons.assignment_outlined, Icons.restaurant,
      Icons.shopping_basket_outlined, Icons.people_outline, Icons.bar_chart];
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final screenWidth = MediaQuery.sizeOf(context).width.clamp(0, 620);
    final cardWidth = ((screenWidth - 56) / 2).toDouble();
    final cardHeight = textScale >= 1.2 ? 190.0 : 158.0;
    return Wrap(spacing: 10, runSpacing: 10, children: [
      for (var i = 0; i < labels.length; i++)
        SizedBox(width: cardWidth, height: cardHeight,
          child: Material(color: colors[i], borderRadius: BorderRadius.circular(18),
            child: InkWell(borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => section = labels[i]),
              child: Padding(padding: const EdgeInsets.all(13), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(radius: 18, backgroundColor: Colors.white,
                    child: Icon(icons[i], color: sage, size: 20)),
                  const SizedBox(height: 8),
                  Text(labels[i], style: GoogleFonts.playfairDisplay(fontSize: 16,
                    color: ink, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(desc[i], maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: ink)),
                  const Align(alignment: Alignment.centerRight,
                    child: Icon(Icons.chevron_right, color: sage)),
                ]))))),
    ]);
  }

  Widget _days() => Row(children: [for (var i = 0; i < 7; i++)
    Expanded(child: GestureDetector(
      onTap: () => setState(() => selectedDay = weekStart.add(Duration(days: i))),
      child: Container(margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: _same(selectedDay, weekStart.add(Duration(days: i)))
          ? sage : Colors.white, borderRadius: BorderRadius.circular(13)),
        child: Column(children: [
          Text(_shortDay(weekStart.add(Duration(days: i))), style: TextStyle(fontSize: 10,
            color: _same(selectedDay, weekStart.add(Duration(days: i))) ? Colors.white : ink)),
          Text('${weekStart.add(Duration(days: i)).day}', style: TextStyle(fontWeight: FontWeight.w700,
            color: _same(selectedDay, weekStart.add(Duration(days: i))) ? Colors.white : ink)),
        ])),
    ))]);

  Widget _preview() {
    final todayTasks = tasks.where((t) => t['day'] == _key(selectedDay)).toList();
    return _card(ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 230),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('${_weekday(selectedDay)}, ${_month(selectedDay.month)} ${selectedDay.day}',
        style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600))),
        IconButton(onPressed: () => _add(tasks, 'Add a task', task: true),
          icon: const Icon(Icons.add_circle_outline, color: sage))]),
      if (todayTasks.isEmpty) const Text('No tasks planned. Add one when you’re ready.')
      else for (final t in todayTasks) _row(tasks, tasks.indexOf(t)),
      const Divider(height: 20),
      _link(Icons.restaurant_outlined, (meals[_key(selectedDay)] as String?) ?? 'Add meals',
        _meal),
      _link(Icons.notes_outlined, (notes[_key(selectedDay)] as String?) ?? 'Add a note',
        _note),
    ])));
  }

  Widget _section() {
    if (section == 'Weekly Goals') return _card(Column(children: [
      _heading('Top Priorities', () => _add(goals, 'Add a weekly priority')),
      if (goals.isEmpty) const Text('Set the priorities you want to focus on this week.'),
      for (var i = 0; i < goals.length; i++) _row(goals, i),
    ]));
    if (section == 'Tasks & Schedule') {
      final items = tasks.where((t) => t['day'] == _key(selectedDay)).toList();
      return Column(children: [
        _days(), const SizedBox(height: 12),
        _card(Column(children: [
          _heading('${_weekday(selectedDay)} tasks', () => _add(tasks, 'Add a task', task: true)),
          if (items.isEmpty) const Text('Nothing planned for this day.'),
          for (final t in items) _row(tasks, tasks.indexOf(t)),
          TextButton.icon(onPressed: () => _add(tasks, 'Add an event or appointment', task: true),
            icon: const Icon(Icons.event_outlined), label: const Text('Add an event or appointment')),
        ])),
      ]);
    }
    if (section == 'Meal Planner') return Column(children: [
      _days(), const SizedBox(height: 12),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading('Meals for ${_weekday(selectedDay)}', _meal),
        Text((meals[_key(selectedDay)] as String?)?.isNotEmpty == true
          ? meals[_key(selectedDay)] as String : 'No meals planned yet.'),
        _link(Icons.shopping_cart_outlined, 'Open Grocery List',
          () => setState(() => section = 'Grocery List')),
      ])),
    ]);
    if (section == 'Grocery List') return _card(Column(children: [
      _heading('Grocery List', () => _add(groceries, 'Add grocery item')),
      if (groceries.isEmpty) const Text('Add items you need for the week.'),
      for (var i = 0; i < groceries.length; i++) _row(groceries, i),
      if (groceries.isNotEmpty) Text('${groceries.where((g) => g['done'] == true).length} of ${groceries.length} checked',
        style: const TextStyle(color: sage, fontSize: 12)),
    ]));
    if (section == 'Weekly Review') return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How did your week go?', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), Text(review.isEmpty
        ? 'Celebrate what went well and prepare for next week.' : review),
      const SizedBox(height: 10),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: sage),
        onPressed: _review, icon: const Icon(Icons.edit_outlined),
        label: Text(review.isEmpty ? 'Write a reflection' : 'Edit reflection')),
    ]));
    return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.people_alt_outlined, size: 34, color: sage),
      Text('Shared Planning', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Keep your personal plan private. Sharing controls are not enabled yet, so this page will not expose your tasks, meals, or schedule to anyone.'),
    ]));
  }

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
      borderRadius: BorderRadius.circular(19)), child: child);

  Widget _heading(String text, VoidCallback add) => Row(children: [
    Expanded(child: Text(text, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w600))),
    IconButton(onPressed: add, tooltip: 'Add', icon: const Icon(Icons.add, color: sage)),
  ]);

  Widget _row(List<Map<String, dynamic>> list, int i) => ListTile(
    dense: true, contentPadding: EdgeInsets.zero,
    leading: Checkbox(value: list[i]['done'] == true, activeColor: sage,
      onChanged: (_) => _toggle(list, i)),
    title: Text(list[i]['title'] as String? ?? '',
      style: TextStyle(decoration: list[i]['done'] == true ? TextDecoration.lineThrough : null)),
    trailing: IconButton(onPressed: () => _remove(list, i),
      icon: const Icon(Icons.more_vert_rounded)),
  );

  Widget _link(IconData icon, String label, VoidCallback onTap) => ListTile(
    contentPadding: EdgeInsets.zero, dense: true, leading: Icon(icon, color: sage),
    title: Text(label), trailing: const Icon(Icons.chevron_right), onTap: onTap);

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  String _weekday(DateTime d) => const ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d.weekday - 1];
  String _shortDay(DateTime d) => const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
  String _month(int m) => const ['January','February','March','April','May','June','July','August','September','October','November','December'][m - 1];
}
