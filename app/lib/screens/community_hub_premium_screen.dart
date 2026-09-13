import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';
import '../services/community_hub_service.dart';
import '../services/village_post_service.dart';
import 'ask_village_screen.dart';
import 'community_detail_screen.dart';
import 'village_feed_screen.dart';

class CommunityHubPremiumScreen extends StatefulWidget {
  const CommunityHubPremiumScreen({super.key});

  @override
  State<CommunityHubPremiumScreen> createState() => _CommunityHubPremiumScreenState();
}

class _CommunityHubPremiumScreenState extends State<CommunityHubPremiumScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const gold = Color(0xFFB78943);
  static const line = Color(0xFFE7DED1);
  static const blush = Color(0xFFF3E2DD);

  final CommunityHubService service = CommunityHubService();
  final VillagePostService postService = VillagePostService();
  final AdminContentService adminService = AdminContentService();

  int selected = 0;
  Set<String> joined = {};
  Set<String> savedResources = {};
  Set<String> registeredEvents = {};
  Map<String, int> memberCounts = {};
  List<VillagePost> posts = [];
  bool loading = true;

  static const communities = <_Community>[
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

  static const resources = <_Resource>[
    _Resource('repair', 'Relationships', 'Repair after a hard argument', 'A practical guide to cooling down, taking responsibility, listening well, and choosing one next step.', '6 min read'),
    _Resource('support', 'Friendship', 'Support someone without trying to fix them', 'Learn how to listen, ask what kind of help is wanted, and follow up in a way that feels caring instead of controlling.', '5 min read'),
    _Resource('grounding', 'Wellness', 'A five-minute grounding reset', 'A simple body-and-senses reset for moments when your thoughts feel fast or the day feels too loud.', '5 min read'),
    _Resource('boundary', 'Life & Growth', 'The boundary check-in', 'Identify the pattern, separate a request from a boundary, and choose a limit you can actually maintain.', '7 min read'),
    _Resource('parenting', 'Moms', 'A calmer reset for hard parenting moments', 'Regulate first, use fewer words, hold the limit clearly, and reconnect after the hard moment.', '6 min read'),
    _Resource('career', 'Career & Purpose', 'A practical career reset', 'Name what is actually stuck and choose one move that creates useful information about what comes next.', '8 min read'),
  ];

  static const events = <_VillageEvent>[
    _VillageEvent('communication', 'Couples Communication Night', 'Relationships', 'Virtual', 'Coming soon', 'A guided conversation on feeling heard, repairing conflict, and reconnecting.'),
    _VillageEvent('moms-coffee', 'New Mom Coffee Chat', 'Moms', 'Virtual', 'Coming soon', 'A low-pressure space for honest conversation about motherhood, identity, and support.'),
    _VillageEvent('starting-over', 'Starting Over Circle', 'New Beginnings', 'Virtual', 'Coming soon', 'For people navigating a new chapter, big transition, or fresh start.'),
    _VillageEvent('career-reset', 'Career Reset Workshop', 'Career & Purpose', 'Virtual', 'Coming soon', 'Clarify what feels stuck and leave with one realistic next step.'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        service.joinedCommunities(), service.savedResources(), service.registeredEvents(),
        service.memberCounts(communities.map((item) => item.id)), postService.load(),
      ]);
      if (!mounted) return;
      setState(() {
        joined = values[0] as Set<String>;
        savedResources = values[1] as Set<String>;
        registeredEvents = values[2] as Set<String>;
        memberCounts = values[3] as Map<String, int>;
        posts = values[4] as List<VillagePost>;
        loading = false;
      });
    } on Object {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggleJoin(_Community community) async {
    final joining = !joined.contains(community.id);
    setState(() {
      joining ? joined.add(community.id) : joined.remove(community.id);
      memberCounts[community.id] = ((memberCounts[community.id] ?? 0) + (joining ? 1 : -1)).clamp(0, 999999).toInt();
    });
    await service.saveJoinedCommunities(joined);
    await service.setCommunityMembership(community.id, joining);
  }

  Future<void> _toggleResource(_Resource resource) async {
    setState(() => savedResources.contains(resource.id) ? savedResources.remove(resource.id) : savedResources.add(resource.id));
    await service.saveResources(savedResources);
  }

  Future<void> _toggleEvent(_VillageEvent event) async {
    setState(() => registeredEvents.contains(event.id) ? registeredEvents.remove(event.id) : registeredEvents.add(event.id));
    await service.saveRegisteredEvents(registeredEvents);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        bottom: false,
        child: loading ? const Center(child: CircularProgressIndicator(color: sage)) : Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 10), child: Column(children: [
            Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('COMMUNITY HUB', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.6, color: gold)),
              const SizedBox(height: 4), Text('Find your people.', style: GoogleFonts.playfairDisplay(fontSize: 32, fontWeight: FontWeight.w700, color: ink)),
            ])), Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.diversity_3_outlined, color: sage))]),
            const SizedBox(height: 16), _tabs(),
          ])),
          Expanded(child: IndexedStack(index: selected, children: [_communities(), _resources(), _events()])),
        ]),
      ),
    );
  }

  Widget _tabs() {
    const labels = [('Communities', Icons.groups_2_outlined), ('Resources', Icons.menu_book_outlined), ('Events', Icons.calendar_month_outlined)];
    return Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(18), border: Border.all(color: line)), child: Row(children: List.generate(labels.length, (index) {
      final active = selected == index;
      return Expanded(child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () => setState(() => selected = index), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(14)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(labels[index].$2, size: 18, color: active ? sage : ink), const SizedBox(width: 6), Text(labels[index].$1, style: GoogleFonts.inter(fontSize: 12, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? sage : ink))]))));
    })));
  }

  Widget _communities() {
    final trending = [...posts]..sort((a, b) => (b.replies.length * 3 + b.supportCount).compareTo(a.replies.length * 3 + a.supportCount));
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
      TextField(readOnly: true, onTap: _showJourneyPicker, decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded, color: sage), hintText: 'What are you going through?', suffixIcon: const Icon(Icons.tune_rounded), filled: true, fillColor: Colors.white.withValues(alpha: .72), border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: line)))),
      const SizedBox(height: 20), _sectionTitle('Explore communities', 'Real spaces for real life'), const SizedBox(height: 12),
      _exploreCommunities(),
      const SizedBox(height: 24), _sectionTitle('Happening in the Village', 'Join the conversation'), const SizedBox(height: 10),
      if (trending.isEmpty) _softCard('The first brave question starts the conversation.', 'As people post, the most active discussions will surface here.') else _conversationCard(trending.first),
      const SizedBox(height: 22), _someoneCard(),
    ]);
  }

  Widget _exploreCommunities() {
    if (!adminService.cloudReady) return _communityScroller(communities);
    return StreamBuilder<List<ManagedContentItem>>(
      stream: adminService.watchPublished('communities'),
      builder: (context, snapshot) {
        final managed = (snapshot.data ?? const <ManagedContentItem>[]).map((item) {
          final name = item.text('name', item.text('title', 'Community'));
          return _Community('admin_${item.id}', name, item.text('description', 'A place to connect in the Village.'), item.text('category', name), item.text('imageUrl'));
        }).toList();
        return _communityScroller([...communities, ...managed]);
      },
    );
  }

  Widget _communityScroller(List<_Community> items) => SizedBox(height: 228, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: items.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, index) => _photoCard(items[index])));

  Widget _photoCard(_Community community) {
    final count = memberCounts[community.id] ?? 0;
    final isJoined = joined.contains(community.id);
    return SizedBox(width: 190, child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(fit: StackFit.expand, children: [
      community.imageUrl.isEmpty ? _fallbackCover() : Image.network(community.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackCover()),
      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x12000000), Color(0xC9000000)], stops: [0.35, 1]))),
      Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(alignment: Alignment.topRight, child: InkWell(onTap: () => _toggleJoin(community), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(20)), child: Text(isJoined ? 'Joined' : 'Join', style: const TextStyle(color: sage, fontSize: 11, fontWeight: FontWeight.w800))))),
        const Spacer(), Text(community.name, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
        Text(community.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11.5, height: 1.3)), const SizedBox(height: 7),
        Row(children: [const Icon(Icons.people_outline_rounded, size: 14, color: Colors.white), const SizedBox(width: 4), Text('$count ${count == 1 ? 'member' : 'members'}', style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700))]), const SizedBox(height: 8),
        InkWell(onTap: () => _openCommunity(community), child: const Row(children: [Text('Enter community', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)), SizedBox(width: 4), Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white)])),
      ])),
    ])));
  }

  Widget _fallbackCover() => Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF355C3B), Color(0xFF6F876B)])), child: const Center(child: Icon(Icons.groups_2_outlined, color: Colors.white, size: 42)));

  Widget _resources() => ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
    _sectionTitle('Resource Library', 'Useful enough to come back to'), const SizedBox(height: 6),
    Text('Practical guides for relationships, wellness, motherhood, friendship, work, and life transitions.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6E746D), height: 1.45)), const SizedBox(height: 16),
    for (final resource in resources) ...[_resourceCard(resource), const SizedBox(height: 12)],
  ]);

  Widget _resourceCard(_Resource resource) {
    final saved = savedResources.contains(resource.id);
    return Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(22), border: Border.all(color: line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: blush, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.auto_stories_outlined, color: sage)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(resource.category.toUpperCase(), style: const TextStyle(color: gold, fontSize: 9.5, fontWeight: FontWeight.w900)), Text(resource.title, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: ink))])), IconButton(onPressed: () => _toggleResource(resource), icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: sage))]),
      const SizedBox(height: 10), Text(resource.summary, style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: const Color(0xFF545B55))), const SizedBox(height: 10), Row(children: [Text(resource.readTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sage)), const Spacer(), TextButton(onPressed: () => _showResource(resource), child: const Text('Read guide'))]),
    ]));
  }

  Widget _events() => ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 32), children: [
    _sectionTitle('Happening in the Village', 'Gather, learn, connect'), const SizedBox(height: 6),
    Text('Virtual and community-led events will live here, with RSVP and reminders in one place.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6E746D), height: 1.45)), const SizedBox(height: 16),
    for (final event in events) ...[_eventCard(event), const SizedBox(height: 12)],
  ]);

  Widget _eventCard(_VillageEvent event) {
    final registered = registeredEvents.contains(event.id);
    return Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .74), borderRadius: BorderRadius.circular(22), border: Border.all(color: line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(20)), child: Text(event.format, style: const TextStyle(color: sage, fontSize: 10, fontWeight: FontWeight.w800))), const SizedBox(width: 8), Text(event.community, style: const TextStyle(color: gold, fontSize: 10.5, fontWeight: FontWeight.w800)), const Spacer(), const Icon(Icons.calendar_month_outlined, color: sage)]),
      const SizedBox(height: 12), Text(event.title, style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 5), Text(event.description, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF5C635D), height: 1.45)), const SizedBox(height: 12),
      Row(children: [Text(event.schedule, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: sage)), const Spacer(), FilledButton(onPressed: () => _toggleEvent(event), style: FilledButton.styleFrom(backgroundColor: registered ? const Color(0xFFE9EEE4) : sage, foregroundColor: registered ? sage : Colors.white), child: Text(registered ? 'Following' : 'Notify Me'))]),
    ]));
  }

  Widget _conversationCard(VillagePost post) => InkWell(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VillageFeedScreen(initialSearch: post.question))), child: _softCard(post.question, '${post.replies.length} replies • ${post.supportCount} helpful'));

  Widget _someoneCard() => InkWell(onTap: _showJourneyPicker, borderRadius: BorderRadius.circular(24), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF2F5135), Color(0xFF496B4F)]), borderRadius: BorderRadius.circular(24)), child: Row(children: [const Icon(Icons.favorite_outline_rounded, color: Colors.white, size: 30), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('I need someone who gets it', style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 4), const Text('Tell us what you are walking through and we will point you toward the right corner of the Village.', style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.35))])), const Icon(Icons.arrow_forward_rounded, color: Colors.white)])));

  Widget _softCard(String title, String body) => Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(22), border: Border.all(color: line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.playfairDisplay(fontSize: 19, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 5), Text(body, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF666C66), height: 1.4))]));
  Widget _sectionTitle(String title, String note) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ink))), Text(note, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: gold))]);

  void _openCommunity(_Community community) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CommunityDetailScreen(
        id: community.id,
        name: community.name,
        description: community.description,
        category: community.category,
        imageUrl: community.imageUrl,
      ),
    )).then((_) => _load());
  }

  void _showJourneyPicker() {
    showModalBottomSheet<void>(context: context, backgroundColor: cream, showDragHandle: true, builder: (sheetContext) => StreamBuilder<List<ManagedContentItem>>(
      stream: adminService.cloudReady ? adminService.watchPublished('communities') : const Stream<List<ManagedContentItem>>.empty(),
      builder: (_, snapshot) {
        final managed = (snapshot.data ?? const <ManagedContentItem>[]).map((item) => _Community('admin_${item.id}', item.text('name', item.text('title', 'Community')), item.text('description', 'A place to connect in the Village.'), item.text('category', item.text('name', 'Community')), item.text('imageUrl'))).toList();
        final all = [...communities, ...managed];
        return SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('What are you going through?', style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 16), Wrap(spacing: 8, runSpacing: 8, children: all.map((community) => ActionChip(label: Text(community.name), onPressed: () { Navigator.pop(sheetContext); _openCommunity(community); })).toList())])));
      },
    ));
  }

  void _showResource(_Resource resource) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, backgroundColor: cream, showDragHandle: true, builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 30), child: ListView(shrinkWrap: true, children: [Text(resource.category.toUpperCase(), style: const TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(resource.title, style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 8), Text(resource.readTime, style: const TextStyle(color: sage, fontWeight: FontWeight.w800)), const SizedBox(height: 18), Text(resource.summary, style: GoogleFonts.inter(fontSize: 15, height: 1.6, color: ink)), const SizedBox(height: 20), FilledButton.icon(onPressed: () => _toggleResource(resource), style: FilledButton.styleFrom(backgroundColor: sage), icon: Icon(savedResources.contains(resource.id) ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined), label: Text(savedResources.contains(resource.id) ? 'Remove from Saved' : 'Save Resource'))])));
  }
}

class _Community {
  const _Community(this.id, this.name, this.description, this.category, this.imageUrl);
  final String id; final String name; final String description; final String category; final String imageUrl;
}
class _Resource {
  const _Resource(this.id, this.category, this.title, this.summary, this.readTime);
  final String id; final String category; final String title; final String summary; final String readTime;
}
class _VillageEvent {
  const _VillageEvent(this.id, this.title, this.community, this.format, this.schedule, this.description);
  final String id; final String title; final String community; final String format; final String schedule; final String description;
}
