import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/log.dart';
import '../domain/use_cases/thc_calculator.dart'; // For basic THC model
import '../domain/models/thc_advanced_model.dart'; // For advanced THC model
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

// Advanced THC content provider (existing)
final liveThcContentProvider = StreamProvider<double>((ref) {
  final controller = StreamController<double>();

  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    // Get the latest logs
    final logsAsyncValue = ref.read(logsStreamProvider);
    final currentLogs = logsAsyncValue.when(
      data: (logs) => logs,
      loading: () => [],
      error: (_, __) => [],
    );

    // Create advanced THC model with current logs
    final thcModel = THCModelNoMgInput();

    // Convert logs to inhalation events
    for (final log in currentLogs) {
      // Map log data to inhalation event parameters
      final method = ConsumptionMethod.joint;
      final perceivedStrength = log.potencyRating != null
          ? (log.potencyRating! / 5.0).clamp(0.25, 2.0)
          : 1.0;

      thcModel.logInhalation(
        timestamp: log.timestamp,
        method: method,
        inhaleDurationSec: log.durationSeconds,
        perceivedStrength: perceivedStrength,
      );
    }

    // Get current THC content
    final currentTHC = thcModel.getTHCContentAtTime(DateTime.now());

    controller.add(currentTHC);
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

// Basic THC content provider (new)
final basicThcContentProvider = StreamProvider<double>((ref) {
  final controller = StreamController<double>();

  final timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
    // Get the latest logs
    final logsAsyncValue = ref.read(logsStreamProvider);
    final currentLogs = logsAsyncValue.when(
      data: (logs) => logs,
      loading: () => [],
      error: (_, __) => [],
    );

    // Calculate basic THC content using the simpler model
    final thcCalculator = THCConcentration(logs: currentLogs as List<Log>);
    final currentTHC = thcCalculator
        .calculateTHCAtTime(DateTime.now().millisecondsSinceEpoch.toDouble());

    // Add the value to the stream
    controller.add(currentTHC);
  });

  // Clean up when the provider is disposed
  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
