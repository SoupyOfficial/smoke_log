import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/log.dart';
import '../screens/edit_log_screen.dart';

class LogList extends StatelessWidget {
  final List<Log> logs;
  final Future<void> Function(String logId) onDeleteLog;

  LogList({super.key, required this.logs, required this.onDeleteLog});

  final _dateFormat = DateFormat('MMM d, y h:mm a');

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
                    title: Text(_dateFormat.format(log.timestamp)),
                    subtitle: Text('${log.durationSeconds}s'),
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
