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

enum ChartRange { daily, weekly, monthly }

typedef DataProcessor = List<FlSpot> Function(List<Log> logs, ChartRange range);

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

// New data processor for THC Concentration.
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
  }

  // Filter logs to only those in the range.
  final filteredLogs = logs
      .where((log) =>
          !log.timestamp.isBefore(startRange) &&
          !log.timestamp.isAfter(endRange))
      .toList();

  final thcCalculator = THCConcentration(logs: filteredLogs);
  final spots = <FlSpot>[];

  DateTime t = startRange;
  while (t.isBefore(endRange) || t.isAtSameMomentAs(endRange)) {
    final x = t.millisecondsSinceEpoch.toDouble();
    final y = thcCalculator.calculateTHCAtTime(x);
    spots.add(FlSpot(x, y));
    t = t.add(const Duration(minutes: 1));
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

  // Determine bottom interval based on chart range.
  double determineBottomInterval(ChartRange range) {
    switch (range) {
      case ChartRange.daily:
        return 30 * 60 * 1000; // 30 minutes.
      case ChartRange.weekly:
        return 24 * 3600 * 1000; // 1 day.
      case ChartRange.monthly:
        return 7 * 24 * 3600 * 1000; // 1 week.
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
          dataProcessor: widget.dataProcessor,
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
    final now = DateTime.now();

    if (spots.isEmpty) {
      minX = 0;
      maxX = 0;
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
      }
      final double nowMs = now.millisecondsSinceEpoch.toDouble();
      maxX = nowMs;
      minX = nowMs - span;
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
                              final dateFormat = DateFormat('MMMM dd, HH:mm');
                              final formattedDate = dateFormat.format(date);
                              final value = touchedSpot.y;
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
