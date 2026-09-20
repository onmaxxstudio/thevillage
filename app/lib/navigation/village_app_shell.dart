import 'package:flutter/material.dart';

import '../screens/ask_village_screen.dart';
import '../screens/circle_screen.dart';
import '../screens/community_hub_managed_screen.dart';
import '../screens/home_screen.dart';
import '../screens/personalization_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../services/personalization_service.dart';
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

  final GlobalKey<ScaffoldState> _shellScaffoldKey =
      GlobalKey<ScaffoldState>();
  int selectedIndex = 0;
  final personalizationService = PersonalizationService();
  bool checkingPersonalization = true;
  bool personalizationComplete = false;
  String? firstCommunityId;
  String? firstCommunityName;

  @override
  void initState() {
    super.initState();
    _loadPersonalization();
  }

  Future<void> _loadPersonalization() async {
    final value = await personalizationService.load();
    if (!mounted) return;
    setState(() {
      personalizationComplete = value.completed;
      checkingPersonalization = false;
    });
  }

  final navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  List<Widget> get rootPages => <Widget>[
    const HomeScreen(),
    const CircleScreen(),
    AskVillageScreen(initialCommunityId: firstCommunityId, initialCommunityName: firstCommunityName, firstQuestionFlow: firstCommunityId != null),
    const VillageFeedScreen(),
    const CommunityHubManagedScreen(),
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

  Drawer _buildDrawer() {
    void closeAndSelect(int index) {
      Navigator.of(context).pop();
      selectTab(index);
    }

    void closeAndPush(Widget screen) {
      Navigator.of(context).pop();
      navigatorKeys[selectedIndex].currentState?.push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
    }

    return Drawer(
      backgroundColor: cream,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            const Icon(Icons.menu_rounded, color: sage, size: 27),
            const SizedBox(height: 16),
            Text(
              'Ask the Village',
              style: const TextStyle(
                color: sage,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real people. Real support. Real answers.',
              style: TextStyle(fontSize: 12, color: Color(0xFF687067)),
            ),
            const SizedBox(height: 20),
            _drawerItem(Icons.home_rounded, 'Home', () => closeAndSelect(0)),
            _drawerItem(Icons.people_rounded, 'My Circle', () => closeAndSelect(1)),
            _drawerItem(Icons.add_circle_outline_rounded, 'Ask the Village', () => closeAndSelect(2)),
            _drawerItem(Icons.forum_rounded, 'The Village', () => closeAndSelect(3)),
            _drawerItem(Icons.diversity_3_rounded, 'Community Hub', () => closeAndSelect(4)),
            const Divider(height: 30),
            _drawerItem(Icons.person_outline_rounded, 'Profile', () => closeAndPush(const ProfileScreen())),
            _drawerItem(Icons.settings_outlined, 'Settings', () => closeAndPush(const SettingsScreen())),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: sage),
      title: Text(label, style: const TextStyle(color: ink, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checkingPersonalization) {
      return const Scaffold(
        backgroundColor: cream,
        body: Center(child: CircularProgressIndicator(color: sage)),
      );
    }
    if (!personalizationComplete) {
      return PersonalizationScreen(
        onComplete: (destination) => setState(() {
        personalizationComplete = true;
        firstCommunityId = destination.communityId;
        firstCommunityName = destination.communityName;
        selectedIndex = destination.startAsking ? 2 : 4;
      }),
      );
    }
    return VillageNavigationScope(
      selectedIndex: selectedIndex,
      onSelect: selectTab,
      onOpenMenu: () => _shellScaffoldKey.currentState?.openDrawer(),
      child: PopScope(
        canPop: selectedIndex == 0 &&
            !(navigatorKeys[selectedIndex].currentState?.canPop() ?? false),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) handleBack();
        },
        child: Scaffold(
          key: _shellScaffoldKey,
          backgroundColor: cream,
          drawer: _buildDrawer(),
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
              NavigationDestination(icon: Icon(Icons.home_outlined, color: ink), selectedIcon: Icon(Icons.home_rounded, color: sage), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.people_outline_rounded, color: ink), selectedIcon: Icon(Icons.people_rounded, color: sage), label: 'Circle'),
              NavigationDestination(icon: Icon(Icons.add_circle_outline_rounded, color: ink), selectedIcon: Icon(Icons.add_circle_rounded, color: sage), label: 'Ask'),
              NavigationDestination(icon: Icon(Icons.forum_outlined, color: ink), selectedIcon: Icon(Icons.forum_rounded, color: sage), label: 'Village'),
              NavigationDestination(icon: Icon(Icons.diversity_3_outlined, color: ink), selectedIcon: Icon(Icons.diversity_3_rounded, color: sage), label: 'Community'),
            ],
          ),
        ),
      ),
    );
  }
}