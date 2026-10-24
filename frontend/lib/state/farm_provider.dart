import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../models/farm_model.dart';

class FarmProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<FarmModel> _farms = [];
  FarmModel? _activeFarm;
  bool _isLoading = false;
  String? _errorMessage;

  List<FarmModel> get farms => _farms;
  FarmModel? get activeFarm => _activeFarm;
  FarmModel? get selectedFarm => _activeFarm;
  bool get hasFarms => _farms.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFarms() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/api/v1/farms');
      if (res is List) {
        _farms = res.map((e) => FarmModel.fromJson(e)).toList();

        // Restore active farm if saved
        final prefs = await SharedPreferences.getInstance();
        final savedFarmId = prefs.getString('active_farm_id');

        if (_farms.isNotEmpty) {
          if (savedFarmId != null) {
            final match = _farms.where((f) => f.farmId == savedFarmId).toList();
            _activeFarm = match.isNotEmpty ? match.first : _farms.first;
          } else {
            _activeFarm = _farms.first;
          }
        } else {
          _activeFarm = null;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> selectFarm(FarmModel farm) async {
    _activeFarm = farm;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_farm_id', farm.farmId);
    notifyListeners();
    return true;
  }

  Future<FarmModel?> createFarm({
    required String farmName,
    required double latitude,
    required double longitude,
    double? locationAccuracyMeters,
    String? address,
    String? village,
    String? district,
    required String state,
    required double area,
    String areaUnit = 'hectares',
    String soilType = 'Loamy',
    String? irrigationSource,
    String? activeCrop,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'farm_name': farmName,
        'latitude': latitude,
        'longitude': longitude,
        'location_accuracy_meters': locationAccuracyMeters,
        'address': address,
        'village': village,
        'district': district,
        'state': state,
        'country': 'India',
        'area': area,
        'area_unit': areaUnit,
        'soil_type': soilType,
        'irrigation_source': irrigationSource ?? 'Borewell',
        'active_crop': activeCrop,
      };

      final res = await _api.post('/api/v1/farms', body: body);
      if (res is Map<String, dynamic>) {
        final newFarm = FarmModel.fromJson(res);
        _farms.insert(0, newFarm);
        _activeFarm = newFarm;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('active_farm_id', newFarm.farmId);

        _isLoading = false;
        notifyListeners();
        return newFarm;
      }
      throw ApiException('Unexpected server response during farm creation');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateFarm(String farmId, Map<String, dynamic> updates) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.patch('/api/v1/farms/$farmId', body: updates);
      if (res is Map<String, dynamic>) {
        final updated = FarmModel.fromJson(res);
        final index = _farms.indexWhere((f) => f.farmId == farmId);
        if (index != -1) {
          _farms[index] = updated;
        }
        if (_activeFarm?.farmId == farmId) {
          _activeFarm = updated;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Failed to update farm');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setActiveCrop(String cropName) async {
    if (_activeFarm == null) return false;
    return await updateFarm(_activeFarm!.farmId, {'active_crop': cropName});
  }

  Future<bool> deleteFarm(String farmId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _api.delete('/api/v1/farms/$farmId');
      _farms.removeWhere((f) => f.farmId == farmId);
      if (_activeFarm?.farmId == farmId) {
        _activeFarm = _farms.isNotEmpty ? _farms.first : null;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
