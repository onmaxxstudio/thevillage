import 'package:flutter/widgets.dart';

class VillageNavigationScope extends InheritedWidget {
  const VillageNavigationScope({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required super.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

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
        onSelect != oldWidget.onSelect;
  }
}
