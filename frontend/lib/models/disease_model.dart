class DiseaseAnalysisModel {
  final String cropIdentified;
  final String conditionDetected;
  final bool isHealthy;
  final String confidenceLevel;
  final List<String> visibleSymptoms;
  final List<String> possibleCauses;
  final List<String> treatmentPlan;
  final List<String> preventionMeasures;
  final String severity;
  final String expertAdvice;
  final String modelProvider;
  final String analysisDate;

  DiseaseAnalysisModel({
    required this.cropIdentified,
    required this.conditionDetected,
    required this.isHealthy,
    required this.confidenceLevel,
    required this.visibleSymptoms,
    required this.possibleCauses,
    required this.treatmentPlan,
    required this.preventionMeasures,
    required this.severity,
    required this.expertAdvice,
    required this.modelProvider,
    required this.analysisDate,
  });

  factory DiseaseAnalysisModel.fromJson(Map<String, dynamic> json) {
    return DiseaseAnalysisModel(
      cropIdentified: json['crop_identified'] ?? 'Crop',
      conditionDetected: json['condition_detected'] ?? 'Condition',
      isHealthy: json['is_healthy'] ?? false,
      confidenceLevel: json['confidence_level'] ?? 'Moderate',
      visibleSymptoms: List<String>.from(json['visible_symptoms'] ?? []),
      possibleCauses: List<String>.from(json['possible_causes'] ?? []),
      treatmentPlan: List<String>.from(json['treatment_plan'] ?? []),
      preventionMeasures: List<String>.from(json['prevention_measures'] ?? []),
      severity: json['severity'] ?? 'Moderate',
      expertAdvice: json['expert_advice'] ?? '',
      modelProvider: json['model_provider'] ?? '',
      analysisDate: json['analysis_date'] ?? '',
    );
  }
}
