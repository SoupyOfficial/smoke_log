import 'package:smoke_log/models/log.dart';

class LogAggregates {
  final String timeSinceLastHit;
  final int totalSecondsToday;
  final String thcContent;

  const LogAggregates({
    required this.timeSinceLastHit,
    required this.totalSecondsToday,
    this.thcContent = 'TBD',
  });

  static String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} '
        '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }

  factory LogAggregates.fromLogs(List<Log> logs) {
    String timeSinceLastHit = 'N/A';
    if (logs.isNotEmpty) {
      final lastLog =
          logs.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      final duration = DateTime.now().difference(lastLog.timestamp);
      timeSinceLastHit = _formatDuration(duration.inSeconds);
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayLogs = logs.where((log) => log.timestamp.isAfter(todayStart));
    final totalSecondsToday =
        todayLogs.fold<int>(0, (sum, log) => sum + log.durationSeconds);

    return LogAggregates(
      timeSinceLastHit: timeSinceLastHit,
      totalSecondsToday: totalSecondsToday,
    );
  }

  String get formattedTotalSecondsToday => _formatDuration(totalSecondsToday);
}
