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
  static const paleSage = Color(0xFFE8EBDD);
  static const ink = Color(0xFF172019);
  static const line = Color(0xFFE3D8C9);

  int selectedIndex = 0;

  final navigatorKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

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
    setState(() {
      selectedIndex = index;
    });
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
            children: List.generate(5, buildTabNavigator),
          ),
          bottomNavigationBar: _VillageBottomBar(
            selectedIndex: selectedIndex,
            onSelect: selectTab,
          ),
        ),
      ),
    );
  }
}

class _VillageBottomBar extends StatelessWidget {
  const _VillageBottomBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onSelect,
        type: BottomNavigationBarType.fixed,
        backgroundColor: _VillageAppShellState.cream,
        selectedItemColor: _VillageAppShellState.sage,
        unselectedItemColor: _VillageAppShellState.ink,
        showUnselectedLabels: true,
        elevation: 16,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_2_outlined),
            label: 'Circle',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 36),
            label: 'Ask',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Village',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.diversity_3_outlined),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}
