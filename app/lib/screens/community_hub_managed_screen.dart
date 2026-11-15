import 'package:flutter/material.dart';

import 'community_hub_live_screen.dart';
import '../widgets/planner_viewport.dart';

/// Admin-managed communities, resources, and events are merged into the
/// Community Hub while preserving the premium Village experience.
class CommunityHubManagedScreen extends StatelessWidget {
  const CommunityHubManagedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlannerViewport(scale: .75, child: CommunityHubLiveScreen());
  }
}
