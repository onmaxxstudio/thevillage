import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/check_in_service.dart';
import '../services/daily_encouragement.dart';
import '../services/circle_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/personalization_service.dart';
import '../navigation/village_navigation_scope.dart';
import '../widgets/village_avatar.dart';
import '../widgets/daily_village_census_card.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'my_space_screen.dart';
import 'plan_my_week_screen.dart';

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
  final CircleService circleService = CircleService();
  StreamSubscription<List<CirclePerson>>? circleSubscription;
  Timer? _dailyMessageTimer;
  int? _shownDay;
  List<MoodCheckIn> history = [];
  List<CirclePerson> circleMembers = [];
  String currentUsername = 'Village member';
  bool showPeriodTracking = false;

  static const moods = <(IconData, String)>[
    (Icons.sentiment_very_satisfied_outlined, 'Great'),
    (Icons.sentiment_satisfied_outlined, 'Good'),
    (Icons.sentiment_neutral_outlined, 'Okay'),
    (Icons.sentiment_dissatisfied_outlined, 'Struggling'),
    (Icons.sentiment_very_dissatisfied_outlined, 'Not good'),
  ];

  String get breathingLesson => DailyEncouragement.forDate(DateTime.now());

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
    _shownDay = DailyEncouragement.dayNumber(DateTime.now());
    _dailyMessageTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      final day = DailyEncouragement.dayNumber(DateTime.now());
      if (day != _shownDay) setState(() => _shownDay = day);
    });
    loadHistory();
    PersonalizationService.notifier.addListener(_personalizationChanged);
    _loadPersonalization();
    _connectRealProfileData();
    NotificationService().startListening();
  }

  void _connectRealProfileData() {
    // The sign-in screen offers a guest preview. Avoid user-scoped Firebase
    // services until a member is authenticated; check-ins still use local storage.
    if (FirebaseAuth.instance.currentUser == null) return;
    ProfileService.usernameNotifier.addListener(_usernameChanged);
    ProfileService.currentUsername().then((username) {
      if (!mounted || username == null || username.trim().isEmpty) return;
      setState(() => currentUsername = username.trim());
    });
    circleSubscription = circleService.members().listen(
      (people) {
        if (mounted) setState(() => circleMembers = people);
      },
      onError: (_) {
        if (mounted) setState(() => circleMembers = []);
      },
    );
  }

  void _usernameChanged() {
    final username = ProfileService.usernameNotifier.value?.trim();
    if (!mounted || username == null || username.isEmpty) return;
    setState(() => currentUsername = username);
  }

  @override
  void dispose() {
    ProfileService.usernameNotifier.removeListener(_usernameChanged);
    PersonalizationService.notifier.removeListener(_personalizationChanged);
    circleSubscription?.cancel();
    _dailyMessageTimer?.cancel();
    super.dispose();
  }

  Future<void> loadHistory() async {
    final saved = await checkInService.load();
    if (mounted) setState(() => history = saved);
  }

  Future<void> _loadPersonalization() async {
    final value = await PersonalizationService().load();
    if (mounted) setState(() => showPeriodTracking = value.periodTracking);
  }

  void _personalizationChanged() {
    final value = PersonalizationService.notifier.value;
    if (mounted && value != null) {
      setState(() => showPeriodTracking = value.periodTracking);
    }
  }

  void openAsk() => VillageNavigationScope.of(context).onSelect(2);

  void openCircle() => VillageNavigationScope.of(context).onSelect(1);

  void openVillage() => VillageNavigationScope.of(context).onSelect(3);

  void openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void openCommunityHub() => VillageNavigationScope.of(context).onSelect(4);

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

  Future<void> openCheckIn({String? initialMood}) async {
    final result = await showModalBottomSheet<_CheckInResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => _CheckInSheet(
        existing: today,
        initialMood: initialMood,
        showPeriodTracking: showPeriodTracking,
        history: history,
        onPeriodTrackingChanged: (enabled) async {
          final value = await PersonalizationService().load();
          await PersonalizationService().save(VillagePersonalization(
            identity: value.identity,
            interests: value.interests,
            periodTracking: enabled,
            completed: value.completed,
          ));
        },
        onHistory: () {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) openHistory();
          });
        },
      ),
    );
    if (result == null) return;
    final saved = await checkInService.saveToday(
      mood: result.mood,
      details: result.details,
      periodStarted: result.periodStarted,
      healthNotes: result.healthNotes,
      periodEnded: result.periodEnded,
      spotting: result.spotting,
      flowLevel: result.flowLevel,
      symptoms: result.symptoms,
      feelingTags: result.feelingTags,
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
        builder: (_) => MoodHistoryScreen(history: history, showPeriodTracking: showPeriodTracking),
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
        child: Column(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: _buildHeader(),
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                        sliver: SliverList.list(
                          children: [
                            _buildWelcomeHero(),
                            const SizedBox(height: 14),
                            _buildDashboardRow(),
                            const SizedBox(height: 14),
                            _buildAskCard(),
                            const SizedBox(height: 14),
                            _buildFeatureGrid(),
                            const SizedBox(height: 14),
                            const DailyVillageCensusCard(),
                          ],
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
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

  Widget _buildFeatureGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 320 ? 1 : 2;
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: columns == 1 ? 2.05 : 1.78,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _buildMySpaceCard(),
            _buildPlanMyWeekCard(),
            _buildCommunityHubCard(),
            _buildTrendingCard(),
          ],
        );
      },
    );
  }

  Widget _buildSquareFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color cardColor,
    required Color iconBackground,
    required Color iconColor,
    required VoidCallback onTap,
    Color? borderColor,
    Color? leafColor,
    double? glyphSize,
  }) {
    final cardRadius = BorderRadius.circular(22);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 300).clamp(.78, 1.0);
        final iconRadius = 27.0 * scale;
        final cardWidth = 92.0 * scale;
        final cardHeight = 96.0 * scale;

        return Material(
          color: cardColor,
          borderRadius: cardRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardRadius,
            child: ClipRRect(
              borderRadius: cardRadius,
              child: Container(
                decoration: BoxDecoration(
                  border: borderColor == null
                      ? null
                      : Border.all(color: borderColor),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      right: -7,
                      bottom: -10,
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: Size(cardWidth, cardHeight),
                          painter: _FeatureCardLeafPainter(
                            (leafColor ?? sage).withValues(alpha: .16),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 13 * scale,
                        vertical: 10 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: GoogleFonts.playfairDisplay(
                                    color: ink,
                                    fontSize: 19 * scale,
                                    height: 1.05,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(width: 2 * scale),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: sage,
                                size: 24 * scale,
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * scale),
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: iconRadius,
                                  backgroundColor: iconBackground,
                                  child: Icon(
                                    icon,
                                    color: iconColor,
                                    size: (glyphSize ?? 32) * scale,
                                  ),
                                ),
                                SizedBox(width: 10 * scale),
                                Expanded(
                                  child: Text(
                                    description,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      color: ink,
                                      fontSize: 13.0 * scale,
                                      height: 1.18,
                                    ),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Widget _buildMySpaceCard() {
    return _buildSquareFeatureCard(
      title: 'My Space',
      description: 'A private place to write, reflect, and clear your mind.',
      icon: Icons.edit_note_rounded,\n      glyphSize: 26,
      cardColor: const Color(0xFFE8EBDD),
      iconBackground: sage,
      iconColor: Colors.white,
      leafColor: sage,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const MySpaceScreen()),
      ),
    );
  }

  Widget _buildPlanMyWeekCard() {
    return _buildSquareFeatureCard(
      title: 'Plan My Week',
      description: 'Set goals, plan tasks, and organize meals for the week.',
      icon: Icons.calendar_month_outlined,
      cardColor: const Color(0xFFF6E9E4),
      iconBackground: const Color(0xFFE8D5CB),
      iconColor: sage,
      leafColor: const Color(0xFF9C8879),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PlanMyWeekScreen(),
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
              (Icons.person_outline_rounded, 'Profile'),
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
                  } else if (item.$2 == 'Profile') {
                    openProfile();
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
            VillageMenuButton(
              onPressed: VillageNavigationScope.of(context).onOpenMenu,
            ),
            Expanded(
              child: Column(
                children: [
                  Image.asset('assets/images/welcome_branch.png', height: 22),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Ask the Village',
                      style: GoogleFonts.playfairDisplay(
                        color: sage,
                        fontSize: 31,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'Real People. Real Support. Real Answers.',
                    style: GoogleFonts.inter(fontSize: 10, color: ink),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService.unreadCount,
                  builder: (context, unreadCount, _) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: openNotifications,
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          size: 29,
                        ),
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
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            maxLines: 1,
                            softWrap: false,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: currentUsername,
                                  style: GoogleFonts.playfairDisplay(
                                    color: sage,
                                    fontSize: 34,
                                    height: 1.1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'TODAY’S ENCOURAGEMENT',
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
        const SizedBox(width: 10),
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
                radius: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Daily Check-In',
                    maxLines: 1,
                    style: GoogleFonts.playfairDisplay(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  entry == null ? 'How are you today?' : 'Today: ${entry.mood}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5),
                ),
              ),
              TextButton.icon(
                onPressed: openHistory,
                style: TextButton.styleFrom(
                  foregroundColor: sage,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  minimumSize: const Size(0, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.history_rounded, size: 14),
                label: const Text(
                  'My History',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          LayoutBuilder(
            builder: (context, constraints) {
              final diameter = ((constraints.maxWidth - 8) / 5)
                  .clamp(21, 28)
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
                radius: 16,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Circle',
                    maxLines: 1,
                    style: GoogleFonts.playfairDisplay(
                      color: ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: sage,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            circleMembers.isEmpty
                ? 'No people added yet'
                : '${circleMembers.length} people in your Circle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5),
          ),
          const Spacer(),
          Row(
            children: [
              if (circleMembers.isEmpty) ...[
                const Icon(Icons.person_add_alt_1_rounded, color: sage, size: 22),
                const SizedBox(width: 7),
                const Text(
                  'Invite someone',
                  style: TextStyle(color: sage, fontWeight: FontWeight.w700),
                ),
              ] else ...[
                for (final member in circleMembers.take(4))
                  Align(
                    widthFactor: .76,
                    child: VillageAvatar(uid: member.uid, radius: 15),
                  ),
              ],
              const Spacer(),
              if (circleMembers.isNotEmpty)
                Text(
                  '${circleMembers.length}',
                  style: const TextStyle(
                    color: sage,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 440;

        final callToAction = Column(
          crossAxisAlignment:
              compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment:
                  compact ? Alignment.centerLeft : Alignment.center,
              child: Text(
                'Ask the Village',
                style: GoogleFonts.playfairDisplay(
                  color: cream,
                  fontSize: compact ? 31 : 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Text(
              'Real People. Real Support. Real Answers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            if (compact) ...[
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.diversity_1_outlined,
                    color: Color(0xFFE4C48A),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Real questions. Brighter days.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: .7,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
        );

        return Container(
          height: compact ? 194 : 184,
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
              if (compact)
                callToAction
              else
                Row(
                  children: [
                    Expanded(flex: 3, child: callToAction),
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
      },
    );
  }

  Widget _buildTrendingCard() {
    return _buildSquareFeatureCard(
      title: 'Visit the Village',
      description: 'Read real questions, offer support, or start a conversation.',
      icon: Icons.chat_bubble_outline_rounded,
      cardColor: Colors.white.withValues(alpha: .6),
      iconBackground: blush,
      iconColor: gold,
      borderColor: line,
      leafColor: const Color(0xFFAD9684),
      onTap: openVillage,
    );
  }

  Widget _buildCommunityHubCard() {
    return _buildSquareFeatureCard(
      title: 'Community Hub',
      description: 'Find your people, explore resources, and gather for live events.',
      icon: Icons.diversity_3_outlined,
      cardColor: paleSage,
      iconBackground: cream,
      iconColor: sage,
      borderColor: line,
      leafColor: sage,
      onTap: openCommunityHub,
    );
  }



}

class _FeatureCardLeafPainter extends CustomPainter {
  const _FeatureCardLeafPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = color.withValues(alpha: color.a * .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width < 70 ? 1.2 : 1.8
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(size.width * .14, size.height * 1.02)
      ..cubicTo(
        size.width * .40,
        size.height * .73,
        size.width * .63,
        size.height * .37,
        size.width * .88,
        size.height * -.04,
      );
    canvas.drawPath(stem, stemPaint);

    final leafPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final veinPaint = Paint()
      ..color = color.withValues(alpha: color.a * .72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width < 70 ? .8 : 1.2
      ..strokeCap = StrokeCap.round;

    void leaf(Offset base, Offset tip, double width) {
      final delta = tip - base;
      final length = delta.distance;
      if (length == 0) return;
      final normal = Offset(-delta.dy / length, delta.dx / length);
      final middle = Offset.lerp(base, tip, .52)!;
      final path = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(
          middle.dx + normal.dx * width,
          middle.dy + normal.dy * width,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          middle.dx - normal.dx * width,
          middle.dy - normal.dy * width,
          base.dx,
          base.dy,
        );
      canvas.drawPath(path, leafPaint);
      canvas.drawLine(base, tip, veinPaint);
    }

    leaf(
      Offset(size.width * .32, size.height * .80),
      Offset(size.width * .02, size.height * .62),
      size.width * .12,
    );
    leaf(
      Offset(size.width * .44, size.height * .68),
      Offset(size.width * .77, size.height * .52),
      size.width * .13,
    );
    leaf(
      Offset(size.width * .57, size.height * .49),
      Offset(size.width * .26, size.height * .33),
      size.width * .12,
    );
    leaf(
      Offset(size.width * .70, size.height * .29),
      Offset(size.width * .96, size.height * .15),
      size.width * .11,
    );
    leaf(
      Offset(size.width * .79, size.height * .12),
      Offset(size.width * .56, size.height * .01),
      size.width * .09,
    );
  }

  @override
  bool shouldRepaint(covariant _FeatureCardLeafPainter oldDelegate) {
    return oldDelegate.color != color;
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
    required this.feelingTags,
    required this.periodStarted,
    required this.healthNotes,
    required this.periodEnded,
    required this.spotting,
    required this.flowLevel,
    required this.symptoms,
  });

  final String mood;
  final String details;
  final List<String> feelingTags;
  final bool periodStarted;
  final String healthNotes;
  final bool periodEnded;
  final bool spotting;
  final String flowLevel;
  final List<String> symptoms;
}

class _CheckInSheet extends StatefulWidget {
  const _CheckInSheet({
    this.existing,
    this.initialMood,
    required this.showPeriodTracking,
    required this.history,
    required this.onPeriodTrackingChanged,
    required this.onHistory,
  });

  final MoodCheckIn? existing;
  final String? initialMood;
  final bool showPeriodTracking;
  final List<MoodCheckIn> history;
  final Future<void> Function(bool enabled) onPeriodTrackingChanged;
  final VoidCallback onHistory;

  @override
  State<_CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends State<_CheckInSheet> {
  static const feelings = <String>[
    'Calm', 'Happy', 'Anxious', 'Stressed', 'Tired',
    'Motivated', 'Overwhelmed', 'Irritable',
  ];
  static const symptomsOptions = <String>[
    'Cramps', 'Bloating', 'Headache', 'Mood changes', 'Back pain', 'Fatigue',
  ];
  static const monthShort = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String? selectedMood;
  final Set<String> selectedFeelings = {};
  bool periodStarted = false;
  bool periodEnded = false;
  bool spotting = false;
  String flowLevel = '';
  final Set<String> symptoms = {};
  bool healthExpanded = true;
  bool cycleExpanded = false;
  late bool cycleEnabled;
  late final TextEditingController detailsController;
  late final TextEditingController healthNotesController;

  @override
  void initState() {
    super.initState();
    selectedMood = widget.initialMood ?? widget.existing?.mood;
    selectedFeelings.addAll(widget.existing?.feelingTags ?? const []);
    periodStarted = widget.existing?.periodStarted ?? false;
    periodEnded = widget.existing?.periodEnded ?? false;
    spotting = widget.existing?.spotting ?? false;
    flowLevel = widget.existing?.flowLevel ?? '';
    symptoms.addAll(widget.existing?.symptoms ?? const []);
    cycleEnabled = widget.showPeriodTracking;
    cycleExpanded = cycleEnabled;
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

  void save() {
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
        details: detailsController.text,
        feelingTags: selectedFeelings.toList(),
        periodStarted: cycleEnabled
            ? periodStarted
            : widget.existing?.periodStarted ?? false,
        healthNotes: healthNotesController.text,
        periodEnded: cycleEnabled
            ? periodEnded
            : widget.existing?.periodEnded ?? false,
        spotting: cycleEnabled ? spotting : widget.existing?.spotting ?? false,
        flowLevel:
            cycleEnabled ? flowLevel : widget.existing?.flowLevel ?? '',
        symptoms:
            cycleEnabled ? symptoms.toList() : widget.existing?.symptoms ?? const [],
      ),
    );
  }

  String _dateLabel(DateTime value) =>
      '${monthShort[value.month - 1]} ${value.day}';

  List<DateTime> _periodStarts() {
    final values = widget.history
        .where((entry) => entry.periodStarted)
        .map((entry) => DateTime(
              entry.createdAt.year,
              entry.createdAt.month,
              entry.createdAt.day,
            ))
        .toList();
    if (periodStarted) {
      final now = DateTime.now();
      values.add(DateTime(now.year, now.month, now.day));
    }
    values.sort();
    final unique = <DateTime>[];
    for (final value in values) {
      if (unique.isEmpty || unique.last != value) unique.add(value);
    }
    return unique;
  }

  DateTime? _nextPeriodEstimate(List<DateTime> starts, int cycleLength) {
    if (starts.isEmpty) return null;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    var estimate = starts.last.add(Duration(days: cycleLength));
    while (estimate.isBefore(todayOnly)) {
      estimate = estimate.add(Duration(days: cycleLength));
    }
    return estimate;
  }

  Future<void> _addFeeling() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _HomeScreenState.cream,
        title: const Text('Add a feeling'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 24,
          decoration: const InputDecoration(hintText: 'Type a feeling'),
          onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    final tag = value?.trim();
    if (tag == null || tag.isEmpty) return;
    setState(() {
      if (selectedFeelings.contains(tag)) {
        selectedFeelings.remove(tag);
      } else {
        selectedFeelings.add(tag);
      }
    });
  }

  Future<void> _addSymptom() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _HomeScreenState.cream,
        title: const Text('Add a symptom'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 32,
          decoration: const InputDecoration(hintText: 'Type a symptom'),
          onSubmitted: (text) => Navigator.pop(dialogContext, text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    final symptom = value?.trim();
    if (symptom == null || symptom.isEmpty) return;
    setState(() {
      if (symptoms.contains(symptom)) {
        symptoms.remove(symptom);
      } else {
        symptoms.add(symptom);
      }
    });
  }

  Widget _tag({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? selectedColor,
    Color? selectedTextColor,
  }) {
    final fill = selectedColor ?? _HomeScreenState.sage;
    return ChoiceChip(
      avatar: icon == null
          ? null
          : Icon(icon, size: 17, color: selected ? (selectedTextColor ?? Colors.white) : _HomeScreenState.sage),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: fill,
      backgroundColor: Colors.white.withValues(alpha: .62),
      side: BorderSide(
        color: selected ? fill : _HomeScreenState.line,
      ),
      labelStyle: TextStyle(
        color: selected ? (selectedTextColor ?? Colors.white) : _HomeScreenState.ink,
        fontSize: 13,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      shape: const StadiumBorder(),
    );
  }

  Widget _sectionCard({
    required Widget child,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: .48),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _HomeScreenState.line.withValues(alpha: .8)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCycleSection() {
    final starts = _periodStarts();
    final intervals = <int>[];
    for (var index = 1; index < starts.length; index++) {
      final days = starts[index].difference(starts[index - 1]).inDays;
      if (days >= 21 && days <= 45) intervals.add(days);
    }
    final cycleLength = intervals.isEmpty
        ? 28
        : (intervals.reduce((a, b) => a + b) / intervals.length)
            .round()
            .clamp(21, 45);
    final nextPeriod = _nextPeriodEstimate(starts, cycleLength);
    final ovulation = nextPeriod?.subtract(const Duration(days: 14));
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    String relative(DateTime? date) {
      if (date == null) return 'Log a start date';
      final days = date.difference(todayOnly).inDays;
      return days == 0 ? 'around today' : days > 0 ? 'in $days days' : '${days.abs()} days ago';
    }

    return _sectionCard(
      color: const Color(0xFFFFF9F1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9E5E3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_rounded,
                    color: Color(0xFFD8505B), size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => cycleExpanded = !cycleExpanded),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'My Cycle ',
                              style: GoogleFonts.playfairDisplay(
                                color: _HomeScreenState.ink,
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(
                              text: '(optional)',
                              style: TextStyle(fontSize: 13, color: _HomeScreenState.sage),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        cycleEnabled
                            ? 'Track your period, symptoms, and view estimated ovulation.'
                            : 'Turn on to track dates, symptoms, and calendar estimates.',
                        style: const TextStyle(fontSize: 13, height: 1.25),
                      ),
                    ],
                  ),
                ),
              ),
              Switch.adaptive(
                value: cycleEnabled,
                activeColor: _HomeScreenState.sage,
                onChanged: (value) async {
                  setState(() {
                    cycleEnabled = value;
                    if (!value) cycleExpanded = false;
                  });
                  await widget.onPeriodTrackingChanged(value);
                },
              ),
              IconButton(
                tooltip: cycleExpanded ? 'Collapse My Cycle' : 'Expand My Cycle',
                onPressed: () => setState(() => cycleExpanded = !cycleExpanded),
                icon: Icon(cycleExpanded ? Icons.expand_less : Icons.expand_more),
              ),
            ],
          ),
          if (cycleEnabled && cycleExpanded) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 4,
              children: [
                _tag(
                  label: 'Period started',
                  selected: periodStarted,
                  icon: Icons.water_drop_rounded,
                  selectedColor: _HomeScreenState.sage,
                  onTap: () => setState(() {
                    periodStarted = !periodStarted;
                    if (periodStarted) {
                      periodEnded = false;
                      spotting = false;
                    }
                  }),
                ),
                _tag(
                  label: 'Period ended',
                  selected: periodEnded,
                  icon: Icons.water_drop_outlined,
                  onTap: () => setState(() {
                    periodEnded = !periodEnded;
                    if (periodEnded) {
                      periodStarted = false;
                      spotting = false;
                    }
                  }),
                ),
                _tag(
                  label: 'Spotting',
                  selected: spotting,
                  icon: Icons.water_drop_outlined,
                  selectedColor: const Color(0xFFF6DADB),
                  selectedTextColor: const Color(0xFF5F2930),
                  onTap: () => setState(() {
                    spotting = !spotting;
                    if (spotting) {
                      periodStarted = false;
                      periodEnded = false;
                    }
                  }),
                ),
                _tag(
                  label: 'None',
                  selected: !periodStarted && !periodEnded && !spotting,
                  icon: Icons.block_outlined,
                  onTap: () => setState(() {
                    periodStarted = false;
                    periodEnded = false;
                    spotting = false;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(children: [
                    TextSpan(text: 'Flow level '),
                    TextSpan(text: '(optional)', style: TextStyle(color: _HomeScreenState.sage, fontSize: 12)),
                  ]),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 5,
                  runSpacing: 3,
                  children: [
                    for (final level in ['Light', 'Medium', 'Heavy'])
                      _tag(
                        label: level,
                        selected: flowLevel == level,
                        icon: Icons.water_drop_rounded,
                        selectedColor: level == 'Medium'
                            ? const Color(0xFFF5DDDC)
                            : _HomeScreenState.paleSage,
                        selectedTextColor: _HomeScreenState.ink,
                        onTap: () => setState(() => flowLevel = flowLevel == level ? '' : level),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'Symptoms '),
                      TextSpan(text: '(optional)', style: TextStyle(color: _HomeScreenState.sage, fontSize: 12)),
                    ]),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final symptom in [...symptomsOptions, ...symptoms.difference(symptomsOptions.toSet())])
                  _tag(
                    label: symptom,
                    selected: symptoms.contains(symptom),
                    onTap: () => setState(() {
                      symptoms.contains(symptom) ? symptoms.remove(symptom) : symptoms.add(symptom);
                    }),
                  ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 17),
                  label: const Text('Add'),
                  onPressed: _addSymptom,
                  side: BorderSide(color: _HomeScreenState.line),
                  backgroundColor: Colors.white.withValues(alpha: .62),
                  shape: const StadiumBorder(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _predictionCard(
                    icon: Icons.calendar_month_outlined,
                    title: 'Next Period',
                    date: nextPeriod == null ? '—' : _dateLabel(nextPeriod),
                    sub: relative(nextPeriod),
                    color: const Color(0xFFF9E5E3),
                    iconColor: const Color(0xFFD8505B),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _predictionCard(
                    icon: Icons.eco_outlined,
                    title: 'Ovulation (Est.)',
                    date: ovulation == null ? '—' : _dateLabel(ovulation),
                    sub: relative(ovulation),
                    color: _HomeScreenState.paleSage,
                    iconColor: _HomeScreenState.sage,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _predictionCard(
                    icon: Icons.autorenew_rounded,
                    title: 'Cycle Length',
                    date: '${cycleLength} days',
                    sub: intervals.isEmpty ? '(typical estimate)' : '(avg)',
                    color: const Color(0xFFF6F0E5),
                    iconColor: _HomeScreenState.sage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Predictions are estimates and can vary. They are not reliable contraception guidance.',
              style: TextStyle(fontSize: 11, height: 1.3),
            ),
            const SizedBox(height: 8),
            _CycleCalendar(history: widget.history),
          ],
        ],
      ),
    );
  }

  Widget _predictionCard({
    required IconData icon,
    required String title,
    required String date,
    required String sub,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 114),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 17),
            const SizedBox(width: 4),
            Expanded(child: Text(title, maxLines: 2, style: const TextStyle(fontSize: 10, height: 1.1))),
          ]),
          const SizedBox(height: 8),
          Text(date, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final date = '${weekdays[now.weekday - 1]}, ${monthShort[now.month - 1]} ${now.day}';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close Daily Check-In',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Image.asset('assets/images/welcome_branch.png', height: 18),
                      Text('Ask the Village',
                          maxLines: 1,
                          style: GoogleFonts.playfairDisplay(
                            color: _HomeScreenState.sage,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onHistory,
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: const Text('My History', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: _HomeScreenState.sage,
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Check-In',
                        style: GoogleFonts.playfairDisplay(
                          color: _HomeScreenState.ink,
                          fontSize: 35,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('How are you today?', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EDE2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 16, color: _HomeScreenState.sage),
                      const SizedBox(width: 5),
                      Text(date, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var index = 0; index < _HomeScreenState.moods.length; index++)
                  Expanded(
                    child: _moodOption(_HomeScreenState.moods[index], index),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'What are you feeling today? ',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _HomeScreenState.ink,
                        ),
                      ),
                      const TextSpan(
                        text: '(optional)',
                        style: TextStyle(fontSize: 12, color: _HomeScreenState.sage),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: [
                      for (final feeling in [
                        ...feelings,
                        ...selectedFeelings.difference(feelings.toSet()),
                      ])
                        _tag(
                          label: feeling,
                          selected: selectedFeelings.contains(feeling),
                          onTap: () => setState(() {
                            selectedFeelings.contains(feeling)
                                ? selectedFeelings.remove(feeling)
                                : selectedFeelings.add(feeling);
                          }),
                          selectedColor: _HomeScreenState.sage,
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 17),
                        label: const Text('Add another'),
                        onPressed: _addFeeling,
                        side: BorderSide(color: _HomeScreenState.line),
                        backgroundColor: Colors.white.withValues(alpha: .62),
                        shape: const StadiumBorder(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => healthExpanded = !healthExpanded),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF6E8D5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit_note_rounded,
                              color: _HomeScreenState.sage, size: 30),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(children: [
                                  TextSpan(
                                    text: 'Health Notes ',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: _HomeScreenState.ink,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: '(optional)',
                                    style: TextStyle(fontSize: 12, color: _HomeScreenState.sage),
                                  ),
                                ]),
                              ),
                              const Text(
                                'Write anything you want to remember about your health, energy, sleep, medication, or symptoms.',
                                style: TextStyle(fontSize: 12, height: 1.25),
                              ),
                            ],
                          ),
                        ),
                        Icon(healthExpanded ? Icons.expand_less : Icons.expand_more),
                      ],
                    ),
                  ),
                  if (healthExpanded) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: healthNotesController,
                      minLines: 2,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: 'Add a note...',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: .55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _HomeScreenState.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: _HomeScreenState.line),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildCycleSection(),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: _HomeScreenState.sage, size: 17),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    cycleEnabled
                        ? 'Your mood, period details, and health notes stay private to your account.'
                        : 'Your mood and health notes stay private to your account.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: save,
                style: FilledButton.styleFrom(
                  backgroundColor: _HomeScreenState.sage,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Save Check-In', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moodOption((IconData, String) mood, int index) {
    const moodColors = [
      Color(0xFFE6EFE1),
      Color(0xFFE6EFE1),
      Color(0xFFF8EDD5),
      Color(0xFFF5DEDB),
      Color(0xFFF5DEDB),
    ];
    final isSelected = selectedMood == mood.$2;
    final iconColor = index == 2 ? const Color(0xFFB87914) : _HomeScreenState.sage;
    final label = mood.$2 == 'Not good' ? 'Tough' : mood.$2;
    return InkWell(
      onTap: () => setState(() => selectedMood = mood.$2),
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: moodColors[index],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? iconColor : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
            ),
            child: Icon(mood.$1, color: iconColor, size: 31),
          ),
          const SizedBox(height: 4),
          Text(label, maxLines: 1, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class MoodHistoryScreen extends StatefulWidget {
  const MoodHistoryScreen({super.key, required this.history, required this.showPeriodTracking});
  final List<MoodCheckIn> history;
  final bool showPeriodTracking;

  @override
  State<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends State<MoodHistoryScreen> {
  String tab = 'Overview';
  String range = 'Last 30 days';
  static const tabNames = ['Overview', 'Mood', 'Cycle', 'Health Notes'];

  List<MoodCheckIn> get entries {
    if (range == 'All time') return widget.history;
    final days = range == 'Last 7 days' ? 7 : range == 'Last 90 days' ? 90 : 30;
    final since = DateTime.now().subtract(Duration(days: days));
    return widget.history.where((e) => !e.createdAt.isBefore(since)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final shownTabs = widget.showPeriodTracking ? tabNames : tabNames.where((t) => t != 'Cycle').toList();
    return Scaffold(
      backgroundColor: _HomeScreenState.cream,
      appBar: AppBar(
        backgroundColor: _HomeScreenState.cream,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        leadingWidth: 0,
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: _HomeScreenState.ink),
                  ),
                  Expanded(
                    child: Text(
                      'My Check-In History',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        color: _HomeScreenState.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: range,
                      isDense: true,
                      iconSize: 18,
                      style: const TextStyle(color: _HomeScreenState.ink, fontSize: 12),
                      items: const [
                        DropdownMenuItem(value: 'Last 7 days', child: Text('Last 7 days')),
                        DropdownMenuItem(value: 'Last 30 days', child: Text('Last 30 days')),
                        DropdownMenuItem(value: 'Last 90 days', child: Text('Last 90 days')),
                        DropdownMenuItem(value: 'All time', child: Text('All time')),
                      ],
                      onChanged: (v) { if (v != null) setState(() => range = v); },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < shownTabs.length; i++) ...[
                      _HistoryTab(label: shownTabs[i], selected: tab == shownTabs[i],
                        onTap: () => setState(() => tab = shownTabs[i])),
                      if (i != shownTabs.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty) _empty()
          else if (tab == 'Overview') _overview(entries)
          else if (tab == 'Mood') _mood(entries)
          else if (tab == 'Cycle') _cycle(entries)
          else _health(entries),
        ],
          ),
        ),
      ),
    );
  }

  Widget _overview(List<MoodCheckIn> data) {
    final now = DateTime.now();
    final month = data.where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month).toList();
    final recent = data.take(5).toList();
    final mood = _topMood(month);
    final notes = month.where((e) => e.healthNotes.trim().isNotEmpty).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.showPeriodTracking) ...[
        _PeriodPredictionCard(history: data), const SizedBox(height: 12),
      ],
      _panel('Your Mood Trend', subtitle: 'Your saved check-ins over time', child: Column(children: [
        _MoodTrendChart(history: widget.history),
        const SizedBox(height: 12),
        _counts(data),
      ])),
      const SizedBox(height: 12),
      _panel('This Month at a Glance', subtitle: _month(now.month) + ' ' + now.year.toString(),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _glance(Icons.calendar_month_outlined, month.length.toString(), 'Check-ins'),
          _glance(Icons.sentiment_satisfied_alt_rounded, mood, 'Most common mood'),
          if (widget.showPeriodTracking)
            _glance(Icons.water_drop_outlined, month.where((e) => e.periodStarted).length.toString(), 'Period starts'),
          _glance(Icons.description_outlined, notes.toString(), 'Health-note days'),
        ])),
      if (widget.showPeriodTracking) ...[
        const SizedBox(height: 12),
        _panel('Cycle Overview', trailing: 'View Calendar', child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Period dates and cycle predictions are estimates.'),
            const SizedBox(height: 8),
            _CycleCalendar(history: data),
          ],
        )),
      ],
      const SizedBox(height: 12),
      _panel('Recent Check-Ins', trailing: 'View All', child: Column(children: [
        for (var i = 0; i < recent.length; i++) ...[
          _entry(recent[i]),
          if (i < recent.length - 1) Divider(height: 1, color: _HomeScreenState.line),
        ],
      ])),
    ]);
  }

  Widget _mood(List<MoodCheckIn> data) => Column(children: [
    _panel('Your Mood Journey', subtitle: 'See how your mood has changed over time.',
      child: Column(children: [_MoodTrendChart(history: widget.history), const SizedBox(height: 12), _counts(data)])),
    const SizedBox(height: 12),
    _panel('Mood Patterns', child: Row(children: [
      const Icon(Icons.lightbulb_outline_rounded, color: _HomeScreenState.gold),
      const SizedBox(width: 10),
      Expanded(child: Text(data.length < 3
        ? 'Keep checking in to see patterns in your mood.'
        : 'Your mood history reflects the check-ins you have saved.')),
    ])),
    const SizedBox(height: 12),
    for (final e in data) _entry(e),
  ]);

  Widget _cycle(List<MoodCheckIn> data) => _panel(
    'Cycle Insights',
    trailing: 'View Calendar',
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _PeriodPredictionCard(history: data),
      const SizedBox(height: 10),
      const Text('These dates are estimates and can vary. They are not reliable contraception guidance.',
        style: TextStyle(fontSize: 12)),
      const SizedBox(height: 10),
      _CycleCalendar(history: data),
    ]),
  );

  Widget _health(List<MoodCheckIn> data) {
    final notes = data.where((e) => e.healthNotes.trim().isNotEmpty).toList();
    return _panel('Health Notes', trailing: 'Saved notes', child: notes.isEmpty
      ? const Text('Health notes saved with your check-ins will appear here.')
      : Column(children: [
          for (var i = 0; i < notes.length; i++) ...[
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(radius: 20, backgroundColor: _HomeScreenState.paleSage,
                child: Icon(Icons.description_outlined, color: _HomeScreenState.sage)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_month(notes[i].createdAt.month) + ' ' + notes[i].createdAt.day.toString() +
                  ', ' + notes[i].createdAt.year.toString(),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(notes[i].healthNotes),
              ])),
              const Icon(Icons.chevron_right_rounded),
            ]),
            if (i < notes.length - 1) Divider(height: 20, color: _HomeScreenState.line),
          ],
        ]));
  }

  Widget _entry(MoodCheckIn e) {
    final color = _color(e.mood);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 48, padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(color: _HomeScreenState.paleSage.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(13)),
          child: Column(children: [
            Text(_shortMonth(e.createdAt.month), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700)),
            Text(e.createdAt.day.toString(), style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700)),
          ])),
        const SizedBox(width: 9),
        CircleAvatar(radius: 18, backgroundColor: color.withValues(alpha: .2),
          child: Icon(_icon(e.mood), size: 21, color: color)),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mood: ' + e.mood, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (e.feelingTags.isNotEmpty) Text(e.feelingTags.join(' · '), style: const TextStyle(fontSize: 12)),
          if (e.healthNotes.isNotEmpty) Text(e.healthNotes, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
          if (e.details.isNotEmpty) Text(e.details, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
          if (e.periodStarted) const Text('Period started', style: TextStyle(fontSize: 11, color: _HomeScreenState.sage)),
        ])),
        const Icon(Icons.chevron_right_rounded),
      ]),
    );
  }

  Widget _counts(List<MoodCheckIn> data) {
    const moods = ['Great', 'Good', 'Okay', 'Struggling', 'Not good'];
    return Wrap(alignment: WrapAlignment.spaceBetween, runSpacing: 8, children: [
      for (final mood in moods)
        Container(width: 62, padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .45), borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Icon(_icon(mood), color: _color(mood), size: 24),
            Text(data.where((e) => e.mood == mood).length.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(mood, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
          ])),
    ]);
  }

  Widget _glance(IconData icon, String value, String label) => Container(
    width: 145, padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: const Color(0xFFF6F2E9), borderRadius: BorderRadius.circular(17)),
    child: Row(children: [
      Icon(icon, color: _HomeScreenState.sage, size: 23),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: _HomeScreenState.ink)),
        Text(label, style: const TextStyle(fontSize: 11)),
      ])),
    ]),
  );

  Widget _empty() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .62),
      border: Border.all(color: _HomeScreenState.line), borderRadius: BorderRadius.circular(20)),
    child: const Column(children: [
      Icon(Icons.spa_outlined, color: _HomeScreenState.sage, size: 34),
      SizedBox(height: 8),
      Text('Your saved check-ins will appear here.'),
    ]),
  );

  Widget _panel(String title, {String? subtitle, String? trailing, required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 0),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .65),
      border: Border.all(color: _HomeScreenState.line), borderRadius: BorderRadius.circular(21)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Text(title, style: GoogleFonts.playfairDisplay(color: _HomeScreenState.ink,
          fontSize: 21, height: 1.1, fontWeight: FontWeight.w600))),
        if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 11, color: _HomeScreenState.sage)),
      ]),
      if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12))],
      const SizedBox(height: 10),
      child,
    ]),
  );

  String _topMood(List<MoodCheckIn> data) {
    if (data.isEmpty) return '—';
    final counts = <String, int>{};
    for (final e in data) { counts.update(e.mood, (n) => n + 1, ifAbsent: () => 1); }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  IconData _icon(String mood) => switch (mood) {
    'Great' => Icons.sentiment_very_satisfied_rounded,
    'Good' => Icons.sentiment_satisfied_alt_rounded,
    'Okay' => Icons.sentiment_neutral_rounded,
    'Struggling' => Icons.sentiment_dissatisfied_rounded,
    _ => Icons.sentiment_very_dissatisfied_rounded,
  };

  Color _color(String mood) => switch (mood) {
    'Great' => const Color(0xFF56835A),
    'Good' => const Color(0xFF76A96F),
    'Okay' => const Color(0xFFE8AD3C),
    'Struggling' => const Color(0xFFE77D92),
    _ => const Color(0xFFB44C7B),
  };

  String _month(int n) => const ['January','February','March','April','May','June',
    'July','August','September','October','November','December'][n - 1];
  String _shortMonth(int n) => const ['JAN','FEB','MAR','APR','MAY','JUN',
    'JUL','AUG','SEP','OCT','NOV','DEC'][n - 1];
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? _HomeScreenState.sage : Colors.white.withValues(alpha: .62),
    borderRadius: BorderRadius.circular(24),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(24),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : _HomeScreenState.ink,
          fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)))),
  );
}

