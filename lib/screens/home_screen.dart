import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/log.dart';
import '../services/log_repository.dart';
import '../widgets/add_log_form.dart';
import '../widgets/info_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LogRepository _logRepository;
  final _dateFormat = DateFormat('MMM d, y h:mm a');

  // Timer for updating "Time Since Last Hit"
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    _logRepository = LogRepository(userId);

    // Update the display every minute
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _deleteLog(String logId) async {
    try {
      await _logRepository.deleteLog(logId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete log')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smoke Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: StreamBuilder<List<Log>>(
        stream: _logRepository.streamLogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final logs = snapshot.data ?? [];

          return Column(
            children: [
              InfoDisplay(
                  logs: logs), // Replace _buildInfoDisplay with InfoDisplay
              AddLogForm(logRepository: _logRepository),
              Expanded(
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
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
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
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) => _deleteLog(log.id!),
                            child: ListTile(
                              title: Text(_dateFormat.format(log.timestamp)),
                              subtitle: Text('${log.durationSeconds}s'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Empty onPressed for now
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}
