import 'package:flutter/foundation.dart';
import '../core/api_client.dart';
import '../models/soil_profile_model.dart';
import '../models/crop_candidate_model.dart';
import '../models/fertilizer_model.dart';
import '../models/yield_prediction_model.dart';
import '../models/irrigation_model.dart';
import '../models/disease_model.dart';
import '../models/market_model.dart';
import '../models/profit_model.dart';
import '../models/weather_model.dart';
import '../models/decision_support_model.dart';

class FarmingWorkflowProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Weather
  WeatherModel? _weather;
  WeatherModel? get weather => _weather;

  // Soil
  SoilProfileModel? _latestSoilProfile;
  List<SoilProfileModel> _soilProfiles = [];
  SoilProfileModel? get latestSoilProfile => _latestSoilProfile;
  List<SoilProfileModel> get soilProfiles => _soilProfiles;

  // Crop Recommendation
  List<CropCandidateModel> _cropCandidates = [];
  List<CropCandidateModel> get cropCandidates => _cropCandidates;

  // Fertilizer Recommendation
  FertilizerRecommendationModel? _fertilizerRecommendation;
  FertilizerRecommendationModel? get fertilizerRecommendation => _fertilizerRecommendation;

  // Yield Prediction
  YieldPredictionModel? _yieldPrediction;
  YieldPredictionModel? get yieldPrediction => _yieldPrediction;

  // Irrigation
  IrrigationModel? _irrigationAdvisory;
  IrrigationModel? get irrigationAdvisory => _irrigationAdvisory;

  // Disease Detection
  DiseaseAnalysisModel? _latestDiseaseAnalysis;
  DiseaseAnalysisModel? get latestDiseaseAnalysis => _latestDiseaseAnalysis;

  // Market Intelligence
  List<MarketPriceRecordModel> _marketPrices = [];
  List<MarketPriceRecordModel> get marketPrices => _marketPrices;

  // Profit Estimation
  ProfitEstimationModel? _profitEstimate;
  ProfitEstimationModel? get profitEstimate => _profitEstimate;

  // Unified Decision Support
  DecisionSupportModel? _decisionSupport;
  DecisionSupportModel? get decisionSupport => _decisionSupport;

  // Digital Diary
  List<Map<String, dynamic>> _diaryEntries = [];
  List<Map<String, dynamic>> get diaryEntries => _diaryEntries;

  // Assistant Chat
  List<Map<String, String>> _chatMessages = [];
  List<Map<String, String>> get chatMessages => _chatMessages;

  // 1. Fetch Weather
  Future<void> fetchWeather(double latitude, double longitude) async {
    try {
      final res = await _api.get('/api/v1/weather', queryParams: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      });
      if (res is Map<String, dynamic>) {
        _weather = WeatherModel.fromJson(res);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching weather: $e');
    }
  }

  // 2. Load Soil Profiles
  Future<void> loadSoilProfiles(String farmId) async {
    try {
      final res = await _api.get('/api/v1/farms/$farmId/soil-profiles');
      if (res is List) {
        _soilProfiles = res.map((e) => SoilProfileModel.fromJson(e)).toList();
        if (_soilProfiles.isNotEmpty) {
          _latestSoilProfile = _soilProfiles.first;
        } else {
          _latestSoilProfile = null;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading soil profiles: $e');
    }
  }

  // 3. Add Soil Profile
  Future<bool> addSoilProfile(String farmId, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/api/v1/farms/$farmId/soil-profiles', body: data);
      if (res is Map<String, dynamic>) {
        final profile = SoilProfileModel.fromJson(res);
        _soilProfiles.insert(0, profile);
        _latestSoilProfile = profile;
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Unexpected soil profile response');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 4. Run Crop Recommendation
  Future<bool> runCropRecommendation({
    String? farmId,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double temperature,
    required double humidity,
    required double ph,
    required double rainfall,
    int topN = 5,
    bool enrichWithGemini = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'farm_id': farmId,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'temperature': temperature,
        'humidity': humidity,
        'ph': ph,
        'rainfall': rainfall,
        'top_n': topN,
      };

      final res = await _api.post(
        '/api/v1/crops/recommend',
        body: body,
        queryParams: {'enrich_with_gemini': enrichWithGemini.toString()},
      );

      if (res is Map<String, dynamic> && res.containsKey('candidates')) {
        final list = res['candidates'] as List<dynamic>;
        _cropCandidates = list.map((e) => CropCandidateModel.fromJson(e)).toList();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Failed to retrieve candidate crops');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 5. Run Fertilizer Recommendation
  Future<bool> runFertilizerRecommendation({
    String? farmId,
    required double temperature,
    required double humidity,
    required double rainfall,
    required double moisture,
    required String soilType,
    required double soilPh,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required String cropType,
    required String growthStage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'farm_id': farmId,
        'temperature': temperature,
        'humidity': humidity,
        'rainfall': rainfall,
        'moisture': moisture,
        'soil_type': soilType,
        'soil_ph': soilPh,
        'nitrogen': nitrogen,
        'phosphorus': phosphorus,
        'potassium': potassium,
        'crop_type': cropType,
        'growth_stage': growthStage,
      };

      final res = await _api.post('/api/v1/fertilizer/recommend', body: body);
      if (res is Map<String, dynamic>) {
        _fertilizerRecommendation = FertilizerRecommendationModel.fromJson(res);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Failed to compute fertilizer recommendation');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 6. Predict Crop Yield
  Future<bool> predictYield({
    String? farmId,
    required String crop,
    required int cropYear,
    required String season,
    required String state,
    required double area,
    String areaUnit = 'hectares',
    required double annualRainfall,
    required double fertilizer,
    required double pesticide,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'farm_id': farmId,
        'crop': crop,
        'crop_year': cropYear,
        'season': season,
        'state': state,
        'area': area,
        'area_unit': areaUnit,
        'annual_rainfall': annualRainfall,
        'fertilizer': fertilizer,
        'pesticide': pesticide,
      };

      final res = await _api.post('/api/v1/yield/predict', body: body);
      if (res is Map<String, dynamic>) {
        _yieldPrediction = YieldPredictionModel.fromJson(res);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Failed to generate yield prediction');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 7. Request Irrigation Advisory
  Future<bool> requestIrrigationAdvisory({
    String? farmId,
    required String soilType,
    required double soilPh,
    required double soilMoisture,
    required double organicCarbon,
    required double electricalConductivity,
    required double temperatureC,
    required double humidity,
    required double rainfallMm,
    required double sunlightHours,
    required double windSpeedKmh,
    required String cropType,
    required String cropGrowthStage,
    required String season,
    required String irrigationType,
    required String waterSource,
    required double fieldAreaHectare,
    String mulchingUsed = 'No',
    double previousIrrigationMm = 15.0,
    String region = 'South',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'farm_id': farmId,
        'soil_type': soilType,
        'soil_ph': soilPh,
        'soil_moisture': soilMoisture,
        'organic_carbon': organicCarbon,
        'electrical_conductivity': electricalConductivity,
        'temperature_c': temperatureC,
        'humidity': humidity,
        'rainfall_mm': rainfallMm,
        'sunlight_hours': sunlightHours,
        'wind_speed_kmh': windSpeedKmh,
        'crop_type': cropType,
        'crop_growth_stage': cropGrowthStage,
        'season': season,
        'irrigation_type': irrigationType,
        'water_source': waterSource,
        'field_area_hectare': fieldAreaHectare,
        'mulching_used': mulchingUsed,
        'previous_irrigation_mm': previousIrrigationMm,
        'region': region,
      };

      final res = await _api.post('/api/v1/irrigation/recommend', body: body);
      if (res is Map<String, dynamic>) {
        _irrigationAdvisory = IrrigationModel.fromJson(res);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Failed to compute irrigation advisory');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 8. Analyze Crop Disease Image
  Future<bool> analyzeDisease({
    String? farmId,
    String? crop,
    String plantPart = 'Leaves',
    String? symptoms,
    required String imageBase64,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'farm_id': farmId,
        'crop': crop,
        'plant_part': plantPart,
        'symptoms_observed': symptoms,
        'image_base64': imageBase64,
      };

      final res = await _api.post('/api/v1/disease/analyze', body: body);
      if (res is Map<String, dynamic>) {
        _latestDiseaseAnalysis = DiseaseAnalysisModel.fromJson(res);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Failed to analyze plant image');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 9. Fetch Market Mandi Prices
  Future<void> fetchMarketPrices({
    String? commodity,
    String? state,
    String? district,
    String? market,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final q = <String, String>{};
      if (commodity != null && commodity.isNotEmpty) q['commodity'] = commodity;
      if (state != null && state.isNotEmpty) q['state'] = state;
      if (district != null && district.isNotEmpty) q['district'] = district;
      if (market != null && market.isNotEmpty) q['market'] = market;

      final res = await _api.get('/api/v1/market/prices', queryParams: q);
      if (res is Map<String, dynamic> && res.containsKey('records')) {
        final records = res['records'] as List<dynamic>;
        _marketPrices = records.map((e) => MarketPriceRecordModel.fromJson(e)).toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 10. Estimate Profit and Scenarios
  Future<bool> estimateProfit({
    String? farmId,
    required String crop,
    required double areaHectares,
    required double predictedYieldPerHectare,
    required double marketPricePerQuintal,
    String marketName = 'Local Mandi',
    required Map<String, double> expenses,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final body = {
        'farm_id': farmId,
        'crop': crop,
        'area_hectares': areaHectares,
        'predicted_yield_per_hectare': predictedYieldPerHectare,
        'market_price_per_quintal': marketPricePerQuintal,
        'market_name': marketName,
        'expenses': expenses,
      };

      final res = await _api.post('/api/v1/profit/estimate', body: body);
      if (res is Map<String, dynamic>) {
        _profitEstimate = ProfitEstimationModel.fromJson(res);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Failed to compute profit estimate');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 11. Load Unified Decision Support
  Future<void> loadDecisionSupport(String farmId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/api/v1/farms/$farmId/decision-support');
      if (res is Map<String, dynamic>) {
        _decisionSupport = DecisionSupportModel.fromJson(res);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 12. Load Digital Diary Entries
  Future<void> loadDiary(String farmId) async {
    try {
      final res = await _api.get('/api/v1/farms/$farmId/diary');
      if (res is List) {
        _diaryEntries = List<Map<String, dynamic>>.from(res);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading diary: $e');
    }
  }

  // 13. Add Diary Entry
  Future<bool> addDiaryEntry(String farmId, Map<String, dynamic> entry) async {
    try {
      final res = await _api.post('/api/v1/farms/$farmId/diary', body: entry);
      if (res is Map<String, dynamic>) {
        _diaryEntries.insert(0, res);
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return false;
  }

  // 14. Chat with AI Assistant
  Future<String?> sendAssistantMessage(String message, {String? farmId, Map<String, dynamic>? farmContext}) async {
    _chatMessages.add({'role': 'user', 'content': message});
    notifyListeners();

    try {
      final history = _chatMessages.map((m) => {
        'role': m['role'] == 'user' ? 'user' : 'model',
        'content': m['content'] ?? '',
      }).toList();

      final body = {
        'message': message,
        'farm_id': farmId,
        'farm_context': farmContext,
        'conversation_history': history,
      };

      final res = await _api.post('/api/v1/assistant/chat', body: body);
      if (res is Map<String, dynamic> && res.containsKey('reply')) {
        final reply = res['reply'].toString();
        _chatMessages.add({'role': 'model', 'content': reply});
        notifyListeners();
        return reply;
      }
    } catch (e) {
      final errorMsg = 'Could not retrieve AI response: ${e.toString()}';
      _chatMessages.add({'role': 'model', 'content': errorMsg});
      notifyListeners();
      return errorMsg;
    }
    return null;
  }

  void clearChat() {
    _chatMessages.clear();
    notifyListeners();
  }
}
