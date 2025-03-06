import '../../models/log.dart';
import '../models/thc_advanced_model.dart';

/// Adapts existing Log objects to the new InhalationEvent model
class LogToInhalationAdapter {
  /// Default consumption method to use if none is specified in the Log
  static const ConsumptionMethod defaultMethod = ConsumptionMethod.joint;

  /// Default perceived strength to use if none is specified in the Log
  static const double defaultPerceivedStrength = 1.0;

  /// Convert a single Log to an InhalationEvent
  static InhalationEvent convertLog(Log log) {
    // TODO: Update this logic based on your Log class structure
    // If your Log class already has method and strength fields, use those instead

    return InhalationEvent(
      timestampMs: log.timestamp.millisecondsSinceEpoch,
      method: _determineMethodFromLog(log),
      inhaleDurationSec: log.durationSeconds.toDouble(),
      perceivedStrength: _determineStrengthFromLog(log),
    );
  }

  /// Convert a list of Logs to InhalationEvents
  static List<InhalationEvent> convertLogs(List<Log> logs) {
    return logs.map(convertLog).toList();
  }

  /// Determine the consumption method from a Log
  /// Update this method based on your Log structure
  static ConsumptionMethod _determineMethodFromLog(Log log) {
    // TODO: Update with your logic to determine method
    // If your Log has a method field, use that
    return defaultMethod;
  }

  /// Determine the perceived strength from a Log
  /// Update this method based on your Log structure
  static double _determineStrengthFromLog(Log log) {
    // TODO: Update with your logic to determine strength
    // If your Log has a strength field, use that
    return defaultPerceivedStrength;
  }
}
