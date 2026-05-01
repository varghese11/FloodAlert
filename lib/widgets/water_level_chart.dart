import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/water_data_provider.dart';
import '../services/water_api_service.dart';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

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

    final dangerLevel = WaterStation.kalloopparaInfo.dangerLevel;
    final highestFloodLevel = WaterStation.kalloopparaInfo.highestFloodLevel;

    final allLevels = readings.map((r) => r.waterLevel).toList();
    final minY = (allLevels.reduce((a, b) => a < b ? a : b) - 0.5)
        .clamp(0.0, double.infinity);
    final dataMax = allLevels.reduce((a, b) => a > b ? a : b) + 0.5;
    final maxY = [dataMax, threshold + 0.5, highestFloodLevel + 0.5]
        .reduce((a, b) => a > b ? a : b);
    final yRange = maxY - minY;
    final yInterval = yRange <= 2 ? 0.5 : yRange <= 6 ? 1.0 : yRange <= 12 ? 2.0 : 5.0;

    // Show at most 6 time labels on X axis
    final interval = (readings.length / 6).ceilToDouble().clamp(1.0, double.infinity);
    final spansMultipleDays = readings.length > 1 &&
        !_sameDay(readings.first.dataTime, readings.last.dataTime);

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
                  maxY: maxY,
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
                        y: dangerLevel,
                        color: Colors.orange.withValues(alpha: 0.8),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topLeft,
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (_) =>
                              ' Danger ${dangerLevel.toStringAsFixed(1)}m',
                        ),
                      ),
                      HorizontalLine(
                        y: highestFloodLevel,
                        color: Colors.red.shade900.withValues(alpha: 0.8),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topLeft,
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          labelResolver: (_) =>
                              ' Highest ${highestFloodLevel.toStringAsFixed(2)}m',
                        ),
                      ),
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
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.min || value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${value.toStringAsFixed(1)}m',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: interval,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= readings.length) {
                            return const SizedBox();
                          }
                          final dt = readings[idx].dataTime;
                          final label = spansMultipleDays
                              ? DateFormat("d MMM\nh:mm a").format(dt)
                              : DateFormat("h:mm a").format(dt);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 9),
                              textAlign: TextAlign.center,
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
