import 'package:ask_the_village/widgets/monthly_challenge_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('November challenge has thirty distinct actionable days', () {
    expect(novemberChallenge.length, 30);
    expect(novemberChallenge.map((day) => day.action).toSet().length, 30);
    for (final day in novemberChallenge) {
      expect(day.action.trim(), isNotEmpty);
      expect(day.prompt.trim(), isNotEmpty);
    }
  });

  testWidgets('Free users cannot see private daily activities', (tester) async {
    await tester.pumpWidget(MaterialApp(home: MonthlyChallengeScreen(
      membershipVerifier: () async => false,
    )));
    await tester.pumpAndSettle();
    expect(find.textContaining('Village Plus members'), findsOneWidget);
    expect(find.text(novemberChallenge.first.action), findsNothing);
    expect(find.byType(TextField), findsNothing);
  });
}
