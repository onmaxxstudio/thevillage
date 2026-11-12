import 'package:ask_the_village/widgets/growth_studio_experience.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'Approved composition keeps every tool working at $width / $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          String? destination;
          var writes = 0;
          var back = 0;
          var settings = 0;
          var membership = 0;
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 1100),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: GrowthStudioExperience(
                      entries: const [
                        {'entryType': 'mood', 'mood': 'Calm'},
                        {'entryType': 'milestone', 'title': 'A real saved win'},
                        {
                          'entryType': 'guided',
                          'guidedJourneyId': 'existing',
                          'title': 'My existing journey',
                          'guidedJourneyAnswers': ['My answer', ''],
                        },
                      ],
                      onOpenTool: (value) => destination = value,
                      onWrite: () => writes++,
                      onBack: () => back++,
                      onSettings: () => settings++,
                      onMembership: () => membership++,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            final actions = ['monthly-event','member-check-in','growth-journey'];
            final bottoms = actions.map((key) => tester.getRect(find.byKey(ValueKey('plus-$key'))).bottom).toList();
            expect(bottoms[1],closeTo(bottoms[0],1));
            expect(bottoms[2],closeTo(bottoms[0],1));
          }
          final pairedModes = ['prompts','guided','gratitude','mood','milestones','goals','letters','budget'];
        final budget = tester.getSize(find.byKey(const ValueKey('growth-tool-budget')));
        for(final mode in pairedModes) {
          final size = tester.getSize(find.byKey(ValueKey('growth-tool-$mode')));
          expect(size.width,closeTo(budget.width,.1));
          expect(size.height,closeTo(budget.height,.1));
        }
        for (final mode in [
            'write',
            'prompts',
            'guided',
            'gratitude',
            'mood',
            'milestones',
            'goals',
            'letters',
            'budget',
          ]) {
            final target = find.byKey(ValueKey('growth-tool-$mode'));
            expect(target, findsOneWidget);
            await tester.ensureVisible(target);
            await tester.tap(target);
            if (mode == 'write') {
              expect(writes, 1);
            } else {
              expect(destination, mode);
            }
          }
          await tester.ensureVisible(find.byTooltip('Back'));
          await tester.tap(find.byTooltip('Back'));
          await tester.tap(find.byTooltip('Settings'));
          expect(back, 1);
          expect(settings, 1);
          await tester.ensureVisible(find.text(r'Village Plus · $4.99/month'));
          await tester.tap(find.text(r'Village Plus · $4.99/month'));
          expect(membership, 1);
          expect(find.text('My Growth Journey'), findsOneWidget);
          expect(find.text('Monthly Event'), findsOneWidget);
          expect(find.text('You’re Not Alone'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
