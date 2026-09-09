import 'package:flutter_test/flutter_test.dart';

import 'package:ask_the_village/main.dart';

void main() {
  testWidgets('welcome screen opens the create account screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Ask the Village'), findsAtLeastNWidgets(1));
    expect(find.text('Join the Village'), findsOneWidget);

    await tester.tap(find.text('Join the Village'));
    await tester.pumpAndSettle();

    expect(find.text('Create Your Account'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Join the Village'), findsOneWidget);
  });

  testWidgets('welcome screen opens the sign in screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back. We’re glad you’re here.'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Recover My Account'), findsOneWidget);
  });

  testWidgets('email account option opens the real sign-up form', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Join the Village'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    expect(find.text('Join Ask the Village'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Create My Account'), findsOneWidget);
  });
}
