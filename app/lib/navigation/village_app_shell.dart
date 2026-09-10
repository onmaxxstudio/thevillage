import 'package:flutter/material.dart';

import '../screens/ask_village_screen.dart';
import '../screens/circle_screen.dart';
import '../screens/community_hub_screen.dart';
import '../screens/home_screen.dart';
import '../screens/village_feed_screen.dart';
import 'village_navigation_scope.dart';

class VillageAppShell extends StatefulWidget {
  const VillageAppShell({super.key});

  @override
  State<VillageAppShell> createState() => _VillageAppShellState();
}

class _VillageAppShellState extends State<VillageAppShell> {
  static const cream = Color(0xFFFFFAF1);
  static const sage = Color(0xFF355C3B);
  static const ink = Color(0xFF172019);

  int selectedIndex = 0;

  final navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const rootPages = <Widget>[
    HomeScreen(),
    CircleScreen(),
    AskVillageScreen(),
    VillageFeedScreen(),
    CommunityHubScreen(),
  ];

  void selectTab(int index) {
    if (index < 0 || index >= rootPages.length || !mounted) return;
    if (index == selectedIndex) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => selectedIndex = index);
  }

  Widget buildTabNavigator(int index) {
    return Navigator(
      key: navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => rootPages[index],
        settings: RouteSettings(name: 'village-tab-$index'),
      ),
    );
  }

  Future<bool> handleBack() async {
    final navigator = navigatorKeys[selectedIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    if (selectedIndex != 0) {
      selectTab(0);
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return VillageNavigationScope(
      selectedIndex: selectedIndex,
      onSelect: selectTab,
      child: PopScope(
        canPop: selectedIndex == 0 &&
            !(navigatorKeys[selectedIndex].currentState?.canPop() ?? false),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) handleBack();
        },
        child: Scaffold(
          backgroundColor: cream,
          body: IndexedStack(
            index: selectedIndex,
            children: List.generate(rootPages.length, buildTabNavigator),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: selectTab,
            backgroundColor: cream,
            indicatorColor: sage.withValues(alpha: .13),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: ink),
                selectedIcon: Icon(Icons.home_rounded, color: sage),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded, color: ink),
                selectedIcon: Icon(Icons.people_rounded, color: sage),
                label: 'Circle',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline_rounded, color: ink),
                selectedIcon: Icon(Icons.add_circle_rounded, color: sage),
                label: 'Ask',
              ),
              NavigationDestination(
                icon: Icon(Icons.forum_outlined, color: ink),
                selectedIcon: Icon(Icons.forum_rounded, color: sage),
                label: 'Village',
              ),
              NavigationDestination(
                icon: Icon(Icons.diversity_3_outlined, color: ink),
                selectedIcon: Icon(Icons.diversity_3_rounded, color: sage),
                label: 'Community',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
