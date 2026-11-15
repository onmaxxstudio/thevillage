import 'package:ask_the_village/widgets/ask_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Ask uses viewport width and scrolls at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AskPageLayout(
              header: const SizedBox(height: 76),
              sections: [
                Column(
                  children: [
                    const Text(
                      'What’s on your mind?',
                      key: ValueKey('heading'),
                    ),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('topic'),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Men', child: Text('Men')),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 1200),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Preview Post'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final dropdown = tester.getRect(find.byKey(const ValueKey('topic')));
      expect(dropdown.center.dx, closeTo(width / 2, .1));
      expect(
        dropdown.width,
        closeTo(
          width < 600 ? width - 22 : (width > 1100 ? 1100 : width) - 48,
          .1,
        ),
      );
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byKey(const ValueKey('heading'))),
        ).scale(16),
        16,
      );
      await tester.ensureVisible(find.text('Preview Post'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('Preview Post')).bottom, lessThan(844));
    });
  }
}
