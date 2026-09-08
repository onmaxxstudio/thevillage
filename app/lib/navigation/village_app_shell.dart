import 'package:flutter/material.dart';

import '../screens/ask_village_screen.dart';
import '../screens/circle_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
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
    ProfileScreen(),
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

  static const items = [
    (Icons.home_rounded, 'Home'),
    (Icons.groups_2_outlined, 'Circle'),
    (Icons.add_rounded, 'Ask'),
    (Icons.chat_bubble_outline_rounded, 'Village'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(18, 4, 18, 8),
          decoration: BoxDecoration(
            color: _VillageAppShellState.cream,
            border: Border.all(color: _VillageAppShellState.line),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A172019),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
          child: Row(
            children: List.generate(items.length, (index) {
              final isAsk = index == 2;
              final isSelected = selectedIndex == index;
              final label = items[index].$2;
              return Expanded(
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: '$label tab',
                  child: TextButton(
                    key: ValueKey('bottom-nav-$index'),
                    onPressed: () => onSelect(index),
                    style: TextButton.styleFrom(
                      foregroundColor: _VillageAppShellState.ink,
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      minimumSize: const Size(48, 62),
                      tapTargetSize: MaterialTapTargetSize.padded,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: isAsk ? 48 : 38,
                          height: isAsk ? 48 : 32,
                          decoration: BoxDecoration(
                            color: isAsk
                                ? _VillageAppShellState.sage
                                : isSelected
                                    ? _VillageAppShellState.paleSage
                                    : Colors.transparent,
                            shape: isAsk ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius:
                                isAsk ? null : BorderRadius.circular(15),
                          ),
                          child: Icon(
                            items[index].$1,
                            color: isAsk
                                ? Colors.white
                                : isSelected
                                    ? _VillageAppShellState.sage
                                    : _VillageAppShellState.ink,
                          ),
                        ),
                        Text(
                          label,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
