import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/admin_content_service.dart';
import '../services/community_hub_feature_service.dart';
import '../services/village_post_service.dart';

class CommunityHubFeatureAdminScreen extends StatefulWidget {
  const CommunityHubFeatureAdminScreen({super.key});

  @override
  State<CommunityHubFeatureAdminScreen> createState() =>
      _CommunityHubFeatureAdminScreenState();
}

class _CommunityHubFeatureAdminScreenState
    extends State<CommunityHubFeatureAdminScreen> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);

  final featuresService = CommunityHubFeatureService();
  final contentService = AdminContentService();
  final postService = VillagePostService();

  static const builtInNames = <String, String>{
    'men': 'Men',
    'relationships': 'Relationships',
    'women': 'Women',
    'moms': 'Moms',
    'friendship': 'Friendship',
    'faith': 'Faith',
    'wellness': 'Wellness',
    'career': 'Career & Purpose',
    'grief': 'Grief & Healing',
    'new_beginnings': 'New Beginnings',
    'caregivers': 'Caregivers',
  };

  bool loading = true;
  bool saving = false;
  String spotlightId = '';
  String firstPostId = '';
  String secondPostId = '';
  String resourceId = '';
  String eventId = '';
  Map<String, String> communities = {};
  Map<String, String> posts = {};
  Map<String, String> resources = {};
  Map<String, String> events = {};
  List<String> communityOrder = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        featuresService.watch().first,
        contentService.loadPublished('communities'),
        contentService.loadPublished('resources'),
        contentService.loadPublished('events'),
        postService.load(),
      ]);
      final features = values[0] as CommunityHubFeatures;
      final managedCommunities = values[1] as List<ManagedContentItem>;
      final publishedResources = values[2] as List<ManagedContentItem>;
      final publishedEvents = values[3] as List<ManagedContentItem>;
      final loadedPosts = values[4] as List<VillagePost>;
      if (!mounted) return;
      setState(() {
        communities = {
          ...builtInNames,
          for (final item in managedCommunities)
            if (item.text('builtinId').isNotEmpty)
              item.text('builtinId'): item.text('name', item.text('title'))
            else
              'admin_${item.id}': item.text('name', item.text('title')),
        };
        communityOrder = [
          ...features.communityOrder.where((id) => communities.containsKey(id)),
          ...communities.keys.where(
              (id) => !features.communityOrder.contains(id)),
        ];
        posts = {
          if (postService.lastLoadUsedCloud)
            for (final post in loadedPosts)
              post.id: post.question,
        };
        resources = {
          for (final item in publishedResources)
            if (item.text('kind') != 'question')
              item.id: item.text('title'),
        };
        events = {
          for (final item in publishedEvents) item.id: item.text('title'),
        };
        spotlightId = features.spotlightId;
        firstPostId =
            features.pulsePostIds.isEmpty ? '' : features.pulsePostIds.first;
        secondPostId = features.pulsePostIds.length < 2
            ? ''
            : features.pulsePostIds[1];
        resourceId = features.resourceId;
        eventId = features.eventId;
        loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load Hub controls: $error')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await featuresService.save(CommunityHubFeatures(
        spotlightId: spotlightId,
        pulsePostIds: [
          if (firstPostId.isNotEmpty) firstPostId,
          if (secondPostId.isNotEmpty && secondPostId != firstPostId)
            secondPostId,
        ],
        resourceId: resourceId,
        eventId: eventId,
        communityOrder: communityOrder,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community Hub features saved.')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save Hub features: $error')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _selector(
    String label,
    String value,
    Map<String, String> choices,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        initialValue: choices.containsKey(value) ? value : '',
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('Automatic / none')),
          ...choices.entries.map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value, overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: (selected) => onChanged(selected ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: cream,
        appBar: AppBar(
          backgroundColor: cream,
          title: Text('Curate Community Hub',
              style: GoogleFonts.playfairDisplay(color: ink)),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator(color: sage))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 35),
                children: [
                  const Text(
                    'Choose what members see in the featured sections. Only published resources and events appear here. Leaving a choice on Automatic lets the Hub select current content.',
                    style: TextStyle(color: ink, height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  _selector('Community Spotlight', spotlightId, communities,
                      (value) => setState(() => spotlightId = value)),
                  _selector('Community Pulse: first conversation',
                      firstPostId, posts,
                      (value) => setState(() => firstPostId = value)),
                  _selector('Community Pulse: second conversation',
                      secondPostId, posts,
                      (value) => setState(() => secondPostId = value)),
                  _selector('Resource of the Week', resourceId, resources,
                      (value) => setState(() => resourceId = value)),
                  _selector('Upcoming Event', eventId, events,
                      (value) => setState(() => eventId = value)),
                  const SizedBox(height: 8),
                  Text('Community order',
                      style: GoogleFonts.playfairDisplay(
                          color: ink, fontSize: 23, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  const Text(
                    'Use the arrows to choose the order in Explore Communities.',
                    style: TextStyle(color: ink, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < communityOrder.length; index++)
                    Card(
                      color: Colors.white,
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              communities[communityOrder[index]] ??
                                  communityOrder[index],
                              style: const TextStyle(
                                  color: ink, fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Move up',
                            onPressed: index == 0
                                ? null
                                : () => setState(() {
                                      final item = communityOrder.removeAt(index);
                                      communityOrder.insert(index - 1, item);
                                    }),
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                          IconButton(
                            tooltip: 'Move down',
                            onPressed: index == communityOrder.length - 1
                                ? null
                                : () => setState(() {
                                      final item = communityOrder.removeAt(index);
                                      communityOrder.insert(index + 1, item);
                                    }),
                            icon: const Icon(Icons.arrow_downward_rounded),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: sage,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(saving ? 'Saving…' : 'Save Hub Features'),
                  ),
                ],
              ),
      );
}
