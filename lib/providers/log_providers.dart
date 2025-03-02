import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log_aggregates.dart';
import '../models/log.dart';
import '../services/log_repository.dart';
import './auth_provider.dart';

final logRepositoryProvider = Provider<LogRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => LogRepository(user?.uid ?? ''),
    loading: () => LogRepository(''),
    error: (_, __) => LogRepository(''),
  );
});

final logsStreamProvider = StreamProvider<List<Log>>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return repository.streamLogs();
});

final logAggregatesProvider = Provider<LogAggregates>((ref) {
  final logsAsyncValue = ref.watch(logsStreamProvider);
  return logsAsyncValue.when(
    data: (logs) => LogAggregates.fromLogs(logs),
    loading: () => const LogAggregates(
        timeSinceLastHit: 'Loading...', totalSecondsToday: 0),
    error: (_, __) =>
        const LogAggregates(timeSinceLastHit: 'Error', totalSecondsToday: 0),
  );
});
