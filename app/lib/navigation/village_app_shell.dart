import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/profile_service.dart';

import '../screens/ask_village_screen.dart';
import '../screens/circle_screen.dart';
import '../screens/community_hub_managed_screen.dart';
import '../screens/home_screen.dart';
import '../screens/personalization_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/private_messages_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/my_space_screen.dart';
import '../screens/my_space_tools_screen.dart';
import '../screens/plan_my_week_screen.dart';
import '../screens/find_help_screen.dart';
import '../screens/write_freely_screen.dart';
import '../services/private_journal_service.dart';
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
  String? _restoredPage;
  bool _loadingNavigation = true;
  final List<String?> _currentPages = List<String?>.filled(5, null);
  final List<int> _tabRouteDepth = List<int>.filled(5, 0);
  late final List<_VillageTabRouteObserver> _routeObservers;
  final personalizationService = PersonalizationService();
  bool checkingPersonalization = true;
  bool personalizationComplete = false;
  String? firstCommunityId;
  String? firstCommunityName;

  @override
  void initState() {
    super.initState();
    _routeObservers = List.generate(
      5,
      (index) => _VillageTabRouteObserver(
        rootRouteName: 'village-tab-$index',
        onDepthChanged: (depth) => _setTabRouteDepth(index, depth),
        onRouteChanged: (route) => _onRouteChanged(index, route),
      ),
    );
    _loadNavigation();
    _loadPersonalization();
    unawaited(ProfileService().refreshDirectoryProfile());
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

  String get _navigationKey =>
      'villageNavigation_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  Future<void> _loadNavigation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_navigationKey)?.split('|');
      if (!mounted) return;
      setState(() {
        if (saved != null && saved.length == 2) {
          final index = int.tryParse(saved[0]);
          if (index != null && index >= 0 && index < 5) {
            selectedIndex = index;
            _restoredPage = saved[1].isEmpty ? null : saved[1];
            _currentPages[index] = _restoredPage;
          }
        }
        _loadingNavigation = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingNavigation = false);
    }
  }

  void _saveNavigation() {
    final page = _currentPages[selectedIndex] ?? '';
    final value = '$selectedIndex|$page';
    SharedPreferences.getInstance().then((prefs) {
      if (mounted) prefs.setString(_navigationKey, value);
    });
  }

  String? _pageKey(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && name.startsWith('village-tab-')) return null;
    if (route is! MaterialPageRoute<dynamic>) return null;
    final page = route.builder(navigatorKeys[selectedIndex].currentContext ?? context);
    if (page is MySpaceToolsScreen) return 'my_space/${page.mode}';
    if (page is MyEntriesScreen) return 'my_space/library';
    if (page is WriteFreelyEditorScreen) return 'my_space/write';
    if (page is MySpaceScreen) return 'my_space';
    if (page is PlanMyWeekScreen) return 'plan_my_week';
    if (page is FindHelpScreen) return 'find_help';
    if (page is PrivateMessagesScreen) return 'messages';
    if (page is ProfileScreen) return 'profile';
    if (page is SettingsScreen) return 'settings';
    return null;
  }

  Widget? _restorePage(String key) {
    if (key.startsWith('my_space/')) {
      return MySpaceScreen(initialDestination: key.substring('my_space/'.length));
    }
    return switch (key) {
      'my_space' => const MySpaceScreen(),
      'plan_my_week' => const PlanMyWeekScreen(),
      'find_help' => const FindHelpScreen(),
      'messages' => const PrivateMessagesScreen(),
      'profile' => const ProfileScreen(),
      'settings' => const SettingsScreen(),
      _ => null,
    };
  }

  void _onRouteChanged(int index, Route<dynamic>? route) {
    if (_loadingNavigation || index != selectedIndex) return;
    final page = route == null ? null : _pageKey(route);
    // The root arrives first while restoring a saved detail route.
    if (page == null && _restoredPage != null && _tabRouteDepth[index] == 0) return;
    _restoredPage = null;
    _currentPages[index] = page;
    _saveNavigation();
  }

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
    _saveNavigation();
  }

  MaterialPageRoute<void> _rootRoute(int index) => MaterialPageRoute<void>(
        builder: (_) => rootPages[index],
        settings: RouteSettings(name: 'village-tab-$index'),
      );

  Widget buildTabNavigator(int index) {
    return Navigator(
      key: navigatorKeys[index],
      observers: [_routeObservers[index]],
      onGenerateInitialRoutes: (_, __) {
        final page = index == selectedIndex && _restoredPage != null
            ? _restorePage(_restoredPage!)
            : null;
        return <Route<dynamic>>[
          _rootRoute(index),
          if (page != null) MaterialPageRoute<void>(builder: (_) => page),
        ];
      },
      onGenerateRoute: (_) => _rootRoute(index),
    );
  }

  void _setTabRouteDepth(int index, int depth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _tabRouteDepth[index] == depth) return;
      setState(() => _tabRouteDepth[index] = depth);
    });
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
            _drawerItem(Icons.mark_unread_chat_alt_outlined, 'Messages', () => closeAndPush(const PrivateMessagesScreen())),
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
    if (checkingPersonalization || _loadingNavigation) {
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
        selectedIndex = 0;
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
          body: Stack(
            children: [
              Positioned.fill(
                child: IndexedStack(
                  index: selectedIndex,
                  children: List.generate(rootPages.length, buildTabNavigator),
                ),
              ),
              if (selectedIndex != 0 &&
                  _tabRouteDepth[selectedIndex] == 0 &&
                  !(selectedIndex == 2 && firstCommunityId != null))
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: VillageMenuButton(
                        onPressed: () => _shellScaffoldKey.currentState
                            ?.openDrawer(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            labelTextStyle: MediaQuery.sizeOf(context).width >= 700
                ? const WidgetStatePropertyAll(TextStyle(fontSize: 14))
                : null,
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

class _VillageTabRouteObserver extends NavigatorObserver {
  _VillageTabRouteObserver({
    required this.rootRouteName,
    required this.onDepthChanged,
    required this.onRouteChanged,
  });

  final String rootRouteName;
  final ValueChanged<int> onDepthChanged;
  final ValueChanged<Route<dynamic>?> onRouteChanged;
  int _depth = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != rootRouteName) onDepthChanged(++_depth);
    onRouteChanged(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != rootRouteName) {
      _depth = _depth > 0 ? _depth - 1 : 0;
      onDepthChanged(_depth);
    }
    onRouteChanged(previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != rootRouteName) {
      _depth = _depth > 0 ? _depth - 1 : 0;
      onDepthChanged(_depth);
    }
    onRouteChanged(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged(newRoute);
  }
}
