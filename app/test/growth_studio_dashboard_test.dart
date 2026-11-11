import 'package:ask_the_village/widgets/growth_studio_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 768.0]) {
    testWidgets(
      'Growth dashboard fits $width with large text and real counts',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? destination;
        var membershipOpened = false;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: GrowthStudioDashboard(
                    entries: const [
                      {'entryType': 'milestone'},
                      {'entryType': 'mood'},
                      {
                        'entryType': 'guided',
                        'guidedJourneyId': 'existing-journey',
                      },
                    ],
                    onOpenTool: (mode) => destination = mode,
                    onMembership: () => membershipOpened = true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('1 saved milestone'), findsOneWidget);
        expect(find.text('1 saved reflection'), findsOneWidget);
        await tester.ensureVisible(find.text('Mood reflections'));
        await tester.tap(find.text('Mood reflections'));
        expect(destination, 'mood');
        await tester.ensureVisible(find.text('Boundaries'));
        await tester.tap(find.text('Boundaries'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining(
            'This exclusive Village Plus journey is coming soon.',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('Explore current guided journals'));
        await tester.pumpAndSettle();
        expect(destination, 'guided');
        await tester.ensureVisible(
          find.text('Explore Village Plus · \$4.99/month'),
        );
        await tester.tap(find.text('Explore Village Plus · \$4.99/month'));
        expect(membershipOpened, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
