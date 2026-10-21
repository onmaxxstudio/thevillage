import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../services/circle_service.dart';

class _MealRecipe {
  const _MealRecipe({required this.title, required this.description,
    required this.tags, required this.prepTime,
    required this.imageUrl, required this.ingredients, required this.steps,
    required this.tip, required this.servedWith, required this.emoji,
    required this.tint});

  final String title, description, prepTime, imageUrl, tip, servedWith, emoji;
  final List<String> tags, ingredients, steps;
  final Color tint;
}

const _mealRecipes = <_MealRecipe>[
  _MealRecipe(title: 'Peanut Tofu Bowls',
    description: 'Crispy tofu and colorful vegetables with a creamy peanut-lime sauce.',
    tags: ['Vegan', 'High Protein'], prepTime: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['14 oz extra-firm tofu', '1 cup brown rice', '1 cucumber, sliced', '1 cup shredded carrots', '2 tbsp peanut butter', '1 tbsp soy sauce', '1 lime'],
    steps: ['Cook rice according to the package directions.', 'Press and cube the tofu. Bake at 425°F for 25 minutes, turning once.', 'Whisk peanut butter, soy sauce, lime juice, and a splash of warm water.', 'Serve tofu and vegetables over rice with peanut sauce.'],
    tip: 'Pat the tofu very dry before baking so the edges crisp.',
    servedWith: 'Steamed edamame or a side of greens', emoji: '🥗', tint: Color(0xFFE9F0DF)),
  _MealRecipe(title: 'Lentil Bolognese',
    description: 'A cozy tomato and lentil sauce tossed with pasta for an easy plant-based dinner.',
    tags: ['Vegan', 'High Protein'], prepTime: '40 min',
    imageUrl: 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['8 oz pasta', '1 cup brown or green lentils', '1 small onion, diced', '2 garlic cloves, minced', '1 can crushed tomatoes', '2 cups vegetable broth', '1 tsp Italian seasoning'],
    steps: ['Cook pasta until tender; reserve a little pasta water.', 'Soften onion and garlic in a pot with a drizzle of oil.', 'Add lentils, tomatoes, broth, and seasoning. Simmer until lentils are tender, about 25 minutes.', 'Spoon sauce over pasta and loosen with pasta water if needed.'],
    tip: 'Use canned lentils to make this dinner faster; rinse and add them near the end.',
    servedWith: 'Green salad or roasted vegetables', emoji: '🍝', tint: Color(0xFFF4E5D8)),
  _MealRecipe(title: 'Chickpea Coconut Curry',
    description: 'Chickpeas simmered in a warmly spiced tomato-coconut sauce.',
    tags: ['Vegan'], prepTime: '25 min',
    imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['2 cans chickpeas, drained', '1 can light coconut milk', '1 can diced tomatoes', '1 small onion, diced', '2 tsp curry powder', '2 cups baby spinach', '1 cup rice'],
    steps: ['Start the rice according to the package directions.', 'Cook onion with curry powder until fragrant.', 'Add chickpeas, coconut milk, and tomatoes. Simmer for 15 minutes.', 'Stir in spinach until wilted and serve over rice.'],
    tip: 'Add a squeeze of lemon at the end to brighten the curry.',
    servedWith: 'Rice, warm flatbread, or cucumber salad', emoji: '🍛', tint: Color(0xFFF3EBD8)),
  _MealRecipe(title: 'Greek Chicken Bowls',
    description: 'Seasoned chicken, crisp vegetables, rice, and a simple yogurt sauce.',
    tags: ['High Protein', 'Regular Recipes'], prepTime: '30 min',
    imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['1 lb boneless chicken breast', '1 cup rice', '1 cucumber, chopped', '1 cup cherry tomatoes', '½ cup plain Greek yogurt', '1 lemon', '1 tsp oregano'],
    steps: ['Cook rice according to the package directions.', 'Season chicken with oregano, lemon, salt, and pepper; cook until the center reaches 165°F.', 'Stir yogurt with lemon juice and a spoonful of water.', 'Slice chicken and serve over rice with vegetables and yogurt sauce.'],
    tip: 'Let the chicken rest for 5 minutes before slicing to keep it juicy.',
    servedWith: 'Hummus, olives, or warm pita', emoji: '🍗', tint: Color(0xFFE9F0DF)),
  _MealRecipe(title: 'Salmon Rice Bowls',
    description: 'Flaky salmon with rice, crunchy vegetables, and a quick savory dressing.',
    tags: ['High Protein', 'Regular Recipes'], prepTime: '25 min',
    imageUrl: 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['2 salmon fillets', '1 cup rice', '1 cucumber, sliced', '1 avocado, sliced', '1 tbsp soy sauce', '1 tsp honey', '1 tsp sesame seeds'],
    steps: ['Cook rice according to the package directions.', 'Bake salmon at 400°F for 12–15 minutes, until it flakes easily.', 'Mix soy sauce and honey for a quick dressing.', 'Serve salmon over rice with cucumber and avocado; drizzle with dressing.'],
    tip: 'For food safety, cook fish until it reaches 145°F at its thickest point.',
    servedWith: 'Steamed broccoli or edamame', emoji: '🐟', tint: Color(0xFFE6EFF0)),
  _MealRecipe(title: 'Turkey Taco Skillet',
    description: 'A one-pan family dinner with lean turkey, beans, corn, and warm spices.',
    tags: ['High Protein', 'Regular Recipes'], prepTime: '25 min',
    imageUrl: 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['1 lb ground turkey', '1 can black beans, drained', '1 cup corn', '1 can diced tomatoes', '1 tbsp taco seasoning', '1 cup shredded cheese (optional)', 'Tortillas or rice'],
    steps: ['Cook turkey in a skillet until no longer pink, breaking it into small pieces.', 'Stir in taco seasoning, beans, corn, and tomatoes.', 'Simmer for 8–10 minutes until hot and slightly thickened.', 'Serve with tortillas or rice and add cheese if you like.'],
    tip: 'Ground turkey should reach 165°F. Add a splash of broth if the skillet gets too dry.',
    servedWith: 'Avocado, salsa, and shredded lettuce', emoji: '🌮', tint: Color(0xFFF4E5D8)),
  _MealRecipe(title: 'Sheet-Pan Chicken & Vegetables',
    description: 'A simple oven dinner with seasoned chicken, potatoes, and vegetables.',
    tags: ['Regular Recipes', 'High Protein'], prepTime: '40 min',
    imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['1 lb chicken thighs', '12 oz baby potatoes, halved', '1 bell pepper, chopped', '1 red onion, wedged', '1 tbsp olive oil', '1 tsp garlic powder', '1 tsp paprika'],
    steps: ['Heat oven to 425°F and line a sheet pan.', 'Toss potatoes and vegetables with oil and seasonings.', 'Add chicken and spread everything in one layer.', 'Roast until vegetables are tender and chicken reaches 165°F, about 25–30 minutes.'],
    tip: 'Cut the potatoes evenly so they cook at the same pace.',
    servedWith: 'Lemon wedges and a green salad', emoji: '🍽️', tint: Color(0xFFF3EBD8)),
  _MealRecipe(title: 'Creamy Tomato Pasta',
    description: 'A weeknight pasta with tomato, spinach, and a little cream.',
    tags: ['Regular Recipes'], prepTime: '25 min',
    imageUrl: 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1000&q=82',
    ingredients: ['8 oz pasta', '1 tbsp olive oil', '2 garlic cloves, minced', '1 can crushed tomatoes', '½ cup cream or unsweetened oat cream', '2 cups baby spinach', '¼ cup grated parmesan (optional)'],
    steps: ['Cook pasta until tender; reserve ½ cup pasta water.', 'Warm oil and garlic in a pan, then add tomatoes and simmer for 10 minutes.', 'Stir in cream and spinach until the spinach wilts.', 'Toss with pasta, adding pasta water as needed. Finish with parmesan.'],
    tip: 'For a vegan version, use oat cream and skip the parmesan or use a dairy-free alternative.',
    servedWith: 'Garlic bread or a simple green salad', emoji: '🍝', tint: Color(0xFFF4E5D8)),
];

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
  bool daySelected = false, loading = true;
  String section = 'Overview', review = '';
  String _recipeFilter = 'Vegan';
  final TextEditingController _taskDraft = TextEditingController();
  final TextEditingController _reviewDraft = TextEditingController();
  DateTime? _draftTaskDay;
  List<Map<String, dynamic>> goals = [], tasks = [], groceries = [];
  Map<String, dynamic> meals = {}, notes = {};
  bool shareTasks = true, shareMeals = false, shareSchedule = true;
  String? shareToken;
  final CircleService _circleService = CircleService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    weekStart = _monday(now);
    selectedDay = DateTime(now.year, now.month, now.day);
    daySelected = false;
    _load();
  }

  @override
  void dispose() {
    _taskDraft.dispose();
    _reviewDraft.dispose();
    super.dispose();
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
        final sharing = Map<String, dynamic>.from(d['sharing'] as Map? ?? {});
        shareTasks = sharing['tasks'] is bool ? sharing['tasks'] as bool : true;
        shareMeals = sharing['meals'] is bool ? sharing['meals'] as bool : false;
        shareSchedule = sharing['schedule'] is bool ? sharing['schedule'] as bool : true;
        shareToken = sharing['token'] as String?;
        review = d['review'] as String? ?? ''; loading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      _msg('Could not load this week: ${e.message ?? e.code}');
    }
  }

  Future<bool> _save() async {
    if (_uid.isEmpty) { _msg('Sign in to save your weekly plan.'); return false; }
    try {
      await _doc.set({'goals': goals, 'tasks': tasks, 'groceries': groceries,
        'meals': meals, 'notes': notes, 'review': review,
        'sharing': {'tasks': shareTasks, 'meals': shareMeals,
          'schedule': shareSchedule, if (shareToken != null) 'token': shareToken},
        'updatedAt': FieldValue.serverTimestamp()});
      if (shareToken != null && !await _syncShareLink()) return false;
      return true;
    } on FirebaseException catch (e) {
      _msg('Could not save your plan: ${e.message ?? e.code}');
      return false;
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
      ? {'title': text, if (daySelected) 'day': _key(selectedDay), 'done': false}
      : {'title': text, 'done': false}));
    await _save();
  }

  void _openTaskPage() => setState(() {
    _draftTaskDay = daySelected ? selectedDay : null;
    section = 'Task List';
  });

  Future<void> _saveTaskDraft() async {
    final title = _taskDraft.text.trim();
    if (title.isEmpty) return;
    final taskDay = _draftTaskDay;
    setState(() {
      tasks.add({'title': title, if (taskDay != null) 'day': _key(taskDay), 'done': false});
      _taskDraft.clear();
      if (taskDay == null) {
        daySelected = false;
      } else {
        selectedDay = taskDay;
        daySelected = true;
      }
    });
    await _save();
  }

  Future<void> _reorderDayTasks(int oldIndex, int newIndex) async {
    final indices = <int>[
      for (var i = 0; i < tasks.length; i++)
        if (!daySelected || tasks[i]['day'] == _key(selectedDay)) i,
    ];
    if (oldIndex < newIndex) newIndex--;
    setState(() {
      final dayTasks = indices.map((i) => tasks[i]).toList();
      final moved = dayTasks.removeAt(oldIndex);
      dayTasks.insert(newIndex, moved);
      for (var i = 0; i < indices.length; i++) {
        tasks[indices[i]] = dayTasks[i];
      }
    });
    await _save();
  }

  String get _activePlanKey => daySelected ? _key(selectedDay) : 'week';
  String get _activePlanLabel => daySelected ? _weekday(selectedDay) : 'this week';

  Future<void> _meal() async {
    final key = _activePlanKey;
    final value = await _input('Plan meals for ${_activePlanLabel}',
      hint: 'Breakfast, lunch, or dinner', initial: meals[key] as String? ?? '');
    if (value == null) return;
    setState(() { if (value.isEmpty) { meals.remove(key); } else { meals[key] = value; } });
    await _save();
  }

  Future<void> _addRecipeToDay(_MealRecipe recipe) async {
    final key = _activePlanKey;
    final existing = (meals[key] as String? ?? '').trim();
    if (!existing.toLowerCase().contains(recipe.title.toLowerCase())) {
      setState(() => meals[key] = existing.isEmpty
        ? recipe.title : '$existing · ${recipe.title}');
      await _save();
    }
    if (mounted) Navigator.of(context).pop();
    _msg('${recipe.title} added to ${_activePlanLabel}.');
  }

  Future<void> _addRecipeIngredients(_MealRecipe recipe) async {
    final existing = groceries.map((item) =>
      (item['title'] as String? ?? '').trim().toLowerCase()).toSet();
    final additions = recipe.ingredients.where((ingredient) =>
      !existing.contains(ingredient.trim().toLowerCase()));
    final newItems = additions.map((ingredient) =>
      {'title': ingredient, 'done': false});
    setState(() => groceries.addAll(newItems));
    await _save();
    _msg('Ingredients added to your grocery list.');
  }

  Future<void> _showRecipe(_MealRecipe recipe) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: cream,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(dialogContext).height * .82),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _recipeImage(recipe, height: 185),
                const SizedBox(height: 14),
                Wrap(spacing: 7, runSpacing: 6, children: [
                  for (final tag in recipe.tags) _recipeTag(tag),
                  _recipeTag(recipe.prepTime, isTime: true),
                ]),
                const SizedBox(height: 8),
                Text(recipe.title, style: GoogleFonts.playfairDisplay(
                  fontSize: 25, fontWeight: FontWeight.w700, color: ink)),
                const SizedBox(height: 4),
                Text(recipe.description, style: const TextStyle(color: ink)),
                const SizedBox(height: 18),
                _recipeSectionTitle('Ingredients'),
                const SizedBox(height: 5),
                for (final ingredient in recipe.ingredients)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(padding: EdgeInsets.only(top: 7),
                          child: Icon(Icons.circle, size: 5, color: sage)),
                        const SizedBox(width: 9),
                        Expanded(child: Text(ingredient)),
                      ])),
                const SizedBox(height: 14),
                _recipeSectionTitle('Method'),
                const SizedBox(height: 7),
                for (var i = 0; i < recipe.steps.length; i++)
                  Padding(padding: const EdgeInsets.only(bottom: 9),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 12, backgroundColor: sage,
                          child: Text('${i + 1}', style: const TextStyle(
                            color: Colors.white, fontSize: 11))),
                        const SizedBox(width: 9),
                        Expanded(child: Padding(padding: const EdgeInsets.only(top: 3),
                          child: Text(recipe.steps[i]))),
                      ])),
                const SizedBox(height: 4),
                _recipeNote(Icons.lightbulb_outline, 'Tip', recipe.tip),
                const SizedBox(height: 8),
                _recipeNote(Icons.restaurant_menu, 'Best served with', recipe.servedWith),
              ])),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Wrap(alignment: WrapAlignment.end, spacing: 4,
              runSpacing: 4, children: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close')),
                TextButton.icon(onPressed: () => _addRecipeIngredients(recipe),
                  icon: const Icon(Icons.shopping_basket_outlined),
                  label: const Text('Add ingredients')),
                FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: sage),
                  onPressed: () => _addRecipeToDay(recipe),
                  icon: const Icon(Icons.add),
                  label: Text('Add to ${daySelected ? _shortDay(selectedDay) : 'week'}')),
              ])),
        ])),
      ),
    );

  Widget _recipeSectionTitle(String title) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: sage, borderRadius: BorderRadius.circular(5)),
    child: Text(title.toUpperCase(), style: const TextStyle(color: Colors.white,
      fontWeight: FontWeight.w700, letterSpacing: .7, fontSize: 12)));

  Widget _recipeNote(IconData icon, String title, String text) => Container(
    width: double.infinity, padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white,
      border: Border.all(color: line), borderRadius: BorderRadius.circular(12)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: sage, size: 19), const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(title, style: const TextStyle(color: sage,
          fontWeight: FontWeight.w700, fontSize: 12)), Text(text)])),
    ]));

  Widget _recipeTag(String label, {bool isTime = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: isTime ? Colors.white : colors[0],
      borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
    child: Text(label, style: const TextStyle(fontSize: 11, color: sage,
      fontWeight: FontWeight.w600)));

  Widget _recipeImage(_MealRecipe recipe, {double height = 145}) => ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: SizedBox(width: double.infinity, height: height,
      child: Stack(fit: StackFit.expand, children: [
        Container(color: recipe.tint, alignment: Alignment.center,
          child: Text(recipe.emoji, style: const TextStyle(fontSize: 62))),
        Image.network(recipe.imageUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: recipe.tint,
            alignment: Alignment.center,
            child: Text(recipe.emoji, style: const TextStyle(fontSize: 62)))),
        Positioned(left: 10, top: 10, child: _recipeTag(recipe.prepTime, isTime: true)),
      ])));

  Future<void> _note() async {
    final key = _key(selectedDay);
    final value = await _input('Note for ${_weekday(selectedDay)}',
      hint: 'A reminder or thought', initial: notes[key] as String? ?? '');
    if (value == null) return;
    setState(() { if (value.isEmpty) { notes.remove(key); } else { notes[key] = value; } });
    await _save();
  }

  void _openReviewEditor() {
    _reviewDraft.text = review;
    setState(() => section = 'Weekly Reflection');
  }

  Future<void> _saveReview() async {
    final previousReview = review;
    setState(() => review = _reviewDraft.text.trim());
    if (await _save()) {
      if (!mounted) return;
      setState(() => section = 'Weekly Review');
      _msg('Weekly reflection saved.');
    } else if (mounted) {
      setState(() => review = previousReview);
    }
  }

  Widget _weeklyReflectionEditor() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Your weekly reflection',
        style: GoogleFonts.playfairDisplay(fontSize: 24,
          color: ink, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Celebrate what went well and consider what you want to carry into next week.',
        style: TextStyle(color: sage)),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: TextField(
          controller: _reviewDraft,
          autofocus: true,
          maxLength: 10000,
          minLines: 10,
          maxLines: null,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'What went well? What would you like to change?',
            border: InputBorder.none,
            alignLabelWithHint: true,
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => setState(() => section = 'Weekly Review'),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: sage),
            onPressed: _saveReview,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save reflection'),
          ),
        ],
      ),
    ],
  );

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
      selectedDay = weekStart;
      daySelected = false;
      _draftTaskDay = null;
      section = 'Overview';
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final start = weekStart;
    final weekTasks = tasks.where((t) {
      final dayKey = t['day'] as String?;
      if (dayKey == null || dayKey.isEmpty) return true;
      final d = DateTime.tryParse(dayKey);
      return d != null && !d.isBefore(start) && d.isBefore(start.add(const Duration(days: 7)));
    }).toList();
    final complete = weekTasks.where((t) => t['done'] == true).length;
    final selectedDayTasks = tasks.where((t) => t['day'] == _key(selectedDay)).toList();
    final selectedDayComplete = selectedDayTasks.where((t) => t['done'] == true).length;
    return PopScope(
      canPop: section == 'Overview',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && section != 'Overview') {
          setState(() => section = 'Overview');
        }
      },
      child: Scaffold(
        backgroundColor: cream,
        appBar: AppBar(backgroundColor: cream, foregroundColor: ink, elevation: 0,
          leading: section == 'Overview' ? null : IconButton(
            tooltip: 'Back to Plan My Week',
            onPressed: () => setState(() => section = 'Overview'),
            icon: const Icon(Icons.arrow_back)),
          title: Text(section == 'Overview' ? 'Plan My Week'
            : section == 'Task List' ? (daySelected ? '${_weekday(selectedDay)} tasks' : 'This Week’s Tasks')
            : section == 'Weekly Reflection' ? 'Weekly Review' : section,
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
              const Text('Make space for what matters this week.'),
              const SizedBox(height: 12),
              _weeklySummary(daySelected ? selectedDayComplete : complete,
                daySelected ? selectedDayTasks.length : weekTasks.length,
                title: daySelected ? _weekday(selectedDay) : 'Your week'),
              const SizedBox(height: 16),
              _days(),
              const SizedBox(height: 16),
              _weeklyFocus(),
              const SizedBox(height: 12),
              _overviewAction(
                icon: Icons.restaurant_outlined,
                title: 'Meals & groceries',
                detail: '${meals.values.where((v) => v is String && v.trim().isNotEmpty).length} meals · ${groceries.length} items',
                tint: colors[2],
                onTap: () => setState(() => section = 'Meal Planner'),
              ),
              const SizedBox(height: 9),
              _overviewAction(
                icon: Icons.assignment_outlined,
                title: 'Tasks & appointments',
                detail: daySelected
                  ? '${selectedDayTasks.length} tasks planned for ${_weekday(selectedDay)}'
                  : '${weekTasks.length} tasks planned this week',
                tint: colors[1],
                onTap: () => setState(() => section = 'Tasks & Schedule'),
              ),
              const SizedBox(height: 9),
              _overviewAction(
                icon: Icons.people_outline,
                title: 'Share this week',
                detail: 'Plan together with someone in your circle',
                tint: colors[0],
                onTap: () => setState(() => section = 'Shared Planning'),
              ),
              const SizedBox(height: 9),
              _overviewAction(
                icon: Icons.auto_graph_outlined,
                title: 'Weekly reflection',
                detail: review.isEmpty ? 'Look back and prepare for next week' : 'Your reflection is saved',
                tint: colors[3],
                onTap: () => setState(() => section = 'Weekly Review'),
              ),
            ] else _section(),
          ]),
      )),
      ),
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
      setState(() {
        weekStart = _monday(now);
        selectedDay = DateTime(now.year, now.month, now.day);
        daySelected = false;
        _draftTaskDay = null;
      });
      _load();
    }, child: const Text('Today', style: TextStyle(color: sage))),
  ]);

  Widget _weeklySummary(int done, int total, {String title = 'Your week'}) =>
    _card(Row(children: [
    SizedBox(width: 42, height: 42, child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(value: total == 0 ? 0 : done / total,
        strokeWidth: 4, color: sage, backgroundColor: const Color(0xFFECE8DE)),
      Icon(total == 0 ? Icons.calendar_today_outlined : Icons.check,
        color: sage, size: 17),
    ])),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.playfairDisplay(
          fontSize: 17, fontWeight: FontWeight.w600, color: ink)),
        Text('$total tasks planned · $done completed',
          style: const TextStyle(fontSize: 12, color: ink)),
        if (total == 0) const Text('Add your first task to start planning.',
          style: TextStyle(fontSize: 11, color: sage)),
      ])),
    const SizedBox(width: 6),
    OutlinedButton.icon(
      onPressed: _openTaskPage,
      icon: const Icon(Icons.add, color: sage),
      label: const Text('Add task', style: TextStyle(color: sage))),
  ]));

  Widget _weeklyFocus() => _card(Column(crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: Text('Weekly focus', style: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: ink))),
        TextButton.icon(onPressed: () => _add(goals, 'Add a weekly priority'),
          icon: const Icon(Icons.add, size: 17), label: const Text('Add')),
      ]),
      if (goals.isEmpty)
        const Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text('Choose a few priorities to guide your week.'))
      else
        for (var i = 0; i < goals.length; i++) _row(goals, i),
    ]));

  Widget _overviewAction({required IconData icon, required String title,
    required String detail, required Color tint, required VoidCallback onTap}) =>
    Material(color: tint, borderRadius: BorderRadius.circular(16),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(children: [
            CircleAvatar(radius: 18, backgroundColor: Colors.white,
              child: Icon(icon, color: sage, size: 19)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.playfairDisplay(fontSize: 16,
                  color: ink, fontWeight: FontWeight.w600)),
                Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: ink)),
              ])),
            const Icon(Icons.chevron_right, color: sage),
          ]))));

  Widget _days() => Column(children: [
    Row(children: [for (var i = 0; i < 7; i++)
      Expanded(child: GestureDetector(
        onTap: () => setState(() {
          final tappedDay = weekStart.add(Duration(days: i));
          final wasSelected = daySelected && _same(selectedDay, tappedDay);
          selectedDay = tappedDay;
          daySelected = !wasSelected;
          _draftTaskDay = daySelected ? tappedDay : null;
        }),
        child: Container(margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: daySelected && _same(selectedDay, weekStart.add(Duration(days: i)))
              ? sage : Colors.white,
            borderRadius: BorderRadius.circular(18)),
          child: Column(children: [
            Text(_shortDay(weekStart.add(Duration(days: i))).substring(0, 1),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                color: daySelected && _same(selectedDay, weekStart.add(Duration(days: i)))
                  ? Colors.white : ink)),
            const SizedBox(height: 3),
            Text('${weekStart.add(Duration(days: i)).day}',
              style: TextStyle(fontWeight: FontWeight.w700,
                color: daySelected && _same(selectedDay, weekStart.add(Duration(days: i)))
                  ? Colors.white : ink)),
          ])),
      ))]),
    if (daySelected)
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(
        onPressed: () => setState(() => daySelected = false),
        icon: const Icon(Icons.calendar_view_week_outlined),
        label: const Text('Show whole week'))),
  ]);

  Widget _section() {
    if (section == 'Weekly Goals') return _card(Column(children: [
      _heading('Top Priorities', () => _add(goals, 'Add a weekly priority')),
      if (goals.isEmpty) const Text('Set the priorities you want to focus on this week.'),
      for (var i = 0; i < goals.length; i++) _row(goals, i),
    ]));
    if (section == 'Task List') return _taskListPage();
    if (section == 'Tasks & Schedule') {
      final items = tasks.where((t) => !daySelected
        || t['day'] == _key(selectedDay)).toList();
      return Column(children: [
        _days(), const SizedBox(height: 12),
        _card(Column(children: [
          _heading(daySelected ? '${_weekday(selectedDay)} tasks' : 'This week’s tasks', _openTaskPage),
          if (items.isEmpty) Text(daySelected
            ? 'Nothing planned for this day.' : 'Nothing planned for this week.'),
          if (items.isNotEmpty) ...[
            const Align(alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(top: 2, bottom: 4),
                child: Text('Swipe left to delete · drag the handle to reorder',
                  style: TextStyle(color: sage, fontSize: 12)),
              )),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: items.length,
              onReorder: _reorderDayTasks,
              itemBuilder: (context, position) {
                final task = items[position];
                final taskIndex = tasks.indexOf(task);
                return _swipeDeleteTask(
                  key: ObjectKey(task),
                  onDelete: () => _remove(tasks, taskIndex),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(color: Colors.white,
                      border: Border.all(color: line),
                      borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Checkbox(value: task['done'] == true, activeColor: sage,
                        onChanged: (_) => _toggle(tasks, taskIndex)),
                      Expanded(child: Text(task['title'] as String? ?? '',
                        style: TextStyle(
                          decoration: task['done'] == true
                            ? TextDecoration.lineThrough : null))),
                      ReorderableDragStartListener(index: position,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          child: Icon(Icons.drag_handle, color: sage))),
                    ]),
                  ),
                );
              },
            ),
          ],
          TextButton.icon(onPressed: _openTaskPage,
            icon: const Icon(Icons.notes_outlined), label: const Text('Open full task list')),
        ])),
      ]);
    }
    if (section == 'Meal Planner') return _mealPlannerSection();
    if (section == 'Grocery List') return _card(Column(children: [
      _heading('Grocery List', () => _add(groceries, 'Add grocery item')),
      if (groceries.isEmpty) const Text('Add items you need for the week.'),
      for (var i = 0; i < groceries.length; i++) _row(groceries, i),
      if (groceries.isNotEmpty) Text('${groceries.where((g) => g['done'] == true).length} of ${groceries.length} checked',
        style: const TextStyle(color: sage, fontSize: 12)),
    ]));
    if (section == 'Weekly Reflection') return _weeklyReflectionEditor();
    if (section == 'Weekly Review') return _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('How did your week go?', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), Text(review.isEmpty
        ? 'Celebrate what went well and prepare for next week.' : review),
      const SizedBox(height: 10),
      FilledButton.icon(style: FilledButton.styleFrom(backgroundColor: sage),
        onPressed: _openReviewEditor, icon: const Icon(Icons.edit_outlined),
        label: Text(review.isEmpty ? 'Write a reflection' : 'Edit reflection')),
    ]));
    if (section == 'Shared Planning') return _sharedPlanning();
    return const SizedBox.shrink();
  }

  Widget _sharedPlanning() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _card(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 52, height: 52, decoration: const BoxDecoration(
        color: Color(0xFFE8EBDD), shape: BoxShape.circle),
        child: const Icon(Icons.lock_outline, color: sage, size: 27)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your plan stays yours', style: GoogleFonts.playfairDisplay(
          fontSize: 19, color: ink, fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        const Text('Choose what to share. Only people you send your private link to can view it.'),
      ])),
    ])),
    const SizedBox(height: 16),
    Text('Sharing with', style: GoogleFonts.playfairDisplay(fontSize: 21,
      color: ink, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    const Text('Share with someone in your Circle, or send a private link to anyone.'),
    const SizedBox(height: 10),
    _card(Row(children: [
      const CircleAvatar(backgroundColor: Color(0xFFE8EBDD),
        child: Icon(Icons.link, color: sage)),
      const SizedBox(width: 10),
      Expanded(child: Text(shareToken == null ? 'No one has access yet'
        : 'Anyone you send this link to', style: const TextStyle(fontWeight: FontWeight.w600))),
      if (shareToken != null) IconButton(tooltip: 'Revoke link',
        onPressed: _revokeShareLink, icon: const Icon(Icons.close, color: sage)),
    ])),
    Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
      onPressed: _addSomeone,
      icon: const Icon(Icons.add, color: sage),
      label: const Text('Add someone'),
    )),
    const SizedBox(height: 16),
    Text('Choose what to share', style: GoogleFonts.playfairDisplay(fontSize: 21,
      color: ink, fontWeight: FontWeight.w600)),
    const SizedBox(height: 4),
    const Text('You can share individual parts of your plan.'),
    const SizedBox(height: 10),
    _card(Column(children: [
      _shareSwitch(Icons.checklist, 'Tasks', 'Share your to-dos and progress.', shareTasks,
        (value) => setState(() => shareTasks = value)),
      const Divider(height: 18),
      _shareSwitch(Icons.restaurant_outlined, 'Meals & grocery list',
        'Share your meal plan and grocery list.', shareMeals,
        (value) => setState(() => shareMeals = value)),
      const Divider(height: 18),
      _shareSwitch(Icons.calendar_month_outlined, 'Weekly schedule',
        'Share your daily notes and schedule.', shareSchedule,
        (value) => setState(() => shareSchedule = value)),
    ])),
    const SizedBox(height: 14),
    _card(Row(children: [
      const Icon(Icons.visibility_outlined, color: sage),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('View only', style: TextStyle(fontWeight: FontWeight.w600)),
        Text('People with the link cannot change your plan.'),
      ])),
    ])),
    const SizedBox(height: 14),
    if (shareToken == null)
      SizedBox(width: double.infinity, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _createAndShareLink, icon: const Icon(Icons.ios_share),
        label: const Text('Create link and share')))
    else ...[
      SizedBox(width: double.infinity, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: sage, padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _saveShareSettings, icon: const Icon(Icons.check),
        label: const Text('Save sharing settings'))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        style: FilledButton.styleFrom(backgroundColor: sage.withValues(alpha: .92), padding: const EdgeInsets.symmetric(vertical: 14)),
        onPressed: _shareExistingLink, icon: const Icon(Icons.ios_share),
        label: const Text('Share with someone'))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: _copyShareLink, icon: const Icon(Icons.copy),
        label: const Text('Copy private link'))),
      const SizedBox(height: 8),
      TextButton(onPressed: _revokeShareLink,
        child: const Text('Revoke access', style: TextStyle(color: sage))),
    ],
    const SizedBox(height: 4),
    const Text('Anyone who receives the link can view the selected sections. You can revoke it anytime.',
      style: TextStyle(fontSize: 12, color: Colors.black54)),
  ]);

  Widget _shareSwitch(IconData icon, String title, String detail, bool value,
      ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: const BoxDecoration(
        color: Color(0xFFE8EBDD), shape: BoxShape.circle),
        child: Icon(icon, color: sage)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(detail, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ])),
      Switch(value: value, activeColor: sage, onChanged: onChanged),
    ]));

  String _newShareToken() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  Map<String, dynamic> _sharePayload() {
    final payload = <String, dynamic>{};
    if (shareTasks) payload['tasks'] = tasks;
    if (shareMeals) {
      payload['meals'] = meals;
      payload['groceries'] = groceries;
    }
    if (shareSchedule) payload['notes'] = notes;
    return payload;
  }

  Future<bool> _syncShareLink() async {
    final token = shareToken;
    if (token == null) return true;
    final ref = FirebaseFirestore.instance.collection('weekly_plan_shares').doc(token);
    final payload = _sharePayload();
    final encodedSize = payload.toString().length;
    if (encodedSize > 700000) {
      _msg('This plan is too large to share as one link.');
      return false;
    }
    await ref.set({
      'ownerUid': _uid,
      'weekLabel': '${_month(weekStart.month)} ${weekStart.day} – ${_month(weekStart.add(const Duration(days: 6)).month)} ${weekStart.add(const Duration(days: 6)).day}',
      'payload': payload,
      'updatedAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
    });
    return true;
  }

  String _shareUrl() => 'https://askthevillage.app/?sharedPlan=$shareToken';

  Future<void> _addSomeone() async {
    if (_uid.isEmpty) {
      _msg('Sign in to share your weekly plan.');
      return;
    }
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Who would you like to share with?',
                style: GoogleFonts.playfairDisplay(
                  color: ink, fontSize: 23, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              const Text('Choose a Circle member or share a private link.'),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8EBDD),
                  child: Icon(Icons.people_outline, color: sage)),
                title: const Text('Someone from My Circle',
                  style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Send it in a private Circle message.'),
                onTap: () => Navigator.pop(sheetContext, 'circle'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8EBDD),
                  child: Icon(Icons.link, color: sage)),
                title: const Text('Share by private link',
                  style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Send by text, email, or any app.'),
                onTap: () => Navigator.pop(sheetContext, 'link'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (choice == 'circle') await _chooseCircleMember();
    if (choice == 'link') await _shareByLink();
  }

  Future<void> _chooseCircleMember() async {
    final height = (MediaQuery.sizeOf(context).height * .68)
        .clamp(280.0, 560.0).toDouble();
    final selection = await showModalBottomSheet<Object?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Share with your Circle',
                  style: GoogleFonts.playfairDisplay(
                    color: ink, fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Choose who should receive the private link.'),
                const SizedBox(height: 12),
                Expanded(
                  child: StreamBuilder<List<CirclePerson>>(
                    stream: _circleService.members(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Your Circle could not be loaded right now.'));
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final members = snapshot.data!;
                      if (members.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.people_outline, size: 36, color: sage),
                              const SizedBox(height: 10),
                              const Text('Your Circle is empty.',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text('You can still share a private link with anyone.'),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(sheetContext, 'share_link'),
                                icon: const Icon(Icons.link),
                                label: const Text('Share by link'),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        itemCount: members.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final username = member.username.startsWith('@')
                              ? member.username : '@${member.username}';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE8EBDD),
                              backgroundImage: member.photoUrl.isEmpty
                                  ? null : NetworkImage(member.photoUrl),
                              child: member.photoUrl.isEmpty
                                  ? Text(username.substring(1, 2).toUpperCase(),
                                      style: const TextStyle(color: sage, fontWeight: FontWeight.w700))
                                  : null,
                            ),
                            title: Text(username,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: member.status.isEmpty ? null : Text(member.status),
                            trailing: const Icon(Icons.send_outlined, color: sage),
                            onTap: () => Navigator.pop(sheetContext, member),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted || selection == null) return;
    if (selection == 'share_link') {
      await _shareByLink();
    } else if (selection is CirclePerson) {
      await _sendPlanToCircleMember(selection);
    }
  }

  bool get _hasShareSelection => shareTasks || shareMeals || shareSchedule;

  Future<bool> _ensureShareLink() async {
    if (!_hasShareSelection) {
      _msg('Turn on at least one section to share.');
      return false;
    }
    if (_uid.isEmpty) {
      _msg('Sign in to create a sharing link.');
      return false;
    }
    final createdToken = shareToken == null;
    if (createdToken) setState(() => shareToken = _newShareToken());
    try {
      if (await _save()) return true;
    } on FirebaseException catch (e) {
      _msg('Could not create the sharing link: ${e.message ?? e.code}');
    }
    if (createdToken && mounted) {
      setState(() => shareToken = null);
      await _save();
    }
    return false;
  }

  Future<void> _shareByLink() async {
    if (await _ensureShareLink() && mounted) await _shareExistingLink();
  }

  Future<void> _sendPlanToCircleMember(CirclePerson member) async {
    if (!await _ensureShareLink() || !mounted) return;
    try {
      await _circleService.sendMessage(
        recipient: member,
        text: 'I shared my weekly plan with you. You can view it here: ${_shareUrl()}',
      );
      if (mounted) _msg('Your weekly plan was sent to @${member.username.replaceFirst('@', '')}.');
    } on Object {
      if (mounted) {
        _msg('The link is ready, but it could not be sent. You can try again or copy it below.');
      }
    }
  }

  Future<void> _createAndShareLink() async {
    await _shareByLink();
  }

  Future<void> _saveShareSettings() async {
    if (!shareTasks && !shareMeals && !shareSchedule) {
      _msg('Turn on at least one section to share.'); return;
    }
    if (await _save() && mounted) _msg('Sharing settings saved.');
  }

  Future<void> _shareExistingLink() async {
    if (shareToken == null) return;
    await Share.share(_shareUrl(), subject: 'My shared weekly plan');
  }

  Future<void> _copyShareLink() async {
    if (shareToken == null) return;
    await Clipboard.setData(ClipboardData(text: _shareUrl()));
    _msg('Private link copied.');
  }

  Future<void> _revokeShareLink() async {
    final token = shareToken;
    if (token == null) return;
    try {
      await FirebaseFirestore.instance.collection('weekly_plan_shares').doc(token).delete();
      setState(() => shareToken = null);
      await _save();
      _msg('Link access revoked.');
    } on FirebaseException catch (e) {
      _msg('Could not revoke the link: ${e.message ?? e.code}');
    }
  }

  Widget _taskDayPicker() {
    final options = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<DateTime?>(
        value: _draftTaskDay,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Task day (optional)',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        hint: const Text('Any day this week'),
        items: [
          const DropdownMenuItem<DateTime?>(
            value: null, child: Text('Any day this week')),
          for (final day in options)
            DropdownMenuItem<DateTime?>(
              value: day,
              child: Text('${_weekday(day)} · ${_month(day.month)} ${day.day}'),
            ),
        ],
        onChanged: (day) => setState(() {
          _draftTaskDay = day;
          daySelected = day != null;
          if (day != null) selectedDay = day;
        }),
      ),
    );
  }

  Widget _taskListPage() {
    final indices = <int>[
      for (var i = 0; i < tasks.length; i++)
        if (!daySelected || tasks[i]['day'] == _key(selectedDay)) i,
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _days(),
      const SizedBox(height: 16),
      Text(daySelected ? 'Tasks for ${_weekday(selectedDay)}' : 'This week’s tasks',
        style: GoogleFonts.playfairDisplay(fontSize: 23,
          color: ink, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(indices.isEmpty
        ? (daySelected ? 'A clear page for whatever matters today.' : 'Add tasks you want to track this week.')
        : '${indices.where((i) => tasks[i]['done'] == true).length} of ${indices.length} completed',
        style: const TextStyle(color: sage)),
      if (indices.isNotEmpty) ...[
        const SizedBox(height: 3),
        const Text('Swipe left to delete · drag the handle to reorder',
          style: TextStyle(color: sage, fontSize: 12)),
      ],
      const SizedBox(height: 12),
      _taskDayPicker(),
      Container(
        decoration: BoxDecoration(color: Colors.white,
          border: Border.all(color: line), borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.circle_outlined, size: 19, color: sage)),
          Expanded(child: TextField(controller: _taskDraft,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveTaskDraft(),
            decoration: const InputDecoration(
              hintText: 'Add a task for the week', border: InputBorder.none,
              counterText: '',), maxLength: 180)),
          FilledButton.icon(
            onPressed: _saveTaskDraft,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add')),
          const SizedBox(width: 6),
        ]),
      ),
      const SizedBox(height: 8),
      if (indices.isEmpty)
        _card(Text(daySelected
          ? 'Your list will appear here. New tasks will be added to ${_weekday(selectedDay)}.'
          : 'Your list will appear here. New tasks will be added to the week. Drag items to put them in the order you want.'))
      else
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: indices.length,
          onReorder: _reorderDayTasks,
          itemBuilder: (context, position) {
            final taskIndex = indices[position];
            final task = tasks[taskIndex];
            final done = task['done'] == true;
            return _swipeDeleteTask(
              key: ObjectKey(task),
              onDelete: () => _remove(tasks, taskIndex),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: Colors.white,
                  border: Border.all(color: line), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  Checkbox(value: done, activeColor: sage,
                    onChanged: (_) => _toggle(tasks, taskIndex)),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['title'] as String? ?? '',
                        style: TextStyle(
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: done ? ink.withValues(alpha: .55) : ink)),
                      if (!daySelected)
                        Text(_taskDayLabel(task),
                          style: const TextStyle(fontSize: 12, color: sage)),
                    ],
                  )),
                  ReorderableDragStartListener(index: position,
                    child: const Padding(padding: EdgeInsets.all(12),
                      child: Icon(Icons.drag_handle, color: sage))),
                ]),
              ),
            );
          },
        ),
      const SizedBox(height: 8),
      TextButton.icon(onPressed: () => setState(() => section = 'Tasks & Schedule'),
        icon: const Icon(Icons.calendar_month_outlined),
        label: const Text('Back to schedule')),
    ]);
  }

  Widget _mealPlannerSection() {
    final filters = ['Vegan', 'High Protein', 'Regular Recipes', 'All'];
    final recipes = _recipeFilter == 'All'
      ? _mealRecipes
      : _mealRecipes.where((recipe) => recipe.tags.contains(_recipeFilter)).toList();
    final plannedMeal = (meals[_activePlanKey] as String?)?.trim() ?? '';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _days(), const SizedBox(height: 12),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _heading('Meals for ${_activePlanLabel}', _meal),
        Text(plannedMeal.isNotEmpty ? plannedMeal : 'No meals planned yet.'),
        _link(Icons.shopping_cart_outlined,
          'Open Grocery List (${groceries.length} items)',
          () => setState(() => section = 'Grocery List')),
      ])),
      const SizedBox(height: 20),
      Text('Meal ideas', style: GoogleFonts.playfairDisplay(fontSize: 23,
        color: ink, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text('Choose a recipe to add to ${_activePlanLabel}, or select a day above. Send ingredients to your grocery list.'),
      const SizedBox(height: 11),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: Row(children: [for (var i = 0; i < filters.length; i++)
          Padding(padding: EdgeInsets.only(right: i == filters.length - 1 ? 0 : 7),
            child: ChoiceChip(label: Text(filters[i]),
              selected: _recipeFilter == filters[i],
              selectedColor: colors[0], labelStyle: TextStyle(color: sage,
                fontWeight: _recipeFilter == filters[i]
                  ? FontWeight.w700 : FontWeight.w500),
              onSelected: (_) => setState(() => _recipeFilter = filters[i]))) ])),
      const SizedBox(height: 12),
      for (final recipe in recipes) ...[
        _recipeCard(recipe), const SizedBox(height: 12),
      ],
    ]);
  }

  Widget _recipeCard(_MealRecipe recipe) => Container(
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
      borderRadius: BorderRadius.circular(18)),
    child: Material(color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(onTap: () => _showRecipe(recipe),
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _recipeImage(recipe),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 5, children: [
              for (final tag in recipe.tags) _recipeTag(tag),
            ]),
            const SizedBox(height: 7),
            Text(recipe.title, style: GoogleFonts.playfairDisplay(fontSize: 20,
              color: ink, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(recipe.description, style: const TextStyle(color: ink)),
            const SizedBox(height: 7),
            Text('You’ll need: ${recipe.ingredients.take(3).join(' · ')}',
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: sage)),
            const SizedBox(height: 3),
            const Align(alignment: Alignment.centerRight,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('View recipe', style: TextStyle(color: sage,
                  fontWeight: FontWeight.w600)),
                SizedBox(width: 3),
                Icon(Icons.chevron_right, color: sage),
              ])),
          ])))),
  );

  Widget _card(Widget child) => Container(padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: line),
      borderRadius: BorderRadius.circular(19)), child: child);

  Widget _heading(String text, VoidCallback add) => Row(children: [
    Expanded(child: Text(text, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w600))),
    IconButton(onPressed: add, tooltip: 'Add', icon: const Icon(Icons.add, color: sage)),
  ]);

  Widget _swipeDeleteTask({
    required Key key,
    required VoidCallback onDelete,
    required Widget child,
  }) => Dismissible(
    key: key,
    direction: DismissDirection.endToStart,
    onDismissed: (_) => onDelete(),
    background: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: const Color(0xFFF7E9E5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.delete_outline, color: Color(0xFF9A4138)),
          SizedBox(width: 6),
          Text('Delete', style: TextStyle(
            color: Color(0xFF9A4138), fontWeight: FontWeight.w600)),
        ],
      ),
    ),
    child: child,
  );

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
  String _taskDayLabel(Map<String, dynamic> task) {
    final day = DateTime.tryParse(task['day'] as String? ?? '');
    if (day == null) return 'Any day this week';
    return '${_shortDay(day)} · ${_month(day.month)} ${day.day}';
  }
  String _shortDay(DateTime d) => const ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d.weekday - 1];
  String _month(int m) => const ['January','February','March','April','May','June','July','August','September','October','November','December'][m - 1];
}

