class SoilProfileModel {
  final String profileId;
  final String farmId;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ph;
  final double? moisture;
  final double? soilTemperature;
  final double? electricalConductivity;
  final double? organicCarbon;
  final String soilType;
  final String? testDate;
  final String? labName;
  final String source;
  final String createdAt;

  SoilProfileModel({
    required this.profileId,
    required this.farmId,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    this.moisture,
    this.soilTemperature,
    this.electricalConductivity,
    this.organicCarbon,
    required this.soilType,
    this.testDate,
    this.labName,
    required this.source,
    required this.createdAt,
  });

  factory SoilProfileModel.fromJson(Map<String, dynamic> json) {
    return SoilProfileModel(
      profileId: json['profile_id'] ?? '',
      farmId: json['farm_id'] ?? '',
      nitrogen: (json['nitrogen'] as num?)?.toDouble() ?? 0.0,
      phosphorus: (json['phosphorus'] as num?)?.toDouble() ?? 0.0,
      potassium: (json['potassium'] as num?)?.toDouble() ?? 0.0,
      ph: (json['ph'] as num?)?.toDouble() ?? 7.0,
      moisture: (json['moisture'] as num?)?.toDouble(),
      soilTemperature: (json['soil_temperature'] as num?)?.toDouble(),
      electricalConductivity: (json['electrical_conductivity'] as num?)?.toDouble(),
      organicCarbon: (json['organic_carbon'] as num?)?.toDouble(),
      soilType: json['soil_type'] ?? 'Loamy',
      testDate: json['test_date'],
      labName: json['lab_name'],
      source: json['source'] ?? 'Manual Lab Entry',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nitrogen': nitrogen,
    'phosphorus': phosphorus,
    'potassium': potassium,
    'ph': ph,
    'moisture': moisture,
    'soil_temperature': soilTemperature,
    'electrical_conductivity': electricalConductivity,
    'organic_carbon': organicCarbon,
    'soil_type': soilType,
    'test_date': testDate,
    'lab_name': labName,
    'source': source,
  };
}
