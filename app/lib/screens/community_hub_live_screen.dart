import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';
import '../services/community_hub_service.dart';
import '../services/personalization_service.dart';
import 'community_detail_screen.dart';
import 'find_help_screen.dart';

class CommunityHubLiveScreen extends StatefulWidget {
  const CommunityHubLiveScreen({super.key});

  @override
  State<CommunityHubLiveScreen> createState() => _CommunityHubLiveScreenState();
}

class _CommunityHubLiveScreenState extends State<CommunityHubLiveScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const gold = Color(0xFFB78943);
  static const line = Color(0xFFE7DED1);

  final admin = AdminContentService();
  final hub = CommunityHubService();
  final searchController = TextEditingController();
  late final PageController featurePager;

  int selected = 0;
  int featuredIndex = 1;
  String query = '';
  Set<String> joined = {};
  Map<String, int> memberCounts = {};
  VillagePersonalization personalization = const VillagePersonalization.empty();

  static const categoryGroups = <_CommunityGroup>[
    _CommunityGroup('women', 'Women', ['women', 'relationships', 'friendship']),
    _CommunityGroup('men', 'Men', ['men', 'career', 'friendship']),
    _CommunityGroup('parenting', 'Parenting', ['moms', 'caregivers', 'relationships']),
    _CommunityGroup('wellness', 'Wellness', ['wellness', 'grief', 'friendship']),
    _CommunityGroup('new_start', 'New Start', ['new_beginnings', 'career', 'caregivers']),
    _CommunityGroup('faith', 'Faith', ['faith', 'grief', 'new_beginnings']),
  ];

  static const builtIns = <_Community>[
    _Community('men', 'Men', 'Honest advice about relationships, fatherhood, purpose, friendship, pressure, and emotional wellbeing.', 'Men', 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=1200&q=85'),
    _Community('relationships', 'Relationships', 'For the conversations you cannot always have with people you know.', 'Relationships', 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=1200&q=85'),
    _Community('women', 'Women', 'Support, perspective, and connection through every season of womanhood.', 'Life & Growth', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=85'),
    _Community('moms', 'Moms', 'Real talk and practical support for motherhood.', 'Parenting', 'https://images.unsplash.com/photo-1543342386-1f1350e27861?auto=format&fit=crop&w=1200&q=85'),
    _Community('friendship', 'Friendship', 'Navigate closeness, change, conflict, and connection.', 'Friendship', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=85'),
    _Community('faith', 'Faith', 'A welcoming space for prayer, encouragement, spiritual growth, and walking through life together.', 'Faith', 'https://images.unsplash.com/photo-1447069387593-a5de0862481e?auto=format&fit=crop&w=1200&q=85'),
    _Community('wellness', 'Wellness', 'Gentle support for emotional and everyday wellbeing.', 'Mental Health', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=85'),
    _Community('career', 'Career & Purpose', 'Work, confidence, growth, and your next move.', 'Work & School', 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&w=1200&q=85'),
    _Community('grief', 'Grief & Healing', 'A softer place for loss, remembrance, and healing.', 'Grief', 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=85'),
    _Community('new_beginnings', 'New Beginnings', 'Moves, endings, transitions, and fresh starts.', 'Life & Growth', 'https://images.unsplash.com/photo-1500534623283-312aade485b7?auto=format&fit=crop&w=1200&q=85'),
    _Community('caregivers', 'Caregivers', 'Care and understanding for people who care for others.', 'Practical help', 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=1200&q=85'),
  ];

  @override
  void initState() {
    super.initState();
    featurePager = PageController(initialPage: 1, viewportFraction: .76);
    _loadMemberships();
  }

  @override
  void dispose() {
    featurePager.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberships() async {
    try {
      final values = await Future.wait<Object>([
        hub.joinedCommunities(),
        hub.memberCounts(builtIns.map((e) => e.id)),
        PersonalizationService().load(),
      ]);
      if (!mounted) return;
      setState(() {
        joined = values[0] as Set<String>;
        memberCounts = values[1] as Map<String, int>;
        personalization = values[2] as VillagePersonalization;
      });
    } on Object {
      // Community discovery remains usable if membership data is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 2),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.energy_savings_leaf_outlined, color: gold, size: 29),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Ask the\nVillage', style: GoogleFonts.playfairDisplay(fontSize: 20, height: .93, fontWeight: FontWeight.w700, color: sage))),
                      Padding(padding: const EdgeInsets.only(top: 5), child: Text('REAL PEOPLE\nBRIGHTER TOMORROWS', textAlign: TextAlign.right, style: TextStyle(color: gold, fontSize: 7.2, fontWeight: FontWeight.w800, letterSpacing: 1.7, height: 1.55))),
                      const SizedBox(width: 10),
                      const CircleAvatar(radius: 15, backgroundColor: sage, child: Icon(Icons.person_rounded, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Align(alignment: Alignment.center, child: Text('Community Hub', style: GoogleFonts.playfairDisplay(fontSize: 29, fontWeight: FontWeight.w700, color: ink))),
                  const SizedBox(height: 8),
                  _tabs(),
                ],
              ),
            ),
            Expanded(child: IndexedStack(index: selected, children: [_communities(), const FindHelpScreen(), _managedList('events', 'Happening in the Village', Icons.calendar_month_outlined)])),
          ],
        ),
      ),
    );
  }

  Widget _tabs() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _topTab('Communities', 0),
          _topTab('Resources', 1),
          _topTab('Events', 2),
        ],
      );

  Widget _topTab(String label, int index) => InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => selected = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: selected == index ? sage : Colors.transparent, borderRadius: BorderRadius.circular(24)),
          child: Text(label, style: TextStyle(color: selected == index ? Colors.white : ink, fontWeight: selected == index ? FontWeight.w800 : FontWeight.w500, fontSize: 12.5)),
        ),
      );

  Widget _communities() {
    if (!admin.cloudReady) return _communityHome(_filter(builtIns));
    return StreamBuilder<List<ManagedContentItem>>(
      stream: admin.watchPublished('communities'),
      builder: (context, snapshot) => _communityHome(_filter(_merge(snapshot.data ?? const <ManagedContentItem>[]))),
    );
  }

  Widget _communityHome(List<_Community> communities) {
    final carouselOrder = <String>['men', 'women', 'relationships'];
    final carouselItems = <_Community>[
      for (final id in carouselOrder)
        ...communities.where((community) => community.id == id),
      ...communities.where((community) => !carouselOrder.contains(community.id)),
    ];
    final visible = carouselItems.isEmpty ? communities : carouselItems;
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 25),
      children: [
        _clubhousePager(visible),
        const SizedBox(height: 12),
        _pagerDots(visible.length),
        const SizedBox(height: 18),
        _quickSpaces(communities),
        const SizedBox(height: 10),
        Center(
          child: Column(
            children: [
              SizedBox(width: 34, child: Divider(color: gold, thickness: 1.4)),
              const SizedBox(height: 10),
              Text(
                'GOOD PEOPLE\nBRIGHTER DAYS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: gold,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _clubhousePager(List<_Community> items) => SizedBox(
        height: 270,
        child: PageView.builder(
          controller: featurePager,
          itemCount: items.length,
          onPageChanged: (index) => setState(() => featuredIndex = index),
          itemBuilder: (_, index) => AnimatedBuilder(
            animation: featurePager,
            builder: (_, child) {
              final page = featurePager.hasClients
                  ? featurePager.page ?? featurePager.initialPage.toDouble()
                  : featurePager.initialPage.toDouble();
              final distance = (page - index).abs().clamp(0.0, 1.0);
              return Transform.scale(
                scale: 1 - (.075 * distance),
                child: Opacity(opacity: 1 - (.28 * distance), child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: _clubhouseCard(items[index]),
            ),
          ),
        ),
      );

  Widget _clubhouseCard(_Community community) {
    final joinedAlready = joined.contains(community.id);
    return InkWell(
      onTap: () => _open(community),
      borderRadius: BorderRadius.circular(27),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: [
            community.imageUrl.isEmpty
                ? _fallback()
                : Image.network(
                    community.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fallback(),
                  ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x08000000), Color(0xEC000000)],
                  stops: [.28, 1],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(19, 18, 19, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    _clubhouseLine(community),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFE4B4),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    community.name,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 13),
                  FilledButton(
                    onPressed: () => _toggleJoin(community),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD0A456),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 39,
                        vertical: 13,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(joinedAlready ? 'Joined' : 'Join'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _clubhouseLine(_Community community) {
    if (community.id == 'women') return 'A STRONGER YOU TOGETHER';
    if (community.id == 'men') return 'HONEST TALK. REAL SUPPORT.';
    if (community.id == 'relationships') return 'GROW TOGETHER';
    if (community.id == 'faith') return 'GROW IN FAITH. TOGETHER.';
    return 'A PLACE TO BELONG';
  }

  Widget _pagerDots(int count) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          count.clamp(0, 5).toInt(),
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == featuredIndex ? 8 : 7,
            height: index == featuredIndex ? 8 : 7,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: index == featuredIndex ? gold : const Color(0xFFE1DDD2),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

  Widget _quickSpaces(List<_Community> communities) => SizedBox(
        height: 78,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 19),
          scrollDirection: Axis.horizontal,
          itemCount: categoryGroups.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, index) {
            final group = categoryGroups[index];
            return InkWell(
              onTap: () => _showCategory(group, communities),
              borderRadius: BorderRadius.circular(40),
              child: SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: paleColor(group.name),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _groupIcon(group.id),
                        color: sage,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

  IconData _groupIcon(String id) {
    return switch (id) {
      'women' => Icons.groups_2_outlined,
      'men' => Icons.people_alt_outlined,
      'parenting' => Icons.family_restroom_outlined,
      'wellness' => Icons.spa_outlined,
      'new_start' => Icons.auto_awesome_outlined,
      'faith' => Icons.volunteer_activism_outlined,
      _ => Icons.groups_2_outlined,
    };
  }

  void _showCategory(_CommunityGroup group, List<_Community> all) {
    final spaces = <_Community>[
      for (final id in group.communityIds)
        ...all.where((community) => community.id == id),
    ];
    showModalBottomSheet<void>(
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
              Text(
                group.name,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Choose a community that fits what you need today.',
                style: TextStyle(color: Color(0xFF626A63)),
              ),
              const SizedBox(height: 12),
              for (final community in spaces)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: paleColor(community.category),
                    child: Icon(_spaceIcon(community.id), color: sage),
                  ),
                  title: Text(
                    community.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    community.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: sage),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _open(community);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _spaceIcon(String id) {
    return switch (id) {
      'women' => Icons.groups_2_outlined,
      'men' => Icons.people_alt_outlined,
      'relationships' => Icons.favorite_border_rounded,
      'moms' => Icons.family_restroom_outlined,
      'wellness' => Icons.spa_outlined,
      'new_beginnings' => Icons.auto_awesome_outlined,
      'faith' => Icons.volunteer_activism_outlined,
      _ => Icons.groups_2_outlined,
    };
  }

  Widget _sectionHeading(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF626A63))),
        ],
      );

  Widget _joinFirstCard() => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: const Color(0xFFE8EBDD), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(width: 43, height: 43, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.groups_2_outlined, color: sage)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Your spaces will live here.', style: TextStyle(fontWeight: FontWeight.w900)),
            SizedBox(height: 3),
            Text('Join a community below to make this feel like home.', style: TextStyle(fontSize: 12, color: Color(0xFF626A63))),
          ])),
        ]),
      );

  Widget _yourSpaces(List<_Community> items) => SizedBox(
        height: 170,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 11),
          itemBuilder: (context, index) => _yourSpaceCard(items[index]),
        ),
      );

  Widget _yourSpaceCard(_Community community) {
    final count = memberCounts[community.id] ?? 0;
    return InkWell(
      onTap: () => _open(community),
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 232,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(fit: StackFit.expand, children: [
            community.imageUrl.isEmpty ? _fallback() : Image.network(community.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stack) => _fallback()),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x12000000), Color(0xE7000000)]))),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)), child: const Text('Your space', style: TextStyle(color: sage, fontSize: 10, fontWeight: FontWeight.w900))),
                const Spacer(),
                Text(community.name, style: GoogleFonts.playfairDisplay(fontSize: 23, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(count == 0 ? 'Start the conversation' : count.toString() + ' members', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _exploreCard(_Community community) {
    final joinedAlready = joined.contains(community.id);
    final count = memberCounts[community.id] ?? 0;
    return InkWell(
      onTap: () => _open(community),
      borderRadius: BorderRadius.circular(19),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: paleColor(community.category), borderRadius: BorderRadius.circular(15)),
            child: Text(community.name.substring(0, 1).toUpperCase(), style: GoogleFonts.playfairDisplay(color: sage, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(community.name, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 2),
            Text(community.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF626A63))),
            const SizedBox(height: 7),
            Text(count == 0 ? 'New community' : count.toString() + ' members', style: const TextStyle(fontSize: 10.5, color: sage, fontWeight: FontWeight.w800)),
          ])),
          const SizedBox(width: 5),
          TextButton(
            onPressed: () => _toggleJoin(community),
            child: Text(joinedAlready ? 'Joined' : 'Join'),
          ),
        ]),
      ),
    );
  }

  Color paleColor(String category) {
    if (category == 'Men') return const Color(0xFFE4EDF1);
    if (category == 'Parenting') return const Color(0xFFFFEBD8);
    if (category == 'Mental Health') return const Color(0xFFE9EEE4);
    if (category == 'Grief') return const Color(0xFFEFE8EE);
    if (category == 'Faith') return const Color(0xFFF0E8D5);
    return const Color(0xFFF5EAD6);
  }

  Widget _upcomingStrip() => InkWell(
        onTap: () => setState(() => selected = 2),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(color: sage, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const Icon(Icons.calendar_month_outlined, color: Color(0xFFFFE4B4), size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Upcoming in the Village', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('See conversations and events happening in your community.', style: TextStyle(color: Color(0xFFE8F0E5), fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ]),
        ),
      );

  List<_Community> _merge(List<ManagedContentItem> managed) {
    final overrides = <String, ManagedContentItem>{};
    final custom = <_Community>[];
    for (final item in managed) {
      final builtinId = item.text('builtinId');
      if (builtinId.isNotEmpty) {
        overrides[builtinId] = item;
      } else {
        final name = item.text('name', item.text('title', 'Community'));
        custom.add(_Community('admin_${item.id}', name, item.text('description', 'A place to connect in the Village.'), item.text('category', name), item.text('imageUrl')));
      }
    }
    return [
      ...builtIns.map((base) {
        final override = overrides[base.id];
        if (override == null) return base;
        return _Community(base.id, override.text('name', base.name), override.text('description', base.description), override.text('category', base.category), override.text('imageUrl', base.imageUrl));
      }),
      ...custom,
    ];
  }

  List<_Community> _filter(List<_Community> items) {
    final filtered = query.isEmpty
        ? [...items]
        : items.where((c) => '${c.name} ${c.category} ${c.description}'.toLowerCase().contains(query)).toList();
    int priority(_Community community) {
      if (personalization.isMan && community.id == 'men') return 0;
      if (personalization.isWoman && community.id == 'women') return 0;
      final searchable = '${community.name} ${community.category}'.toLowerCase();
      if (personalization.interests.any((interest) => searchable.contains(interest.toLowerCase()))) return 1;
      return 2;
    }
    filtered.sort((a, b) => priority(a).compareTo(priority(b)));
    return filtered;
  }

  Widget _communityStream() {
    if (!admin.cloudReady) return _twoRows(_filter(builtIns));
    return StreamBuilder<List<ManagedContentItem>>(
      stream: admin.watchPublished('communities'),
      builder: (context, snapshot) => _twoRows(_filter(_merge(snapshot.data ?? const <ManagedContentItem>[]))),
    );
  }

  Widget _twoRows(List<_Community> items) {
    if (items.isEmpty) return Container(padding: const EdgeInsets.all(18), child: const Text('No communities found. Try another search.'));
    return SizedBox(
      height: 304,
      child: GridView.builder(
        scrollDirection: Axis.horizontal,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .9),
        itemCount: items.length,
        itemBuilder: (context, index) => _communityCard(items[index]),
      ),
    );
  }

  Widget _communityCard(_Community community) {
    final count = memberCounts[community.id] ?? 0;
    final isJoined = joined.contains(community.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          community.imageUrl.isEmpty ? _fallback() : Image.network(community.imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stack) => _fallback()),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x16000000), Color(0xD8000000)]))),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Align(alignment: Alignment.topRight, child: InkWell(onTap: () => _toggleJoin(community), child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Text(isJoined ? 'Joined' : 'Join', style: const TextStyle(color: sage, fontSize: 9, fontWeight: FontWeight.w800))))),
              const Spacer(),
              Text(community.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(community.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 9, height: 1.15)),
              const SizedBox(height: 4),
              Text('$count ${count == 1 ? 'member' : 'members'}', style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              InkWell(onTap: () => _open(community), child: const Text('Enter community →', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800))),
            ]),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleJoin(_Community community) async {
    final joining = !joined.contains(community.id);
    setState(() {
      if (joining) { joined.add(community.id); } else { joined.remove(community.id); }
      memberCounts[community.id] = ((memberCounts[community.id] ?? 0) + (joining ? 1 : -1)).clamp(0, 999999).toInt();
    });
    await hub.saveJoinedCommunities(joined);
    await hub.setCommunityMembership(community.id, joining);
  }

  void _open(_Community community) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityDetailScreen(id: community.id, name: community.name, description: community.description, category: community.category, imageUrl: community.imageUrl)));
  }

  void _showAll() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => StreamBuilder<List<ManagedContentItem>>(
        stream: admin.cloudReady ? admin.watchPublished('communities') : const Stream<List<ManagedContentItem>>.empty(),
        builder: (context, snapshot) {
          final all = admin.cloudReady ? _merge(snapshot.data ?? const <ManagedContentItem>[]) : builtIns;
          return SizedBox(height: MediaQuery.sizeOf(context).height * .82, child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('All Communities', style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 4), Text('${all.length} spaces to find your people'), const SizedBox(height: 12), Expanded(child: ListView.separated(itemCount: all.length, separatorBuilder: (context, index) => const Divider(color: line), itemBuilder: (context, index) { final c = all[index]; return ListTile(contentPadding: EdgeInsets.zero, title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(c.description, maxLines: 2, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right_rounded, color: sage), onTap: () { Navigator.pop(sheetContext); _open(c); }); }))])));
        },
      ),
    );
  }

  Widget _managedList(String type, String title, IconData icon) {
    if (!admin.cloudReady) return Center(child: Text(title));
    return StreamBuilder<List<ManagedContentItem>>(
      stream: admin.watchPublished(type),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <ManagedContentItem>[];
        return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 32), children: [Text(title, style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 14), if (items.isEmpty) Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)), child: const Text('More Village content is coming soon.')), for (final item in items) Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: line)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: sage), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.text('title', item.text('name', 'Village')), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 4), Text(item.text('description', item.text('body', '')), maxLines: 5, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12.5, height: 1.4))]))]))]);
      },
    );
  }

  Widget _fallback() => Container(color: sage, child: const Center(child: Icon(Icons.groups_2_outlined, color: Colors.white, size: 34)));
}

class _CommunityGroup {
  const _CommunityGroup(this.id, this.name, this.communityIds);
  final String id;
  final String name;
  final List<String> communityIds;
}

class _Community {
  const _Community(this.id, this.name, this.description, this.category, this.imageUrl);
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
}
