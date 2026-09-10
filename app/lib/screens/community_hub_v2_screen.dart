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
  Set<String> savedResources = {};
  Set<String> usedSuggestions = {};
  Map<String, int> memberCounts = {};
  List<VillagePost> posts = [];
  bool loading = true;

  static const communities = <_CommunityData>[
    _CommunityData(
      id: 'relationships',
      name: 'Relationships',
      subtitle: 'For the conversations you cannot always have with people you know.',
      icon: Icons.favorite_border_rounded,
      color: Color(0xFFE8D8CB),
      categories: ['Relationships'],
      supportIntents: ['Advice', 'Perspective'],
      prompts: [
        'How do you know when you are asking for reassurance versus asking your partner to change?',
        'What helps you feel heard during a hard conversation?',
        'What small act helps you feel connected when life gets busy?',
      ],
    ),
    _CommunityData(
      id: 'women',
      name: 'Women',
      subtitle: 'A supportive space for every season of womanhood.',
      icon: Icons.woman_2_outlined,
      color: Color(0xFFF1DED8),
      categories: ['Life & Growth'],
      supportIntents: ['Advice', 'Encouragement'],
      prompts: [
        'What are you learning about yourself lately?',
        'What support would make this week feel lighter?',
        'What part of yourself are you trying to reconnect with?',
      ],
    ),
    _CommunityData(
      id: 'moms',
      name: 'Moms',
      subtitle: 'Real talk, practical help, and encouragement for moms.',
      icon: Icons.child_care_outlined,
      color: Color(0xFFFFE7BE),
      categories: ['Parenting'],
      supportIntents: ['Advice', 'Encouragement'],
      prompts: [
        'What parenting season are you in right now?',
        'What is one routine that makes home life easier?',
        'What is something about motherhood you wish people talked about more?',
      ],
    ),
    _CommunityData(
      id: 'friendship',
      name: 'Friendship',
      subtitle: 'Build stronger friendships and navigate changing ones.',
      icon: Icons.people_outline_rounded,
      color: Color(0xFFF2E4D4),
      categories: ['Friendship'],
      supportIntents: ['Advice', 'Perspective'],
      prompts: [
        'What makes you feel valued in a friendship?',
        'How do you reconnect after growing apart?',
        'How do you know when a friendship has run its course?',
      ],
    ),
    _CommunityData(
      id: 'wellness',
      name: 'Wellness',
      subtitle: 'Gentle support for emotional and everyday wellbeing.',
      icon: Icons.spa_outlined,
      color: Color(0xFFDDE7D7),
      categories: ['Mental Health'],
      supportIntents: ['Encouragement', 'Advice'],
      prompts: [
        'What does rest look like for you this week?',
        'What habit helps you feel grounded?',
        'What are you carrying that you are ready to put down?',
      ],
    ),
    _CommunityData(
      id: 'career',
      name: 'Career & Purpose',
      subtitle: 'Support for work, goals, confidence, and your next move.',
      icon: Icons.work_outline_rounded,
      color: Color(0xFFE6E2D5),
      categories: ['Work & School'],
      supportIntents: ['Advice', 'Perspective'],
      prompts: [
        'What professional goal are you working toward?',
        'Where do you need more confidence at work?',
        'What would a meaningful next step look like?',
      ],
    ),
    _CommunityData(
      id: 'grief',
      name: 'Grief & Healing',
      subtitle: 'A gentle space for loss, remembrance, and healing.',
      icon: Icons.eco_outlined,
      color: Color(0xFFDDE6DF),
      categories: ['Grief'],
      supportIntents: ['Encouragement', 'Listening'],
      prompts: [
        'What do you wish people understood about your grief?',
        'Is there a memory you want to share today?',
        'What has brought even a small amount of comfort?',
      ],
    ),
    _CommunityData(
      id: 'new_beginnings',
      name: 'New Beginnings',
      subtitle: 'Support through moves, transitions, endings, and fresh starts.',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFFE9CB),
      categories: ['Life & Growth'],
      supportIntents: ['Advice', 'Encouragement'],
      prompts: [
        'What new chapter are you stepping into?',
        'What are you leaving behind?',
        'What would help this transition feel less lonely?',
      ],
    ),
    _CommunityData(
      id: 'caregivers',
      name: 'Caregivers',
      subtitle: 'Care, resources, and understanding for people who give care.',
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFFE3EAD7),
      categories: ['Practical help'],
      supportIntents: ['Advice', 'Encouragement'],
      prompts: [
        'What part of caregiving feels heaviest right now?',
        'Where could you accept help this week?',
        'What is one thing you wish other people understood about caregiving?',
      ],
    ),
  ];

  static const resources = <_ResourceData>[
    _ResourceData(
      id: 'repair_after_argument',
      title: 'How to repair after a bad argument',
      category: 'Relationships',
      readTime: '6 min read',
      icon: Icons.forum_outlined,
      communityIds: ['relationships'],
      body: 'Repair starts by lowering the temperature, naming what happened without building a case, and taking responsibility for your part. Start with one sentence that describes the moment instead of the person. Then ask what landed badly, reflect back what you heard, and agree on one small change for the next similar moment. If either person is still flooded, pause with a specific return time so the pause does not feel like abandonment.',
    ),
    _ResourceData(
      id: 'friend_support',
      title: 'How to support someone without trying to fix them',
      category: 'Friendship',
      readTime: '5 min read',
      icon: Icons.volunteer_activism_outlined,
      communityIds: ['friendship', 'women'],
      body: 'Ask what kind of support is wanted before jumping into solutions. Listening, advice, encouragement, distraction, and practical help are different needs. Reflect the feeling you hear, offer specific help you can actually follow through on, and check back after the urgent moment passes. Consistency is often more supportive than one perfect conversation.',
    ),
    _ResourceData(
      id: 'grounding_reset',
      title: 'A five-minute grounding reset',
      category: 'Wellness',
      readTime: '5 min read',
      icon: Icons.spa_outlined,
      communityIds: ['wellness', 'grief', 'caregivers', 'new_beginnings'],
      body: 'Put both feet down and notice the support under your body. Take five easy breaths with a slightly longer exhale. Name five things you can see, four things you can feel, three sounds, two scents, and one comforting thought or taste. Finish by choosing one caring action that takes less than ten minutes.',
    ),
    _ResourceData(
      id: 'boundary_check',
      title: 'The boundary check-in',
      category: 'Life & Growth',
      readTime: '7 min read',
      icon: Icons.shield_outlined,
      communityIds: ['women', 'career', 'relationships'],
      body: 'A boundary describes what you will do to protect your wellbeing, time, safety, or values. Identify the repeated pattern, separate your request from your boundary, choose a limit you can realistically maintain, and communicate it simply. Follow through calmly and review whether the boundary is protecting what it was meant to protect.',
    ),
    _ResourceData(
      id: 'parenting_reset',
      title: 'A calmer reset for hard parenting moments',
      category: 'Moms',
      readTime: '6 min read',
      icon: Icons.child_care_outlined,
      communityIds: ['moms'],
      body: 'Begin with safety, then regulate yourself before trying to teach. Use fewer words while emotions are high. Describe what you see without labeling the child, hold the limit in one clear sentence, offer one manageable choice, and reconnect after the storm. Repair matters more than pretending parents never struggle.',
    ),
    _ResourceData(
      id: 'career_reset',
      title: 'A practical career reset when you feel stuck',
      category: 'Career & Purpose',
      readTime: '8 min read',
      icon: Icons.route_outlined,
      communityIds: ['career', 'new_beginnings'],
      body: 'Start by naming what is actually stuck: the role, manager, pay, environment, confidence, or direction. Separate what needs to change now from what can be explored over time. Pick one move that creates information, such as talking to someone in a role you want, updating one section of your resume, or applying to one position that stretches you.',
    ),
  ];

  static const journeys = <_JourneyData>[
    _JourneyData(label: 'Marriage struggling', communityId: 'relationships', icon: Icons.favorite_outline),
    _JourneyData(label: 'New mom', communityId: 'moms', icon: Icons.child_friendly_outlined),
    _JourneyData(label: 'Starting over', communityId: 'new_beginnings', icon: Icons.restart_alt_rounded),
    _JourneyData(label: 'Grieving', communityId: 'grief', icon: Icons.eco_outlined),
    _JourneyData(label: 'Feeling alone', communityId: 'women', icon: Icons.person_outline_rounded),
    _JourneyData(label: 'Career change', communityId: 'career', icon: Icons.work_outline_rounded),
    _JourneyData(label: 'Caregiving', communityId: 'caregivers', icon: Icons.health_and_safety_outlined),
    _JourneyData(label: 'Friendship changes', communityId: 'friendship', icon: Icons.people_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.joinedCommunities(),
        _service.savedResources(),
        _service.usedSuggestedQuestions(),
        _postService.load(),
        _service.memberCounts(communities.map((e) => e.id)),
      ]);
      if (!mounted) return;
      setState(() {
        joined = results[0] as Set<String>;
        savedResources = results[1] as Set<String>;
        usedSuggestions = results[2] as Set<String>;
        posts = results[3] as List<VillagePost>;
        memberCounts = results[4] as Map<String, int>;
        loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List<VillagePost> _postsFor(_CommunityData community) {
    final matches = posts.where((post) {
      if (post.communityId != null) return post.communityId == community.id;
      return community.categories.contains(post.category) ||
          community.supportIntents.contains(post.supportIntent);
    }).toList();
    matches.sort((a, b) {
      final aScore = a.replies.length * 3 + a.supportCount;
      final bScore = b.replies.length * 3 + b.supportCount;
      if (aScore != bScore) return bScore.compareTo(aScore);
      return b.createdAt.compareTo(a.createdAt);
    });
    return matches;
  }

  List<_ResourceData> _resourcesFor(_CommunityData community) =>
      resources.where((r) => r.communityIds.contains(community.id)).toList();

  List<String> _availablePrompts(_CommunityData community) {
    final posted = posts.map((e) => e.question.trim().toLowerCase()).toSet();
    return [
      for (var i = 0; i < community.prompts.length; i++)
        if (!usedSuggestions.contains('${community.id}.$i') &&
            !posted.contains(community.prompts[i].trim().toLowerCase()))
          community.prompts[i],
    ];
  }

  Future<void> _toggleJoin(_CommunityData community) async {
    final joining = !joined.contains(community.id);
    setState(() {
      if (joining) {
        joined.add(community.id);
      } else {
        joined.remove(community.id);
      }
      final oldCount = memberCounts[community.id] ?? 0;
      memberCounts[community.id] = (oldCount + (joining ? 1 : -1)).clamp(0, 999999);
    });
    await _service.saveJoinedCommunities(joined);
    await _service.setCommunityMembership(community.id, joining);
  }

  Future<void> _toggleResource(_ResourceData resource) async {
    setState(() {
      if (!savedResources.add(resource.id)) savedResources.remove(resource.id);
    });
    await _service.saveResources(savedResources);
  }

  Future<void> _askPrompt(_CommunityData community, String prompt) async {
    final index = community.prompts.indexOf(prompt);
    final suggestionId = '${community.id}.$index';
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AskVillageScreen(
          initialQuestion: prompt,
          initialCategory: community.categories.first,
          initialSupportIntent: community.supportIntents.first,
          initialCommunityId: community.id,
          initialCommunityName: community.name,
          suggestionId: suggestionId,
          onSuggestedQuestionPosted: (id) async {
            await _service.markSuggestedQuestionUsed(id);
            if (!mounted) return;
            setState(() => usedSuggestions.add(id));
          },
        ),
      ),
    );
    await _load();
  }

  void _openCommunity(_CommunityData community) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CommunityDetailPage(
          community: community,
          joined: joined.contains(community.id),
          memberCount: memberCounts[community.id] ?? 0,
          posts: _postsFor(community),
          prompts: _availablePrompts(community),
          resources: _resourcesFor(community),
          savedResources: savedResources,
          onToggleJoin: () => _toggleJoin(community),
          onPrompt: (prompt) => _askPrompt(community, prompt),
          onToggleResource: _toggleResource,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final joinedCommunities = communities.where((c) => joined.contains(c.id)).toList();
    final hottest = [...posts]..sort((a, b) {
      final aScore = a.replies.length * 3 + a.supportCount;
      final bScore = b.replies.length * 3 + b.supportCount;
      return bScore.compareTo(aScore);
    });

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
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('COMMUNITY HUB', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.8, color: gold)),
                              const SizedBox(height: 5),
                              Text('Find your people.', style: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.w700, color: ink, height: 1.05)),
                            ],
                          ),
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: paleSage, borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.diversity_3_outlined, color: sage),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _HeroSupportCard(onTap: _showJourneyPicker),
                    if (joinedCommunities.isNotEmpty) ...[
                      const SizedBox(height: 26),
                      _SectionHeader(title: 'Your communities', action: '${joinedCommunities.length} joined'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 124,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: joinedCommunities.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final community = joinedCommunities[index];
                            return _JoinedCommunityCard(
                              community: community,
                              count: memberCounts[community.id] ?? 0,
                              onTap: () => _openCommunity(community),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                    const _SectionHeader(title: 'Happening now', action: 'Village is talking'),
                    const SizedBox(height: 12),
                    if (hottest.isEmpty)
                      const _EmptyConversationCard()
                    else
                      _TrendingCard(post: hottest.first),
                    const SizedBox(height: 26),
                    const _SectionHeader(title: 'Explore communities', action: 'Choose your spaces'),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: communities.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.03,
                      ),
                      itemBuilder: (context, index) {
                        final community = communities[index];
                        return _ExploreCommunityCard(
                          community: community,
                          joined: joined.contains(community.id),
                          count: memberCounts[community.id] ?? 0,
                          onTap: () => _openCommunity(community),
                        );
                      },
                    ),
                    const SizedBox(height: 26),
                    const _SectionHeader(title: 'You might need this today', action: 'Useful, not filler'),
                    const SizedBox(height: 12),
                    _ResourceSpotlight(
                      resource: resources.firstWhere(
                        (r) => joinedCommunities.any((c) => r.communityIds.contains(c.id)),
                        orElse: () => resources.first,
                      ),
                      saved: savedResources.contains(resources.first.id),
                      onTap: (resource) => _openResource(resource),
                    ),
                    const SizedBox(height: 26),
                    _QuestionOfTheDay(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AskVillageScreen(
                            initialQuestion: 'What is something you need your village to understand today?',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showJourneyPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: line, borderRadius: BorderRadius.circular(20)))),
              const SizedBox(height: 20),
              Text('I need someone who gets it', style: GoogleFonts.playfairDisplay(fontSize: 27, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 7),
              Text('Choose what you are walking through. We will take you to people and conversations that fit.', style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: muted)),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: journeys.map((journey) {
                  return ActionChip(
                    avatar: Icon(journey.icon, size: 18, color: sage),
                    label: Text(journey.label),
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, color: ink),
                    backgroundColor: cream,
                    side: const BorderSide(color: line),
                    onPressed: () {
                      Navigator.pop(context);
                      _openCommunity(communities.firstWhere((c) => c.id == journey.communityId));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openResource(_ResourceData resource) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ResourceDetailPage(
          resource: resource,
          saved: savedResources.contains(resource.id),
          onToggleSaved: () => _toggleResource(resource),
        ),
      ),
    ).then((_) => setState(() {}));
  }
}

