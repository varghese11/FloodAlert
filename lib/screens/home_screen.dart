import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/water_data_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/pause_toggle_button.dart';
import '../widgets/upstream_indicator_card.dart';
import '../widgets/water_level_card.dart';
import '../widgets/water_level_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WaterDataProvider>();
      provider.loadFromStorage();
      provider.refreshFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = context.watch<SettingsProvider>().isPaused;
    final error = context.watch<WaterDataProvider>().errorMessage;
    final isLoading = context.watch<WaterDataProvider>().isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FloodAlert',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            Text(
              'Kallooppara · Manimala River',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          const PauseToggleButton(),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<WaterDataProvider>().refreshFromApi(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isPaused)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.pause_circle,
                        color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Monitoring is paused. Tap ▶ in the toolbar to resume.',
                        style: TextStyle(
                            color: Colors.orange.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            const UpstreamIndicatorCard(),
            const SizedBox(height: 12),
            const WaterLevelCard(),
            const SizedBox(height: 16),
            const WaterLevelChart(),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '017-SWRDKOCHI · 035-SWRDKOCHI · Kerala, India',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
