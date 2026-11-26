import 'package:ask_the_village/widgets/monthly_focus_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Nonmember preview accepts temporary typing without saving', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MonthlyFocusScreen(
      membershipVerifier: () async => false,
    )));
    await tester.pumpAndSettle();
    expect(find.text('Building Boundaries'), findsNothing);
    await tester.tap(find.text('Preview Monthly Focus'));
    await tester.pumpAndSettle();
    expect(find.text('Building Boundaries'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('monthly-focus-journal-1')), 250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Save Reflection'), findsNothing);
    expect(find.text('Mark Week Complete'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    await tester.enterText(find.byType(TextField), 'A boundary I want to practice');
    expect(find.text('A boundary I want to practice'), findsOneWidget);
    expect(find.textContaining('this draft will disappear'), findsOneWidget);
    final practice = find.byType(CheckboxListTile).first;
    await tester.scrollUntilVisible(practice, 250,
      scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(practice);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(practice).value, isFalse);
    await tester.tap(practice);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(practice).value, isTrue);
    expect(find.textContaining('Preview checks are temporary'), findsOneWidget);
  });
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
      await tester.ensureVisible(week4);
      await tester.pumpAndSettle();
      await tester.tap(week4);
      await tester.pumpAndSettle();
      expect(find.text('Week 4: Build a gentler rhythm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
