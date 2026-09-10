import 'package:flutter_test/flutter_test.dart';

import 'package:ask_the_village/main.dart';
import 'package:ask_the_village/services/notification_service.dart';
import 'package:ask_the_village/services/village_post_service.dart';

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

  test('post edits preserve identity and engagement', () {
    final createdAt = DateTime(2026, 9, 9);
    final post = VillagePost(
      id: 'post-1',
      question: 'How can I support a friend?',
      category: 'Friendship',
      audience: 'The Village',
      author: '@Ariel',
      createdAt: createdAt,
      needsSupport: true,
      supportCount: 4,
    );

    final edited = post.copyWith(
      question: 'How can I listen to a friend with more care?',
      supportIntent: 'Just listen',
    );

    expect(edited.question, contains('more care'));
    expect(edited.supportIntent, 'Just listen');
    expect(edited.id, post.id);
    expect(edited.createdAt, createdAt);
    expect(edited.supportCount, 4);
  });

  test('notification type survives local serialization', () {
    final createdAt = DateTime(2026, 9, 9);
    final original = VillageNotification(
      id: 'notice-1',
      title: 'New reply',
      message: 'A neighbor replied.',
      createdAt: createdAt,
      destinationIndex: 3,
      type: 'post_reply',
    );

    final restored = VillageNotification.fromJson(original.toJson());

    expect(restored.type, 'post_reply');
    expect(restored.destinationIndex, 3);
    expect(restored.createdAt, createdAt);
  });

  test('community questions keep their exact community', () {
    final original = VillagePost(
      id: 'community-post-1',
      question: 'What support would make this week feel lighter?',
      category: 'Life & Growth',
      audience: 'The Village',
      author: '@Ariel',
      createdAt: DateTime(2026, 9, 10),
      needsSupport: false,
      communityId: 'women',
      communityName: 'Women',
    );

    final restored = VillagePost.fromJson(original.toJson());

    expect(restored.communityId, 'women');
    expect(restored.communityName, 'Women');
  });
}
