import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/use_cases/thc_calculator.dart';
import '../models/log.dart';
import 'log_providers.dart';

final liveThcContentProvider = StreamProvider<double>((ref) {
  // Controller that emits the current THC value.
  final controller = StreamController<double>();

  // We keep the latest logs in a variable.
  List<Log> currentLogs = [];

  // Listen to updates from the logsProvider.
  final sub =
      ref.listen<AsyncValue<List<Log>>>(logsStreamProvider, (_, logsState) {
    logsState.when(
      data: (logs) => currentLogs = logs,
      loading: () => currentLogs = [],
      error: (_, __) => currentLogs = [],
    );
  });

  // Create a timer that recalculates the THC content periodically.
  final timer = Timer.periodic(const Duration(milliseconds: 150), (_) {
    final calculator = THCConcentration(logs: currentLogs);
    final currentTHC = calculator
        .calculateTHCAtTime(DateTime.now().millisecondsSinceEpoch.toDouble());
    controller.add(currentTHC);
  });

  // Clean up when the provider is disposed.
  ref.onDispose(() {
    timer.cancel();
    sub.close();
    controller.close();
  });

  return controller.stream;
});