class _CommunityDetailPage extends StatefulWidget {
  const _CommunityDetailPage({
    required this.community,
    required this.joined,
    required this.memberCount,
    required this.posts,
    required this.prompts,
    required this.resources,
    required this.savedResources,
    required this.onToggleJoin,
    required this.onPrompt,
    required this.onToggleResource,
  });

  final _CommunityData community;
  final bool joined;
  final int memberCount;
  final List<VillagePost> posts;
  final List<String> prompts;
  final List<_ResourceData> resources;
  final Set<String> savedResources;
  final Future<void> Function() onToggleJoin;
  final Future<void> Function(String) onPrompt;
  final Future<void> Function(_ResourceData) onToggleResource;

  @override
  State<_CommunityDetailPage> createState() => _CommunityDetailPageState();
}

class _CommunityDetailPageState extends State<_CommunityDetailPage> {
  late bool joined = widget.joined;

  @override
  Widget build(BuildContext context) {
    final c = widget.community;
    return Scaffold(
      backgroundColor: _CommunityHubV2ScreenState.cream,
      appBar: AppBar(
        backgroundColor: _CommunityHubV2ScreenState.cream,
        title: Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: c.color, borderRadius: BorderRadius.circular(26)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(16)), child: Icon(c.icon, color: _CommunityHubV2ScreenState.sage)),
                const SizedBox(height: 18),
                Text(c.name, style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: _CommunityHubV2ScreenState.ink)),
                const SizedBox(height: 8),
                Text(c.subtitle, style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: _CommunityHubV2ScreenState.ink)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('${widget.memberCount} ${widget.memberCount == 1 ? 'member' : 'members'}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _CommunityHubV2ScreenState.ink)),
                    const Spacer(),
                    FilledButton.tonal(
                      onPressed: () async {
                        await widget.onToggleJoin();
                        if (mounted) setState(() => joined = !joined);
                      },
                      style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: .78), foregroundColor: _CommunityHubV2ScreenState.sage),
                      child: Text(joined ? 'Joined' : 'Join community'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const _SectionHeader(title: 'What are we talking about?', action: 'Start a real conversation'),
          const SizedBox(height: 12),
          if (widget.prompts.isEmpty)
            const _SoftCard(child: Text('Fresh conversation starters are on the way.'))
          else
            ...widget.prompts.take(3).map((prompt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PromptCard(prompt: prompt, onTap: () => widget.onPrompt(prompt)),
                )),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Trending in this community', action: 'What people need right now'),
          const SizedBox(height: 12),
          if (widget.posts.isEmpty)
            const _EmptyConversationCard()
          else
            ...widget.posts.take(4).map((post) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DiscussionCard(post: post),
                )),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Resource library', action: 'Save what helps'),
          const SizedBox(height: 12),
          if (widget.resources.isEmpty)
            const _SoftCard(child: Text('Resources for this community are being built.'))
          else
            ...widget.resources.map((resource) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ResourceListCard(
                    resource: resource,
                    saved: widget.savedResources.contains(resource.id),
                    onSaved: () async {
                      await widget.onToggleResource(resource);
                      if (mounted) setState(() {});
                    },
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _ResourceDetailPage(
                          resource: resource,
                          saved: widget.savedResources.contains(resource.id),
                          onToggleSaved: () => widget.onToggleResource(resource),
                        ),
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _HeroSupportCard extends StatelessWidget {
  const _HeroSupportCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF355C3B), Color(0xFF4D7052)]),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.handshake_outlined, color: Colors.white)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I need someone who gets it', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 5),
                  Text('Tell us what you are walking through. We will help you find the right corner of the Village.', style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: Colors.white.withValues(alpha: .86))),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: _CommunityHubV2ScreenState.ink))),
        const SizedBox(width: 10),
        Text(action, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _CommunityHubV2ScreenState.gold)),
      ],
    );
  }
}

