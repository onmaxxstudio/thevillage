import 'package:flutter_test/flutter_test.dart';
import '../lib/services/check_in_service.dart';
import '../lib/services/cycle_estimate.dart';

void main() {
  final today = DateTime(2026, 11, 6);
  MoodCheckIn entry(int month, int day, {bool start = false, bool end = false}) =>
      MoodCheckIn(mood: 'Okay', createdAt: DateTime(2026, month, day),
          periodStarted: start, periodEnded: end);
  CycleEstimate estimate(List<MoodCheckIn> history) =>
      CycleEstimate.fromHistory(history, now: today);

  test('end alone estimates from a five-day period without saving a start', () {
    final history = [entry(11, 6, end: true)];
    final result = estimate(history);
    expect(result.nextPeriod, DateTime(2026, 11, 30));
    expect(result.inferredStart, isTrue);
    expect(result.detail, contains('assuming a 5-day period'));
    expect(history.single.periodStarted, isFalse);
  });
  test('a recorded start takes priority for the same period', () {
    final result = estimate([entry(11, 2, start: true), entry(11, 6, end: true)]);
    expect(result.nextPeriod, DateTime(2026, 11, 30));
    expect(result.inferredStart, isFalse);
  });
  test('unmatched recent end uses learned duration and cycle length', () {
    final result = estimate([
      entry(9, 1, start: true), entry(9, 6, end: true),
      entry(10, 1, start: true), entry(10, 6, end: true),
      entry(11, 6, end: true),
    ]);
    expect(result.periodDays, 6);
    expect(result.cycleDays, 30);
    expect(result.nextPeriod, DateTime(2026, 12, 1));
    expect(result.inferredStart, isTrue);
  });
  test('an older end does not replace a newer start', () {
    final result = estimate([entry(10, 6, end: true), entry(11, 2, start: true)]);
    expect(result.nextPeriod, DateTime(2026, 11, 30));
    expect(result.inferredStart, isFalse);
  });
  test('empty history and spotting alone do not invent a cycle', () {
    expect(estimate([]).nextPeriod, isNull);
    expect(estimate([entry(11, 6)]).nextPeriod, isNull);
  });
  test('old estimates roll forward and duplicate starts do not alter averages', () {
    final result = estimate([
      entry(9, 1, start: true), entry(10, 1, start: true),
      entry(10, 1, start: true),
    ]);
    expect(result.cycleDays, 30);
    expect(result.nextPeriod, DateTime(2026, 11, 30));
  });
}
