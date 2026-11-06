import 'package:ask_the_village/services/username_directory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UsernameDirectory directory({
    Map<String, Map<String, dynamic>> claims = const {},
    Map<String, Map<String, dynamic>> profiles = const {},
    DirectorySearch? search,
  }) => UsernameDirectory(
    readClaim: (key) async => claims[key],
    readProfile: (uid) async => profiles[uid],
    searchProfiles: search ?? (prefix) async => profiles.values.toList(),
  );

  test('exact username remains findable when its public profile is missing', () async {
    final users = directory(claims: {
      'ariel': {'uid': 'member-a', 'username': 'Ariel'},
    });
    final member = await users.findExact('  @ARIEL  ');
    expect(member?.uid, 'member-a');
    expect(member?.username, 'Ariel');
  });

  test('prefix search returns multiple people, exact first, without self or duplicates', () async {
    final users = directory(
      claims: {'ari': {'uid': 'exact', 'username': 'Ari'}},
      profiles: {
        'a': {'uid': 'a', 'username': 'Ariel'},
        'exact': {'uid': 'exact', 'username': 'Ari'},
        'me': {'uid': 'me', 'username': 'Aria'},
        'b': {'uid': 'b', 'username': 'Brian'},
      },
    );
    final matches = await users.search('@ARI', excludeUid: 'me');
    expect(matches.map((member) => member.uid), ['exact', 'a']);
  });

  test('invalid and too-short searches never query the directory', () async {
    var reads = 0;
    final users = UsernameDirectory(
      readClaim: (_) async { reads++; return null; },
      readProfile: (_) async { reads++; return null; },
      searchProfiles: (_) async { reads++; return []; },
    );
    expect(await users.search('a'), isEmpty);
    expect(await users.search('name/path'), isEmpty);
    expect(reads, 0);
  });

  test('connection errors do not become a false no-members result', () async {
    final users = directory(search: (_) async => throw StateError('offline'));
    await expectLater(users.search('ar'), throwsStateError);
  });

  test('search results are bounded even if a backend returns too many', () async {
    final users = directory(search: (_) async => List.generate(
      30, (i) => {'uid': 'uid-$i', 'username': 'member_$i'},
    ));
    expect((await users.search('member')).length, 20);
  });
}
