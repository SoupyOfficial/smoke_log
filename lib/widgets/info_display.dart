import 'package:flutter/material.dart';
import '../models/log.dart';
import '../models/log_aggregates.dart';

class InfoDisplay extends StatelessWidget {
  final List<Log> logs;
  final double? liveThcContent;

  const InfoDisplay({
    super.key,
    required this.logs,
    this.liveThcContent,
  });

  @override
  Widget build(BuildContext context) {
    final aggregates = LogAggregates.fromLogs(logs);

    // Helper to format a Duration as HH:MM:SS.
    String formatDurationHHMMSS(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$hours:$minutes:$seconds";
    }

    // If no last hit is available, default to a zero Duration.
    final lastHitTime = aggregates.lastHit ?? DateTime.now();
    final timeSinceLastHit = DateTime.now().difference(lastHitTime);

    // Other helper for formatting duration (ex: Total Length Display) remains
    String formatNormalDuration(int seconds) {
      if (seconds < 60) return '$seconds seconds';
      if (seconds < 3600) {
        final minutes = seconds ~/ 60;
        return '$minutes ${minutes == 1 ? "minute" : "minutes"}';
      }
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '$hours ${hours == 1 ? "hour" : "hours"} $minutes ${minutes == 1 ? "minute" : "minutes"}';
    }

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    final totalSecondsLast24 = logs
        .where((log) => log.timestamp.isAfter(cutoff))
        .fold<int>(0, (sum, log) => sum + log.durationSeconds);

    // Use the live value if available; otherwise, fallback to aggregates.
    final thcValue = (liveThcContent ?? aggregates.thcContent) as double;

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Since Last Hit: ${formatDurationHHMMSS(timeSinceLastHit)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Length Today: ${aggregates.formattedTotalSecondsToday}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Length Last 24 Hours: ${formatNormalDuration(totalSecondsLast24)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Current THC Content: ${thcValue.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
