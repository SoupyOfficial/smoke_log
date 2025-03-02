import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/log_providers.dart';
import '../widgets/log_list.dart';
import '../widgets/chart_line_graph.dart';

class LogListScreen extends ConsumerWidget {
  const LogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsyncValue = ref.watch(logsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log List'),
      ),
      body: logsAsyncValue.when(
        data: (logs) {
          return Column(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LineChartWidget(
                    logs: logs,
                    dataProcessor: defaultDataProcessor,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: LogList(
                  logs: logs,
                  onDeleteLog: (logId) async {
                    final logRepository = ref.read(logRepositoryProvider);
                    await logRepository.deleteLog(logId);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
