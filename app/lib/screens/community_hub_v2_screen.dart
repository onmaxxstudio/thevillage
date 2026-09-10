import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/community_hub_service.dart';
import '../services/village_post_service.dart';
import 'ask_village_screen.dart';

class CommunityHubV2Screen extends StatefulWidget {
  const CommunityHubV2Screen({super.key});

  @override
  State<CommunityHubV2Screen> createState() => _CommunityHubV2ScreenState();
}

class _CommunityHubV2ScreenState extends State<CommunityHubV2Screen> {
  static const cream = Color(0xFFFFFAF1);
  static const paper = Color(0xFFFFFDF8);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE9EEE4);
  static const gold = Color(0xFFB78943);
  static const ink = Color(0xFF172019);
  static const muted = Color(0xFF6E746D);
  static const line = Color(0xFFE7DED1);
  static const blush = Color(0xFFF3E2DD);

  final CommunityHubService _service = CommunityHubService();
  final VillagePostService _postService = VillagePostService();

  Set<String> joined = {};
  Set<String> usedSuggestions = {};
  Map<String, int> memberCounts = {};
  List<VillagePost> posts = [];
  bool loading = true;

  static const communities = <_Community>[
    _Community('relationships', 'Relationships', 'Healthier communication, connection, and boundaries.', Icons.favorite_border_rounded, Color(0xFFE8D8CB), 'Relationships', ['What helps you feel heard during a hard conversation?', 'What small act helps you feel connected when life gets busy?', 'Which boundary are you learning to protect?']),
    _Community('women', 'Women', 'A supportive space for every season of womanhood.', Icons.woman_2_outlined, Color(0xFFF1DED8), 'Life & Growth', ['What are you learning about yourself lately?', 'What support would make this week feel lighter?', 'What part of yourself are you reconnecting with?']),
    _Community('moms', 'Moms', 'Real talk, practical help, and encouragement for moms.', Icons.child_care_outlined, Color(0xFFFFE7BE), 'Parenting', ['What parenting season are you in right now?', 'What routine makes home life easier?', 'What about motherhood do you wish people discussed more?']),
    _Community('friendship', 'Friendship', 'Build stronger friendships and navigate changing ones.', Icons.people_outline_rounded, Color(0xFFF2E4D4), 'Friendship', ['What makes you feel valued in a friendship?', 'How do you reconnect after growing apart?', 'How do you know when a friendship has run its course?']),
    _Community('wellness', 'Wellness', 'Gentle support for emotional and everyday wellbeing.', Icons.spa_outlined, Color(0xFFDDE7D7), 'Mental Health', ['What does rest look like for you this week?', 'What habit helps you feel grounded?', 'What are you ready to release?']),
    _Community('career', 'Career & Purpose', 'Support for work, goals, confidence, and your next move.', Icons.work_outline_rounded, Color(0xFFE6E2D5), 'Work & School', ['What professional goal are you working toward?', 'Where do you need more confidence at work?', 'What would a meaningful next step look like?']),
    _Community('grief', 'Grief & Healing', 'A gentle space for loss, remembrance, and healing.', Icons.eco_outlined, Color(0xFFDDE6DF), 'Grief', ['What do you wish people understood about your grief?', 'Is there a memory you want to share today?', 'What has brought even a small amount of comfort?']),
    _Community('new_beginnings', 'New Beginnings', 'Support through moves, transitions, endings, and fresh starts.', Icons.wb_sunny_outlined, Color(0xFFFFE9CB), 'Life & Growth', ['What new chapter are you stepping into?', 'What are you leaving behind?', 'What would make this transition feel less lonely?']),
    _Community('caregivers', 'Caregivers', 'Care, resources, and understanding for people who give care.', Icons.health_and_safety_outlined, Color(0xFFE3EAD7), 'Practical help', ['What part of caregiving feels heaviest right now?', 'Where could you accept help this week?', 'What do you wish others understood about caregiving?']),
  ];

  static const resources = <_Resource>[
    _Resource('repair', 'How to repair after a bad argument', 'Relationships', '6 min read', Icons.forum_outlined, ['relationships'], 'Repair starts by lowering the temperature and naming what happened without building a case against the other person. Take responsibility for your part, ask what landed badly, and reflect back what you heard before defending your intent. Agree on one small change for the next similar moment. If either person is still flooded, pause with a specific return time so the pause does not feel like abandonment.'),
    _Resource('support', 'How to support someone without trying to fix them', 'Friendship', '5 min read', Icons.volunteer_activism_outlined, ['friendship', 'women'], 'Ask what kind of support is wanted before jumping into solutions. Listening, advice, encouragement, distraction, and practical help are different needs. Reflect the feeling you hear, offer specific help you can actually follow through on, and check back after the urgent moment passes. Consistency is often more supportive than one perfect conversation.'),
    _Resource('grounding', 'A five-minute grounding reset', 'Wellness', '5 min read', Icons.spa_outlined, ['wellness', 'grief', 'caregivers', 'new_beginnings'], 'Put both feet down and notice the support under your body. Take five easy breaths with a slightly longer exhale. Name five things you can see, four things you can feel, three sounds, two scents, and one comforting thought. Finish by choosing one caring action that takes less than ten minutes.'),
    _Resource('boundary', 'The boundary check-in', 'Life & Growth', '7 min read', Icons.shield_outlined, ['women', 'career', 'relationships'], 'A boundary describes what you will do to protect your wellbeing, time, safety, or values. Identify the repeated pattern, separate your request from your boundary, choose a limit you can realistically maintain, and communicate it simply. Follow through calmly and review whether the boundary is protecting what it was meant to protect.'),
    _Resource('parenting', 'A calmer reset for hard parenting moments', 'Moms', '6 min read', Icons.child_care_outlined, ['moms'], 'Begin with safety, then regulate yourself before trying to teach. Use fewer words while emotions are high. Describe what you see without labeling the child, hold the limit in one clear sentence, offer one manageable choice, and reconnect after the storm. Repair matters more than pretending parents never struggle.'),
    _Resource('career', 'A practical career reset when you feel stuck', 'Career & Purpose', '8 min read', Icons.route_outlined, ['career', 'new_beginnings'], 'Name what is actually stuck: the role, manager, pay, environment, confidence, or direction. Separate what needs to change now from what can be explored over time. Pick one move that creates information, such as talking to someone in a role you want, updating one section of your resume, or applying to one position that stretches you.'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        _service.joinedCommunities(),
        _service.usedSuggestedQuestions(),
        _service.memberCounts(communities.map((community) => community.id)),
        _postService.load(),
      ]);
      if (!mounted) return;
      setState(() {
        joined = values[0] as Set<String>;
        usedSuggestions = values[1] as Set<String>;
        memberCounts = values[2] as Map<String, int>;
        posts = values[3] as List<VillagePost>;
        loading = false;
      });
    } on Object {
      if (mounted) setState(() => loading = false);
    }
  }

  List<VillagePost> _postsFor(_Community community) {
    final result = posts.where((post) => post.communityId == community.id || (post.communityId == null && post.category == community.category)).toList();
    result.sort((a, b) => (b.replies.length * 3 + b.supportCount).compareTo(a.replies.length * 3 + a.supportCount));
    return result;
  }

  Future<void> _toggleJoin(_Community community) async {
    final joining = !joined.contains(community.id);
    setState(() {
      joining ? joined.add(community.id) : joined.remove(community.id);
      memberCounts[community.id] = ((memberCounts[community.id] ?? 0) + (joining ? 1 : -1)).clamp(0, 999999);
    });
    await _service.saveJoinedCommunities(joined);
    await _service.setCommunityMembership(community.id, joining);
  }

  Future<void> _ask(_Community community, String prompt) async {
    final suggestionId = '${community.id}.${community.prompts.indexOf(prompt)}';
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => AskVillageScreen(
      initialQuestion: prompt,
      initialCategory: community.category,
      initialCommunityId: community.id,
      initialCommunityName: community.name,
      suggestionId: suggestionId,
      onSuggestedQuestionPosted: (id) async {
        await _service.markSuggestedQuestionUsed(id);
        if (mounted) setState(() => usedSuggestions.add(id));
      },
    )));
    await _load();
  }

  void _openCommunity(_Community community) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => _CommunityPage(
      community: community,
      memberCount: memberCounts[community.id] ?? 0,
      joined: joined.contains(community.id),
      posts: _postsFor(community),
      prompts: [for (var i = 0; i < community.prompts.length; i++) if (!usedSuggestions.contains('${community.id}.$i')) community.prompts[i]],
      resources: resources.where((resource) => resource.communityIds.contains(community.id)).toList(),
      onJoin: () => _toggleJoin(community),
      onAsk: (prompt) => _ask(community, prompt),
    ))).then((value) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final joinedCommunities = communities.where((community) => joined.contains(community.id)).toList();
    final trending = [...posts]..sort((a, b) => (b.replies.length * 3 + b.supportCount).compareTo(a.replies.length * 3 + a.supportCount));
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        bottom: false,
        child: loading
            ? const Center(child: CircularProgressIndicator(color: sage))
            : RefreshIndicator(
                color: sage,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                  children: [
                    Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('COMMUNITY HUB', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.7, color: gold)), const SizedBox(height: 5), Text('Find your people.', style: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.w700, color: ink))])), Container(width: 44, height: 44, decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.diversity_3_outlined, color: sage))]),
                    const SizedBox(height: 22),
                    _HeroCard(onTap: _showJourneyPicker),
                    if (joinedCommunities.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _heading('Your communities', '${joinedCommunities.length} joined'),
                      const SizedBox(height: 12),
                      SizedBox(height: 120, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: joinedCommunities.length, separatorBuilder: (context, index) => const SizedBox(width: 12), itemBuilder: (context, index) { final community = joinedCommunities[index]; return _JoinedCard(community: community, count: memberCounts[community.id] ?? 0, onTap: () => _openCommunity(community)); })),
                    ],
                    const SizedBox(height: 28),
                    _heading('Happening now', 'Village is talking'),
                    const SizedBox(height: 12),
                    trending.isEmpty ? _emptyCard() : _TrendingCard(post: trending.first),
                    const SizedBox(height: 28),
                    _heading('Explore communities', 'Choose your spaces'),
                    const SizedBox(height: 12),
                    GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: communities.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.08), itemBuilder: (context, index) { final community = communities[index]; return _ExploreCard(community: community, joined: joined.contains(community.id), count: memberCounts[community.id] ?? 0, onTap: () => _openCommunity(community)); }),
                    const SizedBox(height: 28),
                    _heading('You might need this today', 'Useful, not filler'),
                    const SizedBox(height: 12),
                    _ResourceCard(resource: _featuredResource(joinedCommunities), onTap: _openResource),
                    const SizedBox(height: 28),
                    _QuestionCard(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => const AskVillageScreen(initialQuestion: 'What is something you need your village to understand today?')))),
                  ],
                ),
              ),
      ),
    );
  }

  _Resource _featuredResource(List<_Community> joinedCommunities) {
    for (final community in joinedCommunities) {
      for (final resource in resources) {
        if (resource.communityIds.contains(community.id)) return resource;
      }
    }
    return resources.first;
  }

  Widget _heading(String title, String note) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ink))), Text(note, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: gold))]);

  Widget _emptyCard() => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: paper, border: Border.all(color: line), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('The first brave question starts the conversation.', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 5), Text('Active discussions will surface here as the Village grows.', style: GoogleFonts.inter(fontSize: 12, color: muted))]));

  void _showJourneyPicker() {
    const choices = [('Marriage struggling', 'relationships'), ('New mom', 'moms'), ('Starting over', 'new_beginnings'), ('Grieving', 'grief'), ('Feeling alone', 'women'), ('Career change', 'career'), ('Caregiving', 'caregivers'), ('Friendship changes', 'friendship')];
    showModalBottomSheet<void>(context: context, backgroundColor: paper, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (context) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('I need someone who gets it', style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700, color: ink)), const SizedBox(height: 7), Text('Choose what you are walking through. We will take you to the right corner of the Village.', style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: muted)), const SizedBox(height: 18), Wrap(spacing: 9, runSpacing: 9, children: choices.map((choice) => ActionChip(label: Text(choice.$1), backgroundColor: cream, side: const BorderSide(color: line), onPressed: () { Navigator.pop(context); _openCommunity(communities.firstWhere((community) => community.id == choice.$2)); })).toList())]))));
  }

  void _openResource(_Resource resource) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => _ResourcePage(resource: resource)));
  }
}

