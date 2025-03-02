import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // added for date formatting
import '../models/log.dart';

enum ChartType { lengthPerHit /*, cumulative, etc. */ }

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

  // Helper to calculate dynamic left axis interval
  double calculateInterval(double minY, double maxY) {
    double range = maxY - minY;
    double interval = range / 6;
    return interval > 0 ? interval : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final spots = widget.dataProcessor(widget.logs, _selectedRange);

    // Compute x-range bounds based on spots
    final double minX = spots.isEmpty ? 0 : spots.map((s) => s.x).reduce(min);
    final double maxX = spots.isEmpty ? 0 : spots.map((s) => s.x).reduce(max);

    // Compute y-range bounds based on spots
    final double minY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(min);
    final double maxY = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce(max);

    return Column(
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
          items: ChartRange.values.map((chartRange) {
            return DropdownMenuItem<ChartRange>(
              value: chartRange,
              child: Text(chartRange.name.toUpperCase()),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // Use LayoutBuilder to provide finite height.
        LayoutBuilder(
          builder: (context, constraints) {
            final height =
                constraints.hasBoundedHeight ? constraints.maxHeight : 300.0;
            return SizedBox(
              height: height,
              child: LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: calculateInterval(minY, maxY),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        // You might choose an interval here based on your data/time range.
                        // For example:
                        // interval: (maxX - minX) / (spots.length < 2 ? 1 : spots.length - 1),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (spots.isEmpty || value == spots.last.x) {
                            return Container();
                          }
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          final formattedDate =
                              DateFormat('MMM dd').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center,
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
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineTouchData: LineTouchData(enabled: true),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
