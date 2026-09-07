import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/village_post_service.dart';
import '../services/profile_service.dart';
import '../navigation/village_navigation_scope.dart';
import 'ask_village_screen.dart';

class VillageFeedScreen extends StatefulWidget {
  const VillageFeedScreen({super.key, this.initialFilter = 'All'});

  final String initialFilter;

  @override
  State<VillageFeedScreen> createState() => _VillageFeedScreenState();
}

class _VillageFeedScreenState extends State<VillageFeedScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const paleSage = Color(0xFFE8EBDD);
  static const gold = Color(0xFFB78943);
  static const blush = Color(0xFFF3E2DD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  final VillagePostService service = VillagePostService();
  final TextEditingController searchController = TextEditingController();
  List<VillagePost> posts = [];
  final Set<String> expandedReplyPosts = {};
  bool loading = true;
  String currentUsername = 'KindHeart';
  late String filter;

  static const filters = [
    'All',
    'My Posts',
    'My Circle',
    'Saved',
    'Needs Support',
  ];

  @override
  void initState() {
    super.initState();
    filter = filters.contains(widget.initialFilter) ? widget.initialFilter : 'All';
    searchController.addListener(_refresh);
    currentUsername =
        ProfileService.usernameNotifier.value ?? 'KindHeart';
    ProfileService.usernameNotifier.addListener(_usernameChanged);
    ProfileService.currentUsername();
    _load();
  }

  String get currentHandle => '@$currentUsername';

  void _usernameChanged() {
    final username = ProfileService.usernameNotifier.value?.trim();
    if (!mounted || username == null || username.isEmpty) return;
    setState(() => currentUsername = username);
  }

  String _postAuthor(VillagePost post) {
    if (post.isMine && post.author != 'Anonymous Neighbor') {
      return currentHandle;
    }
    return post.author;
  }

  String _replyAuthor(VillageReply reply) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMyReply = reply.authorUid == currentUid ||
        (reply.authorUid == null && reply.author == '@KindHeart');
    if (isMyReply && reply.author != 'Anonymous Neighbor') {
      return currentHandle;
    }
    return reply.author;
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    final saved = await service.load();
    if (!mounted) return;
    final savedIds = saved.map((post) => post.id).toSet();
    final newSamples = service.lastLoadUsedCloud
        ? const <VillagePost>[]
        : _samplePosts().where((post) => !savedIds.contains(post.id));
    setState(() {
      posts = [...saved, ...newSamples];
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      loading = false;
    });
  }

  List<VillagePost> _samplePosts() {
    final now = DateTime.now();
    return [
      VillagePost(
        id: 'sample-rest',
        question:
            'What helps you quiet your mind when you know you need rest but cannot slow down?',
        category: 'Mental Health',
        audience: 'The Village',
        author: '@GentleGrowth',
        createdAt: now.subtract(const Duration(minutes: 24)),
        needsSupport: true,
        supportCount: 18,
        replies: [
          VillageReply(
            id: 'sample-rest-reply-1',
            text:
                'I put my phone in another room and breathe for five minutes.',
            author: '@CalmCorner',
            createdAt: now.subtract(const Duration(minutes: 18)),
            supportCount: 7,
          ),
          VillageReply(
            id: 'sample-rest-reply-2',
            text:
                'A warm shower and writing down tomorrow’s worries helps me.',
            author: 'Anonymous Neighbor',
            createdAt: now.subtract(const Duration(minutes: 12)),
            supportCount: 4,
          ),
        ],
        isMine: false,
      ),
      VillagePost(
        id: 'sample-boundaries',
        question:
            'How do you set a boundary with family without feeling like you are abandoning them?',
        category: 'Relationships',
        audience: 'The Village',
        author: 'Anonymous Neighbor',
        createdAt: now.subtract(const Duration(hours: 3)),
        needsSupport: false,
        supportCount: 31,
        replies: [
          VillageReply(
            id: 'sample-boundaries-reply-1',
            text:
                'A boundary can protect the relationship instead of ending it.',
            author: '@GentleTruth',
            createdAt: now.subtract(const Duration(hours: 2)),
            supportCount: 11,
          ),
        ],
        isMine: false,
      ),
      VillagePost(
        id: 'sample-parent',
        question:
            'What is one simple routine that made weekday mornings easier for your family?',
        category: 'Parenting',
        audience: 'My Circle',
        author: '@MorningGrace',
        createdAt: now.subtract(const Duration(days: 1)),
        needsSupport: false,
        supportCount: 12,
        replies: const <VillageReply>[],
        isMine: false,
      ),
    ];
  }

  List<VillagePost> get visiblePosts {
    final query = searchController.text.trim().toLowerCase();
    return posts.where((post) {
      final matchesFilter = switch (filter) {
        'My Posts' => post.isMine,
        'My Circle' => post.audience == 'My Circle',
        'Saved' => post.saved,
        'Needs Support' => post.needsSupport,
        _ => true,
      };
      final matchesSearch = query.isEmpty ||
          post.question.toLowerCase().contains(query) ||
          post.category.toLowerCase().contains(query) ||
          _postAuthor(post).toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _persistMine() {
    return service.save(posts);
  }

  Future<void> _toggleSupport(VillagePost post) async {
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index < 0) return;
    final supported = !post.supportedByMe;
    setState(() {
      posts[index] = post.copyWith(
        supportedByMe: supported,
        supportCount: post.supportCount + (supported ? 1 : -1),
      );
    });
    await _persistMine();
  }

  Future<void> _toggleSaved(VillagePost post) async {
    final index = posts.indexWhere((item) => item.id == post.id);
    if (index < 0) return;
    setState(() => posts[index] = post.copyWith(saved: !post.saved));
    await _persistMine();
  }

  void _toggleReplies(VillagePost post) {
    setState(() {
      if (!expandedReplyPosts.add(post.id)) {
        expandedReplyPosts.remove(post.id);
      }
    });
  }

  Future<void> _openReplies(VillagePost post) async {
    final controller = TextEditingController();
    var anonymous = false;
    final reply = await showModalBottomSheet<VillageReply>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final activePost = posts.firstWhere(
            (item) => item.id == post.id,
            orElse: () => post,
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              2,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replies to this post',
                    style: GoogleFonts.playfairDisplay(
                      color: sage,
                      fontSize: 29,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (activePost.replies.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Be the first person to respond with care.'),
                    )
                  else
                    for (final existing in activePost.replies) ...[
                      _replyTile(
                        activePost.id,
                        existing,
                        onChanged: () => setSheetState(() {}),
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    minLines: 2,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Reply with kindness…',
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .62),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const Text(
                    'Post this reply as:',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        avatar: const Icon(Icons.person_outline_rounded, size: 17),
                        label: const Text('@KindHeart'),
                        selected: !anonymous,
                        onSelected: (_) => setSheetState(() => anonymous = false),
                        selectedColor: paleSage,
                        side: const BorderSide(color: line),
                        showCheckmark: false,
                      ),
                      ChoiceChip(
                        avatar: const Icon(
                          Icons.visibility_off_outlined,
                          size: 17,
                        ),
                        label: const Text('Anonymous'),
                        selected: anonymous,
                        onSelected: (_) => setSheetState(() => anonymous = true),
                        selectedColor: blush,
                        side: const BorderSide(color: line),
                        showCheckmark: false,
                      ),
                    ],
                  ),
                  if (anonymous) ...[
                    const SizedBox(height: 7),
                    const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: sage, size: 16),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Your username will not appear with this reply.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final text = controller.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Write a reply first.'),
                            ),
                          );
                          return;
                        }
                        final now = DateTime.now();
                        Navigator.pop(
                          sheetContext,
                          VillageReply(
                            id: now.microsecondsSinceEpoch.toString(),
                            text: text,
                            author:
                                anonymous ? 'Anonymous Neighbor' : currentHandle,
                            authorUid: anonymous
                                ? null
                                : FirebaseAuth.instance.currentUser?.uid,
                            createdAt: now,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: sage,
                        padding: const EdgeInsets.all(15),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(
                        anonymous
                            ? 'Post Anonymous Reply'
                            : 'Post as $currentHandle',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    controller.dispose();
    if (reply == null || !mounted) return;

    final index = posts.indexWhere((item) => item.id == post.id);
    if (index < 0) return;
    setState(() {
      final current = posts[index];
      posts[index] = current.copyWith(replies: [...current.replies, reply]);
      expandedReplyPosts.add(post.id);
    });
    await _persistMine();
  }

  Future<void> _toggleReplySupport(String postId, String replyId) async {
    final postIndex = posts.indexWhere((item) => item.id == postId);
    if (postIndex < 0) return;
    final currentPost = posts[postIndex];
    final replyIndex =
        currentPost.replies.indexWhere((item) => item.id == replyId);
    if (replyIndex < 0) return;
    final currentReply = currentPost.replies[replyIndex];
    final supported = !currentReply.supportedByMe;
    final updatedReplies = List<VillageReply>.of(currentPost.replies);
    updatedReplies[replyIndex] = currentReply.copyWith(
      supportedByMe: supported,
      supportCount: currentReply.supportCount + (supported ? 1 : -1),
    );
    setState(() {
      posts[postIndex] = currentPost.copyWith(replies: updatedReplies);
    });
    await _persistMine();
  }


  Future<void> _deletePost(VillagePost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cream,
        title: const Text('Delete this post?'),
        content: const Text(
          'This permanently removes it from the Village and My Posts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep It'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await service.delete(post);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This post could not be deleted. Please try again.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => posts.removeWhere((item) => item.id == post.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post deleted.')),
    );
  }

  void _report(VillagePost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you. This post was sent for safety review.'),
      ),
    );
  }

  @override
  void dispose() {
    ProfileService.usernameNotifier.removeListener(_usernameChanged);
    searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _createVillagePost() async {
    VillageNavigationScope.of(context).onSelect(2);
  }

  @override
  Widget build(BuildContext context) {
    final shown = visiblePosts;
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              VillageNavigationScope.of(context).onSelect(0),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'The Village',
          style: GoogleFonts.playfairDisplay(
            color: sage,
            fontSize: 29,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 30),
                      children: [
                        _welcomeCard(),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _createVillagePost,
                            style: FilledButton.styleFrom(
                              backgroundColor: sage,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text(
                              'Create a Post',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search questions, topics, or usernames',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: .58),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: filters.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 7),
                            itemBuilder: (_, index) {
                              final option = filters[index];
                              return ChoiceChip(
                                label: Text(option),
                                selected: filter == option,
                                onSelected: (_) {
                                  setState(() => filter = option);
                                },
                                selectedColor: paleSage,
                                side: const BorderSide(color: line),
                                showCheckmark: false,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (shown.isEmpty)
                          _emptyState()
                        else
                          for (final post in shown) ...[
                            _postCard(post),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: sage,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFE8BE),
            child: Icon(Icons.forum_outlined, color: sage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Real questions. Real care.',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Listen, share what helped, and remind someone they are not alone.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .55),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_outlined, color: sage, size: 38),
          const SizedBox(height: 10),
          Text(
            filter == 'My Posts'
                ? 'Your questions will appear here after you publish them.'
                : 'No posts match this view yet.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _createVillagePost,
            style: FilledButton.styleFrom(backgroundColor: sage),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create a Post'),
          ),
        ],
      ),
    );
  }

  Widget _replyTile(
    String postId,
    VillageReply reply, {
    VoidCallback? onChanged,
  }) {
    final anonymous = reply.author == 'Anonymous Neighbor';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: paleSage.withValues(alpha: .58),
        border: Border.all(color: line.withValues(alpha: .7)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: anonymous ? blush : Colors.white,
            child: Icon(
              anonymous
                  ? Icons.visibility_off_outlined
                  : Icons.person_outline_rounded,
              color: sage,
              size: 17,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyAuthor(reply),
                  style: const TextStyle(
                    color: sage,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(reply.text),
                const SizedBox(height: 3),
                Text(
                  _timeLabel(reply.createdAt),
                  style: const TextStyle(fontSize: 10, color: Color(0xFF687067)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Column(
            children: [
              IconButton(
                tooltip: reply.supportedByMe
                    ? 'Remove support from reply'
                    : 'Support this reply',
                onPressed: () async {
                  await _toggleReplySupport(postId, reply.id);
                  onChanged?.call();
                },
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  reply.supportedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: reply.supportedByMe ? const Color(0xFFB8656E) : sage,
                  size: 19,
                ),
              ),
              Text(
                '${reply.supportCount}',
                style: const TextStyle(
                  color: sage,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _postCard(VillagePost post) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .62),
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: post.author == 'Anonymous Neighbor'
                    ? blush
                    : paleSage,
                child: Icon(
                  post.author == 'Anonymous Neighbor'
                      ? Icons.visibility_off_outlined
                      : Icons.person_outline_rounded,
                  color: sage,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _postAuthor(post),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      _timeLabel(post.createdAt),
                      style: const TextStyle(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              if (post.isMine)
                const Chip(
                  label: Text('My Post'),
                  visualDensity: VisualDensity.compact,
                ),
              PopupMenuButton<String>(
                tooltip: 'Post options',
                onSelected: (value) {
                  if (value == 'delete') {
                    _deletePost(post);
                  } else {
                    _report(post);
                  }
                },
                itemBuilder: (_) => [
                  if (post.isMine)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded),
                          SizedBox(width: 8),
                          Text('Delete my post'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'report',
                      child: Text('Report for safety review'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            children: [
              _label(post.category, paleSage),
              _label(
                post.audience == 'My Circle' ? 'Circle only' : 'Village',
                const Color(0xFFFFE8BE),
              ),
              if (post.needsSupport) _label('Needs support', blush),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.question,
            style: const TextStyle(
              color: ink,
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 13),
          const Divider(height: 1),
          const SizedBox(height: 7),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _toggleSupport(post),
                icon: Icon(
                  post.supportedByMe
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                ),
                label: Text('Support ${post.supportCount}'),
              ),
              TextButton.icon(
                onPressed: () => _openReplies(post),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: Text(
                  post.replies.isEmpty
                      ? 'Be first to reply'
                      : 'Reply (${post.replies.length})',
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: post.saved ? 'Remove saved post' : 'Save post',
                onPressed: () => _toggleSaved(post),
                icon: Icon(
                  post.saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: sage,
                ),
              ),
            ],
          ),
          if (post.replies.isNotEmpty) ...[
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _toggleReplies(post),
                style: TextButton.styleFrom(
                  foregroundColor: sage,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                ),
                child: Row(
                  children: [
                    Text(
                      expandedReplyPosts.contains(post.id)
                          ? 'Hide replies'
                          : 'View all ${post.replies.length} '
                              '${post.replies.length == 1 ? 'reply' : 'replies'}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      expandedReplyPosts.contains(post.id)
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (expandedReplyPosts.contains(post.id)) ...[
              const SizedBox(height: 4),
              for (final reply in post.replies) ...[
                _replyTile(post.id, reply),
                const SizedBox(height: 8),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _openReplies(post),
                  icon: const Icon(Icons.add_comment_outlined, size: 18),
                  label: const Text('Add your reply'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _label(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _timeLabel(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hr ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
