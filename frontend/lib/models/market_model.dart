class MarketPriceRecordModel {
  final String state;
  final String district;
  final String market;
  final String commodity;
  final String variety;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String priceUnit;
  final String source;
  final String retrievedAt;

  MarketPriceRecordModel({
    required this.state,
    required this.district,
    required this.market,
    required this.commodity,
    required this.variety,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.priceUnit,
    required this.source,
    required this.retrievedAt,
  });

  factory MarketPriceRecordModel.fromJson(Map<String, dynamic> json) {
    return MarketPriceRecordModel(
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      market: json['market'] ?? '',
      commodity: json['commodity'] ?? '',
      variety: json['variety'] ?? 'Standard',
      arrivalDate: json['arrival_date'] ?? '',
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 0.0,
      priceUnit: json['price_unit'] ?? 'Rs/Quintal',
      source: json['source'] ?? '',
      retrievedAt: json['retrieved_at'] ?? '',
    );
  }
}