class _JoinedCommunityCard extends StatelessWidget {
  const _JoinedCommunityCard({required this.community, required this.count, required this.onTap});
  final _CommunityData community;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 185,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: community.color, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(community.icon, color: _CommunityHubV2ScreenState.sage), const Spacer(), const Icon(Icons.arrow_outward_rounded, size: 18, color: _CommunityHubV2ScreenState.sage)]),
            const Spacer(),
            Text(community.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: _CommunityHubV2ScreenState.ink)),
            const SizedBox(height: 3),
            Text('$count members', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted)),
          ],
        ),
      ),
    );
  }
}

class _ExploreCommunityCard extends StatelessWidget {
  const _ExploreCommunityCard({required this.community, required this.joined, required this.count, required this.onTap});
  final _CommunityData community;
  final bool joined;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Container(width: 38, height: 38, decoration: BoxDecoration(color: community.color, borderRadius: BorderRadius.circular(12)), child: Icon(community.icon, size: 21, color: _CommunityHubV2ScreenState.sage)), const Spacer(), if (joined) const Icon(Icons.check_circle, size: 18, color: _CommunityHubV2ScreenState.sage)]),
            const Spacer(),
            Text(community.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, height: 1.1, color: _CommunityHubV2ScreenState.ink)),
            const SizedBox(height: 5),
            Text('$count members', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted)),
          ],
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.post});
  final VillagePost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [const Icon(Icons.local_fire_department_outlined, size: 18, color: _CommunityHubV2ScreenState.gold), const SizedBox(width: 6), Text('Village is talking about this', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: _CommunityHubV2ScreenState.gold))]),
          const SizedBox(height: 12),
          Text(post.question, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w750, height: 1.35, color: _CommunityHubV2ScreenState.ink)),
          const SizedBox(height: 12),
          Text('${post.replies.length} replies  •  ${post.supportCount} helpful', style: GoogleFonts.inter(fontSize: 12, color: _CommunityHubV2ScreenState.muted)),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.onTap});
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(child: Text(prompt, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w650, height: 1.35, color: _CommunityHubV2ScreenState.ink))),
          const SizedBox(width: 10),
          TextButton(onPressed: onTap, child: const Text('Ask this →')),
        ],
      ),
    );
  }
}

