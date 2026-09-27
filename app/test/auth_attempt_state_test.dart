import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ask_the_village/services/auth_service.dart';
import 'package:ask_the_village/widgets/auth_attempt_state.dart';

class _Harness extends StatefulWidget {
  const _Harness({super.key});

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> with AuthAttemptState<_Harness> {
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: TextButton(
            onPressed: loading ? null : () {},
            child: const Text('Sign in'),
          ),
        ),
      );
}

void main() {
  testWidgets('return from Google unlocks controls while preserving success',
      (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_Harness(key: key));
    final state = key.currentState!;
    final attempt = state.beginAuthAttempt(external: true);
    await tester.pump();
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<TextButton>(find.byType(TextButton)).onPressed, isNotNull);
    expect(state.isCurrentAuthAttempt(attempt), isTrue);
    state.finishAuthAttempt(attempt);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an old response cannot unlock or supersede a newer attempt',
      (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_Harness(key: key));
    final state = key.currentState!;
    final oldAttempt = state.beginAuthAttempt(external: true);
    final newAttempt = state.beginAuthAttempt(external: false);
    state.finishAuthAttempt(oldAttempt);
    expect(state.loading, isTrue);
    expect(state.isCurrentAuthAttempt(oldAttempt), isFalse);
    expect(state.isCurrentAuthAttempt(newAttempt), isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(state.loading, isTrue);
    state.finishAuthAttempt(newAttempt);
    expect(state.loading, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('missing browser events cannot lock controls indefinitely',
      (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_Harness(key: key));
    key.currentState!.beginAuthAttempt(external: true);
    await tester.pump(const Duration(seconds: 61));
    expect(key.currentState!.loading, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving the screen cancels recovery timers', (tester) async {
    final key = GlobalKey<_HarnessState>();
    await tester.pumpWidget(_Harness(key: key));
    key.currentState!.beginAuthAttempt(external: true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 61));
    expect(tester.takeException(), isNull);
  });

  test('popup cancellation is distinct from real authentication errors', () {
    for (final code in [
      'popup-closed-by-user',
      'cancelled-popup-request',
      'canceled-popup-request',
    ]) {
      expect(AuthService.isSignInCanceled(FirebaseAuthException(code: code)), isTrue);
    }
    expect(
      AuthService.isSignInCanceled(
        FirebaseAuthException(code: 'network-request-failed'),
      ),
      isFalse,
    );
  });
}
