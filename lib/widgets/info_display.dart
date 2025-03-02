import 'package:flutter/material.dart';
import '../models/log.dart';

class InfoDisplay extends StatelessWidget {
  final List<Log> logs;

  const InfoDisplay({
    super.key,
    required this.logs,
  });

  String _formatDuration(int seconds) {
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

  @override
  Widget build(BuildContext context) {
    // Calculate time since last hit
    String timeSinceLastHit = 'N/A';
    if (logs.isNotEmpty) {
      final lastLog =
          logs.reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);
      final duration = DateTime.now().difference(lastLog.timestamp);
      timeSinceLastHit = _formatDuration(duration.inSeconds);
    }

    // Calculate total length today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayLogs = logs.where((log) => log.timestamp.isAfter(todayStart));
    final totalSecondsToday =
        todayLogs.fold<int>(0, (sum, log) => sum + log.durationSeconds);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Since Last Hit: $timeSinceLastHit',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Length Today: ${_formatDuration(totalSecondsToday)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'THC Content: TBD', // Placeholder for future implementation
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