class _CommunityPage extends StatefulWidget {
  const _CommunityPage({required this.community, required this.memberCount, required this.joined, required this.posts, required this.prompts, required this.resources, required this.onJoin, required this.onAsk});
  final _Community community;
  final int memberCount;
  final bool joined;
  final List<VillagePost> posts;
  final List<String> prompts;
  final List<_Resource> resources;
  final Future<void> Function() onJoin;
  final Future<void> Function(String) onAsk;

  @override
  State<_CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<_CommunityPage> {
  late bool joined = widget.joined;

  @override
  Widget build(BuildContext context) {
    final community = widget.community;
    return Scaffold(backgroundColor: _CommunityHubV2ScreenState.cream, appBar: AppBar(backgroundColor: _CommunityHubV2ScreenState.cream, title: Text(community.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800))), body: ListView(padding: const EdgeInsets.fromLTRB(20, 6, 20, 32), children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: community.color, borderRadius: BorderRadius.circular(26)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .7), borderRadius: BorderRadius.circular(16)), child: Icon(community.icon, color: _CommunityHubV2ScreenState.sage)), const SizedBox(height: 16), Text(community.name, style: GoogleFonts.playfairDisplay(fontSize: 29, fontWeight: FontWeight.w700, color: _CommunityHubV2ScreenState.ink)), const SizedBox(height: 7), Text(community.description, style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: _CommunityHubV2ScreenState.ink)), const SizedBox(height: 15), Row(children: [Text('${widget.memberCount} members', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)), const Spacer(), FilledButton.tonal(onPressed: () async { await widget.onJoin(); if (mounted) setState(() => joined = !joined); }, style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .72), foregroundColor: _CommunityHubV2ScreenState.sage), child: Text(joined ? 'Joined' : 'Join community'))])])),
      const SizedBox(height: 26), _title('Start a conversation'), const SizedBox(height: 10),
      if (widget.prompts.isEmpty) _smallEmpty('Fresh conversation starters are on the way.') else ...widget.prompts.take(3).map((prompt) => Padding(padding: const EdgeInsets.only(bottom: 9), child: InkWell(onTap: () => widget.onAsk(prompt), borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(18)), child: Row(children: [Expanded(child: Text(prompt, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.35))), const SizedBox(width: 8), const Icon(Icons.arrow_forward_rounded, size: 18, color: _CommunityHubV2ScreenState.sage)]))))),
      const SizedBox(height: 18), _title('Trending in this community'), const SizedBox(height: 10),
      if (widget.posts.isEmpty) _smallEmpty('The first question here can be yours.') else ...widget.posts.take(4).map((post) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(post.question, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4)), const SizedBox(height: 8), Text('${post.replies.length} replies  •  ${post.supportCount} helpful', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted))])))),
      const SizedBox(height: 18), _title('Resource library'), const SizedBox(height: 10),
      if (widget.resources.isEmpty) _smallEmpty('Resources for this community are being built.') else ...widget.resources.map((resource) => Padding(padding: const EdgeInsets.only(bottom: 9), child: _ResourceCard(resource: resource, onTap: (value) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (context) => _ResourcePage(resource: value)))))),
    ]));
  }

  Widget _title(String value) => Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _CommunityHubV2ScreenState.ink));
  Widget _smallEmpty(String value) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(18)), child: Text(value, style: GoogleFonts.inter(color: _CommunityHubV2ScreenState.muted)));
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onTap}); final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(26), child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF355C3B), Color(0xFF4D7052)]), borderRadius: BorderRadius.circular(26)), child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.handshake_outlined, color: Colors.white)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('I need someone who gets it', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)), const SizedBox(height: 5), Text('Find people who understand the season you are in.', style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: Colors.white.withValues(alpha: .86)))])), const Icon(Icons.arrow_forward_rounded, color: Colors.white)])));
}

