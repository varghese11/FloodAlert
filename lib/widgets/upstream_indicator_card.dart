import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/water_data_provider.dart';

class UpstreamIndicatorCard extends StatelessWidget {
  const UpstreamIndicatorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<WaterDataProvider>();
    final settings = context.watch<SettingsProvider>();

    final current = data.upstreamStation.currentReading;
    final delta = data.upstreamStation.levelDelta;
    final threshold = settings.upstreamThreshold;
    final isWarning = current != null && current.waterLevel >= threshold;

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
                    'Pullakkayar (Upstream)',
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
                  if (isWarning)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Rising above ${threshold.toStringAsFixed(0)} — watch Kallooppara',
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
      return _chip('+${abs.toStringAsFixed(2)} m', Colors.green.shade700,
          Icons.arrow_upward);
    } else {
      return _chip('-${abs.toStringAsFixed(2)} m', Colors.blue.shade700,
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
