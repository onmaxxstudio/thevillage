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
}
