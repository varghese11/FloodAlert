import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class PauseToggleButton extends StatelessWidget {
  const PauseToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isPaused = context.watch<SettingsProvider>().isPaused;

    return IconButton(
      tooltip: isPaused ? 'Monitoring paused — tap to resume' : 'Pause monitoring',
      icon: Icon(
        isPaused ? Icons.pause_circle_outline : Icons.play_circle_outline,
        color: isPaused ? Colors.orange : Colors.white,
      ),
      onPressed: () async {
        await context.read<SettingsProvider>().togglePause();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPaused
                    ? 'Monitoring resumed — fetching every hour'
                    : 'Monitoring paused — no hourly requests will be sent',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }
}
