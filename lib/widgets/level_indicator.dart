import 'package:flutter/material.dart';

class LevelIndicator extends StatelessWidget {
  final double? delta;

  const LevelIndicator({super.key, required this.delta});

  @override
  Widget build(BuildContext context) {
    if (delta == null) {
      return const Text(
        '— No previous data',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      );
    }

    final isRising = delta! > 0;
    final isStable = delta!.abs() < 0.01;
    final color = isStable
        ? Colors.orange
        : isRising
            ? Colors.red
            : Colors.blue;
    final icon = isStable
        ? Icons.remove
        : isRising
            ? Icons.arrow_upward
            : Icons.arrow_downward;
    final label = isStable
        ? 'Stable'
        : isRising
            ? 'Rising'
            : 'Falling';
    final sign = delta! > 0 ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text(
          '$label  $sign${delta!.toStringAsFixed(2)} m from last hour',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
