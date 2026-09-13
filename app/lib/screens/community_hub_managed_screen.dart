import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';
import 'community_hub_premium_screen.dart';

/// Keeps the complete premium Community Hub and adds Village Admin communities
/// on top of it. Admin content is additive and never replaces built-in content.
class CommunityHubManagedScreen extends StatelessWidget {
  const CommunityHubManagedScreen({super.key});

  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const gold = Color(0xFFB78943);
  static const line = Color(0xFFE7DED1);

  @override
  Widget build(BuildContext context) {
    final service = AdminContentService();
    if (!service.cloudReady) return const CommunityHubPremiumScreen();

    return Scaffold(
      backgroundColor: cream,
      body: Column(
        children: [
          StreamBuilder<List<ManagedContentItem>>(
            stream: service.watchPublished('communities'),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const <ManagedContentItem>[];
              if (items.isEmpty) return const SizedBox.shrink();
              return SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  decoration: const BoxDecoration(
                    color: cream,
                    border: Border(bottom: BorderSide(color: line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'NEW IN THE VILLAGE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: gold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${items.length} ${items.length == 1 ? 'community' : 'communities'}',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: sage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) => _managedCard(context, items[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Expanded(child: CommunityHubPremiumScreen()),
        ],
      ),
    );
  }

  Widget _managedCard(BuildContext context, ManagedContentItem item) {
    final title = item.text('name', item.text('title', 'Community'));
    final description = item.text('description', 'A new place to connect in the Village.');
    final imageUrl = item.text('imageUrl');

    return InkWell(
      onTap: () => _openManagedCommunity(context, item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 68,
              height: 76,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackCover(),
                    )
                  : _fallbackCover(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10.5, height: 1.25, color: const Color(0xFF646B65)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF355C3B), Color(0xFF6F876B)],
        ),
      ),
      child: const Center(child: Icon(Icons.groups_2_outlined, color: Colors.white, size: 28)),
    );
  }

  void _openManagedCommunity(BuildContext context, ManagedContentItem item) {
    final title = item.text('name', item.text('title', 'Community'));
    final description = item.text('description', 'A new place to connect in the Village.');
    final imageUrl = item.text('imageUrl');

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: cream,
          appBar: AppBar(backgroundColor: cream, foregroundColor: ink, elevation: 0),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 210,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackCover())
                      : _fallbackCover(),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: GoogleFonts.playfairDisplay(fontSize: 30, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 8),
              Text(description, style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: const Color(0xFF545B55))),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Community space', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: ink)),
                    const SizedBox(height: 6),
                    Text('Questions, conversations, resources, and events for this community will live here as they are added.', style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: const Color(0xFF646B65))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
