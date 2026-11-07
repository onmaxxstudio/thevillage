import 'package:ask_the_village/screens/about_contact_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1440, 1000),
  ]) {
    testWidgets('Founder fits and follows the mission at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AboutContactScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final photo = find.byKey(const ValueKey('founder-portrait'));
      final message = find.byKey(const ValueKey('founder-message'));
      final card = find.byKey(const ValueKey('founder-section'));
      final photoRect = tester.getRect(photo);
      final messageRect = tester.getRect(message);
      final cardRect = tester.getRect(card);
      expect(cardRect.left, greaterThanOrEqualTo(0));
      expect(cardRect.right, lessThanOrEqualTo(size.width));
      expect(photoRect.left, greaterThanOrEqualTo(cardRect.left));
      expect(photoRect.right, lessThanOrEqualTo(cardRect.right));
      expect(messageRect.right, lessThanOrEqualTo(cardRect.right));
      if (size.width < 700) {
        expect(photoRect.bottom, lessThan(messageRect.top));
      } else {
        expect(photoRect.right, lessThan(messageRect.left));
      }
      expect(find.text('Meet the Founder'), findsOneWidget);
      expect(find.text('Ariel Mitchell'), findsOneWidget);
      expect(find.text('Founder of Ask the Village'), findsOneWidget);
      expect(
        find.textContaining('Everyone deserves a village. Welcome to yours.'),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(
              find.textContaining(
                'Everyone deserves a village. Welcome to yours.',
              ),
            )
            .dy,
        lessThan(cardRect.top),
      );
      await tester.ensureVisible(find.text('Contact us'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('support@askthevillage.app'), findsOneWidget);
      expect(find.text('Email support'), findsOneWidget);
    });
  }
}
