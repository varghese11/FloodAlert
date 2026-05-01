import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late double _sliderValue;
  late double _upstreamSliderValue;
  late double _manikalSliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = context.read<SettingsProvider>().threshold.clamp(5.0, 15.0);
    _upstreamSliderValue =
        context.read<SettingsProvider>().upstreamThreshold.clamp(50.0, 200.0);
    _manikalSliderValue =
        context.read<SettingsProvider>().manikalThreshold.clamp(50.0, 200.0);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Alarm threshold ---
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert Threshold',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send a notification when water level reaches this value.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('5.0 m',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Expanded(
                        child: Slider(
                          value: _sliderValue,
                          min: 5.0,
                          max: 15.0,
                          divisions: 100,
                          activeColor: Colors.blue,
                          onChanged: (v) => setState(() => _sliderValue = v),
                          onChangeEnd: (v) =>
                              context.read<SettingsProvider>().setThreshold(v),
                        ),
                      ),
                      const Text('15.0 m',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Center(
                    child: Text(
                      '${_sliderValue.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Upstream threshold ---
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upstream Early Warning (Pullakkayar)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alarm when upstream station rises above this level.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('50',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Expanded(
                        child: Slider(
                          value: _upstreamSliderValue,
                          min: 50.0,
                          max: 200.0,
                          divisions: 150,
                          activeColor: Colors.orange,
                          onChanged: (v) =>
                              setState(() => _upstreamSliderValue = v),
                          onChangeEnd: (v) => context
                              .read<SettingsProvider>()
                              .setUpstreamThreshold(v),
                        ),
                      ),
                      const Text('200',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Center(
                    child: Text(
                      _upstreamSliderValue.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Manikal upstream threshold ---
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upstream Early Warning (Manikal)',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alarm when Manikal station rises above this level.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('50',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Expanded(
                        child: Slider(
                          value: _manikalSliderValue,
                          min: 50.0,
                          max: 200.0,
                          divisions: 150,
                          activeColor: Colors.orange,
                          onChanged: (v) =>
                              setState(() => _manikalSliderValue = v),
                          onChangeEnd: (v) => context
                              .read<SettingsProvider>()
                              .setManikalThreshold(v),
                        ),
                      ),
                      const Text('200',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  Center(
                    child: Text(
                      _manikalSliderValue.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // --- Monitoring toggle ---
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              title: const Text(
                'Pause monitoring',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                settings.isPaused
                    ? 'Hourly requests are stopped. Toggle off to resume.'
                    : 'App fetches water level every hour in the background.',
                style: const TextStyle(fontSize: 12),
              ),
              secondary: Icon(
                settings.isPaused
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                color: settings.isPaused ? Colors.orange : Colors.green,
              ),
              value: settings.isPaused,
              activeThumbColor: Colors.orange,
              onChanged: (_) => context.read<SettingsProvider>().togglePause(),
            ),
          ),

          const SizedBox(height: 12),

          // --- Station info ---
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station Information',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 12),
                  _InfoRow(label: 'Main station', value: 'KALLOOPPARA (017-SWRDKOCHI)'),
                  _InfoRow(label: 'Upstream 1', value: 'PULLAKKAYAR (035-SWRDKOCHI)'),
                  _InfoRow(label: 'Upstream 2', value: 'MANIKAL (032-SWRDKOCHI)'),
                  _InfoRow(label: 'River', value: 'Manimala River'),
                  _InfoRow(label: 'State', value: 'Kerala, India'),
                  _InfoRow(label: 'Data source', value: 'Central Water Commission'),
                  _InfoRow(label: 'Update interval', value: 'Every hour'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
