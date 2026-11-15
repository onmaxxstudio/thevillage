import 'package:ask_the_village/widgets/home_overview_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> overview(
    WidgetTester tester,
    Size size, {
    double textScale = 1,
    VoidCallback? onTap,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: HomeOverviewLayout(
              header: const SizedBox(height: 90),
              sections: [
                const SizedBox(height: 220),
                const SizedBox(height: 124),
                const SizedBox(height: 184),
                GestureDetector(
                  key: const ValueKey('last-card'),
                behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: const SizedBox(width: double.infinity, height: 320),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final size in [const Size(393, 700), const Size(430, 800)]) {
    testWidgets('Compact overview fills $size without a bottom gap', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var tapped = false;
      await overview(tester, size, onTap: () => tapped = true);
      final last = find.byKey(const ValueKey('last-card'));
      expect(tester.getTopRight(last).dx - tester.getTopLeft(last).dx, closeTo(size.width * 732 / 768, .1));
      expect(
        size.height - tester.getBottomLeft(last).dy,
        closeTo(12 * size.width / 768, .1),
      );
      await tester.tap(last);
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Short screens scroll to the final card', (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await overview(tester, const Size(320, 350));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getBottomLeft(find.byKey(const ValueKey('last-card'))).dy,
      lessThanOrEqualTo(350),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Larger accessibility text keeps native width and scrolls', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await overview(tester, const Size(393, 700), textScale: 2);
    expect(tester.getSize(find.byKey(const ValueKey('last-card'))).width, 357);
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .maxScrollExtent,
      greaterThan(0),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Circle and Home share visible text scale on phones', (tester) async {
    tester.view.physicalSize = const Size(393, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<double> visibleTextHeight(bool distribute) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(
        body: HomeOverviewLayout(
          distributeSections: distribute,
          header: const SizedBox(height: 30),
          sections: const [Text('Matching heading',
            key: ValueKey('heading'), style: TextStyle(fontSize: 19))],
        ),
      )));
      await tester.pump();
      final heading = find.byKey(const ValueKey('heading'));
      final paragraph = tester.renderObject(heading);
      return paragraph.paintBounds.height * paragraph.getTransformTo(null).storage[5];
    }

    final homeHeight = await visibleTextHeight(true);
    final circleHeight = await visibleTextHeight(false);
    expect(circleHeight, closeTo(homeHeight, .01));
    expect(tester.takeException(), isNull);
  });

}
