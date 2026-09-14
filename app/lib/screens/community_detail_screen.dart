import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';
import '../services/community_hub_service.dart';
import '../services/village_post_service.dart';
import 'ask_village_screen.dart';
import 'village_feed_screen.dart';

class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({
    super.key,
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;

  @override
  State<CommunityDetailScreen> createState() =>
      _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const gold = Color(0xFFB78943);
  static const line = Color(0xFFE7DED1);
  static const softSage = Color(0xFFE9EEE4);
  static const softGold = Color(0xFFF5EBDD);

  final hubService = CommunityHubService();
  final postService = VillagePostService();
  final adminService = AdminContentService();

  bool loading = true;
  bool joined = false;
  int memberCount = 0;
  int selectedTab = 0;
  String conversationFilter = 'New';
  List<VillagePost> communityPosts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final joinedCommunities = await hubService.joinedCommunities();
      final counts = await hubService.memberCounts([widget.id]);
      final allPosts = await postService.load();
      final name = widget.name.toLowerCase();
      final category = widget.category.toLowerCase();
      final filtered = allPosts.where((post) {
        final exact = post.communityId == widget.id ||
            post.communityName?.toLowerCase() == name;
        final legacy = post.communityId == null &&
            post.communityName == null &&
            post.category.toLowerCase() == category;
        return exact || legacy;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        joined = joinedCommunities.contains(widget.id);
        memberCount = counts[widget.id] ?? 0;
        communityPosts = filtered;
        loading = false;
      });
    } on Object {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggleJoin() async {
    final next = !joined;
    final saved = await hubService.joinedCommunities();
    next ? saved.add(widget.id) : saved.remove(widget.id);
    setState(() {
      joined = next;
      memberCount = (memberCount + (next ? 1 : -1)).clamp(0, 999999).toInt();
    });
    await hubService.saveJoinedCommunities(saved);
    await hubService.setCommunityMembership(widget.id, next);
  }

  Future<void> _ask({String? suggestedQuestion}) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AskVillageScreen(
        initialCategory: widget.category,
        initialCommunityId: widget.id,
        initialCommunityName: widget.name,
        initialQuestion: suggestedQuestion,
      ),
    ));
    await _load();
  }

  bool _belongs(ManagedContentItem item) {
    final community = item.text('community').trim().toLowerCase();
    return community == widget.name.toLowerCase() ||
        community == widget.category.toLowerCase() ||
        community == widget.id.toLowerCase() ||
        community == 'admin_${widget.id}'.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: sage))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 42),
                children: [
                  _topBar(),
                  const SizedBox(height: 8),
                  _hero(),
                  const SizedBox(height: 14),
                  _membershipRow(),
                  const SizedBox(height: 18),
                  _startHere(),
                  const SizedBox(height: 16),
                  _composer(),
                  const SizedBox(height: 20),
                  _tabs(),
                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: KeyedSubtree(
                      key: ValueKey(selectedTab),
                      child: switch (selectedTab) {
                        1 => _resourcesTab(),
                        2 => _eventsTab(),
                        _ => _conversationsTab(),
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _topBar() => Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: ink),
          ),
          const Spacer(),
          Text(
            'COMMUNITY',
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: gold,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Community options',
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: cream,
              showDragHandle: true,
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.shield_outlined, color: sage),
                        title: const Text('Community guidelines'),
                        subtitle: const Text('Kindness, privacy, and real support.'),
                        onTap: () => Navigator.pop(context),
                      ),
                      ListTile(
                        leading: const Icon(Icons.flag_outlined, color: sage),
                        title: const Text('Report a concern'),
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            icon: const Icon(Icons.more_horiz_rounded, color: ink),
          ),
        ],
      );

  Widget _hero() => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 225,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.imageUrl.isEmpty
                  ? _fallbackCover()
                  : Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover(),
                    ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x08000000), Color(0xD9000000)],
                    stops: [.28, 1],
                  ),
                ),
              ),
              Positioned(
                left: 20,
                right: 20,
                bottom: 19,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _membershipRow() => Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: softSage,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.people_outline_rounded, size: 17, color: sage),
                const SizedBox(width: 6),
                Text(
                  '$memberCount ${memberCount == 1 ? 'member' : 'members'}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'A supportive, judgment-free space',
            style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF667066)),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _toggleJoin,
            style: FilledButton.styleFrom(
              backgroundColor: joined ? softSage : sage,
              foregroundColor: joined ? sage : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
            icon: Icon(joined ? Icons.check_rounded : Icons.add_rounded, size: 17),
            label: Text(joined ? 'Joined' : 'Join'),
          ),
        ],
      );

  Widget _startHere() => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: softSage.withValues(alpha: .8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start here',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Choose what you need right now.',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF5E685F)),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Expanded(
                  child: _pathCard(
                    Icons.masks_outlined,
                    'Ask anonymously',
                    'Share safely',
                    () => _ask(),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _pathCard(
                    Icons.auto_stories_outlined,
                    'Browse advice',
                    'Practical help',
                    () => setState(() => selectedTab = 1),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _pathCard(
                    Icons.groups_2_outlined,
                    'Join live support',
                    'Find events',
                    () => setState(() => selectedTab = 2),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _pathCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: sage, size: 23),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF6B746C)),
              ),
            ],
          ),
        ),
      );

  Widget _composer() => InkWell(
        onTap: () => _ask(),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .82),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: line),
            boxShadow: const [
              BoxShadow(color: Color(0x0D172019), blurRadius: 18, offset: Offset(0, 7)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: softGold, shape: BoxShape.circle),
                child: const Icon(Icons.edit_outlined, color: sage, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What’s on your heart?',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ask a question, share a win, or request support.',
                      style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF667066)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: sage),
            ],
          ),
        ),
      );

  Widget _tabs() {
    const tabs = [
      ('Conversations', Icons.forum_outlined),
      ('Resources', Icons.menu_book_outlined),
      ('Events', Icons.calendar_month_outlined),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softSage,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final active = selectedTab == index;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => selectedTab = index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tabs[index].$2, size: 17, color: active ? sage : ink),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        tabs[index].$1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active ? sage : ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _conversationsTab() {
    final posts = [...communityPosts];
    if (conversationFilter == 'Needs Support') {
      posts.sort((a, b) => a.replies.length.compareTo(b.replies.length));
    } else if (conversationFilter == 'Most Helpful') {
      posts.sort((a, b) => b.supportCount.compareTo(a.supportCount));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Community conversations', 'Real people. Real support.'),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['New', 'Needs Support', 'Most Helpful'].map((filter) {
            final active = conversationFilter == filter;
            return ChoiceChip(
              label: Text(filter),
              selected: active,
              onSelected: (_) => setState(() => conversationFilter = filter),
              selectedColor: sage,
              backgroundColor: softGold,
              side: BorderSide.none,
              labelStyle: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : ink,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 13),
        if (posts.isEmpty)
          _emptyQuestions()
        else
          for (final post in posts.take(5)) ...[
            _questionCard(post),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => VillageFeedScreen(initialSearch: widget.name),
            )),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('View all conversations'),
          ),
        ),
        const SizedBox(height: 26),
        _sectionTitle('Conversation starters', 'Not sure what to ask?'),
        const SizedBox(height: 11),
        _suggestions(),
      ],
    );
  }

  Widget _resourcesTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recommended for you', 'Helpful next steps'),
          const SizedBox(height: 6),
          Text(
            'Practical guidance created for the ${widget.name} community.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xFF646D65),
            ),
          ),
          const SizedBox(height: 13),
          _managedSection(
            'resources',
            _resourceCard,
            'Community-specific resources will appear here as they are published.',
            excludeQuestions: true,
          ),
        ],
      );

  Widget _eventsTab() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Live support & events', 'Connect in real time'),
          const SizedBox(height: 6),
          Text(
            'Join guided conversations, workshops, and community gatherings.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: const Color(0xFF646D65),
            ),
          ),
          const SizedBox(height: 13),
          _managedSection(
            'events',
            _eventCard,
            'Events for this community will appear here as they are published.',
          ),
        ],
      );

  Widget _fallbackCover() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF355C3B), Color(0xFF6F876B)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.groups_2_outlined, color: Colors.white, size: 56),
        ),
      );

  Widget _questionCard(VillagePost post) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => VillageFeedScreen(initialSearch: post.question),
        )),
        child: _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: softSage,
                    child: Icon(
                      post.author.toLowerCase().contains('anonymous')
                          ? Icons.masks_outlined
                          : Icons.person_outline_rounded,
                      size: 18,
                      color: sage,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      post.author,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: sage,
                      ),
                    ),
                  ),
                  if (post.replies.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6E4DF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Needs Support',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.question,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 11),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: sage),
                  const SizedBox(width: 4),
                  Text('${post.replies.length} replies'),
                  const SizedBox(width: 13),
                  const Icon(Icons.favorite_border_rounded, size: 15, color: sage),
                  const SizedBox(width: 4),
                  Text('${post.supportCount} helpful'),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_rounded, size: 17, color: sage),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _emptyQuestions() => _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Start the conversation.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'No questions have been posted in ${widget.name} yet. Your question may be exactly what someone else needs too.',
              style: GoogleFonts.inter(fontSize: 12.5, height: 1.45),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _ask(),
              style: FilledButton.styleFrom(backgroundColor: sage),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Ask the first question'),
            ),
          ],
        ),
      );

  List<ManagedContentItem> _fallbackItems(String type) {
    if (widget.id != 'men') return const <ManagedContentItem>[];
    if (type == 'resources') {
      return const [
        ManagedContentItem(id: 'men_support', data: {
          'title': 'Strength includes asking for support',
          'description': 'A practical guide to naming pressure, opening an honest conversation, and building dependable friendships.',
          'category': 'Men',
        }),
        ManagedContentItem(id: 'fatherhood', data: {
          'title': 'Showing up as the father you want to be',
          'description': 'Use presence, patience, repair, and everyday consistency to help children feel safe, seen, and supported.',
          'category': 'Men',
        }),
        ManagedContentItem(id: 'mens_relationships', data: {
          'title': 'Communicating before frustration becomes distance',
          'description': 'Simple ways to name what you need, listen without becoming defensive, and reconnect with your partner.',
          'category': 'Men',
        }),
      ];
    }
    if (type == 'questions') {
      return const [
        ManagedContentItem(id: 'men_question_pressure', data: {
          'kind': 'question',
          'question': 'How do you handle the pressure to always appear strong?',
          'category': 'Men',
        }),
        ManagedContentItem(id: 'men_question_friendship', data: {
          'kind': 'question',
          'question': 'How have you built honest friendships with other men as an adult?',
          'category': 'Men',
        }),
        ManagedContentItem(id: 'men_question_fatherhood', data: {
          'kind': 'question',
          'question': 'What has helped you become a more present father or partner?',
          'category': 'Men',
        }),
      ];
    }
    return const <ManagedContentItem>[];
  }

  Widget _managedCards(List<ManagedContentItem> items, Widget Function(ManagedContentItem) card) {
    return Column(
      children: [
        for (final item in items.take(6)) ...[
          card(item),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _suggestions() {
    if (!adminService.cloudReady) {
      final fallback = _fallbackItems('questions');
      return fallback.isEmpty
          ? _empty('Suggested conversation starters will appear here.')
          : _managedCards(fallback, _suggestionCard);
    }
    return StreamBuilder<List<ManagedContentItem>>(
      stream: adminService.watchPublished('resources'),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <ManagedContentItem>[])
            .where((item) => item.text('kind').toLowerCase() == 'question')
            .where(_belongs)
            .where((item) {
          final question = item.text('question', item.text('title'));
          return !communityPosts.any(
            (post) => post.question.trim().toLowerCase() == question.trim().toLowerCase(),
          );
        }).toList();
        final visible = items.isEmpty ? _fallbackItems('questions') : items;
        if (visible.isEmpty) {
          return _empty('No suggested questions right now. Ask what is on your mind.');
        }
        return _managedCards(visible.take(3).toList(), _suggestionCard);
      },
    );
  }

  Widget _suggestionCard(ManagedContentItem item) {
    final question = item.text('question', item.text('title', 'Start a conversation'));
    return _card(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              question,
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _ask(suggestedQuestion: question),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  Widget _managedSection(
    String type,
    Widget Function(ManagedContentItem) card,
    String empty, {
    bool excludeQuestions = false,
  }) {
    if (!adminService.cloudReady) {
      final fallback = _fallbackItems(type);
      return fallback.isEmpty ? _empty(empty) : _managedCards(fallback, card);
    }
    return StreamBuilder<List<ManagedContentItem>>(
      stream: adminService.watchPublished(type),
      builder: (context, snapshot) {
        final items = (snapshot.data ?? const <ManagedContentItem>[])
            .where(_belongs)
            .where(
              (item) => !excludeQuestions || item.text('kind').toLowerCase() != 'question',
            )
            .toList();
        final visible = items.isEmpty ? _fallbackItems(type) : items;
        if (visible.isEmpty) return _empty(empty);
        return _managedCards(visible, card);
      },
    );
  }

  Widget _resourceCard(ManagedContentItem item) => _card(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: softGold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_stories_outlined, color: sage),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text('title', 'Resource'),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.text('description', item.text('body')),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    item.text('readTime', 'Practical guide'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: gold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: sage),
          ],
        ),
      );

  Widget _eventCard(ManagedContentItem item) => _card(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: softSage,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.calendar_month_outlined, color: sage),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text('title', 'Village event'),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.text('dateTimeLabel', 'Coming soon'),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.text('description'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, size: 18, color: sage),
          ],
        ),
      );

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .78),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: line),
        ),
        child: child,
      );

  Widget _empty(String text) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: softSage.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: ink),
        ),
      );

  Widget _sectionTitle(String title, String note) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
          Text(
            note,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: gold,
            ),
          ),
        ],
      );
}
