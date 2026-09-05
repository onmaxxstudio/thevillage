import 'package:flutter_test/flutter_test.dart';

import 'package:ineedmyvillage/main.dart';

void main() {
  testWidgets('welcome screen opens the create account screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('The Village'), findsAtLeastNWidgets(1));
    expect(find.text('Join The Village'), findsOneWidget);

    await tester.tap(find.text('Join The Village'));
    await tester.pumpAndSettle();

    expect(find.text('Create Your Account'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Join The Village'), findsOneWidget);
  });

  testWidgets('welcome screen opens the sign in screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back. We’re glad you’re here.'), findsOneWidget);
    expect(find.text('Email or Username'), findsOneWidget);
    expect(find.text('Recover My Account'), findsOneWidget);
  });

  testWidgets('account provider opens the Village Promise', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Join The Village'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    expect(find.text('Before you enter,'), findsOneWidget);
    expect(find.text('I agree to The Village Promise.'), findsOneWidget);

    final promiseButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'I Promise'),
    );
    expect(promiseButton.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    final enabledPromiseButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'I Promise'),
    );
    expect(enabledPromiseButton.onPressed, isNotNull);
  });
}
