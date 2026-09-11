import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';
import 'community_hub_premium_screen.dart';

class CommunityHubManagedScreen extends StatefulWidget {
  const CommunityHubManagedScreen({super.key});

  @override
  State<CommunityHubManagedScreen> createState() => _CommunityHubManagedScreenState();
}

class _CommunityHubManagedScreenState extends State<CommunityHubManagedScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);
  static const gold = Color(0xFFB78943);
  static const line = Color(0xFFE7DED1);

  final service = AdminContentService();
  int selected = 0;
  bool loading = true;
  List<ManagedContentItem> communities = const [];
  List<ManagedContentItem> resources = const [];
  List<ManagedContentItem> events = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = await Future.wait([
      service.loadPublished('communities'),
      service.loadPublished('resources'),
      service.loadPublished('events'),
    ]);
    if (!mounted) return;
    setState(() {
      communities = values[0];
      resources = values[1];
      events = values[2];
      loading = false;
    });
  }

  bool get hasManagedContent =>
      communities.isNotEmpty || resources.isNotEmpty || events.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(child: CircularProgressIndicator(color: sage)),
      );
    }

    if (!hasManagedContent) {
      return const CommunityHubPremiumScreen();
    }

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMMUNITY HUB',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: gold)),
                  const SizedBox(height: 4),
                  Text('Find your people.',
                      style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: ink)),
                  const SizedBox(height: 16),
                  _tabs(),
                ],
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: selected,
                children: [
                  _communities(),
                  _resources(),
                  _events(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Communities', 'Resources', 'Events'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = selected == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => selected = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    color: active ? sage : ink,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _communities() {
    if (communities.isEmpty) {
      return _empty('No published communities yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: communities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        final item = communities[index];
        final image = item.text('imageUrl');
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 210,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image.isNotEmpty)
                  Image.network(image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback())
                else
                  _imageFallback(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22000000), Color(0xD9000000)],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(item.text('name', 'Community'),
                          style: GoogleFonts.playfairDisplay(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(item.text('description'),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              height: 1.35,
                              fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resources() {
    if (resources.isEmpty) {
      return _empty('No published resources yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: resources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = resources[index];
        return Card(
          elevation: 0,
          color: Colors.white.withValues(alpha: .78),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.text('community', 'RESOURCE').toUpperCase(),
                    style: const TextStyle(
                        color: gold,
                        fontSize: 10,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                Text(item.text('title', 'Resource'),
                    style: GoogleFonts.playfairDisplay(
                        color: ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(item.text('description'),
                    style: GoogleFonts.inter(height: 1.45, color: ink)),
                if (item.text('body').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    title: const Text('Read guide',
                        style: TextStyle(
                            color: sage, fontWeight: FontWeight.w800)),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(item.text('body'),
                            style: GoogleFonts.inter(height: 1.55)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _events() {
    if (events.isEmpty) {
      return _empty('No published events yet.');
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final item = events[index];
        return Card(
          elevation: 0,
          color: Colors.white.withValues(alpha: .8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: line),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EEE4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.event_outlined, color: sage),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.text('title', 'Event'),
                          style: GoogleFonts.playfairDisplay(
                              color: ink,
                              fontSize: 21,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(item.text('dateTimeLabel', 'Date coming soon'),
                          style: const TextStyle(
                              color: sage, fontWeight: FontWeight.w800)),
                      if (item.text('community').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.text('community'),
                            style: const TextStyle(color: gold)),
                      ],
                      const SizedBox(height: 8),
                      Text(item.text('description'),
                          style: GoogleFonts.inter(height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _empty(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: ink, fontSize: 15)),
        ),
      );

  Widget _imageFallback() => Container(
        color: const Color(0xFFE7DED1),
        child: const Icon(Icons.groups_2_rounded, color: sage, size: 46),
      );
}