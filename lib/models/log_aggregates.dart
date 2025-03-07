import 'log.dart';
import '../utils/format_utils.dart';

class LogAggregates {
  final DateTime? lastHit;
  final double totalSecondsToday;
  final double thcContent;

  LogAggregates({
    required this.lastHit,
    required this.totalSecondsToday,
    required this.thcContent,
  });

  // Returns a human-readable format for the total seconds today.
  String get formattedTotalSecondsToday {
    return formatDurationHHMMSS(totalSecondsToday, detailed: true);
  }

  /// Creates aggregates from the given list of logs.
  /// The [lastHit] is the most recent log timestamp (if available).
  /// It calculates today's total duration from logs whose timestamp is after midnight.
  /// THC content calculation is left as an example.
  factory LogAggregates.fromLogs(List<Log> logs) {
    DateTime? lastHit;
    if (logs.isNotEmpty) {
      // Get the most recent log timestamp.
      final sortedLogs = List<Log>.from(logs)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      lastHit = sortedLogs.first.timestamp;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    final totalSeconds = logs
        .where((log) => log.timestamp.isAfter(todayStart))
        .fold<double>(0, (sum, log) => sum + log.durationSeconds);

    // Example THC content calculation. You may replace this with your own logic.
    final double thcContent =
        logs.isNotEmpty ? logs.last.durationSeconds / 3600.0 : 0.0;

    return LogAggregates(
      lastHit: lastHit,
      totalSecondsToday: totalSeconds,
      thcContent: thcContent,
    );
  }
}
