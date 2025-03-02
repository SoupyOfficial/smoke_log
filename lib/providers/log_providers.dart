import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/use_cases/thc_calculator.dart';
import '../models/log_aggregates.dart';
import '../models/log.dart';
import '../services/log_repository.dart';
import './auth_provider.dart';

// Repository provider
final logRepositoryProvider = Provider<LogRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => LogRepository(user?.uid ?? ''),
    loading: () => LogRepository(''),
    error: (_, __) => LogRepository(''),
  );
});

// Stream of logs
final logsStreamProvider = StreamProvider<List<Log>>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return repository.streamLogs();
});

// Computed aggregates using the updated LogAggregates model.
final logAggregatesProvider = Provider<LogAggregates>((ref) {
  final logsAsyncValue = ref.watch(logsStreamProvider);
  return logsAsyncValue.when(
    data: (logs) => LogAggregates.fromLogs(logs),
    loading: () => LogAggregates(
        lastHit: DateTime.now(), totalSecondsToday: 0, thcContent: 0.0),
    error: (_, __) => LogAggregates(
        lastHit: DateTime.now(), totalSecondsToday: 0, thcContent: 0.0),
  );
});

// Add new provider for selected log if needed
final selectedLogProvider = StateProvider<Log?>((ref) => null);
