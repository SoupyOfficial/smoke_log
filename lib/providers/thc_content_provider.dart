import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/use_cases/thc_calculator.dart';
import '../models/log.dart';
import 'log_providers.dart'; // Assumes logsStreamProvider is defined here

final liveThcContentProvider = StreamProvider<double>((ref) async* {
  // Continuously update the live THC content each second.
  while (true) {
    // Get the current list of logs; if still loading or error, provide an empty list.
    final logsAsync = ref.watch(logsStreamProvider);
    final List<Log> logs = logsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Log>[],
    );
    final calculator = THCConcentration(logs: logs);
    final currentTHC = calculator
        .calculateTHCAtTime(DateTime.now().millisecondsSinceEpoch.toDouble());
    yield currentTHC;
    await Future.delayed(const Duration(milliseconds: 150));
  }
});
