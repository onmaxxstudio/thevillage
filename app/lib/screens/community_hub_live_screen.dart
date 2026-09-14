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

  int selected = 0;
  String query = '';
  Set<String> joined = {};
  Map<String, int> memberCounts = {};
  VillagePersonalization personalization = const VillagePersonalization.empty();

  static const builtIns = <_Community>[
    _Community('men', 'Men', 'Honest advice about relationships, fatherhood, purpose, friendship, pressure, and emotional wellbeing.', 'Men', 'https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&w=1200&q=85'),
    _Community('relationships', 'Relationships', 'For the conversations you cannot always have with people you know.', 'Relationships', 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?auto=format&fit=crop&w=1200&q=85'),
    _Community('women', 'Women', 'Support, perspective, and connection through every season of womanhood.', 'Life & Growth', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=85'),
    _Community('moms', 'Moms', 'Real talk and practical support for motherhood.', 'Parenting', 'https://images.unsplash.com/photo-1543342386-1f1350e27861?auto=format&fit=crop&w=1200&q=85'),
    _Community('friendship', 'Friendship', 'Navigate closeness, change, conflict, and connection.', 'Friendship', 'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?auto=format&fit=crop&w=1200&q=85'),
    _Community('wellness', 'Wellness', 'Gentle support for emotional and everyday wellbeing.', 'Mental Health', 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?auto=format&fit=crop&w=1200&q=85'),
    _Community('career', 'Career & Purpose', 'Work, confidence, growth, and your next move.', 'Work & School', 'https://images.unsplash.com/photo-1521737711867-e3b97375f902?auto=format&fit=crop&w=1200&q=85'),
    _Community('grief', 'Grief & Healing', 'A softer place for loss, remembrance, and healing.', 'Grief', 'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=85'),
    _Community('new_beginnings', 'New Beginnings', 'Moves, endings, transitions, and fresh starts.', 'Life & Growth', 'https://images.unsplash.com/photo-1500534623283-312aade485b7?auto=format&fit=crop&w=1200&q=85'),
    _Community('caregivers', 'Caregivers', 'Care and understanding for people who care for others.', 'Practical help', 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=1200&q=85'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMemberships();
  }

  @override
  void dispose() {
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COMMUNITY HUB', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: gold)),
                            const SizedBox(height: 4),
                            Text('Find your people.', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: ink)),
                          ],
                        ),
                      ),
                      Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.diversity_3_outlined, color: sage)),
                    ],
                  ),
                  const SizedBox(height: 16),
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

  Widget _tabs() {
    const labels = [('Communities', Icons.groups_2_outlined), ('Resources', Icons.menu_book_outlined), ('Events', Icons.calendar_month_outlined)];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(18), border: Border.all(color: line)),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => selected = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(labels[index].$2, size: 18, color: active ? sage : ink), const SizedBox(width: 6), Text(labels[index].$1, style: GoogleFonts.inter(fontSize: 12, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? sage : ink))]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _communities() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(children: [Expanded(child: Text('Explore communities', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ink))), TextButton(onPressed: _showAll, child: const Text('See All →'))]),
        const SizedBox(height: 8),
        TextField(
          controller: searchController,
          onChanged: (value) => setState(() => query = value.trim().toLowerCase()),
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded, color: sage), hintText: 'Search communities', suffixIcon: query.isEmpty ? null : IconButton(onPressed: () { searchController.clear(); setState(() => query = ''); }, icon: const Icon(Icons.close_rounded)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: line))),
        ),
        const SizedBox(height: 14),
        _communityStream(),
        const SizedBox(height: 20),
        Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Happening in the Village', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 5), Text('Join a community to ask questions, share support, and find resources made for what you are going through.', style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: const Color(0xFF666C66)))])),
      ],
    );
  }

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

class _Community {
  const _Community(this.id, this.name, this.description, this.category, this.imageUrl);
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
}
