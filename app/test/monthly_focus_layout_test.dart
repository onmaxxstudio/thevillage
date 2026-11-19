import 'package:ask_the_village/widgets/monthly_focus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    testWidgets('Monthly Focus fits at $width and keeps every week accessible', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: MonthlyFocusScreen(
        membershipVerifier: () async => true,
      )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Building Boundaries'), findsOneWidget);
      final week4 = find.byKey(const ValueKey('monthly-focus-week-4'));
      await tester.scrollUntilVisible(week4, 250, scrollable: find.byType(Scrollable).last);
      await tester.tap(week4);
      await tester.pumpAndSettle();
      expect(find.text('Week 4: Build a gentler rhythm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
