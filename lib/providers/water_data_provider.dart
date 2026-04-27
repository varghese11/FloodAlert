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
  bool _isLoading = false;
  String? _errorMessage;
  bool _apiReturnedEmpty = false;

  late final ValueListenable<Box<WaterReading>> _readingsListenable;
  late final ValueListenable<Box<WaterReading>> _upstreamListenable;

  WaterDataProvider(this._storage, this._api) {
    _readingsListenable = _storage.getReadingsListenable();
    _upstreamListenable = _storage.getUpstreamListenable();
    _readingsListenable.addListener(_onDataChanged);
    _upstreamListenable.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    loadFromStorage();
  }

  @override
  void dispose() {
    _readingsListenable.removeListener(_onDataChanged);
    _upstreamListenable.removeListener(_onDataChanged);
    super.dispose();
  }

  List<WaterReading> get readings => _readings;
  List<WaterReading> get upstreamReadings => _upstreamReadings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get apiReturnedEmpty => _apiReturnedEmpty;

  // --- Station Data Accessors ---

  StationData get mainStation => StationData(_readings);
  StationData get upstreamStation => StationData(_upstreamReadings);

  // --- Data loading ---

  void loadFromStorage() {
    _readings = _storage.getReadings();
    _upstreamReadings = _storage.getUpstreamReadings();
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
      ]);
      await _storage.saveReadings(results[0]);
      await _storage.saveUpstreamReadings(results[1]);
      _readings = _storage.getReadings();
      _upstreamReadings = _storage.getUpstreamReadings();
      if (results[0].isEmpty && results[1].isEmpty) {
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
