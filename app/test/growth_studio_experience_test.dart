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
          expect(find.text('My existing journey'), findsOneWidget);
          expect(find.text('A real saved win'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
