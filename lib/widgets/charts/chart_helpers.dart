import 'chart_config.dart';
import 'chart_data_processors.dart';

/// Calculate the left y‑axis interval.
double calculateLeftInterval(double minY, double maxY) {
  final range = maxY - minY;
  final interval = range / 6;
  return interval > 0 ? interval : 1.0;
}

/// Determine bottom x‑axis interval based on the range and chart type.
double determineBottomInterval(ChartRange range, ChartType chartType) {
  if (chartType == ChartType.cumulative) {
    if (range == ChartRange.yearly) {
      return 30 * 24 * 3600 * 1000; // ~30 days (monthly tick)
    } else if (range != ChartRange.daily) {
      return 24 * 3600 * 1000; // 1 day.
    }
  }
  switch (range) {
    case ChartRange.daily:
      return 60 * 60 * 1000; // Changed from 30 minutes to 60 minutes
    case ChartRange.weekly:
      return 24 * 3600 * 1000; // 1 day.
    case ChartRange.monthly:
      return 2.5 * 24 * 3600 * 1000; // Halved from 5 days to 2.5 days
    case ChartRange.yearly:
      return 30 * 24 * 3600 * 1000; // 30 days
  }
  return 24 * 3600 * 1000; // Default to 1 day
}
