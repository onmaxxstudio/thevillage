import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ask_the_village/screens/about_contact_screen.dart';

void main() {
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('About founder fits a $width logical-pixel viewport', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AboutContactScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('founder-section')));
      await tester.pumpAndSettle();
      final photo = tester.getRect(find.byKey(const ValueKey('founder-photo')));
      final message = tester.getRect(find.byKey(const ValueKey('founder-message')));
      expect(photo.left, greaterThanOrEqualTo(0));
      expect(photo.right, lessThanOrEqualTo(width));
      expect(message.right, lessThanOrEqualTo(width));
      if (width < 700) {
        expect(photo.bottom, lessThan(message.top));
      } else {
        expect(photo.right, lessThan(message.left));
      }
      expect(find.text('Meet the Founder'), findsOneWidget);
      expect(find.textContaining('Everyone deserves a village. Welcome to yours.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Email support'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
