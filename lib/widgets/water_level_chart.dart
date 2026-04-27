import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/water_data_provider.dart';

class WaterLevelChart extends StatelessWidget {
  const WaterLevelChart({super.key});

  @override
  Widget build(BuildContext context) {
    final readings = context.watch<WaterDataProvider>().mainStation.readings;
    final threshold = context.watch<SettingsProvider>().threshold;

    if (readings.isEmpty) {
      return const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: Text('No data yet — pull to refresh')),
        ),
      );
    }

    final spots = readings.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.waterLevel);
    }).toList();

    final allLevels = readings.map((r) => r.waterLevel).toList();
    final minY = (allLevels.reduce((a, b) => a < b ? a : b) - 0.5)
        .clamp(0.0, double.infinity);
    final maxY = allLevels.reduce((a, b) => a > b ? a : b) + 0.5;

    // Show at most 6 time labels on X axis
    final interval = (readings.length / 6).ceilToDouble().clamp(1.0, double.infinity);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 12),
              child: Text(
                'Water Level — Last 3 Days',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY > threshold + 0.5 ? maxY : threshold + 0.5,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 0.5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: threshold,
                        color: Colors.red.withValues(alpha: 0.7),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (_) =>
                              ' Alert ${threshold.toStringAsFixed(1)}m',
                        ),
                      ),
                    ],
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toStringAsFixed(1)}m',
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= readings.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('HH:mm').format(readings[idx].dataTime),
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
