import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/station_data.dart';
import '../models/water_reading.dart';
import '../services/storage_service.dart';
import '../services/water_api_service.dart';

class WaterDataProvider extends ChangeNotifier {
  final StorageService _storage;
  final WaterApiService _api;

  List<WaterReading> _readings = [];
  List<WaterReading> _upstreamReadings = [];
  List<WaterReading> _manikalReadings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _apiReturnedEmpty = false;

  late final ValueListenable<Box<WaterReading>> _readingsListenable;
  late final ValueListenable<Box<WaterReading>> _upstreamListenable;
  late final ValueListenable<Box<WaterReading>> _manikalListenable;

  WaterDataProvider(this._storage, this._api) {
    _readingsListenable = _storage.getReadingsListenable();
    _upstreamListenable = _storage.getUpstreamListenable();
    _manikalListenable = _storage.getManikalListenable();
    _readingsListenable.addListener(_onDataChanged);
    _upstreamListenable.addListener(_onDataChanged);
    _manikalListenable.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    loadFromStorage();
  }

  @override
  void dispose() {
    _readingsListenable.removeListener(_onDataChanged);
    _upstreamListenable.removeListener(_onDataChanged);
    _manikalListenable.removeListener(_onDataChanged);
    super.dispose();
  }

  List<WaterReading> get readings => _readings;
  List<WaterReading> get upstreamReadings => _upstreamReadings;
  List<WaterReading> get manikalReadings => _manikalReadings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get apiReturnedEmpty => _apiReturnedEmpty;

  // --- Station Data Accessors ---

  StationData get mainStation => StationData(_readings);
  StationData get upstreamStation => StationData(_upstreamReadings);
  StationData get manikalStation => StationData(_manikalReadings);

  // --- Data loading ---

  void loadFromStorage() {
    _readings = _storage.getReadings();
    _upstreamReadings = _storage.getUpstreamReadings();
    _manikalReadings = _storage.getManikalReadings();
    notifyListeners();
  }

  Future<void> refreshFromApi() async {
    _isLoading = true;
    _errorMessage = null;
    _apiReturnedEmpty = false;
    notifyListeners();
    try {
      final results = await Future.wait([
        _api.fetchReadings(stationCode: WaterStation.kallooppara),
        _api.fetchReadings(stationCode: WaterStation.pullakkayar),
        _api.fetchReadings(stationCode: WaterStation.manikal),
      ]);
      await _storage.saveReadings(results[0]);
      await _storage.saveUpstreamReadings(results[1]);
      await _storage.saveManikalReadings(results[2]);
      _readings = _storage.getReadings();
      _upstreamReadings = _storage.getUpstreamReadings();
      _manikalReadings = _storage.getManikalReadings();
      if (results[0].isEmpty && results[1].isEmpty && results[2].isEmpty) {
        _apiReturnedEmpty = true;
      }
    } on ApiTimeoutException {
      _errorMessage = 'Connection timed out. Please try again.';
    } on NetworkException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to fetch data. Check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
