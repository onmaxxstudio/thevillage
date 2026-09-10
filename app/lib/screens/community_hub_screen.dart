import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../navigation/village_navigation_scope.dart';
import '../services/community_hub_service.dart';
import '../services/village_post_service.dart';
import 'village_feed_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const blush = Color(0xFFF3E2DD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final CommunityHubService service = CommunityHubService();
  int selectedSection = 0;
  bool loadingPreferences = true;
  Set<String> joined = {};
  Set<String> savedResources = {};
  Set<String> registeredEvents = {};
  Map<String, int> memberCounts = {};
  List<VillagePost> villagePosts = [];

  static const sections = <(IconData, String)>[
    (Icons.groups_2_outlined, 'Communities'),
    (Icons.menu_book_outlined, 'Resources'),
    (Icons.calendar_month_outlined, 'Events'),
  ];

  static const communities = <_CommunityInfo>[
    _CommunityInfo(
      id: 'women',
      name: 'Women',
      description: 'A supportive space for every season of womanhood.',
      icon: Icons.woman_2_outlined,
      color: Color(0xFFF1DED8),
      memberLabel: 'Open community',
      conversationSearch: 'Life & Growth',
      prompts: [
        'What are you learning about yourself lately?',
        'What support would make this week feel lighter?',
        'Share a win that deserves to be celebrated.',
      ],
    ),
    _CommunityInfo(
      id: 'moms',
      name: 'Moms',
      description: 'Real talk, practical help, and encouragement for moms.',
      icon: Icons.child_care_outlined,
      color: Color(0xFFFFE8BE),
      memberLabel: 'Open community',
      conversationSearch: 'Parenting',
      prompts: [
        'What parenting season are you in right now?',
        'What is one routine that makes home life easier?',
        'Where could you use a little encouragement today?',
      ],
    ),
    _CommunityInfo(
      id: 'relationships',
      name: 'Relationships',
      description: 'Healthier communication, connection, and boundaries.',
      icon: Icons.favorite_border_rounded,
      color: Color(0xFFE7D8C9),
      memberLabel: 'Open community',
      conversationSearch: 'Relationships',
      prompts: [
        'What helps you feel heard during a hard conversation?',
        'Which boundary are you learning to protect?',
        'What small act helps you feel connected?',
      ],
    ),
    _CommunityInfo(
      id: 'wellness',
      name: 'Wellness',
      description: 'Gentle support for your emotional and everyday wellbeing.',
      icon: Icons.spa_outlined,
      color: Color(0xFFDDE7D7),
      memberLabel: 'Open community',
      conversationSearch: 'Mental Health',
      prompts: [
        'What does rest look like for you this week?',
        'Name one habit that helps you feel grounded.',
        'What are you ready to release?',
      ],
    ),
    _CommunityInfo(
      id: 'faith',
      name: 'Faith & Spirituality',
      description: 'Encouragement, reflection, prayer, and spiritual growth.',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFFE9E1F0),
      memberLabel: 'Open community',
      conversationSearch: 'Prayer',
      prompts: [
        'What is giving you hope in this season?',
        'Is there something your community can pray about with you?',
        'Share a practice that helps you feel spiritually grounded.',
      ],
    ),
    _CommunityInfo(
      id: 'men',
      name: 'Men',
      description: 'Honest support for life, relationships, and wellbeing.',
      icon: Icons.man_2_outlined,
      color: Color(0xFFDCE5E7),
      memberLabel: 'Open community',
      conversationSearch: 'Life & Growth',
      prompts: [
        'What pressure have you been carrying quietly?',
        'What does healthy support look like to you?',
        'What is one area where you want to grow?',
      ],
    ),
    _CommunityInfo(
      id: 'friendship',
      name: 'Friendship',
      description: 'Build stronger friendships and navigate changing ones.',
      icon: Icons.people_outline_rounded,
      color: Color(0xFFF2E4D4),
      memberLabel: 'Open community',
      conversationSearch: 'Friendship',
      prompts: [
        'What makes you feel valued in a friendship?',
        'How do you reconnect after growing apart?',
        'What friendship lesson did you learn the hard way?',
      ],
    ),
    _CommunityInfo(
      id: 'career',
      name: 'Career & Purpose',
      description: 'Support for work, goals, confidence, and next steps.',
      icon: Icons.work_outline_rounded,
      color: Color(0xFFE6E2D5),
      memberLabel: 'Open community',
      conversationSearch: 'Work & School',
      prompts: [
        'What professional goal are you working toward?',
        'Where do you need more confidence at work?',
        'What would a meaningful next step look like?',
      ],
    ),
    _CommunityInfo(
      id: 'grief',
      name: 'Grief & Healing',
      description: 'A gentle space for loss, remembrance, and healing.',
      icon: Icons.eco_outlined,
      color: Color(0xFFDDE6DF),
      memberLabel: 'Open community',
      conversationSearch: 'Grief',
      prompts: [
        'What do you wish people understood about your grief?',
        'Is there a memory you would like to share today?',
        'What has brought even a small amount of comfort?',
      ],
    ),
    _CommunityInfo(
      id: 'new_beginnings',
      name: 'New Beginnings',
      description: 'Support through moves, transitions, endings, and fresh starts.',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFFE9CB),
      memberLabel: 'Open community',
      conversationSearch: 'Life & Growth',
      prompts: [
        'What new chapter are you stepping into?',
        'What are you leaving behind with gratitude?',
        'What would help this transition feel less lonely?',
      ],
    ),
    _CommunityInfo(
      id: 'caregivers',
      name: 'Caregivers',
      description: 'Care, resources, and understanding for those who give care.',
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFFE3EAD7),
      memberLabel: 'Open community',
      conversationSearch: 'Practical help',
      prompts: [
        'What part of caregiving feels heaviest right now?',
        'Where could you accept help this week?',
        'Share one way you care for yourself, too.',
      ],
    ),
    _CommunityInfo(
      id: 'empty_nest',
      name: 'Life After the Kids',
      description: 'Rediscover identity, connection, and purpose in a new season.',
      icon: Icons.home_outlined,
      color: Color(0xFFECE3D8),
      memberLabel: 'Open community',
      conversationSearch: 'Life & Growth',
      prompts: [
        'What are you rediscovering about yourself?',
        'How has home life changed in this season?',
        'What dream finally has room to grow?',
      ],
    ),
  ];

  static const resources = <_ResourceInfo>[
    _ResourceInfo(
      id: 'hard_conversation',
      title: 'A gentler way to start a hard conversation',
      category: 'Relationships',
      readTime: '4 min read',
      icon: Icons.forum_outlined,
      color: Color(0xFFF1DED8),
      introduction:
          'The first minute of a difficult conversation can shape everything that follows. Begin with clarity, care, and one issue at a time.',
      steps: [
        'Choose a calm time instead of starting in the heat of the moment.',
        'Lead with what you feel and need, not a judgment about the other person.',
        'Ask one clear question, then make room for the answer.',
        'Pause if either person becomes overwhelmed and agree when to return.',
      ],
      communityIds: ['relationships'],
    ),
    _ResourceInfo(
      id: 'support_friend',
      title: 'How to support someone without trying to fix them',
      category: 'Friendship',
      readTime: '3 min read',
      icon: Icons.volunteer_activism_outlined,
      color: Color(0xFFFFE8BE),
      introduction:
          'Support often starts with presence. You do not need the perfect answer to help someone feel less alone.',
      steps: [
        'Ask whether they want listening, advice, encouragement, or practical help.',
        'Reflect what you heard before sharing your perspective.',
        'Offer one specific form of help instead of saying “anything you need.”',
        'Check in again later; support should not end with one conversation.',
      ],
      communityIds: ['friendship', 'women'],
    ),
    _ResourceInfo(
      id: 'grounding_reset',
      title: 'A five-minute grounding reset',
      category: 'Wellness',
      readTime: '5 min practice',
      icon: Icons.spa_outlined,
      color: Color(0xFFDDE7D7),
      introduction:
          'Use this brief reset when your thoughts feel fast or your body feels tense. Move gently and stop if anything feels uncomfortable.',
      steps: [
        'Place both feet down and notice the support beneath you.',
        'Breathe in for four, pause for two, and breathe out for six.',
        'Name five things you see, four you feel, and three you hear.',
        'Choose one small next step rather than solving everything at once.',
      ],
      communityIds: ['wellness', 'grief', 'caregivers', 'new_beginnings'],
    ),
    _ResourceInfo(
      id: 'boundary_check',
      title: 'The boundary check-in',
      category: 'Life & Growth',
      readTime: '6 min exercise',
      icon: Icons.shield_outlined,
      color: Color(0xFFE8EBDD),
      introduction:
          'A boundary is a clear description of what you will do to protect your wellbeing. This check-in helps turn discomfort into a practical next step.',
      steps: [
        'Notice the situation that repeatedly leaves you resentful or depleted.',
        'Name the limit you need without trying to control another person.',
        'Say the boundary simply and explain what action you will take.',
        'Follow through consistently while leaving room for respectful dialogue.',
      ],
      communityIds: ['women', 'men', 'career', 'relationships'],
    ),
    _ResourceInfo(
      id: 'parenting_pause',
      title: 'A calmer reset for hard parenting moments',
      category: 'Moms',
      readTime: '4 min practice',
      icon: Icons.child_care_outlined,
      color: Color(0xFFFFE8BE),
      introduction:
          'A brief pause can help you respond with more steadiness when everyone is overwhelmed.',
      steps: [
        'Make sure everyone is physically safe, then slow your own breathing.',
        'Name what is happening without labeling the child.',
        'Offer one simple choice or next step.',
        'Reconnect after the moment instead of expecting perfection.',
      ],
      communityIds: ['moms'],
    ),
    _ResourceInfo(
      id: 'hope_reflection',
      title: 'A reflection for seasons of uncertainty',
      category: 'Faith & Spirituality',
      readTime: '5 min reflection',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFFE9E1F0),
      introduction:
          'Use this quiet reflection to name what you are carrying and reconnect with hope.',
      steps: [
        'Name the worry that feels loudest today.',
        'Recall one moment when support arrived unexpectedly.',
        'Write one prayer, intention, or grounding truth.',
        'Choose one small action that reflects hope.',
      ],
      communityIds: ['faith'],
    ),
    _ResourceInfo(
      id: 'empty_nest_identity',
      title: 'Rediscovering yourself in a new season',
      category: 'Life After the Kids',
      readTime: '6 min exercise',
      icon: Icons.home_outlined,
      color: Color(0xFFECE3D8),
      introduction:
          'A changing home can create both grief and possibility. This exercise makes room for both.',
      steps: [
        'List what you miss without judging the feeling.',
        'Name an interest or dream you set aside.',
        'Choose one relationship you want to nurture differently.',
        'Plan one small experience that belongs to this new chapter.',
      ],
      communityIds: ['empty_nest'],
    ),
  ];

  static const events = <_EventInfo>[
    _EventInfo(
      id: 'communication_circle',
      title: 'Building Healthier Communication',
      schedule: 'Coming soon',
      host: 'Hosted by The Village Team',
      icon: Icons.record_voice_over_outlined,
      description:
          'A guided community conversation about feeling heard, repairing misunderstandings, and speaking with more care.',
    ),
    _EventInfo(
      id: 'moms_coffee',
      title: 'Moms’ Morning Coffee Circle',
      schedule: 'Coming soon',
      host: 'Hosted by the Moms Community',
      icon: Icons.coffee_outlined,
      description:
          'Bring your coffee and join an honest, low-pressure conversation about parenting, identity, and asking for help.',
    ),
    _EventInfo(
      id: 'wellness_reset',
      title: 'Sunday Evening Reset',
      schedule: 'Coming soon',
      host: 'Hosted by the Wellness Community',
      icon: Icons.self_improvement_outlined,
      description:
          'A gentle guided reset with breathing, reflection, and one intention for the week ahead.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final values = await Future.wait([
      service.joinedCommunities(),
      service.savedResources(),
      service.registeredEvents(),
      service.memberCounts(communities.map((community) => community.id)),
      VillagePostService().load(),
    ]);
    if (!mounted) return;
    setState(() {
      joined = values[0] as Set<String>;
      savedResources = values[1] as Set<String>;
      registeredEvents = values[2] as Set<String>;
      memberCounts = values[3] as Map<String, int>;
      villagePosts = values[4] as List<VillagePost>;
      for (final id in joined) {
        if ((memberCounts[id] ?? 0) < 1) memberCounts[id] = 1;
      }
      loadingPreferences = false;
    });
  }

  void _selectSection(int index) {
    setState(() => selectedSection = index);
  }

  Future<void> _toggleCommunity(_CommunityInfo community) async {
    final wasJoined = joined.contains(community.id);
    setState(() {
      if (!joined.add(community.id)) joined.remove(community.id);
      memberCounts[community.id] =
          ((memberCounts[community.id] ?? 0) + (wasJoined ? -1 : 1))
              .clamp(0, 999999)
              .toInt();
    });
    await service.saveJoinedCommunities(joined);
    await service.setCommunityMembership(community.id, !wasJoined);
    final refreshed = await service.memberCounts([community.id]);
    if (mounted) {
      setState(() {
        final count = refreshed[community.id] ?? 0;
        memberCounts[community.id] = !wasJoined && count < 1 ? 1 : count;
      });
    }
  }

  Future<void> _toggleResource(_ResourceInfo resource) async {
    setState(() {
      if (!savedResources.add(resource.id)) savedResources.remove(resource.id);
    });
    await service.saveResources(savedResources);
  }

  Future<void> _toggleEvent(_EventInfo event) async {
    setState(() {
      if (!registeredEvents.add(event.id)) registeredEvents.remove(event.id);
    });
    await service.saveRegisteredEvents(registeredEvents);
  }

  String _memberLabel(_CommunityInfo community) {
    final count = memberCounts[community.id] ?? 0;
    return '$count ${count == 1 ? 'member' : 'members'}';
  }

  List<VillagePost> _questionsFor(_CommunityInfo community) {
    return villagePosts.where((post) {
      return community.questionCategories.contains(post.category) ||
          community.supportIntents.contains(post.supportIntent);
    }).toList();
  }

  List<_ResourceInfo> _resourcesFor(_CommunityInfo community) {
    return resources
        .where((resource) => resource.communityIds.contains(community.id))
        .toList();
  }

  void _openCommunityFeed(_CommunityInfo community) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VillageFeedScreen(
          initialSearch: community.conversationSearch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: IconButton(
          tooltip: 'Home',
          onPressed: () => VillageNavigationScope.of(context).onSelect(0),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'Community',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 29,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 12),
              child: Column(
                children: [
                  const Text(
                    'Find your people. Learn. Gather.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF687067)),
                  ),
                  const SizedBox(height: 14),
                  _sectionPicker(),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: selectedSection,
                children: [
                  _communitiesView(),
                  _resourcesView(),
                  _eventsView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionPicker() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: paleSage.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: line),
      ),
      child: Row(
        children: List.generate(sections.length, (index) {
          final section = sections[index];
          final selected = index == selectedSection;
          return Expanded(
            child: Semantics(
              button: true,
              selected: selected,
              label: '${section.$2} section',
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => _selectSection(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: selected
                        ? const [
                            BoxShadow(
                              color: Color(0x16000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(section.$1, color: selected ? sage : ink, size: 20),
                      const SizedBox(height: 3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          section.$2,
                          style: TextStyle(
                            color: selected ? sage : ink,
                            fontSize: 10.5,
                            fontWeight:
                                selected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _communitiesView() {
    return _centeredList(
      children: [
        _featuredCard(),
        const SizedBox(height: 22),
        _sectionHeading(
          'Explore Communities',
          'Join a space and make it your own.',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .88,
          ),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            final isJoined = joined.contains(community.id);
            return _communityCard(community, isJoined);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _featuredCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Image.asset(
              'assets/images/create_account_hero.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -.15),
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: paleSage,
                child: Icon(Icons.groups_2_outlined, color: sage, size: 58),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8BE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'FEATURED THIS WEEK',
                    style: TextStyle(
                      color: sage,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Building healthier communication',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Share what helps you feel heard and learn from neighbors who have been there.',
                  style: TextStyle(color: Colors.white, height: 1.35),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _openCommunityFeed(communities[2]),
                  style: FilledButton.styleFrom(
                    foregroundColor: sage,
                    backgroundColor: cream,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Join the conversation'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _communityCard(_CommunityInfo community, bool isJoined) {
    return Material(
      color: community.color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openCommunity(community),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: .7),
                child: Icon(community.icon, color: sage),
              ),
              const Spacer(),
              Text(
                community.name,
                style: GoogleFonts.playfairDisplay(
                  color: ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _memberLabel(community),
                style: const TextStyle(fontSize: 10.5),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _toggleCommunity(community),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: sage,
                    backgroundColor:
                        isJoined ? Colors.white.withValues(alpha: .7) : null,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(isJoined ? 'Joined' : 'Join'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCommunity(_CommunityInfo community) {
    final questions = _questionsFor(community);
    final communityResources = _resourcesFor(community);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: cream,
          appBar: AppBar(
            backgroundColor: cream,
            title: Text(
              community.name,
              style: GoogleFonts.playfairDisplay(
                color: sage,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: community.color,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 33,
                            backgroundColor: Colors.white.withValues(alpha: .75),
                            child: Icon(community.icon, color: sage, size: 34),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            community.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            community.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(height: 1.4),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _memberLabel(community),
                            style: const TextStyle(
                              color: sage,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _sectionHeading(
                      'Questions Asked',
                      questions.isEmpty
                          ? 'Be the first to ask this community.'
                          : '${questions.length} recent ${questions.length == 1 ? 'question' : 'questions'} from the Village.',
                    ),
                    const SizedBox(height: 10),
                    if (questions.isEmpty)
                      for (final prompt in community.prompts)
                        Card(
                          color: Colors.white.withValues(alpha: .62),
                          child: ListTile(
                            leading: const Icon(
                              Icons.lightbulb_outline_rounded,
                              color: gold,
                            ),
                            title: Text(prompt),
                            subtitle: const Text('Conversation idea'),
                          ),
                        )
                    else
                      for (final post in questions.take(8))
                      Card(
                        color: Colors.white.withValues(alpha: .62),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.of(this.context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => VillageFeedScreen(
                                  initialSearch: post.question,
                                ),
                              ),
                            );
                          },
                          leading: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: sage,
                          ),
                          title: Text(
                            post.question,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${post.author}  •  ${post.replies.length} ${post.replies.length == 1 ? 'reply' : 'replies'}',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      ),
                    const SizedBox(height: 22),
                    _sectionHeading(
                      'Resources for ${community.name}',
                      'Guidance selected for this community.',
                    ),
                    const SizedBox(height: 10),
                    for (final resource in communityResources) ...[
                      _resourceCard(resource),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _openCommunityFeed(community);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: sage,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('View Conversations'),
                    ),
                    const SizedBox(height: 9),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        VillageNavigationScope.of(this.context).onSelect(2);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: sage,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Ask This Community'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resourcesView() {
    return _centeredList(
      children: [
        _sectionHeading(
          'Resource Library',
          'Practical guidance you can return to anytime.',
        ),
        const SizedBox(height: 12),
        if (savedResources.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: paleSage,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Row(
              children: [
                const Icon(Icons.bookmark_rounded, color: sage),
                const SizedBox(width: 10),
                Text(
                  '${savedResources.length} saved resource${savedResources.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final resource in resources) ...[
          _resourceCard(resource),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _resourceCard(_ResourceInfo resource) {
    final saved = savedResources.contains(resource.id);
    return Material(
      color: Colors.white.withValues(alpha: .62),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openResource(resource),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: resource.color,
                child: Icon(resource.icon, color: sage),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.category.toUpperCase(),
                      style: const TextStyle(
                        color: gold,
                        fontSize: 9.5,
                        letterSpacing: .7,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resource.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(resource.readTime,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                tooltip: saved ? 'Remove saved resource' : 'Save resource',
                onPressed: () => _toggleResource(resource),
                icon: Icon(
                  saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: sage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openResource(_ResourceInfo resource) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .78,
        maxChildSize: .94,
        minChildSize: .55,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: resource.color,
              child: Icon(resource.icon, color: sage, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              resource.category.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: gold,
                fontWeight: FontWeight.w900,
                letterSpacing: .8,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              resource.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                color: sage,
                fontSize: 29,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            Text(resource.readTime, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text(resource.introduction,
                style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 20),
            for (var index = 0; index < resource.steps.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: sage,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(resource.steps[index],
                          style: const TextStyle(height: 1.45)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () {
                _toggleResource(resource);
                Navigator.pop(sheetContext);
              },
              style: FilledButton.styleFrom(
                backgroundColor: sage,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: Icon(savedResources.contains(resource.id)
                  ? Icons.bookmark_remove_outlined
                  : Icons.bookmark_add_outlined),
              label: Text(savedResources.contains(resource.id)
                  ? 'Remove from Saved'
                  : 'Save Resource'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventsView() {
    return _centeredList(
      children: [
        _sectionHeading(
          'Live Events',
          'Gather for honest conversations and guided support.',
        ),
        const SizedBox(height: 12),
        for (final event in events) ...[
          _eventCard(event),
          const SizedBox(height: 13),
        ],
        Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: blush,
            borderRadius: BorderRadius.circular(19),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.notifications_active_outlined, color: sage),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Tap Notify Me to follow an event. Dates and access details will appear here once each event is officially scheduled.',
                  style: TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _eventCard(_EventInfo event) {
    final registered = registeredEvents.contains(event.id);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .66),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: paleSage,
                child: Icon(event.icon, color: sage),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'LIVE COMMUNITY EVENT',
                  style: const TextStyle(
                    color: gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ),
              if (registered)
                const Icon(Icons.check_circle_rounded, color: sage),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            event.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 23,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(event.schedule,
              style: const TextStyle(color: sage, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(event.host, style: const TextStyle(fontSize: 11.5)),
          const SizedBox(height: 10),
          Text(event.description, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _toggleEvent(event),
              style: FilledButton.styleFrom(
                backgroundColor: registered ? paleSage : sage,
                foregroundColor: registered ? sage : Colors.white,
              ),
              icon: Icon(registered
                  ? Icons.notifications_off_outlined
                  : Icons.notifications_active_outlined),
              label: Text(registered ? 'Turn Off Reminder' : 'Notify Me'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Color(0xFF687067))),
      ],
    );
  }

  Widget _centeredList({required List<Widget> children}) {
    if (loadingPreferences) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: children,
        ),
      ),
    );
  }
}

class _CommunityInfo {
  const _CommunityInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.memberLabel,
    required this.conversationSearch,
    required this.prompts,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String memberLabel;
  final String conversationSearch;
  final List<String> prompts;

  List<String> get questionCategories => switch (id) {
        'moms' => const ['Parenting'],
        'relationships' => const ['Relationships'],
        'wellness' => const ['Mental Health'],
        'friendship' => const ['Friendship'],
        'career' => const ['Work & School'],
        'grief' => const ['Mental Health', 'Life & Growth'],
        _ => const ['Life & Growth'],
      };

  List<String> get supportIntents => switch (id) {
        'faith' => const ['Prayer'],
        'caregivers' => const ['Practical help'],
        _ => const [],
      };
}

class _ResourceInfo {
  const _ResourceInfo({
    required this.id,
    required this.title,
    required this.category,
    required this.readTime,
    required this.icon,
    required this.color,
    required this.introduction,
    required this.steps,
    required this.communityIds,
  });

  final String id;
  final String title;
  final String category;
  final String readTime;
  final IconData icon;
  final Color color;
  final String introduction;
  final List<String> steps;
  final List<String> communityIds;
}

class _EventInfo {
  const _EventInfo({
    required this.id,
    required this.title,
    required this.schedule,
    required this.host,
    required this.icon,
    required this.description,
  });

  final String id;
  final String title;
  final String schedule;
  final String host;
  final IconData icon;
  final String description;
}