class _DiscussionCard extends StatelessWidget {
  const _DiscussionCard({required this.post});
  final VillagePost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.communityName != null) Text(post.communityName!, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _CommunityHubV2ScreenState.gold)),
          if (post.communityName != null) const SizedBox(height: 6),
          Text(post.question, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, height: 1.4, color: _CommunityHubV2ScreenState.ink)),
          const SizedBox(height: 10),
          Text('${post.replies.length} replies  •  ${post.supportCount} helpful', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted)),
        ],
      ),
    );
  }
}

class _ResourceSpotlight extends StatelessWidget {
  const _ResourceSpotlight({required this.resource, required this.saved, required this.onTap});
  final _ResourceData resource;
  final bool saved;
  final ValueChanged<_ResourceData> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(resource),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paleSage, borderRadius: BorderRadius.circular(22)),
        child: Row(
          children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(14)), child: Icon(resource.icon, color: _CommunityHubV2ScreenState.sage)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(resource.title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _CommunityHubV2ScreenState.ink)), const SizedBox(height: 5), Text('${resource.category}  •  ${resource.readTime}', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted))])),
            Icon(saved ? Icons.bookmark_rounded : Icons.arrow_forward_rounded, color: _CommunityHubV2ScreenState.sage),
          ],
        ),
      ),
    );
  }
}

