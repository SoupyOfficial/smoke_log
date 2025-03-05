import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/use_cases/thc_calculator.dart';
import '../models/log.dart';
import 'log_providers.dart';

final liveThcContentProvider = StreamProvider<double>((ref) {
  // Controller that emits the current THC value.
  final controller = StreamController<double>();

  // Directly watch the logs stream to ensure we always have the latest data
  final logsAsyncValue = ref.watch(logsStreamProvider);
  List<Log> currentLogs = logsAsyncValue.when(
    data: (logs) => logs,
    loading: () => [],
    error: (_, __) => [],
  );

  // Create a timer that recalculates the THC content periodically.
  final timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
    final calculator = THCConcentration(
      logs: currentLogs,
    );

    final currentTHC = calculator
        .calculateTHCAtTime(DateTime.now().millisecondsSinceEpoch.toDouble());

    // // Add debugging
    // print('Current THC: $currentTHC (from ${currentLogs.length} logs)');
    controller.add(currentTHC);
  });

  // Clean up when the provider is disposed.
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
