import 'package:ask_the_village/screens/ask_village_screen.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  setUpAll(() async {
    await Firebase.initializeApp();
  });
  for (final width in [320.0, 390.0, 768.0, 1440.0]) {
    testWidgets('Composer fits and selections work at $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: AskVillageScreen()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final heading = tester.widget<Text>(find.text('What’s on your mind?'));
      expect(heading.style?.fontSize, width < 600 ? 16 : 24);
      final field = find.byType(TextField).first;
      final composer = tester.widget<TextField>(field);
      expect(composer.style?.fontSize, width < 600 ? 12 : 16);
      expect(composer.maxLength, 1500);
      await tester.enterText(field, 'How can I build better boundaries?');
      await tester.pump();
      expect(
        find.text('${'How can I build better boundaries?'.length}/1500'),
        findsOneWidget,
      );
      final topic = find.byType(DropdownButtonFormField<String>).first;
      await tester.ensureVisible(topic);
      await tester.pumpAndSettle();
      final rect = tester.getRect(topic);
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(width));
      await tester.tap(topic);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Men').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Preview Post'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Save Draft'), findsOneWidget);
    });
  }
}
