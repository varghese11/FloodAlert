import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/water_data_provider.dart';
import '../services/water_api_service.dart';
import 'level_indicator.dart';

class WaterLevelCard extends StatelessWidget {
  const WaterLevelCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WaterDataProvider>();
    final current = provider.mainStation.currentReading;
    final lastUpdated = provider.mainStation.lastUpdated;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Water Level',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            current == null
                ? const Text(
                    '—',
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        current.waterLevel.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          ' m',
                          style: TextStyle(fontSize: 22, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 8),
            LevelIndicator(delta: provider.mainStation.levelDelta),
            const SizedBox(height: 10),
            Row(
              children: [
                _LevelInfo(
                  label: 'Danger Level',
                  value: '${WaterStation.kalloopparaInfo.dangerLevel.toStringAsFixed(1)} m',
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 20),
                _LevelInfo(
                  label: 'Highest Flood',
                  value: '${WaterStation.kalloopparaInfo.highestFloodLevel.toStringAsFixed(2)} m',
                  color: Colors.red.shade700,
                ),
              ],
            ),
            if (lastUpdated != null) ...[
              const SizedBox(height: 8),
              Text(
                'Last updated: ${DateFormat('dd MMM yyyy, hh:mm a').format(lastUpdated)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LevelInfo({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
