class CropGuidanceModel {
  final String? cropOverview;
  final String? whyRecommended;
  final String? soilSuitability;
  final String? climateSuitability;
  final String? sowingSeason;
  final String? cropDuration;
  final String? waterManagement;
  final String? nutrientManagement;
  final String? majorRisks;
  final String? harvestingConsiderations;
  final String? marketPotential;

  CropGuidanceModel({
    this.cropOverview,
    this.whyRecommended,
    this.soilSuitability,
    this.climateSuitability,
    this.sowingSeason,
    this.cropDuration,
    this.waterManagement,
    this.nutrientManagement,
    this.majorRisks,
    this.harvestingConsiderations,
    this.marketPotential,
  });

  factory CropGuidanceModel.fromJson(Map<String, dynamic> json) {
    return CropGuidanceModel(
      cropOverview: json['crop_overview'],
      whyRecommended: json['why_recommended'],
      soilSuitability: json['soil_suitability'],
      climateSuitability: json['climate_suitability'],
      sowingSeason: json['sowing_season'],
      cropDuration: json['crop_duration'],
      waterManagement: json['water_management'],
      nutrientManagement: json['nutrient_management'],
      majorRisks: json['major_risks'],
      harvestingConsiderations: json['harvesting_considerations'],
      marketPotential: json['market_potential'],
    );
  }
}

class CropCandidateModel {
  final int rank;
  final String cropName;
  final double probability;
  final double confidencePercentage;
  final String season;
  final String indicativeWaterNeed;
  final String suitabilitySummary;
  final CropGuidanceModel? guidance;

  CropCandidateModel({
    required this.rank,
    required this.cropName,
    required this.probability,
    required this.confidencePercentage,
    required this.season,
    required this.indicativeWaterNeed,
    required this.suitabilitySummary,
    this.guidance,
  });

  factory CropCandidateModel.fromJson(Map<String, dynamic> json) {
    return CropCandidateModel(
      rank: json['rank'] ?? 1,
      cropName: json['crop_name'] ?? 'Crop',
      probability: (json['probability'] as num?)?.toDouble() ?? 0.0,
      confidencePercentage: (json['confidence_percentage'] as num?)?.toDouble() ?? 0.0,
      season: json['season'] ?? 'Kharif',
      indicativeWaterNeed: json['indicative_water_need'] ?? 'Moderate',
      suitabilitySummary: json['suitability_summary'] ?? '',
      guidance: json['guidance'] != null ? CropGuidanceModel.fromJson(json['guidance']) : null,
    );
  }
}
