import 'check_in_service.dart';

class CycleEstimate {
  const CycleEstimate({
    required this.nextPeriod,
    required this.cycleDays,
    required this.hasCycleHistory,
    required this.inferredStart,
    required this.periodDays,
  });

  final DateTime? nextPeriod;
  final int cycleDays;
  final bool hasCycleHistory;
  final bool inferredStart;
  final int periodDays;

  String get detail {
    final basis = hasCycleHistory
        ? 'your average $cycleDays-day cycle'
        : 'a typical 28-day cycle';
    return inferredStart
        ? 'Estimated from your period end date, assuming a $periodDays-day period and $basis. Log the start date for a more personal estimate.'
        : 'Estimated using $basis. Predictions improve as you log more cycles.';
  }

  factory CycleEstimate.fromHistory(List<MoodCheckIn> history, {DateTime? now}) {
    DateTime day(DateTime value) => DateTime(value.year, value.month, value.day);
    final today = day(now ?? DateTime.now());
    final starts = history.where((e) => e.periodStarted)
        .map((e) => day(e.createdAt)).where((d) => !d.isAfter(today))
        .toSet().toList()..sort();
    final ends = history.where((e) => e.periodEnded)
        .map((e) => day(e.createdAt)).where((d) => !d.isAfter(today))
        .toSet().toList()..sort();
    final intervals = <int>[];
    for (var i = 1; i < starts.length; i++) {
      final days = starts[i].difference(starts[i - 1]).inDays;
      if (days >= 21 && days <= 45) intervals.add(days);
    }
    final cycleDays = intervals.isEmpty ? 28
        : (intervals.reduce((a, b) => a + b) / intervals.length).round();
    final durations = <int>[];
    for (final end in ends) {
      final previous = starts.where((start) => !start.isAfter(end));
      if (previous.isEmpty) continue;
      final days = end.difference(previous.last).inDays + 1;
      if (days >= 2 && days <= 10) durations.add(days);
    }
    final periodDays = durations.isEmpty ? 5
        : (durations.reduce((a, b) => a + b) / durations.length).round();
    DateTime? anchor = starts.isEmpty ? null : starts.last;
    var inferredStart = false;
    if (ends.isNotEmpty && (anchor == null ||
        ends.last.difference(anchor).inDays >= 10)) {
      anchor = ends.last.subtract(Duration(days: periodDays - 1));
      inferredStart = true;
    }
    DateTime? nextPeriod;
    if (anchor != null) {
      var estimate = anchor.add(Duration(days: cycleDays));
      while (estimate.isBefore(today)) {
        estimate = estimate.add(Duration(days: cycleDays));
      }
      nextPeriod = estimate;
    }
    return CycleEstimate(
      nextPeriod: nextPeriod,
      cycleDays: cycleDays,
      hasCycleHistory: intervals.isNotEmpty,
      inferredStart: inferredStart,
      periodDays: periodDays,
    );
  }
}

