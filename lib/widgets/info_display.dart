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
              'THC Content: ${thcValue.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