class _ResourceListCard extends StatelessWidget {
  const _ResourceListCard({required this.resource, required this.saved, required this.onSaved, required this.onOpen});
  final _ResourceData resource;
  final bool saved;
  final VoidCallback onSaved;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paleSage, borderRadius: BorderRadius.circular(12)), child: Icon(resource.icon, size: 20, color: _CommunityHubV2ScreenState.sage)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(resource.title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w750, color: _CommunityHubV2ScreenState.ink)), const SizedBox(height: 4), Text('${resource.category}  •  ${resource.readTime}', style: GoogleFonts.inter(fontSize: 11, color: _CommunityHubV2ScreenState.muted))])),
            IconButton(onPressed: onSaved, icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: _CommunityHubV2ScreenState.sage)),
          ],
        ),
      ),
    );
  }
}

class _ResourceDetailPage extends StatefulWidget {
  const _ResourceDetailPage({required this.resource, required this.saved, required this.onToggleSaved});
  final _ResourceData resource;
  final bool saved;
  final Future<void> Function() onToggleSaved;

  @override
  State<_ResourceDetailPage> createState() => _ResourceDetailPageState();
}

class _ResourceDetailPageState extends State<_ResourceDetailPage> {
  late bool saved = widget.saved;

  @override
  Widget build(BuildContext context) {
    final r = widget.resource;
    return Scaffold(
      backgroundColor: _CommunityHubV2ScreenState.cream,
      appBar: AppBar(
        backgroundColor: _CommunityHubV2ScreenState.cream,
        actions: [
          IconButton(
            onPressed: () async {
              await widget.onToggleSaved();
              if (mounted) setState(() => saved = !saved);
            },
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 36),
        children: [
          Text(r.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: _CommunityHubV2ScreenState.gold)),
          const SizedBox(height: 8),
          Text(r.title, style: GoogleFonts.playfairDisplay(fontSize: 34, fontWeight: FontWeight.w700, height: 1.1, color: _CommunityHubV2ScreenState.ink)),
          const SizedBox(height: 8),
          Text(r.readTime, style: GoogleFonts.inter(fontSize: 12, color: _CommunityHubV2ScreenState.muted)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(22)),
            child: Text(r.body, style: GoogleFonts.inter(fontSize: 16, height: 1.75, color: _CommunityHubV2ScreenState.ink)),
          ),
        ],
      ),
    );
  }
}

