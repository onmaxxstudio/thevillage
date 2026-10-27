import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/anonymous_identity_service.dart';

void main() {
  test('generated names are readable and never exceed 13 characters', () {
    final random = Random(42);
    for (var i = 0; i < 10000; i++) {
      final name = AnonymousIdentityService.candidate(random);
      expect(name.length, lessThanOrEqualTo(13));
      expect(AnonymousIdentityService.isAlias(name), isTrue);
      expect(name, matches(RegExp(r'^[A-Z][a-z]+[A-Z][a-z]+[0-9]{2}$')));
    }
  });
}
