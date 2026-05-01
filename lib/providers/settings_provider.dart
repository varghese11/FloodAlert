import 'package:flutter/foundation.dart';
import '../background/background_task.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  double _threshold;
  double _upstreamThreshold;
  double _manikalThreshold;
  bool _isPaused;

  SettingsProvider(this._storage)
      : _threshold = _storage.getThreshold(),
        _upstreamThreshold = _storage.getUpstreamThreshold(),
        _manikalThreshold = _storage.getManikalThreshold(),
        _isPaused = _storage.isFetchingPaused();

  double get threshold => _threshold;
  double get upstreamThreshold => _upstreamThreshold;
  double get manikalThreshold => _manikalThreshold;
  bool get isPaused => _isPaused;

  Future<void> setThreshold(double value) async {
    _threshold = value;
    await _storage.saveThreshold(value);
    notifyListeners();
  }

  Future<void> setUpstreamThreshold(double value) async {
    _upstreamThreshold = value;
    await _storage.saveUpstreamThreshold(value);
    notifyListeners();
  }

  Future<void> setManikalThreshold(double value) async {
    _manikalThreshold = value;
    await _storage.saveManikalThreshold(value);
    notifyListeners();
  }

  Future<void> togglePause() async {
    _isPaused = !_isPaused;
    await _storage.savePaused(_isPaused);
    if (_isPaused) {
      await BackgroundTaskManager.cancelHourlyFetch();
    } else {
      await BackgroundTaskManager.scheduleHourlyFetch();
    }
    notifyListeners();
  }
}