class _JoinedCard extends StatelessWidget {
  const _JoinedCard({required this.community, required this.count, required this.onTap}); final _Community community; final int count; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(width: 180, padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: community.color, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(community.icon, color: _CommunityHubV2ScreenState.sage), const Spacer(), Text(community.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('$count members', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted))])));
}

class _ExploreCard extends StatelessWidget {
  const _ExploreCard({required this.community, required this.joined, required this.count, required this.onTap}); final _Community community; final bool joined; final int count; final VoidCallback onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(22), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: community.color, borderRadius: BorderRadius.circular(12)), child: Icon(community.icon, size: 21, color: _CommunityHubV2ScreenState.sage)), const Spacer(), if (joined) const Icon(Icons.check_circle, size: 18, color: _CommunityHubV2ScreenState.sage)]), const Spacer(), Text(community.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, height: 1.1)), const SizedBox(height: 5), Text('$count members', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted))])));
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.post}); final VillagePost post;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(22)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.local_fire_department_outlined, size: 18, color: _CommunityHubV2ScreenState.gold), const SizedBox(width: 6), Text('Village is talking about this', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: _CommunityHubV2ScreenState.gold))]), const SizedBox(height: 11), Text(post.question, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, height: 1.35)), const SizedBox(height: 10), Text('${post.replies.length} replies  •  ${post.supportCount} helpful', style: GoogleFonts.inter(fontSize: 12, color: _CommunityHubV2ScreenState.muted))]));
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.resource, required this.onTap}); final _Resource resource; final ValueChanged<_Resource> onTap;
  @override Widget build(BuildContext context) => InkWell(onTap: () => onTap(resource), borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paleSage, borderRadius: BorderRadius.circular(20)), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(13)), child: Icon(resource.icon, size: 21, color: _CommunityHubV2ScreenState.sage)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(resource.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text('${resource.category}  •  ${resource.readTime}', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted))])), const Icon(Icons.arrow_forward_rounded, color: _CommunityHubV2ScreenState.sage)])));
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.onTap}); final VoidCallback onTap;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.blush, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('VILLAGE QUESTION OF THE DAY', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: _CommunityHubV2ScreenState.gold)), const SizedBox(height: 9), Text('What is something you need your village to understand today?', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25)), const SizedBox(height: 12), TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add_comment_outlined), label: const Text('Answer this question'))]));
}

