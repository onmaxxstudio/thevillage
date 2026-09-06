import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/check_in_service.dart';
import 'ask_village_screen.dart';

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
  int selectedTab = 0;

  static const moods = <(IconData, String)>[
    (Icons.sentiment_very_satisfied_outlined, 'Great'),
    (Icons.sentiment_satisfied_outlined, 'Good'),
    (Icons.sentiment_neutral_outlined, 'Okay'),
    (Icons.sentiment_dissatisfied_outlined, 'Struggling'),
    (Icons.sentiment_very_dissatisfied_outlined, 'Not good'),
  ];

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
  }

  Future<void> loadHistory() async {
    final saved = await checkInService.load();
    if (mounted) setState(() => history = saved);
  }

  void openAsk() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AskVillageScreen()),
    );
  }

  void comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature is the next part of your village.')),
      );
  }

  Future<void> openCheckIn() async {
    final result = await showModalBottomSheet<_CheckInResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (_) => _CheckInSheet(existing: today),
    );
    if (result == null) return;
    final saved = await checkInService.saveToday(
      mood: result.mood,
      details: result.details,
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
                      const SizedBox(height: 18),
                      _buildSafeSpace(),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 92)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildNavigation(),
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
              (Icons.book_outlined, 'Village Library'),
              (Icons.settings_outlined, 'Settings'),
            ])
              ListTile(
                leading: Icon(item.$1, color: sage),
                title: Text(item.$2),
                onTap: () {
                  Navigator.pop(context);
                  if (item.$2 != 'Home') comingSoon(item.$2);
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  tooltip: 'Notifications',
                  onPressed: () => comingSoon('Notifications'),
                  icon: const Icon(Icons.notifications_none_rounded, size: 29),
                ),
                Positioned(
                  right: 3,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: sage,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
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
              'assets/images/create_account_hero.png',
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
                      const SizedBox(height: 8),
                      Text(
                        'Your village is here.',
                        style: GoogleFonts.inter(
                          fontSize: 16,
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
      onTap: openCheckIn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RoundIcon(icon: Icons.wb_sunny_outlined, gold: true),
          const SizedBox(height: 10),
          Text(
            'Daily Check-In',
            style: GoogleFonts.playfairDisplay(
              color: ink,
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            entry == null ? 'How are you today?' : 'Today: ${entry.mood}',
            style: const TextStyle(fontSize: 12.5),
          ),
          const Spacer(),
          if (entry == null)
            const Text(
              'Choose your mood  ›',
              style: TextStyle(
                color: sage,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: openCheckIn,
                    child: const Text('Edit'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: openHistory,
                    child: const Text('History'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCircleCard() {
    return _DashboardCard(
      color: const Color(0xFFFFF7ED),
      onTap: () => comingSoon('My Circle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _RoundIcon(icon: Icons.groups_2_outlined),
          const SizedBox(height: 10),
          Text(
            'My Circle',
            style: GoogleFonts.playfairDisplay(
              color: ink,
              fontSize: 23,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text('12 neighbors online', style: TextStyle(fontSize: 12.5)),
          const Spacer(),
          Row(
            children: [
              for (final letter in ['A', 'J', 'M'])
                Align(
                  widthFactor: .75,
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: paleSage,
                    child: Text(
                      letter,
                      style: const TextStyle(
                        color: sage,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: sage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAskCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.volunteer_activism_outlined,
            color: Color(0xFFE4C48A),
            size: 45,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask the Village',
                  style: GoogleFonts.playfairDisplay(
                    color: cream,
                    fontSize: 27,
                  ),
                ),
                const Text(
                  'Real questions. Real support.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: openAsk,
            style: FilledButton.styleFrom(
              backgroundColor: cream,
              foregroundColor: sage,
            ),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Ask Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trending in the Village',
          style: GoogleFonts.playfairDisplay(
            color: ink,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 9),
        InkWell(
          onTap: () => comingSoon('This conversation'),
          borderRadius: BorderRadius.circular(21),
          child: Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .5),
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(21),
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
                      const Text(
                        'Relationships',
                        style: TextStyle(
                          color: sage,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'What helped you feel like yourself again?',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
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
        ),
      ],
    );
  }

  Widget _buildSafeSpace() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: sage),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'This is your safe space. Be you. You belong here.',
            ),
          ),
          Icon(Icons.favorite_border_rounded, color: gold),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.groups_2_outlined, 'Circle'),
      (Icons.add_rounded, 'Ask'),
      (Icons.chat_bubble_outline_rounded, 'Village'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: cream,
          border: Border(top: BorderSide(color: line)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
        child: Row(
          children: List.generate(items.length, (index) {
            final ask = index == 2;
            final selected = selectedTab == index;
            return Expanded(
              child: InkWell(
                onTap: () {
                  setState(() => selectedTab = index);
                  if (ask) {
                    openAsk();
                  } else if (index != 0) {
                    comingSoon(items[index].$2);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: ask ? 48 : 38,
                        height: ask ? 48 : 32,
                        decoration: BoxDecoration(
                          color: ask
                              ? sage
                              : selected
                                  ? paleSage
                                  : Colors.transparent,
                          shape: ask ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius:
                              ask ? null : BorderRadius.circular(15),
                        ),
                        child: Icon(
                          items[index].$1,
                          color: ask
                              ? Colors.white
                              : selected
                                  ? sage
                                  : ink,
                        ),
                      ),
                      Text(
                        items[index].$2,
                        style: const TextStyle(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
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
    return AspectRatio(
      aspectRatio: .95,
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
  const _RoundIcon({required this.icon, this.gold = false});

  final IconData icon;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 24,
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
  const _CheckInResult(this.mood, this.details);

  final String mood;
  final String details;
}

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet({this.existing});

  final MoodCheckIn? existing;

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  String? selectedMood;
  late final TextEditingController detailsController;

  @override
  void initState() {
    super.initState();
    selectedMood = widget.existing?.mood;
    detailsController = TextEditingController(
      text: widget.existing?.details ?? '',
    );
  }

  @override
  void dispose() {
    detailsController.dispose();
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
        selectedMood!,
        includeDetails ? detailsController.text : '',
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
            Text(
              'Want to add more details?',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: detailsController,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Write what’s on your mind (optional)…',
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
                    'Your check-in and details are private.',
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
                child: const Text('Skip Details & Save'),
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
      appBar: AppBar(title: const Text('Mood History')),
      body: history.isEmpty
          ? const Center(
              child: Text('Your saved check-ins will appear here.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = history[index];
                final date =
                    '${entry.createdAt.month}/${entry.createdAt.day}/${entry.createdAt.year}';
                return Container(
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
                            Text(date, style: const TextStyle(fontSize: 12)),
                            if (entry.details.isNotEmpty) ...[
                              const SizedBox(height: 7),
                              Text(entry.details),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
