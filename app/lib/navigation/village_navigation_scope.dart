import 'package:flutter/material.dart';


/// The one menu control used throughout the signed-in app.
/// Its fixed 48px touch target keeps the icon from drifting between headers.
class VillageMenuButton extends StatelessWidget {
  const VillageMenuButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: 'Menu',
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: const Icon(Icons.menu_rounded, size: 30),
      ),
    );
  }
}

class VillageNavigationScope extends InheritedWidget {
  const VillageNavigationScope({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.onOpenMenu,
    required super.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onOpenMenu;

  static VillageNavigationScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<VillageNavigationScope>();
    assert(scope != null, 'VillageNavigationScope is missing.');
    return scope!;
  }

  static VillageNavigationScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<VillageNavigationScope>();
  }

  @override
  bool updateShouldNotify(VillageNavigationScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex ||
        onSelect != oldWidget.onSelect ||
        onOpenMenu != oldWidget.onOpenMenu;
  }
}