class _CycleCalendar extends StatefulWidget {
  const _CycleCalendar({required this.history});
  final List<MoodCheckIn> history;

  @override
  State<_CycleCalendar> createState() => _CycleCalendarState();
}

class _CycleCalendarState extends State<_CycleCalendar> {
  bool expanded = false;
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final starts = widget.history
        .where((entry) => entry.periodStarted)
        .map((entry) => DateTime(entry.createdAt.year, entry.createdAt.month, entry.createdAt.day))
        .toList()
      ..sort();
    final intervals = <int>[];
    for (var i = 1; i < starts.length; i++) {
      final days = starts[i].difference(starts[i - 1]).inDays;
      if (days >= 21 && days <= 45) intervals.add(days);
    }
    final cycleLength = intervals.isEmpty
        ? 28
        : (intervals.reduce((a, b) => a + b) / intervals.length).round().clamp(21, 45);
    DateTime? nextPeriod;
    DateTime? ovulation;
    if (starts.isNotEmpty) {
      nextPeriod = starts.last.add(Duration(days: cycleLength));
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      while (nextPeriod!.isBefore(today)) {
        nextPeriod = nextPeriod.add(Duration(days: cycleLength));
      }
      ovulation = nextPeriod.subtract(const Duration(days: 14));
    }
    final startOffset = DateTime(month.year, month.month, 1).weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () => setState(() => expanded = !expanded),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: _HomeScreenState.paleSage.withValues(alpha: .62),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_month_outlined, color: _HomeScreenState.sage),
            const SizedBox(width: 10),
            Expanded(child: Text(expanded ? 'Hide My Cycle Calendar' : 'View My Cycle Calendar',
              style: const TextStyle(color: _HomeScreenState.sage, fontWeight: FontWeight.w600))),
            Icon(expanded ? Icons.expand_less : Icons.chevron_right, color: _HomeScreenState.sage),
          ]),
        ),
      ),
      if (expanded) ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)),
            icon: const Icon(Icons.chevron_left)),
          Text('${month.month}/${month.year}', style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)),
            icon: const Icon(Icons.chevron_right)),
        ]),
        Row(children: [
          for (final day in ['S','M','T','W','T','F','S'])
            Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 11)))),
        ]),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: startOffset + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final date = DateTime(month.year, month.month, index - startOffset + 1);
            final period = widget.history.any((e) =>
                (e.periodStarted || e.spotting || e.flowLevel.isNotEmpty) &&
                e.createdAt.year == date.year && e.createdAt.month == date.month && e.createdAt.day == date.day);
            final fertile = ovulation != null &&
                !date.isBefore(ovulation.subtract(const Duration(days: 5))) &&
                !date.isAfter(ovulation);
            final estimatedOvulation = ovulation != null &&
                date.year == ovulation.year && date.month == ovulation.month && date.day == ovulation.day;
            return Container(margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: period ? const Color(0xFFF3B9BD) :
                    estimatedOvulation ? const Color(0xFF355C3B) :
                    fertile ? const Color(0xFFDDE7C9) : null),
              alignment: Alignment.center,
              child: Text('${date.day}', style: TextStyle(
                fontSize: 12, color: estimatedOvulation ? Colors.white : Colors.black87)));
          }),
        const Text('Pink: logged period  •  Light green: estimated fertile days  •  Dark green: estimated ovulation',
          style: TextStyle(fontSize: 10)),
      ],
    ]);
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

class _MoodTrendChart extends StatefulWidget {
  const _MoodTrendChart({required this.history});

  final List<MoodCheckIn> history;

  @override
  State<_MoodTrendChart> createState() => _MoodTrendChartState();
}

class _MoodTrendChartState extends State<_MoodTrendChart> {
  int rangeDays = 7;

  @override
  Widget build(BuildContext context) {
    final start = DateTime.now().subtract(Duration(days: rangeDays));
    final points = widget.history
        .where((entry) => !entry.createdAt.isBefore(start))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Your Mood Trend',
                  style: GoogleFonts.playfairDisplay(
                    color: _HomeScreenState.ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: rangeDays,
                  isDense: true,
                  iconSize: 18,
                  style: const TextStyle(
                    color: _HomeScreenState.ink,
                    fontSize: 12,
                  ),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 60, child: Text('60 days')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => rangeDays = value);
                  },
                ),
              ),
            ],
          ),
          Text(
            '${points.length} check-ins in the last $rangeDays days',
            style: const TextStyle(fontSize: 12),
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
      final labelStride = (entries.length / 6).ceil();
      if (index % labelStride != 0 && index != entries.length - 1) continue;
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
