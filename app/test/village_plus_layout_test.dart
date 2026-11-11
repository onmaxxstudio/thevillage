import 'package:ask_the_village/screens/village_plus_screen.dart';
import 'package:ask_the_village/widgets/village_plus_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [280.0, 320.0, 390.0, 600.0, 768.0, 1024.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Plus banner opens safe enrollment at $width / $scale', (tester) async {
        tester.view.physicalSize = Size(width, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const Scaffold(body: SingleChildScrollView(
            child: Padding(padding: EdgeInsets.all(18), child: VillagePlusBanner()))),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Village Plus'), findsOneWidget);
        expect(find.text('\$4.99'), findsOneWidget);
        await tester.tap(find.byType(InkWell));
        await tester.pumpAndSettle();
        expect(find.byType(VillagePlusScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        for (final title in ['My Growth Studio', 'The Village Sessions', 'The Monthly Reset']) {
          await tester.scrollUntilVisible(find.text(title), 200);
          expect(tester.takeException(), isNull);
        }
        final join = find.byKey(const ValueKey('join-village-plus'));
        await tester.scrollUntilVisible(join, 200);
        expect(tester.widget<FilledButton>(join).onPressed, isNull);
        expect(find.text('\$4.99/month'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.byType(VillagePlusBanner), findsOneWidget);
      });
    }
  }
}
