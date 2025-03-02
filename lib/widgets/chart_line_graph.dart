import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/log.dart';

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
      startRange = DateTime(now.year, now.month, now.day);
      break;
    case ChartRange.weekly:
      startRange = now.subtract(Duration(days: now.weekday - 1));
      break;
    case ChartRange.monthly:
      startRange = DateTime(now.year, now.month, 1);
      break;
  }
  final filteredLogs =
      logs.where((log) => log.timestamp.isAfter(startRange)).toList();
  return filteredLogs
      .map((log) => FlSpot(
            log.timestamp.millisecondsSinceEpoch.toDouble(),
            log.durationSeconds.toDouble(),
          ))
      .toList();
}

class LineChartWidget extends StatefulWidget {
  final List<Log> logs;
  final DataProcessor dataProcessor;
  final ChartType chartType;

  const LineChartWidget({
    Key? key,
    required this.logs,
    required this.dataProcessor,
    this.chartType = ChartType.lengthPerHit,
  }) : super(key: key);

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  ChartRange _selectedRange = ChartRange.daily;

  // Calculate dynamic interval for the left axis.
  double calculateLeftInterval(double minY, double maxY) {
    double range = maxY - minY;
    double interval = range / 6;
    return interval > 0 ? interval : 1.0;
  }

  // Mimic DataUtils.determineInterval from the example based on time range.
  double determineBottomInterval(ChartRange range) {
    switch (range) {
      case ChartRange.daily:
        return 30 * 60 * 1000; // 30 minutes in milliseconds
      case ChartRange.weekly:
        return 24 * 3600 * 1000; // 1 day
      case ChartRange.monthly:
        return 7 * 24 * 3600 * 1000; // 1 week
    }
  }

  @override
  Widget build(BuildContext context) {
    // Process data based on selected range.
    final spots = widget.dataProcessor(widget.logs, _selectedRange);

    // Sort spots by x value.
    spots.sort((a, b) => a.x.compareTo(b.x));

    // Compute x-range bounds.
    double minX, maxX;
    final now = DateTime.now();

    if (spots.isEmpty) {
      minX = 0;
      maxX = 0;
    } else {
      if (_selectedRange == ChartRange.daily) {
        const dailySpan = 25 * 3600 * 1000; // 25 hours in milliseconds.
        // Round current time up to the next 30-minute mark.
        final int remainder = now.minute % 30;
        final int minutesToAdd =
            (remainder == 0 && now.second == 0 && now.millisecond == 0)
                ? 30
                : (30 - remainder);
        final next30 = DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        ).add(Duration(minutes: minutesToAdd));
        maxX = next30.millisecondsSinceEpoch.toDouble();
        minX = maxX - dailySpan;
      } else if (_selectedRange == ChartRange.weekly) {
        // For weekly, round up to the next day boundary (midnight) and subtract 7 days.
        final nextDay =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        maxX = nextDay.millisecondsSinceEpoch.toDouble();
        const weekSpan = 7 * 24 * 3600 * 1000; // 7 days in milliseconds.
        minX = maxX - weekSpan;
      } else if (_selectedRange == ChartRange.monthly) {
        // For monthly, use the start of the month as minX and round current time to next day for maxX.
        final startOfMonth =
            DateTime(now.year, now.month, 1).millisecondsSinceEpoch.toDouble();
        final nextDay =
            DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
        maxX = nextDay.millisecondsSinceEpoch.toDouble();
        minX = startOfMonth;
      } else {
        // Fallback: use first and last data points.
        maxX = spots.last.x;
        minX = spots.first.x;
      }
    }

    // Compute natural y-range bounds.
    final double computedMinY =
        spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(min);
    final double maxY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(max);
    // For specific chart types, force the minY to 0.
    final double minY = (widget.chartType == ChartType.lengthPerHit ||
            widget.chartType == ChartType.cumulative)
        ? 0
        : computedMinY;

    try {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        child: Text(chartRange.name.toUpperCase()),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Use LayoutBuilder to provide a finite height.
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
                          isCurved:
                              widget.chartType == ChartType.thcConcentration
                                  ? false
                                  : true,
                          dotData: FlDotData(
                              show: widget.chartType !=
                                  ChartType.thcConcentration),
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
                              // For charts other than THC Concentration, append seconds unit.
                              final label =
                                  widget.chartType == ChartType.thcConcentration
                                      ? value.toStringAsFixed(0)
                                      : '${value.toStringAsFixed(0)} s';
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
                              // Hide labels if they're at the min or max x position.
                              if (value.toInt() == minX.toInt() ||
                                  value.toInt() == maxX.toInt()) {
                                return Container();
                              }

                              Widget labelWidget;
                              if (_selectedRange == ChartRange.daily) {
                                // Daily: 12-hour format with AM/PM.
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
                                // Weekly: Abbreviated weekday name.
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
                                // Monthly: Month and day.
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
                                // Fallback - default formatting.
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
                                  angle: -0.6, // Increased rotation angle.
                                  child: labelWidget,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
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
                              final value = touchedSpot.y.toStringAsFixed(2);
                              String label = '';
                              switch (widget.chartType) {
                                case ChartType.cumulative:
                                  label = 'Cumulative Usage';
                                  break;
                                case ChartType.thcConcentration:
                                  label = 'THC Concentration';
                                  break;
                                case ChartType.rolling24h:
                                  label = 'Rolling 24h Usage';
                                  break;
                                case ChartType.rolling30d:
                                  label = 'Rolling 30d Usage';
                                  break;
                                case ChartType.rolling90d:
                                  label = 'Rolling 90d Usage';
                                  break;
                                default:
                                  label = 'Usage';
                              }
                              return LineTooltipItem(
                                '$formattedDate\n$label: $value',
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
