import 'dart:math';
import 'package:intl/intl.dart';
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
      return 30 * 60 * 1000; // 30 minutes.
    case ChartRange.weekly:
      return 24 * 3600 * 1000; // 1 day.
    case ChartRange.monthly:
      return 7 * 24 * 3600 * 1000; // 1 week.
    case ChartRange.yearly:
      return 30 * 24 * 3600 * 1000; // 1 month.
  }
}
