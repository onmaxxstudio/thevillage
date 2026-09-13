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
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const gold = Color(0xFFB78943);
  static const line = Color(0xFFE7DED1);

  final CommunityHubService hubService = CommunityHubService();
  final VillagePostService postService = VillagePostService();
  final AdminContentService adminService = AdminContentService();

  bool loading = true;
  bool joined = false;
  int memberCount = 0;
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
        final exactCommunity = post.communityId == widget.id ||
            post.communityName?.toLowerCase() == name;
        final legacyCategory = post.communityId == null &&
            post.communityName == null &&
            post.category.toLowerCase() == category;
        return exactCommunity || legacyCategory;
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
    if (next) {
      saved.add(widget.id);
    } else {
      saved.remove(widget.id);
    }
    setState(() {
      joined = next;
      memberCount = (memberCount + (next ? 1 : -1)).clamp(0, 999999).toInt();
    });
    await hubService.saveJoinedCommunities(saved);
    await hubService.setCommunityMembership(widget.id, next);
  }

  Future<void> _ask() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => AskVillageScreen(
        initialCategory: widget.category,
        initialCommunityId: widget.id,
        initialCommunityName: widget.name,
      ),
    ));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(color: sage))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                children: [
                  Row(children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: ink),
                    ),
                    const Spacer(),
                    Text('COMMUNITY', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: gold)),
                  ]),
                  const SizedBox(height: 8),
                  _hero(),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.people_outline_rounded, size: 18, color: sage),
                    const SizedBox(width: 6),
                    Text('$memberCount ${memberCount == 1 ? 'member' : 'members'}', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: ink)),
                    const Spacer(),
                    Text(widget.category, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: gold)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _toggleJoin,
                        style: FilledButton.styleFrom(
                          backgroundColor: joined ? const Color(0xFFE9EEE4) : sage,
                          foregroundColor: joined ? sage : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(joined ? 'Joined' : 'Join Community'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _ask,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: sage,
                          side: const BorderSide(color: sage),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Ask'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 28),
                  _sectionTitle('Questions from this community', 'Real conversations'),
                  const SizedBox(height: 12),
                  if (communityPosts.isEmpty)
                    _emptyQuestions()
                  else
                    for (final post in communityPosts.take(5)) ...[
                      _questionCard(post),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 18),
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
                  const SizedBox(height: 28),
                  _sectionTitle('Resources for ${widget.name}', 'Helpful next steps'),
                  const SizedBox(height: 12),
                  _resources(),
                ],
              ),
      ),
    );
  }

  Widget _hero() => ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 260,
          child: Stack(fit: StackFit.expand, children: [
            widget.imageUrl.isEmpty
                ? _fallbackCover()
                : Image.network(widget.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackCover()),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x16000000), Color(0xD9000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.name, style: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(widget.description, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, height: 1.4)),
              ]),
            ),
          ]),
        ),
      );

  Widget _fallbackCover() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF355C3B), Color(0xFF6F876B)]),
        ),
        child: const Center(child: Icon(Icons.groups_2_outlined, color: Colors.white, size: 56)),
      );

  Widget _questionCard(VillagePost post) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => VillageFeedScreen(initialSearch: post.question))),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .76), borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.question, maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 10),
            Row(children: [
              Text(post.author, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: sage)),
              const Spacer(),
              const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: sage),
              const SizedBox(width: 4),
              Text('${post.replies.length}', style: const TextStyle(fontSize: 11, color: ink)),
              const SizedBox(width: 12),
              const Icon(Icons.favorite_border_rounded, size: 15, color: sage),
              const SizedBox(width: 4),
              Text('${post.supportCount}', style: const TextStyle(fontSize: 11, color: ink)),
            ]),
          ]),
        ),
      );

  Widget _emptyQuestions() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Start the conversation.', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 5),
          Text('No questions have been posted in ${widget.name} yet. Ask something you have been carrying, wondering, or working through.', style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: const Color(0xFF646B65))),
          const SizedBox(height: 12),
          TextButton.icon(onPressed: _ask, icon: const Icon(Icons.add_rounded), label: const Text('Ask the first question')),
        ]),
      );

  Widget _resources() {
    if (!adminService.cloudReady) return _resourceEmpty();
    return StreamBuilder<List<ManagedContentItem>>(
      stream: adminService.watchPublished('resources'),
      builder: (context, snapshot) {
        final targetName = widget.name.toLowerCase();
        final targetCategory = widget.category.toLowerCase();
        final items = (snapshot.data ?? const <ManagedContentItem>[]).where((item) {
          final community = item.text('community').trim().toLowerCase();
          return community == targetName || community == targetCategory;
        }).toList();
        if (items.isEmpty) return _resourceEmpty();
        return Column(children: [
          for (final item in items.take(4)) ...[
            _resourceCard(item),
            const SizedBox(height: 10),
          ],
        ]);
      },
    );
  }

  Widget _resourceCard(ManagedContentItem item) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .76), borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE9EEE4), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.auto_stories_outlined, color: sage)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.text('title', 'Resource'), style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 4),
            Text(item.text('description', item.text('body')), maxLines: 3, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: const Color(0xFF626A63))),
          ])),
        ]),
      );

  Widget _resourceEmpty() => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: const Color(0xFFE9EEE4).withValues(alpha: .7), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const Icon(Icons.menu_book_outlined, color: sage),
          const SizedBox(width: 12),
          Expanded(child: Text('Community-specific resources will appear here as they are published.', style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: ink))),
        ]),
      );

  Widget _sectionTitle(String title, String note) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: ink))),
          Text(note, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: gold)),
        ],
      );
}
