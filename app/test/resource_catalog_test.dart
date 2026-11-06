import 'package:flutter_test/flutter_test.dart';
import '../lib/screens/find_help_screen.dart';

void main() {
  const states = {'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY'};

  test('catalog covers all 50 states with unique stable resource IDs', () {
    final covered = allStateResourceCatalog.expand((resource) => resource.states).toSet();
    expect(covered, states);
    expect(allStateResourceCatalog.map((resource) => resource.id).toSet().length,
        allStateResourceCatalog.length);
  });

  test('every newly covered state has core government and nonprofit help', () {
    for (final state in states.where((state) => state != 'FL')) {
      final entries = allStateResourceCatalog.where((resource) => resource.states.contains(state));
      final needs = entries.expand((resource) => resource.needs).toSet();
      expect(needs, containsAll(['Food', 'Healthcare', 'Utilities', 'Childcare', 'Rent & Housing', 'Legal Help']),
          reason: 'Missing core assistance in $state');
      expect(entries.any((resource) => resource.providerType == 'Nonprofit'), isTrue,
          reason: 'Missing nonprofit assistance in $state');
      expect(entries.any((resource) => resource.providerType == 'Government'), isTrue,
          reason: 'Missing government assistance in $state');
    }
  });

  test('each listing has secure sources and actionable program details', () {
    for (final resource in allStateResourceCatalog) {
      expect(Uri.parse(resource.url).scheme, 'https', reason: resource.id);
      expect(resource.sourceUrls, isNotEmpty, reason: resource.id);
      expect(resource.sourceUrls.every((url) => Uri.parse(url).scheme == 'https'), isTrue);
      expect(resource.serviceArea, isNotEmpty, reason: resource.id);
      expect(resource.eligibility, isNotEmpty, reason: resource.id);
      expect(resource.howToApply, isNotEmpty, reason: resource.id);
      expect(resource.cost, isNotEmpty, reason: resource.id);
      expect(resource.reviewedAt, isNotEmpty, reason: resource.id);
      expect(resource.verified, isEmpty, reason: 'Web research must not claim provider verification');
    }
  });
}