class _QuestionOfTheDay extends StatelessWidget {
  const _QuestionOfTheDay({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _CommunityHubV2ScreenState.blush, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VILLAGE QUESTION OF THE DAY', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: _CommunityHubV2ScreenState.gold)),
          const SizedBox(height: 10),
          Text('What is something you need your village to understand today?', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.w700, height: 1.25, color: _CommunityHubV2ScreenState.ink)),
          const SizedBox(height: 14),
          TextButton.icon(onPressed: onTap, icon: const Icon(Icons.add_comment_outlined), label: const Text('Answer this question')),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _CommunityHubV2ScreenState.paper, border: Border.all(color: _CommunityHubV2ScreenState.line), borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }
}

class _EmptyConversationCard extends StatelessWidget {
  const _EmptyConversationCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This conversation starts with the first brave question.', style: GoogleFonts.inter(fontWeight: FontWeight.w750, color: _CommunityHubV2ScreenState.ink)),
          const SizedBox(height: 5),
          Text('As people post, the most active discussions will surface here.', style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: _CommunityHubV2ScreenState.muted)),
        ],
      ),
    );
  }
}

class _CommunityData {
  const _CommunityData({required this.id, required this.name, required this.subtitle, required this.icon, required this.color, required this.categories, required this.supportIntents, required this.prompts});
  final String id;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> categories;
  final List<String> supportIntents;
  final List<String> prompts;
}

class _ResourceData {
  const _ResourceData({required this.id, required this.title, required this.category, required this.readTime, required this.icon, required this.communityIds, required this.body});
  final String id;
  final String title;
  final String category;
  final String readTime;
  final IconData icon;
  final List<String> communityIds;
  final String body;
}

class _JourneyData {
  const _JourneyData({required this.label, required this.communityId, required this.icon});
  final String label;
  final String communityId;
  final IconData icon;
}
