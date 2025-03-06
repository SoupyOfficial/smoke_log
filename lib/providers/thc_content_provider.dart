import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/thc_advanced_model.dart';
import '../domain/adapters/log_to_inhalation_adapter.dart';
import '../models/log.dart';
import 'log_providers.dart';

// Provider for user demographic settings
// TODO: Create actual providers for these settings in your app
final userAgeProvider = Provider<int>((ref) => 30); // Default age
final userSexProvider = Provider<String>((ref) => "male"); // Default sex
final userBodyFatProvider =
    Provider<double>((ref) => 15.0); // Default body fat %
final userCaloricBurnProvider =
    Provider<double>((ref) => 2000.0); // Default caloric burn

// THC model instance provider
final thcModelProvider = Provider<THCModelNoMgInput>((ref) {
  final age = ref.watch(userAgeProvider);
  final sex = ref.watch(userSexProvider);
  final bodyFat = ref.watch(userBodyFatProvider);
  final caloricBurn = ref.watch(userCaloricBurnProvider);

  return THCModelNoMgInput(
    ageYears: age,
    sex: sex,
    bodyFatPercent: bodyFat,
    dailyCaloricBurn: caloricBurn,
  );
});

// Live THC content provider using the new model
final liveThcContentProvider = StreamProvider<double>((ref) {
  // Controller that emits the current THC value
  final controller = StreamController<double>();

  // Get the THC model instance
  final thcModel = ref.watch(thcModelProvider);

  // Create a timer that recalculates THC content periodically
  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    // Get the latest logs on every tick
    final logsAsyncValue = ref.read(logsStreamProvider);
    final currentLogs = logsAsyncValue.when(
      data: (logs) => logs,
      loading: () => [],
      error: (_, __) => [],
    );

    // Convert logs to inhalation events and populate the model
    final events = LogToInhalationAdapter.convertLogs(currentLogs.cast<Log>());

    // Update the model with the new events
    thcModel.updateEvents(events);

    // Calculate current THC content
    final currentTHC = thcModel.getTHCContentAtTime(DateTime.now());

    // Add the value to the stream
    controller.add(currentTHC);

    // Inside timer callback
    // print('Processing ${currentLogs.length} logs, THC content: $currentTHC mg');
  });

  // Clean up when the provider is disposed
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
