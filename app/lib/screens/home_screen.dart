import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF496B4F);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFC8A35E);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  int selectedMood = -1;
  int selectedTab = 0;

  void comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$feature is the next part of your village.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      drawer: Drawer(
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
                (Icons.groups_2_outlined, 'Groups'),
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
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                  sliver: SliverList.list(
                    children: [
                      _buildWelcome(),
                      const SizedBox(height: 18),
                      _buildTourCard(),
                      const SizedBox(height: 18),
                      _buildCheckIn(),
                      const SizedBox(height: 18),
                      _buildAskCard(),
                      const SizedBox(height: 18),
                      _buildHowItWorks(),
                      const SizedBox(height: 18),
                      _buildSafeSpace(),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildNavigation(),
    );
  }

  Widget _buildHeader() {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 5),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu_rounded, size: 30),
              onPressed: Scaffold.of(context).openDrawer,
            ),
            Expanded(
              child: Column(
                children: [
                  Image.asset('assets/images/welcome_branch.png', height: 25),
                  Text(
                    'Ask the Village',
                    style: GoogleFonts.playfairDisplay(
                      color: sage,
                      fontSize: 32,
                      height: 1.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Real People. Real Support. Real Answers.',
                    style: GoogleFonts.inter(fontSize: 10.5, color: ink),
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
                  right: 4,
                  top: 1,
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

  Widget _buildWelcome() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome home,',
          style: GoogleFonts.playfairDisplay(
            color: ink,
            fontSize: 43,
            height: 1.05,
            fontWeight: FontWeight.w600,
          ),
        ),
        Row(
          children: [
            Flexible(
              child: Text(
                '@kindheart',
                style: GoogleFonts.playfairDisplay(
                  color: sage,
                  fontSize: 38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.favorite_border_rounded, color: gold, size: 35),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'You’re in the right place.\nWe’re so glad you’re here.',
          style: GoogleFonts.inter(color: ink, fontSize: 17, height: 1.45),
        ),
        Text(
          'You’re not alone.',
          style: GoogleFonts.inter(
            color: sage,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 15),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.asset(
            'assets/images/create_account_hero.png',
            width: double.infinity,
            height: 205,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }

  Widget _buildTourCard() {
    return _Card(
      child: Row(
        children: [
          const _RoundIcon(icon: Icons.eco_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take a moment to get familiar.',
                  style: GoogleFonts.inter(
                    color: sage,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                const Text('We’ll show you around so you feel at home.'),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton(
            onPressed: () => comingSoon('Your guided tour'),
            style: FilledButton.styleFrom(backgroundColor: sage),
            child: const Text('Take a Tour ✨'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckIn() {
    const moods = [
      (Icons.sentiment_very_satisfied_outlined, 'Great'),
      (Icons.sentiment_satisfied_outlined, 'Good'),
      (Icons.sentiment_neutral_outlined, 'Okay'),
      (Icons.sentiment_dissatisfied_outlined, 'Struggling'),
      (Icons.sentiment_very_dissatisfied_outlined, 'Not good'),
    ];
    return _Card(
      color: const Color(0xFFF7F3E9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _RoundIcon(icon: Icons.wb_sunny_outlined, gold: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Check-In',
                      style: GoogleFonts.inter(
                        color: sage,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text('How are you showing up for yourself today?'),
                    const Row(
                      children: [
                        Text('Your check-in is private', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 4),
                        Icon(Icons.lock_outline_rounded, size: 12, color: sage),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: List.generate(moods.length, (index) {
              final selected = selectedMood == index;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == moods.length - 1 ? 0 : 5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => setState(() => selectedMood = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
                      decoration: BoxDecoration(
                        color: selected ? paleSage : cream,
                        border: Border.all(color: selected ? sage : line),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        children: [
                          Icon(moods[index].$1, color: index < 2 ? sage : gold, size: 27),
                          const SizedBox(height: 3),
                          FittedBox(child: Text(moods[index].$2, style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          TextButton.icon(
            onPressed: () => comingSoon('Check-in notes'),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded),
            label: const Text('Write more about how you feel (optional)'),
          ),
        ],
      ),
    );
  }

  Widget _buildAskCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.volunteer_activism_outlined, color: cream, size: 47),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ask the Village ♡',
                  style: GoogleFonts.playfairDisplay(color: cream, fontSize: 27),
                ),
                const Text(
                  'Get real answers, advice, and support from people who get it.',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => comingSoon('Ask the Village'),
            style: FilledButton.styleFrom(backgroundColor: cream, foregroundColor: sage),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Ask Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    const steps = [
      (Icons.people_outline_rounded, 'You’re not alone'),
      (Icons.favorite_border_rounded, 'Share & connect'),
      (Icons.shield_outlined, 'Privacy matters'),
      (Icons.home_outlined, 'Grow together'),
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New here? Here’s how it works.',
            style: GoogleFonts.inter(color: sage, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(steps.length, (index) => Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: paleSage,
                    child: Icon(steps[index].$1, color: sage),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    steps[index].$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeSpace() {
    return _Card(
      child: Row(
        children: [
          const _RoundIcon(icon: Icons.spa_outlined),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This is your safe space.',
                  style: GoogleFonts.inter(color: sage, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Text('Be you. We’re so glad you’re here.'),
              ],
            ),
          ),
          const Icon(Icons.favorite_border_rounded, color: gold, size: 33),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.groups_2_outlined, 'Groups'),
      (Icons.add_rounded, 'Ask'),
      (Icons.chat_bubble_outline_rounded, 'Messages'),
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
                  if (index != 0) comingSoon(items[index].$2);
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: ask ? 47 : 37,
                        height: ask ? 47 : 32,
                        decoration: BoxDecoration(
                          color: ask ? sage : selected ? paleSage : Colors.transparent,
                          shape: ask ? BoxShape.circle : BoxShape.rectangle,
                          borderRadius: ask ? null : BorderRadius.circular(15),
                        ),
                        child: Icon(items[index].$1, color: ask ? Colors.white : selected ? sage : ink),
                      ),
                      if (!ask) Text(items[index].$2, style: const TextStyle(fontSize: 10.5)),
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

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color = _HomeScreenState.cream});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: _HomeScreenState.line),
        borderRadius: BorderRadius.circular(23),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: child,
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
      radius: 27,
      backgroundColor: gold ? const Color(0xFFFFEBD0) : _HomeScreenState.paleSage,
      child: Icon(icon, color: gold ? _HomeScreenState.gold : _HomeScreenState.sage, size: 29),
    );
  }
}
