import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log.dart';
import '../screens/edit_log_screen.dart';

class LogList extends StatelessWidget {
  final List<Log> logs;
  final Future<void> Function(String logId) onDeleteLog;

  LogList({super.key, required this.logs, required this.onDeleteLog});

  final _dateFormat = DateFormat('MMM d, y h:mm a');

  String _formatReason(String reason) {
    // Remove brackets if present
    String formatted = reason.trim();
    if (formatted.startsWith('[') && formatted.endsWith(']')) {
      formatted = formatted.substring(1, formatted.length - 1);
    }

    // If it's an empty list or just contains whitespace
    if (formatted.trim().isEmpty) {
      return '';
    }

    // Clean up any extra commas or whitespace
    List<String> parts = formatted
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: logs.isEmpty
          ? const Center(child: Text('No logs yet'))
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Dismissible(
                  key: Key(log.id!),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Log'),
                        content: const Text(
                            'Are you sure you want to delete this log?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) => onDeleteLog(log.id!),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    title: Row(
                      children: [
                        Expanded(
                            child: Text(_dateFormat.format(log.timestamp),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                        Container(
                          margin: const EdgeInsets.only(right: 16.0),
                          child: Text('${log.durationSeconds}s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (log.reason != null && log.reason!.isNotEmpty)
                              Expanded(
                                  child: Text(
                                      'Reason: ${_formatReason(log.reason!.join(","))}',
                                      style: const TextStyle(fontSize: 12))),
                          ],
                        ),
                        Row(
                          children: [
                            if (log.moodRating != null)
                              Text('Mood: ${log.moodRating}/10',
                                  style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 10),
                            if (log.physicalRating != null)
                              Text('Physical: ${log.physicalRating}/10',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        if (log.notes != null && log.notes!.isNotEmpty)
                          Text('Notes: ${log.notes}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditLogScreen(log: log),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // Navigate to the edit screen when the list item is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditLogScreen(log: log),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
