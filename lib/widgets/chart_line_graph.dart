import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/log.dart';
import '../domain/use_cases/thc_calculator.dart';

enum ChartType {
  lengthPerHit,
  cumulative,
  thcConcentration,
  rolling24h,
  rolling30d,
  rolling90d,
}

// 1. Extend the ChartRange enum:
enum ChartRange { daily, weekly, monthly, yearly }

typedef DataProcessor = List<FlSpot> Function(List<Log> logs, ChartRange range);

// 2. Update defaultDataProcessor to support yearly:
List<FlSpot> defaultDataProcessor(List<Log> logs, ChartRange range) {
  final now = DateTime.now();
  late DateTime startRange;
  switch (range) {
    case ChartRange.daily:
      startRange = now.subtract(const Duration(hours: 24));
      break;
    case ChartRange.weekly:
      startRange = now.subtract(const Duration(days: 7));
      break;
    case ChartRange.monthly:
      startRange = now.subtract(const Duration(days: 30));
      break;
    case ChartRange.yearly:
      startRange = now.subtract(const Duration(days: 365));
      break;
  }
  final filteredLogs =
      logs.where((log) => !log.timestamp.isBefore(startRange)).toList();
  return filteredLogs
      .map((log) => FlSpot(
            log.timestamp.millisecondsSinceEpoch.toDouble(),
            log.durationSeconds.toDouble(),
          ))
      .toList();
}

// 3. Update THC concentration data processor:
List<FlSpot> thcConcentrationDataProcessor(List<Log> logs, ChartRange range) {
  final now = DateTime.now();
  late DateTime startRange;
  late DateTime endRange;
  switch (range) {
    case ChartRange.daily:
      startRange = now.subtract(const Duration(hours: 24));
      endRange = now;
      break;
    case ChartRange.weekly:
      startRange = now.subtract(const Duration(days: 7));
      endRange = now;
      break;
    case ChartRange.monthly:
      startRange = now.subtract(const Duration(days: 30));
      endRange = now;
      break;
    case ChartRange.yearly:
      startRange = now.subtract(const Duration(days: 365));
      endRange = now;
      break;
  }

  final thcCalculator = THCConcentration(logs: logs); // all logs are passed
  final spots = <FlSpot>[];

  // Choose sample interval based on range.
  late Duration sampleInterval;
  switch (range) {
    case ChartRange.daily:
      sampleInterval = const Duration(minutes: 1);
      break;
    case ChartRange.weekly:
      sampleInterval = const Duration(minutes: 10);
      break;
    case ChartRange.monthly:
      sampleInterval = const Duration(hours: 1);
      break;
    case ChartRange.yearly:
      sampleInterval = const Duration(hours: 6);
      break;
  }

  DateTime t = startRange;
  while (t.isBefore(endRange) || t.isAtSameMomentAs(endRange)) {
    final x = t.millisecondsSinceEpoch.toDouble();
    final y = thcCalculator.calculateTHCAtTime(x);
    spots.add(FlSpot(x, y));
    t = t.add(sampleInterval);
  }

  return spots;
}

// 4. Update cumulativeDataProcessor to support yearly:
List<FlSpot> cumulativeDataProcessor(List<Log> logs, ChartRange range) {
  final now = DateTime.now();
  late DateTime startRange;
  final endRange = now;

  // For daily we use aggregation by day; for yearly we group by month.
  if (range == ChartRange.daily) {
    startRange = DateTime(now.year, now.month, now.day);
  } else if (range == ChartRange.yearly) {
    startRange = now.subtract(const Duration(days: 365));
  } else {
    // weekly and monthly still group by day.
    switch (range) {
      case ChartRange.weekly:
        startRange = now.subtract(const Duration(days: 7));
        break;
      case ChartRange.monthly:
        startRange = now.subtract(const Duration(days: 30));
        break;
      default:
        break;
    }
  }

  // Filter logs within the range.
  final filteredLogs = logs
      .where((log) =>
          (log.timestamp.isAfter(startRange) ||
              log.timestamp.isAtSameMomentAs(startRange)) &&
          (log.timestamp.isBefore(endRange) ||
              log.timestamp.isAtSameMomentAs(endRange)))
      .toList();

  final spots = <FlSpot>[];

  if (range == ChartRange.daily) {
    // Detailed daily view.
    final day = DateTime(now.year, now.month, now.day);
    final logsForDay = filteredLogs
        .where((log) =>
            DateTime(
                log.timestamp.year, log.timestamp.month, log.timestamp.day) ==
            day)
        .toList();
    logsForDay.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    double cumulative = 0;
    spots.add(FlSpot(day.millisecondsSinceEpoch.toDouble(), 0));
    for (final log in logsForDay) {
      cumulative += log.durationSeconds;
      spots.add(
          FlSpot(log.timestamp.millisecondsSinceEpoch.toDouble(), cumulative));
    }
  } else if (range == ChartRange.yearly) {
    // Group logs by month.
    final Map<DateTime, List<Log>> groupedLogs = {};
    for (final log in filteredLogs) {
      final monthKey = DateTime(log.timestamp.year, log.timestamp.month);
      groupedLogs.putIfAbsent(monthKey, () => []).add(log);
    }
    final sortedMonths = groupedLogs.keys.toList()..sort();
    for (final month in sortedMonths) {
      final logsForMonth = groupedLogs[month]!;
      final monthlyTotal =
          logsForMonth.fold(0.0, (prev, log) => prev + log.durationSeconds);
      // Position the consolidated point at the last day of the month, 11:59pm.
      final lastDayOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59);
      spots.add(FlSpot(
          lastDayOfMonth.millisecondsSinceEpoch.toDouble(), monthlyTotal));
    }
  } else {
    // For weekly and monthly, group logs by day.
    final Map<DateTime, List<Log>> groupedLogs = {};
    for (final log in filteredLogs) {
      final day =
          DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      groupedLogs.putIfAbsent(day, () => []).add(log);
    }
    final sortedDays = groupedLogs.keys.toList()..sort();
    for (final day in sortedDays) {
      final logsForDay = groupedLogs[day]!;
      final dailyTotal =
          logsForDay.fold(0.0, (prev, log) => prev + log.durationSeconds);
      // Consolidated point at 11:59pm of the day.
      final pointTime = DateTime(day.year, day.month, day.day, 23, 59);
      spots
          .add(FlSpot(pointTime.millisecondsSinceEpoch.toDouble(), dailyTotal));
    }
  }

  return spots;
}

