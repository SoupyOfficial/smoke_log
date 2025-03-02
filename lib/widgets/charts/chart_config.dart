import 'package:fl_chart/fl_chart.dart';
import '../../models/log.dart';
import 'chart_data_processors.dart';

enum ChartType {
  lengthPerHit,
  cumulative,
  thcConcentration,
  rolling24h,
  rolling30d,
  rolling90d,
}

typedef DataProcessor = List<FlSpot> Function(List<Log> logs, ChartRange range);

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
