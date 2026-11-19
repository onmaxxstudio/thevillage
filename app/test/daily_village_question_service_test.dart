import 'package:flutter_test/flutter_test.dart';
import 'package:ask_the_village/services/daily_village_question_service.dart';

void main() {
  group('Daily Village Question date keys', () {
    test('formats single-digit month and day', () {
      expect(DailyVillageQuestionService.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('uses the provided calendar day at year boundary', () {
      expect(DailyVillageQuestionService.dateKey(DateTime(2026, 12, 31)), '2026-12-31');
      expect(DailyVillageQuestionService.dateKey(DateTime(2027, 1, 1)), '2027-01-01');
    });

    test('supports leap day', () {
      expect(DailyVillageQuestionService.dateKey(DateTime(2028, 2, 29)), '2028-02-29');
    });
  });
}
