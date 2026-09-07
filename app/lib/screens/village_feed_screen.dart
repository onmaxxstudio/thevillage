import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/village_post_service.dart';

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
  bool loading = true;
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
    _load();
  }

  void _refresh() => setState(() {});

  Future<void> _load() async {
    final mine = await service.load();
    if (!mounted) return;
    setState(() {
      posts = [...mine, ..._samplePosts()];
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
        replies: const [
          'I put my phone in another room and breathe for five minutes.',
          'A warm shower and writing down tomorrow’s worries helps me.',
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
        replies: const [
          'A boundary can protect the relationship instead of ending it.',
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
        replies: const [],
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
          post.author.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _persistMine() {
    return service.save(posts.where((post) => post.isMine).toList());
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

  Future<void> _openReplies(VillagePost post) async {
    final controller = TextEditingController();
    final reply = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cream,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
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
                'Village Replies',
                style: GoogleFonts.playfairDisplay(
                  color: sage,
                  fontSize: 29,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (post.replies.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('Be the first person to respond with care.'),
                )
              else
                for (final existing in post.replies) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .58),
                      border: Border.all(color: line),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(existing),
                  ),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isNotEmpty) Navigator.pop(sheetContext, text);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: sage,
                    padding: const EdgeInsets.all(15),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Post Reply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.dispose();
    if (reply == null || !mounted) return;

    final index = posts.indexWhere((item) => item.id == post.id);
    if (index < 0) return;
    setState(() {
      posts[index] = post.copyWith(replies: [...post.replies, reply]);
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
    setState(() => posts.removeWhere((item) => item.id == post.id));
    await _persistMine();
    if (!mounted) return;
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
    searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
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
                        const SizedBox(height: 14),
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
                      post.author,
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
                label: Text('Reply ${post.replies.length}'),
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
