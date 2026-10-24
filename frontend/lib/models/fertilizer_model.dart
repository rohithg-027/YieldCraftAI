class FertilizerRecommendationModel {
  final String fertilizerName;
  final double? confidence;
  final String cropType;
  final String growthStage;
  final Map<String, dynamic> soilContext;
  final String applicationGuidance;
  final String safetyCautions;
  final String modelVersion;
  final String timestamp;

  FertilizerRecommendationModel({
    required this.fertilizerName,
    this.confidence,
    required this.cropType,
    required this.growthStage,
    required this.soilContext,
    required this.applicationGuidance,
    required this.safetyCautions,
    required this.modelVersion,
    required this.timestamp,
  });

  factory FertilizerRecommendationModel.fromJson(Map<String, dynamic> json) {
    return FertilizerRecommendationModel(
      fertilizerName: json['fertilizer_name'] ?? 'Urea',
      confidence: (json['confidence'] as num?)?.toDouble(),
      cropType: json['crop_type'] ?? '',
      growthStage: json['growth_stage'] ?? '',
      soilContext: json['soil_context'] ?? {},
      applicationGuidance: json['application_guidance'] ?? '',
      safetyCautions: json['safety_cautions'] ?? '',
      modelVersion: json['model_version'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
