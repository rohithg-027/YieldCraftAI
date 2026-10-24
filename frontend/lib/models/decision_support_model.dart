class DecisionSupportModel {
  final String farmId;
  final String farmName;
  final String location;
  final String? activeCrop;
  final String latestSoilStatus;
  final String weatherSummary;
  final List<String> topRecommendedCrops;
  final String? fertilizerRecommendation;
  final String? irrigationNeed;
  final String? recentDiseaseCheck;
  final String? marketPriceHighlight;
  final String? yieldEstimateHighlight;
  final String? profitEstimateHighlight;
  final List<String> keyActionItems;
  final List<String> missingDataWarnings;
  final String generatedAt;

  DecisionSupportModel({
    required this.farmId,
    required this.farmName,
    required this.location,
    this.activeCrop,
    required this.latestSoilStatus,
    required this.weatherSummary,
    required this.topRecommendedCrops,
    this.fertilizerRecommendation,
    this.irrigationNeed,
    this.recentDiseaseCheck,
    this.marketPriceHighlight,
    this.yieldEstimateHighlight,
    this.profitEstimateHighlight,
    required this.keyActionItems,
    required this.missingDataWarnings,
    required this.generatedAt,
  });

  factory DecisionSupportModel.fromJson(Map<String, dynamic> json) {
    return DecisionSupportModel(
      farmId: json['farm_id'] ?? '',
      farmName: json['farm_name'] ?? '',
      location: json['location'] ?? '',
      activeCrop: json['active_crop'],
      latestSoilStatus: json['latest_soil_status'] ?? '',
      weatherSummary: json['weather_summary'] ?? '',
      topRecommendedCrops: List<String>.from(json['top_recommended_crops'] ?? []),
      fertilizerRecommendation: json['fertilizer_recommendation'],
      irrigationNeed: json['irrigation_need'],
      recentDiseaseCheck: json['recent_disease_check'],
      marketPriceHighlight: json['market_price_highlight'],
      yieldEstimateHighlight: json['yield_estimate_highlight'],
      profitEstimateHighlight: json['profit_estimate_highlight'],
      keyActionItems: List<String>.from(json['key_action_items'] ?? []),
      missingDataWarnings: List<String>.from(json['missing_data_warnings'] ?? []),
      generatedAt: json['generated_at'] ?? '',
    );
  }
}
