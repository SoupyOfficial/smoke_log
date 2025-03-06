import 'package:flutter/material.dart';
import '../models/log.dart';
import '../models/log_aggregates.dart';
import '../utils/format_utils.dart';

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

    // Use the live value if available; otherwise, fallback to aggregates.
    final thcValue = (liveThcContent ?? aggregates.thcContent);

    // Debug print to verify the value is being passed correctly
    // print(
    //     'InfoDisplay rebuilding with THC value: $thcValue mg (from live provider: ${liveThcContent != null})');

    // Helper to format a Duration as HH:MM:SS.
    String formatDurationHHMMSS(Duration duration) {
      String twoDigits(dynamic n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "$hours:$minutes:$seconds";
    }

    // If no last hit is available, default to a zero Duration.
    final lastHitTime = aggregates.lastHit ?? DateTime.now();
    final timeSinceLastHit = DateTime.now().difference(lastHitTime);

    // Other helper for formatting duration (ex: Total Length Display) remains
    String formatNormalDuration(double seconds) {
      if (seconds < 60) return '${formatSecondsDisplay(seconds)} seconds';
      if (seconds < 3600) {
        final minutes = seconds ~/ 60;
        final remainingSeconds = seconds % 60;
        return '$minutes ${minutes == 1 ? "minute" : "minutes"} ${remainingSeconds.toStringAsFixed(2)} seconds';
      }
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '$hours ${hours == 1 ? "hour" : "hours"} $minutes ${minutes == 1 ? "minute" : "minutes"}';
    }

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    final totalSecondsLast24 = logs
        .where((log) => log.timestamp.isAfter(cutoff))
        .fold<double>(0.0, (sum, log) => sum + log.durationSeconds);

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
              'Current THC Content: ${thcValue > 0.0001 ? "${thcValue.toStringAsFixed(3)} fg" : "Loading..."}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // const SizedBox(height: 8),
            // Text(
            //   'Logs available: ${logs.length}',
            //   style: Theme.of(context).textTheme.bodySmall,
            // ),
            // Text(
            //   'Duration: ${formatSecondsDisplay(log.durationSeconds)} seconds',
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),
          ],
        ),
      ),
    );
  }
}
