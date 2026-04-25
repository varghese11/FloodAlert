import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/water_data_provider.dart';
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
            if (lastUpdated != null) ...[
              const SizedBox(height: 10),
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
