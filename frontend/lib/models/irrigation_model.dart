class IrrigationModel {
  final String irrigationNeed;
  final Map<String, double> probabilities;
  final double soilMoisture;
  final double rainfallContext;
  final String recommendedAction;
  final String waterConservationTip;
  final String modelVersion;
  final String timestamp;

  IrrigationModel({
    required this.irrigationNeed,
    required this.probabilities,
    required this.soilMoisture,
    required this.rainfallContext,
    required this.recommendedAction,
    required this.waterConservationTip,
    required this.modelVersion,
    required this.timestamp,
  });

  factory IrrigationModel.fromJson(Map<String, dynamic> json) {
    final rawProbs = json['probabilities'] as Map<String, dynamic>? ?? {};
    final probs = <String, double>{};
    rawProbs.forEach((k, v) {
      probs[k] = (v as num).toDouble();
    });

    return IrrigationModel(
      irrigationNeed: json['irrigation_need'] ?? 'Medium',
      probabilities: probs,
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble() ?? 0.0,
      rainfallContext: (json['rainfall_context'] as num?)?.toDouble() ?? 0.0,
      recommendedAction: json['recommended_action'] ?? '',
      waterConservationTip: json['water_conservation_tip'] ?? '',
      modelVersion: json['model_version'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
