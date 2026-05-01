import 'package:flutter/material.dart';
import '../models/station_data.dart';

class UpstreamIndicatorCard extends StatelessWidget {
  final String stationName;
  final StationData stationData;
  final double alertThreshold;
  final double dangerLevel;
  final double highestFloodLevel;

  const UpstreamIndicatorCard({
    super.key,
    required this.stationName,
    required this.stationData,
    required this.alertThreshold,
    required this.dangerLevel,
    required this.highestFloodLevel,
  });

  @override
  Widget build(BuildContext context) {
    final current = stationData.currentReading;
    final delta = stationData.levelDelta;
    final isWarning = current != null && current.waterLevel >= alertThreshold;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isWarning ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.arrow_upward,
              color: isWarning ? Colors.orange.shade700 : Colors.blue.shade300,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stationName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (current == null)
                    Text('No data yet',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500))
                  else
                    Row(
                      children: [
                        Text(
                          current.waterLevel.toStringAsFixed(2),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        _TrendChip(delta: delta),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _LevelBadge(
                        label: 'Danger',
                        value: dangerLevel.toStringAsFixed(1),
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 10),
                      _LevelBadge(
                        label: 'Highest Flood',
                        value: highestFloodLevel.toStringAsFixed(2),
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                  if (isWarning)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Rising above ${alertThreshold.toStringAsFixed(0)} — watch Kallooppara',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LevelBadge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _TrendChip extends StatelessWidget {
  final double? delta;
  const _TrendChip({this.delta});

  @override
  Widget build(BuildContext context) {
    if (delta == null) {
      return const SizedBox.shrink();
    }
    final abs = delta!.abs();
    if (abs < 0.01) {
      return _chip('Stable', Colors.grey.shade600, Icons.remove);
    } else if (delta! > 0) {
      return _chip('+${abs.toStringAsFixed(2)}', Colors.green.shade700,
          Icons.arrow_upward);
    } else {
      return _chip('-${abs.toStringAsFixed(2)}', Colors.blue.shade700,
          Icons.arrow_downward);
    }
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
