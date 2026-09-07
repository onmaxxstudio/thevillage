import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/check_in_service.dart';
import '../services/notification_service.dart';
import '../navigation/village_navigation_scope.dart';
import 'ask_village_screen.dart';
import 'circle_screen.dart';
import 'village_feed_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const blush = Color(0xFFF3E2DD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final CheckInService checkInService = CheckInService();
  List<MoodCheckIn> history = [];

  static const moods = <(IconData, String)>[
    (Icons.sentiment_very_satisfied_outlined, 'Great'),
    (Icons.sentiment_satisfied_outlined, 'Good'),
    (Icons.sentiment_neutral_outlined, 'Okay'),
    (Icons.sentiment_dissatisfied_outlined, 'Struggling'),
    (Icons.sentiment_very_dissatisfied_outlined, 'Not good'),
  ];

  static const breathingLessons = [
    'Breathe in for 4. Hold for 4. Exhale for 6.',
    'Inhale calm. Exhale what you cannot control.',
    'Take three slow breaths, making each exhale longer.',
    'Breathe in for 4. Hold for 4. Breathe out for 4.',
    'Drop your shoulders and breathe into the pause.',
    'Place a hand on your heart and breathe slowly for one minute.',
    'Inhale possibility. Exhale pressure.',
  ];

  String get breathingLesson {
    return breathingLessons[DateTime.now().weekday - 1];
  }

  MoodCheckIn? get today {
    final now = DateTime.now();
    for (final entry in history) {
      if (entry.createdAt.year == now.year &&
          entry.createdAt.month == now.month &&
          entry.createdAt.day == now.day) {
        return entry;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    loadHistory();
    NotificationService().load();
  }

  Future<void> loadHistory() async {
    final saved = await checkInService.load();
    if (mounted) setState(() => history = saved);
  }

  void openAsk() => VillageNavigationScope.of(context).onSelect(2);

  void openCircle() => VillageNavigationScope.of(context).onSelect(1);

  void openVillage() => VillageNavigationScope.of(context).onSelect(3);

  void openProfile() => VillageNavigationScope.of(context).onSelect(4);

  void openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  void comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature is the next part of your village.')),
      );
  }

  Future<void> openCheckIn({String? initialMood}) async {
    final result = await showModalBottomSheet<_CheckInResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (_) => _CheckInSheet(existing: today, initialMood: initialMood),
    );
    if (result == null) return;
    final saved = await checkInService.saveToday(
      mood: result.mood,
      details: result.details,
      periodStarted: result.periodStarted,
      healthNotes: result.healthNotes,
    );
    if (!mounted) return;
    setState(() => history = saved);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your private check-in was saved.')),
    );
  }

  void openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MoodHistoryScreen(history: history),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      drawer: _buildDrawer(),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  sliver: SliverList.list(
                    children: [
                      _buildWelcomeHero(),
                      const SizedBox(height: 14),
                      _buildDashboardRow(),
                      const SizedBox(height: 14),
                      _buildAskCard(),
                      const SizedBox(height: 18),
                      _buildTrendingCard(),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: cream,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Ask the Village',
              style: GoogleFonts.playfairDisplay(
                color: sage,
                fontSize: 31,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            for (final item in const [
              (Icons.home_rounded, 'Home'),
              (Icons.groups_2_outlined, 'My Circle'),
              (Icons.forum_outlined, 'Village'),
              (Icons.settings_outlined, 'Settings'),
            ])
              ListTile(
                leading: Icon(item.$1, color: sage),
                title: Text(item.$2),
                onTap: () {
                  Navigator.pop(context);
                  if (item.$2 == 'My Circle') {
                    openCircle();
                  } else if (item.$2 == 'Village') {
                    openVillage();
                  } else if (item.$2 == 'Settings') {
                    openSettings();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Menu',
              onPressed: Scaffold.of(context).openDrawer,
              icon: const Icon(Icons.menu_rounded, size: 30),
            ),
            Expanded(
              child: Column(
                children: [
                  Image.asset('assets/images/welcome_branch.png', height: 22),
                  Text(
                    'Ask the Village',
                    style: GoogleFonts.playfairDisplay(
                      color: sage,
                      fontSize: 31,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Real People. Real Support. Real Answers.',
                    style: GoogleFonts.inter(fontSize: 10, color: ink),
                  ),
                ],
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: NotificationService.unreadCount,
              builder: (context, unreadCount, _) => Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: openNotifications,
                    icon:
                        const Icon(Icons.notifications_none_rounded, size: 29),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 3,
                      top: 0,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18),
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: sage,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
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

  Widget _buildWelcomeHero() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        height: 218,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/home_breathing_hero_v2.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFDF8EE),
                    Color(0xE8FDF8EE),
                    Color(0x00FDF8EE),
                  ],
                  stops: [0, .42, .72],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome home,',
                        style: GoogleFonts.playfairDisplay(
                          color: ink,
                          fontSize: 28,
                          height: 1,
                        ),
                      ),
                      Text(
                        'KindHeart ♡',
                        style: GoogleFonts.playfairDisplay(
                          color: sage,
                          fontSize: 34,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'TODAY’S BREATH',
                        style: TextStyle(
                          color: gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        breathingLesson,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
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
  }

  Widget _buildDashboardRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildCheckInCard()),
        const SizedBox(width: 12),
        Expanded(child: _buildCircleCard()),
      ],
    );
  }

  Widget _buildCheckInCard() {
    final entry = today;
    return _DashboardCard(
      color: const Color(0xFFF1F4E9),
      onTap: () => openCheckIn(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RoundIcon(
                icon: Icons.wb_sunny_outlined,
                gold: true,
                radius: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Daily Check-In',
                        style: GoogleFonts.playfairDisplay(
                          color: ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      entry == null ? 'How are you today?' : 'Today: ${entry.mood}',
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              if (entry != null)
                TextButton.icon(
                  onPressed: openHistory,
                  style: TextButton.styleFrom(
                    foregroundColor: sage,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('My History'),
                ),
            ],
          ),
          const Spacer(),
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter = ((constraints.maxWidth - 8) / 5)
                  .clamp(25, 36)
                  .toDouble();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final mood in moods)
                    InkWell(
                      onTap: () => openCheckIn(initialMood: mood.$2),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: diameter,
                        height: diameter,
                        decoration: BoxDecoration(
                          color: entry?.mood == mood.$2
                              ? sage
                              : _moodColor(mood.$2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          mood.$1,
                          size: diameter * .58,
                          color: entry?.mood == mood.$2 ? Colors.white : ink,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircleCard() {
    return _DashboardCard(
      color: const Color(0xFFFFF7ED),
      onTap: openCircle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RoundIcon(
                icon: Icons.groups_2_outlined,
                radius: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Circle',
                      style: GoogleFonts.playfairDisplay(
                        color: ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      '3 people available',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: sage),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              for (final alignment in const [-1.0, -.5, 0.0, .5])
                Align(
                  widthFactor: .72,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cream, width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/create_account_hero.png',
                        fit: BoxFit.cover,
                        alignment: Alignment(alignment, 0),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              const Text(
                '+7',
                style: TextStyle(
                  color: sage,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _moodColor(String mood) {
    return switch (mood) {
      'Great' => const Color(0xFFA9B99A),
      'Good' => const Color(0xFFC7D0AF),
      'Okay' => const Color(0xFFE8D8B9),
      'Struggling' => const Color(0xFFE9BFB5),
      _ => const Color(0xFFD2AAAA),
    };
  }

  Widget _buildAskCard() {
    return Container(
      height: 184,
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F172019),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -25,
            bottom: -24,
            child: Opacity(
              opacity: .5,
              child: Image.asset(
                'assets/images/welcome_branch.png',
                width: 155,
                color: const Color(0xFFE4C48A),
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Ask the Village',
                        style: GoogleFonts.playfairDisplay(
                          color: cream,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Text(
                      'Real People. Real Support. Real Answers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: openAsk,
                        style: FilledButton.styleFrom(
                          backgroundColor: cream,
                          foregroundColor: sage,
                        ),
                        iconAlignment: IconAlignment.end,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text(
                          'Ask Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 1,
                height: 120,
                color: const Color(0x99E4C48A),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.diversity_1_outlined,
                      color: Color(0xFFE4C48A),
                      size: 44,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'REAL\nQUESTIONS.\nBRIGHTER\nDAYS.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.55,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard() {
    return InkWell(
      onTap: openVillage,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .6),
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(21),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10172019),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 29,
              backgroundColor: blush,
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: gold,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trending in the Village',
                    style: GoogleFonts.playfairDisplay(
                      color: ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'What helped you feel like yourself again?',
                    style: TextStyle(fontSize: 14.5),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '♡ 124     ◯ 28 replies',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: sage),
          ],
        ),
      ),
    );
  }


}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.color,
    required this.child,
    required this.onTap,
  });

  final Color color;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: _HomeScreenState.line),
            borderRadius: BorderRadius.circular(22),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    this.gold = false,
    this.radius = 24,
  });

  final IconData icon;
  final bool gold;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          gold ? const Color(0xFFFFEBD0) : _HomeScreenState.blush,
      child: Icon(
        icon,
        color: gold ? _HomeScreenState.gold : _HomeScreenState.sage,
      ),
    );
  }
}

class _CheckInResult {
  const _CheckInResult({
    required this.mood,
    required this.details,
    required this.periodStarted,
    required this.healthNotes,
  });

  final String mood;
  final String details;
  final bool periodStarted;
  final String healthNotes;
}

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet({this.existing, this.initialMood});

  final MoodCheckIn? existing;
  final String? initialMood;

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  String? selectedMood;
  bool periodStarted = false;
  late final TextEditingController detailsController;
  late final TextEditingController healthNotesController;

  @override
  void initState() {
    super.initState();
    selectedMood = widget.initialMood ?? widget.existing?.mood;
    periodStarted = widget.existing?.periodStarted ?? false;
    detailsController = TextEditingController(
      text: widget.existing?.details ?? '',
    );
    healthNotesController = TextEditingController(
      text: widget.existing?.healthNotes ?? '',
    );
  }

  @override
  void dispose() {
    detailsController.dispose();
    healthNotesController.dispose();
    super.dispose();
  }

  void save({required bool includeDetails}) {
    if (selectedMood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose how you’re feeling first.')),
      );
      return;
    }
    Navigator.pop(
      context,
      _CheckInResult(
        mood: selectedMood!,
        details: includeDetails ? detailsController.text : '',
        periodStarted: periodStarted,
        healthNotes: includeDetails ? healthNotesController.text : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        2,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Check-In',
              style: GoogleFonts.playfairDisplay(
                color: _HomeScreenState.sage,
                fontSize: 31,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'How are you showing up for yourself today?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (final mood in _HomeScreenState.moods)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: InkWell(
                        onTap: () => setState(() => selectedMood = mood.$2),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            color: selectedMood == mood.$2
                                ? _HomeScreenState.paleSage
                                : _HomeScreenState.cream,
                            border: Border.all(
                              color: selectedMood == mood.$2
                                  ? _HomeScreenState.sage
                                  : _HomeScreenState.line,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(mood.$1, color: _HomeScreenState.sage),
                              const SizedBox(height: 3),
                              FittedBox(
                                child: Text(
                                  mood.$2,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: periodStarted,
              onChanged: (value) {
                setState(() => periodStarted = value ?? false);
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: _HomeScreenState.sage,
              title: Text(
                'My period started today',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text(
                'Saving the start date helps estimate your next period.',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Health notes (optional)',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: healthNotesController,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Symptoms, sleep, pain, medication, or anything else…',
                filled: true,
                fillColor: Colors.white.withValues(alpha: .55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Personal notes (optional)',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: detailsController,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Write what’s on your mind…',
                filled: true,
                fillColor: Colors.white.withValues(alpha: .55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: _HomeScreenState.sage,
                  size: 17,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Your mood, period start date, and health notes stay private on this device.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => save(includeDetails: true),
                style: FilledButton.styleFrom(
                  backgroundColor: _HomeScreenState.sage,
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Save Check-In'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => save(includeDetails: false),
                child: const Text('Save Without Notes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoodHistoryScreen extends StatelessWidget {
  const MoodHistoryScreen({super.key, required this.history});

  final List<MoodCheckIn> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _HomeScreenState.cream,
      appBar: AppBar(
        backgroundColor: _HomeScreenState.cream,
        title: Text(
          'My Check-In History',
          style: GoogleFonts.playfairDisplay(
            color: _HomeScreenState.sage,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _PeriodPredictionCard(history: history),
          const SizedBox(height: 14),
          _MoodTrendChart(history: history),
          const SizedBox(height: 22),
          Text(
            'Monthly Health Summary',
            style: GoogleFonts.playfairDisplay(
              color: _HomeScreenState.ink,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'A private overview based only on your saved check-ins.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          _MonthlyHealthSummary(history: history),
          const SizedBox(height: 22),
          Text(
            'Recent Check-Ins',
            style: GoogleFonts.playfairDisplay(
              color: _HomeScreenState.ink,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text('Your saved check-ins will appear here.'),
              ),
            )
          else
            for (final entry in history) ...[
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .55),
                    border: Border.all(color: _HomeScreenState.line),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: _HomeScreenState.paleSage,
                        child: Icon(
                          Icons.favorite_outline_rounded,
                          color: _HomeScreenState.sage,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.mood,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${entry.createdAt.month}/${entry.createdAt.day}/${entry.createdAt.year}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (entry.periodStarted) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Period started',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (entry.healthNotes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Health notes: ${entry.healthNotes}'),
                            ],
                            if (entry.details.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Personal note: ${entry.details}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _PeriodPredictionCard extends StatelessWidget {
  const _PeriodPredictionCard({required this.history});

  final List<MoodCheckIn> history;

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final starts = history
        .where((entry) => entry.periodStarted)
        .map(
          (entry) => DateTime(
            entry.createdAt.year,
            entry.createdAt.month,
            entry.createdAt.day,
          ),
        )
        .toList()
      ..sort();

    if (starts.isEmpty) {
      return _predictionShell(
        title: 'Next Period Estimate',
        message:
            'Mark “My period started today” in a Daily Check-In to begin tracking.',
      );
    }

    var cycleDays = 28;
    if (starts.length > 1) {
      final intervals = <int>[];
      for (var index = 1; index < starts.length; index++) {
        final days = starts[index].difference(starts[index - 1]).inDays;
        if (days > 0) intervals.add(days);
      }
      if (intervals.isNotEmpty) {
        cycleDays =
            (intervals.reduce((a, b) => a + b) / intervals.length).round();
      }
    }

    var estimate = starts.last.add(Duration(days: cycleDays));
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    while (estimate.isBefore(todayOnly)) {
      estimate = estimate.add(Duration(days: cycleDays));
    }

    final date =
        '${monthNames[estimate.month - 1]} ${estimate.day}, ${estimate.year}';
    final detail = starts.length == 1
        ? 'Early estimate using a 28-day cycle. It becomes more personal after more start dates.'
        : 'Based on ${starts.length} saved period start dates and an average ${cycleDays}-day cycle.';

    return _predictionShell(
      title: 'Next Period Estimate',
      message: 'Around $date',
      detail: detail,
    );
  }

  Widget _predictionShell({
    required String title,
    required String message,
    String? detail,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7E8E7),
        border: Border.all(color: _HomeScreenState.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFF4F1),
            child: Icon(
              Icons.calendar_month_outlined,
              color: _HomeScreenState.sage,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    color: _HomeScreenState.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 5),
                  Text(detail, style: const TextStyle(fontSize: 12)),
                ],
                const SizedBox(height: 5),
                const Text(
                  'Estimate only—cycles can vary.',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyHealthSummary extends StatelessWidget {
  const _MonthlyHealthSummary({required this.history});

  final List<MoodCheckIn> history;

  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .55),
          border: Border.all(color: _HomeScreenState.line),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'Your monthly summaries will appear after you save check-ins.',
        ),
      );
    }

    final grouped = <int, List<MoodCheckIn>>{};
    for (final entry in history) {
      final key = entry.createdAt.year * 100 + entry.createdAt.month;
      grouped.putIfAbsent(key, () => <MoodCheckIn>[]).add(entry);
    }
    final months = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        for (var index = 0; index < months.length; index++) ...[
          _monthCard(months[index], entries: grouped[months[index]]!),
          if (index != months.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _monthCard(
    int key, {
    required List<MoodCheckIn> entries,
  }) {
    final year = key ~/ 100;
    final month = key % 100;
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      moodCounts.update(entry.mood, (value) => value + 1, ifAbsent: () => 1);
    }
    final mostCommonMood = moodCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    final periodStarts = entries.where((entry) => entry.periodStarted).length;
    final healthEntries =
        entries.where((entry) => entry.healthNotes.isNotEmpty).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .58),
        border: Border.all(color: _HomeScreenState.line),
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${monthNames[month - 1]} $year',
            style: GoogleFonts.playfairDisplay(
              color: _HomeScreenState.sage,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _summaryPill(
                Icons.fact_check_outlined,
                '${entries.length} check-in${entries.length == 1 ? '' : 's'}',
              ),
              _summaryPill(
                Icons.favorite_outline_rounded,
                'Mood: $mostCommonMood',
              ),
              _summaryPill(
                Icons.calendar_today_outlined,
                '$periodStarts period start${periodStarts == 1 ? '' : 's'}',
              ),
              _summaryPill(
                Icons.health_and_safety_outlined,
                '${healthEntries.length} health-note day${healthEntries.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Health notes',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          if (healthEntries.isEmpty)
            const Text(
              'No health notes recorded this month.',
              style: TextStyle(fontSize: 12),
            )
          else
            for (final entry in healthEntries.take(3)) ...[
              Text(
                '${entry.createdAt.month}/${entry.createdAt.day}  •  ${entry.healthNotes}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 4),
            ],
          const SizedBox(height: 6),
          const Text(
            'This is a personal record, not medical advice.',
            style: TextStyle(fontSize: 10.5),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: _HomeScreenState.paleSage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _HomeScreenState.sage),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _MoodTrendChart extends StatelessWidget {
  const _MoodTrendChart({required this.history});

  final List<MoodCheckIn> history;

  @override
  Widget build(BuildContext context) {
    final points = history.take(7).toList().reversed.toList();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        border: Border.all(color: _HomeScreenState.line),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Mood Trend',
            style: GoogleFonts.playfairDisplay(
              color: _HomeScreenState.ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text(
            'Your last 7 check-ins, from happy to sad',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                const SizedBox(
                  width: 68,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Great', style: TextStyle(fontSize: 10)),
                        Text('Good', style: TextStyle(fontSize: 10)),
                        Text('Okay', style: TextStyle(fontSize: 10)),
                        Text('Struggling', style: TextStyle(fontSize: 10)),
                        Text('Not good', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: CustomPaint(
                    painter: _MoodTrendPainter(points),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          if (points.isEmpty)
            const Center(
              child: Text(
                'Complete a check-in to begin your graph.',
                style: TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodTrendPainter extends CustomPainter {
  _MoodTrendPainter(this.entries);

  final List<MoodCheckIn> entries;

  static const moodValues = {
    'Great': 0.0,
    'Good': 1.0,
    'Okay': 2.0,
    'Struggling': 3.0,
    'Not good': 4.0,
  };

  @override
  void paint(Canvas canvas, Size size) {
    const bottomSpace = 25.0;
    final graphHeight = size.height - bottomSpace;
    final gridPaint = Paint()
      ..color = _HomeScreenState.line
      ..strokeWidth = 1;

    for (var row = 0; row < 5; row++) {
      final y = graphHeight * row / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (entries.isEmpty) return;

    Offset pointAt(int index) {
      final x = entries.length == 1
          ? size.width / 2
          : size.width * index / (entries.length - 1);
      final value = moodValues[entries[index].mood] ?? 2;
      return Offset(x, graphHeight * value / 4);
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var index = 1; index < entries.length; index++) {
      final point = pointAt(index);
      line.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _HomeScreenState.sage
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var index = 0; index < entries.length; index++) {
      final point = pointAt(index);
      canvas.drawCircle(point, 6, Paint()..color = _HomeScreenState.sage);
      canvas.drawCircle(
        point,
        3,
        Paint()..color = _HomeScreenState.cream,
      );
      final date = entries[index].createdAt;
      final label = TextPainter(
        text: TextSpan(
          text: '${date.month}/${date.day}',
          style: const TextStyle(
            color: _HomeScreenState.ink,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(
          (point.dx - label.width / 2)
              .clamp(0, size.width - label.width)
              .toDouble(),
          graphHeight + 8,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MoodTrendPainter oldDelegate) {
    return oldDelegate.entries != entries;
  }
}
