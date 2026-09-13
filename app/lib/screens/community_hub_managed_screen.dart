import 'package:flutter/material.dart';

import 'community_hub_premium_screen.dart';

/// Admin-published communities are integrated directly into the premium
/// Explore communities carousel.
class CommunityHubManagedScreen extends StatelessWidget {
  const CommunityHubManagedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommunityHubPremiumScreen();
  }
}
