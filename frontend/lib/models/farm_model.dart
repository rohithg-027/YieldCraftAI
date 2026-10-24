class FarmModel {
  final String farmId;
  final String ownerUid;
  final String farmName;
  final double latitude;
  final double longitude;
  final double? locationAccuracyMeters;
  final String? address;
  final String? village;
  final String? district;
  final String state;
  final String country;
  final double area;
  final String areaUnit;
  final String soilType;
  final String? irrigationSource;
  final String? activeCrop;
  final String createdAt;
  final String updatedAt;

  String get id => farmId;
  String get name => farmName;

  FarmModel({
    required this.farmId,
    required this.ownerUid,
    required this.farmName,
    required this.latitude,
    required this.longitude,
    this.locationAccuracyMeters,
    this.address,
    this.village,
    this.district,
    required this.state,
    this.country = 'India',
    required this.area,
    this.areaUnit = 'hectares',
    required this.soilType,
    this.irrigationSource,
    this.activeCrop,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      farmId: json['farm_id'] ?? '',
      ownerUid: json['owner_uid'] ?? '',
      farmName: json['farm_name'] ?? 'Unnamed Farm',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      locationAccuracyMeters: (json['location_accuracy_meters'] as num?)?.toDouble(),
      address: json['address'],
      village: json['village'],
      district: json['district'],
      state: json['state'] ?? 'Karnataka',
      country: json['country'] ?? 'India',
      area: (json['area'] as num?)?.toDouble() ?? 1.0,
      areaUnit: json['area_unit'] ?? 'hectares',
      soilType: json['soil_type'] ?? 'Loamy',
      irrigationSource: json['irrigation_source'],
      activeCrop: json['active_crop'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'farm_name': farmName,
    'latitude': latitude,
    'longitude': longitude,
    'location_accuracy_meters': locationAccuracyMeters,
    'address': address,
    'village': village,
    'district': district,
    'state': state,
    'country': country,
    'area': area,
    'area_unit': areaUnit,
    'soil_type': soilType,
    'irrigation_source': irrigationSource,
    'active_crop': activeCrop,
  };
}