// New configuration class for chart-specific settings.
class ChartConfig {
  final DataProcessor dataProcessor;
  final bool showDots;
  final String Function(double) leftTitleFormatter;
  final String Function(double) tooltipLabel;

  const ChartConfig({
    required this.dataProcessor,
    required this.showDots,
    required this.leftTitleFormatter,
    required this.tooltipLabel,
  });
}

class LineChartWidget extends StatefulWidget {
  final List<Log> logs;
  final DataProcessor dataProcessor;
  // Default chart type is now controlled by state.
  const LineChartWidget({
    Key? key,
    required this.logs,
    required this.dataProcessor,
  }) : super(key: key);

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  ChartRange _selectedRange = ChartRange.daily;
  ChartType _selectedChartType = ChartType.lengthPerHit;

  // Calculate dynamic interval for the left axis.
  double calculateLeftInterval(double minY, double maxY) {
    double range = maxY - minY;
    double interval = range / 6;
    return interval > 0 ? interval : 1.0;
  }

  // 5. Update determineBottomInterval() to account for yearly:
  double determineBottomInterval(ChartRange range) {
    // For cumulative charts in weekly/monthly, force one-day intervals,
    // but for yearly use one-month intervals.
    if (_selectedChartType == ChartType.cumulative) {
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

  // New helper function to return chart configuration based on ChartType.
  ChartConfig getChartConfig() {
    switch (_selectedChartType) {
      case ChartType.thcConcentration:
        return ChartConfig(
          dataProcessor: thcConcentrationDataProcessor,
          showDots: false,
          leftTitleFormatter: (value) => value.toStringAsFixed(0),
          tooltipLabel: (value) =>
              'THC Concentration: ${value.toStringAsFixed(2)}',
        );
      case ChartType.cumulative:
        return ChartConfig(
          dataProcessor: cumulativeDataProcessor,
          showDots: true,
          leftTitleFormatter: (value) => '${value.toStringAsFixed(0)} s',
          tooltipLabel: (value) =>
              'Cumulative Usage: ${value.toStringAsFixed(2)}',
        );
      // Add additional chart types as needed.
      default:
        return ChartConfig(
          dataProcessor: widget.dataProcessor,
          showDots: true,
          leftTitleFormatter: (value) => '${value.toStringAsFixed(0)} s',
          tooltipLabel: (value) => 'Usage: ${value.toStringAsFixed(2)}',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the chart configuration for settings.
    final chartConfig = getChartConfig();
    final spots = chartConfig.dataProcessor(widget.logs, _selectedRange);
    spots.sort((a, b) => a.x.compareTo(b.x));

    // Compute x-range bounds.
    double minX, maxX;
    if (spots.isEmpty) {
      minX = 0;
      maxX = 0;
    } else {
      // 7. Update the x‑axis bounds in build() to support yearly for cumulative:
      if (_selectedChartType == ChartType.cumulative &&
          _selectedRange != ChartRange.daily) {
        if (_selectedRange == ChartRange.yearly) {
          final now = DateTime.now();
          // Align to the last day of the current month.
          final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59);
          maxX = lastDay.millisecondsSinceEpoch.toDouble();
          // Go back 1 year.
          final startMonth =
              DateTime(lastDay.year - 1, lastDay.month, lastDay.day, 23, 59);
          minX = startMonth.millisecondsSinceEpoch.toDouble();
        } else {
          final today = DateTime.now();
          final todayEnd = DateTime(today.year, today.month, today.day, 23, 59);
          maxX = todayEnd.millisecondsSinceEpoch.toDouble();
          if (_selectedRange == ChartRange.weekly) {
            final startDay = todayEnd.subtract(const Duration(days: 7));
            minX = startDay.millisecondsSinceEpoch.toDouble();
          } else {
            // monthly.
            final startDay = todayEnd.subtract(const Duration(days: 30));
            minX = startDay.millisecondsSinceEpoch.toDouble();
          }
        }
      } else {
        final now = DateTime.now();
        double span;
        switch (_selectedRange) {
          case ChartRange.daily:
            span = 24 * 3600 * 1000; // 24 hours.
            break;
          case ChartRange.weekly:
            span = 7 * 24 * 3600 * 1000; // 7 days.
            break;
          case ChartRange.monthly:
            span = 30 * 24 * 3600 * 1000; // 30 days.
            break;
          case ChartRange.yearly:
            span = 365 * 24 * 3600 * 1000; // 365 days.
            break;
        }
        final double nowMs = now.millisecondsSinceEpoch.toDouble();
        maxX = nowMs;
        minX = nowMs - span;
      }
    }

    // Compute y-range bounds.
    final double computedMinY =
        spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(min);
    final double maxY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(max);
    final double minY = (_selectedChartType == ChartType.lengthPerHit ||
            _selectedChartType == ChartType.cumulative)
        ? 0
        : computedMinY;

    try {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Type selection dropdown.
            DropdownButton<ChartType>(
              value: _selectedChartType,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedChartType = newValue;
                  });
                }
              },
              items: ChartType.values
                  .map((chartType) => DropdownMenuItem<ChartType>(
                        value: chartType,
                        child: Text(
                            chartType.toString().split('.').last.toUpperCase()),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Chart Range dropdown.
            DropdownButton<ChartRange>(
              value: _selectedRange,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRange = newValue;
                  });
                }
              },
              items: ChartRange.values
                  .map((chartRange) => DropdownMenuItem<ChartRange>(
                        value: chartRange,
                        child: Text(chartRange
                            .toString()
                            .split('.')
                            .last
                            .toUpperCase()),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : 300.0;
                return SizedBox(
                  height: height,
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: false,
                          dotData: FlDotData(show: chartConfig.showDots),
                          color: Theme.of(context).highlightColor,
                          barWidth: 4,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                          ),
                          spots: spots,
                        ),
                      ],
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: calculateLeftInterval(minY, maxY),
                            getTitlesWidget: (value, meta) {
                              final label =
                                  chartConfig.leftTitleFormatter(value);
                              return Text(
                                label,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: determineBottomInterval(_selectedRange),
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() == minX.toInt() ||
                                  value.toInt() == maxX.toInt()) {
                                return Container();
                              }
                              Widget labelWidget;
                              // 6. Update bottom label widget to display yearly labels:
                              if (_selectedRange == ChartRange.daily) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(
                                    value.toInt());
                                final formattedTime =
                                    DateFormat('hh:mm a').format(dt);
                                labelWidget = Text(
                                  formattedTime,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                );
                              } else if (_selectedChartType ==
                                  ChartType.cumulative) {
                                if (_selectedRange == ChartRange.yearly) {
                                  final dt =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          value.toInt());
                                  final formattedDate =
                                      DateFormat('MMM yyyy').format(dt);
                                  labelWidget = Text(formattedDate,
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center);
                                } else {
                                  final dt =
                                      DateTime.fromMillisecondsSinceEpoch(
                                          value.toInt());
                                  final formattedDate =
                                      DateFormat('MMM dd').format(dt);
                                  labelWidget = Text(formattedDate,
                                      style: const TextStyle(fontSize: 10),
                                      textAlign: TextAlign.center);
                                }
                              } else if (_selectedRange == ChartRange.weekly) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(
                                    value.toInt());
                                final formattedDay =
                                    DateFormat('EEE').format(dt);
                                labelWidget = Text(
                                  formattedDay,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                );
                              } else if (_selectedRange == ChartRange.monthly) {
                                final dt = DateTime.fromMillisecondsSinceEpoch(
                                    value.toInt());
                                final formattedDate =
                                    DateFormat('MMM dd').format(dt);
                                labelWidget = Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                );
                              } else {
                                final dt = DateTime.fromMillisecondsSinceEpoch(
                                    value.toInt());
                                final formattedDate =
                                    DateFormat('MMM dd').format(dt);
                                labelWidget = Text(
                                  formattedDate,
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                );
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                  angle: -0.6,
                                  child: labelWidget,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: true),
                      minX: minX,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipPadding: const EdgeInsets.all(8.0),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((touchedSpot) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  touchedSpot.x.toInt());
                              final value = touchedSpot.y;
                              // Use only the date for cumulative weekly/monthly charts.
                              final formattedDate = (_selectedChartType ==
                                          ChartType.cumulative &&
                                      _selectedRange != ChartRange.daily)
                                  ? DateFormat('MMM dd').format(date)
                                  : DateFormat('MMMM dd, HH:mm').format(date);
                              return LineTooltipItem(
                                '$formattedDate\n${chartConfig.tooltipLabel(value)}',
                                TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('Error building chart: $e');
      print(stackTrace);
      return ErrorWidget('Something went wrong');
    }
  }
}
