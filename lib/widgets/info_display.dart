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

    // Local helper to format duration similar to LogAggregates.
    String formatDuration(int seconds) {
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
              'Time Since Last Hit: ${aggregates.timeSinceLastHit}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Length Today: ${aggregates.formattedTotalSecondsToday}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Length Last 24 Hours: ${formatDuration(totalSecondsLast24)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'THC Content: ${thcValue.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