class _ResourcePage extends StatelessWidget {
  const _ResourcePage({required this.resource}); final _Resource resource;
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: _CommunityHubV2ScreenState.cream, appBar: AppBar(backgroundColor: _CommunityHubV2ScreenState.cream), body: ListView(padding: const EdgeInsets.fromLTRB(22, 8, 22, 36), children: [Text(resource.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: _CommunityHubV2ScreenState.gold)), const SizedBox(height: 8), Text(resource.title, style: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.w700, height: 1.1)), const SizedBox(height: 8), Text(resource.readTime, style: GoogleFonts.inter(fontSize: 12, color: _CommunityHubV2ScreenState.muted)), const SizedBox(height: 22), Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(22)), child: Text(resource.body, style: GoogleFonts.inter(fontSize: 16, height: 1.75, color: _CommunityHubV2ScreenState.ink)))]));
}

class _Community {
  const _Community(this.id, this.name, this.description, this.icon, this.color, this.category, this.prompts);
  final String id; final String name; final String description; final IconData icon; final Color color; final String category; final List<String> prompts;
}

class _Resource {
  const _Resource(this.id, this.title, this.category, this.readTime, this.icon, this.communityIds, this.body);
  final String id; final String title; final String category; final String readTime; final IconData icon; final List<String> communityIds; final String body;
}
