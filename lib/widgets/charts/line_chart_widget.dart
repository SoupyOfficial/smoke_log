import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/log.dart';
import 'chart_config.dart';
import 'chart_data_processors.dart';
import 'chart_helpers.dart';

class LineChartWidget extends StatefulWidget {
  final List<Log> logs;
  final DataProcessor dataProcessor;
  const LineChartWidget({
    super.key,
    required this.logs,
    required this.dataProcessor,
  });

  @override
  _LineChartWidgetState createState() => _LineChartWidgetState();
}

class _LineChartWidgetState extends State<LineChartWidget> {
  ChartRange _selectedRange = ChartRange.daily;
  ChartType _selectedChartType = ChartType.lengthPerHit;

  // Helper method for clean ChartType display names.
  String _chartTypeDisplayName(ChartType type) {
    switch (type) {
      case ChartType.lengthPerHit:
        return 'Length per Hit';
      case ChartType.cumulative:
        return 'Cumulative';
      case ChartType.thcConcentration:
        return 'THC Concentration';
      case ChartType.rolling24h:
        return 'Rolling 24h';
      case ChartType.rolling30d:
        return 'Rolling 30d';
      case ChartType.rolling90d:
        return 'Rolling 90d';
    }
  }

  // Helper method for clean ChartRange display names.
  String _chartRangeDisplayName(ChartRange range) {
    switch (range) {
      case ChartRange.daily:
        return 'Daily';
      case ChartRange.weekly:
        return 'Weekly';
      case ChartRange.monthly:
        return 'Monthly';
      case ChartRange.yearly:
        return 'Yearly';
    }
  }

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
    final chartConfig = getChartConfig();
    final spots = chartConfig.dataProcessor(widget.logs, _selectedRange);
    spots.sort((a, b) => a.x.compareTo(b.x));

    double minX, maxX;
    if (spots.isEmpty) {
      minX = 0;
      maxX = 0;
    } else {
      if (_selectedChartType == ChartType.cumulative &&
          _selectedRange != ChartRange.daily) {
        if (_selectedRange == ChartRange.yearly) {
          final now = DateTime.now();
          final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59);
          maxX = lastDay.millisecondsSinceEpoch.toDouble();
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
            final startDay = todayEnd.subtract(const Duration(days: 30));
            minX = startDay.millisecondsSinceEpoch.toDouble();
          }
        }
      } else {
        final now = DateTime.now();
        double span;
        switch (_selectedRange) {
          case ChartRange.daily:
            span = 24 * 3600 * 1000;
            break;
          case ChartRange.weekly:
            span = 7 * 24 * 3600 * 1000;
            break;
          case ChartRange.monthly:
            span = 30 * 24 * 3600 * 1000;
            break;
          case ChartRange.yearly:
            span = 365 * 24 * 3600 * 1000;
            break;
        }
        final nowMs = now.millisecondsSinceEpoch.toDouble();
        maxX = nowMs;
        minX = nowMs - span;
      }
    }

    final double computedMinY = spots.isEmpty
        ? 0
        : spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final double maxY = spots.isEmpty
        ? 0
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
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
            Row(
              children: [
                Expanded(
                  child: DropdownButton<ChartType>(
                    isExpanded: true,
                    value: _selectedChartType,
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedChartType = newValue;
                        });
                      }
                    },
                    items: ChartType.values.map((chartType) {
                      return DropdownMenuItem<ChartType>(
                        value: chartType,
                        child: Text(_chartTypeDisplayName(chartType)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<ChartRange>(
                    isExpanded: true,
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
                        child: Text(_chartRangeDisplayName(chartRange)),
                      );
                    }).toList(),
                  ),
                ),
              ],
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
                              return Text(label,
                                  style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: determineBottomInterval(
                                _selectedRange, _selectedChartType),
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
                                labelWidget = Text(formattedTime,
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center);
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
                                labelWidget = Text(formattedDay,
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center);
                              } else {
                                // monthly or fallback.
                                final dt = DateTime.fromMillisecondsSinceEpoch(
                                    value.toInt());
                                final formattedDate =
                                    DateFormat('MMM dd').format(dt);
                                labelWidget = Text(formattedDate,
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center);
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Transform.rotate(
                                    angle: -0.6, child: labelWidget),
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
