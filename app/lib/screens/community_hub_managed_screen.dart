import 'package:flutter/material.dart';

import 'community_hub_premium_screen.dart';

/// Community Hub remains the full premium experience.
///
/// Admin-managed communities are additive content and must never replace the
/// built-in hub. The premium hub is the source of truth for the public
/// experience while managed content is integrated into that experience.
class CommunityHubManagedScreen extends StatelessWidget {
  const CommunityHubManagedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityHubPremiumScreen();
  }
}
