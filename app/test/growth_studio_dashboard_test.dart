import 'package:ask_the_village/widgets/growth_studio_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'Growth dashboard fits $width at $scale text scale and real counts',
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
                  textScaler: TextScaler.linear(scale),
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
          for (final key in ['growth-next-chapter', 'growth-membership-price']) {
            expect(tester.getRect(find.byKey(ValueKey(key))).center.dx, closeTo(width / 2, 1));
          }

          if (scale == 1) {
            final covers = [
              for (var i = 0; i < 3; i++)
                find.byKey(ValueKey('growth-book-$i')),
            ];
            final bounds = covers.map(tester.getRect).toList();
            expect(bounds.last.right, lessThanOrEqualTo(width + 1));
            expect(bounds[0].width, closeTo(bounds[1].width, .1));
            expect(bounds[1].width, closeTo(bounds[2].width, .1));
          }
          expect(find.text('1 saved milestone'), findsOneWidget);
          expect(find.text('1 saved reflection'), findsOneWidget);
          await tester.ensureVisible(find.text('Mood history'));
          await tester.tap(find.text('Mood history'));
          expect(destination, 'mood');
          await tester.ensureVisible(
            find.byKey(const ValueKey('growth-book-0')),
          );
          await tester.tap(find.byKey(const ValueKey('growth-book-0')));
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
          await tester.ensureVisible(find.text('Village Plus · \$4.99/month'));
          await tester.tap(find.text('Village Plus · \$4.99/month'));
          expect(membershipOpened, isTrue);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
