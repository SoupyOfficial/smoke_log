import 'package:flutter/material.dart';
import '../models/log.dart';
import '../models/log_aggregates.dart';

class InfoDisplay extends StatelessWidget {
  final List<Log> logs;

  const InfoDisplay({
    super.key,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final aggregates = LogAggregates.fromLogs(logs);

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
              'THC Content: ${aggregates.thcContent}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
