class YieldHarvestRangeModel {
  final double conservativeYield;
  final double expectedYield;
  final double optimisticYield;
  final double conservativeTotal;
  final double expectedTotal;
  final double optimisticTotal;

  YieldHarvestRangeModel({
    required this.conservativeYield,
    required this.expectedYield,
    required this.optimisticYield,
    required this.conservativeTotal,
    required this.expectedTotal,
    required this.optimisticTotal,
  });

  factory YieldHarvestRangeModel.fromJson(Map<String, dynamic> json) {
    return YieldHarvestRangeModel(
      conservativeYield: (json['conservative_yield'] as num?)?.toDouble() ?? 0.0,
      expectedYield: (json['expected_yield'] as num?)?.toDouble() ?? 0.0,
      optimisticYield: (json['optimistic_yield'] as num?)?.toDouble() ?? 0.0,
      conservativeTotal: (json['conservative_total'] as num?)?.toDouble() ?? 0.0,
      expectedTotal: (json['expected_total'] as num?)?.toDouble() ?? 0.0,
      optimisticTotal: (json['optimistic_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class YieldBenchmarkModel {
  final double stateAverageYield;
  final double nationalAverageYield;
  final double performanceVsStatePct;
  final String status;

  YieldBenchmarkModel({
    required this.stateAverageYield,
    required this.nationalAverageYield,
    required this.performanceVsStatePct,
    required this.status,
  });

  factory YieldBenchmarkModel.fromJson(Map<String, dynamic> json) {
    return YieldBenchmarkModel(
      stateAverageYield: (json['state_average_yield'] as num?)?.toDouble() ?? 0.0,
      nationalAverageYield: (json['national_average_yield'] as num?)?.toDouble() ?? 0.0,
      performanceVsStatePct: (json['performance_vs_state_pct'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Benchmark Available',
    );
  }
}

class YieldRevenueModel {
  final double modalPricePerQuintal;
  final String marketName;
  final double estimatedGrossRevenue;
  final double conservativeRevenue;
  final double optimisticRevenue;

  YieldRevenueModel({
    required this.modalPricePerQuintal,
    required this.marketName,
    required this.estimatedGrossRevenue,
    required this.conservativeRevenue,
    required this.optimisticRevenue,
  });

  factory YieldRevenueModel.fromJson(Map<String, dynamic> json) {
    return YieldRevenueModel(
      modalPricePerQuintal: (json['modal_price_per_quintal'] as num?)?.toDouble() ?? 0.0,
      marketName: json['market_name'] ?? 'Mandi APMC',
      estimatedGrossRevenue: (json['estimated_gross_revenue'] as num?)?.toDouble() ?? 0.0,
      conservativeRevenue: (json['conservative_revenue'] as num?)?.toDouble() ?? 0.0,
      optimisticRevenue: (json['optimistic_revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class YieldFactorImpactModel {
  final String factor;
  final String impactPct;
  final String status;
  final String description;

  YieldFactorImpactModel({
    required this.factor,
    required this.impactPct,
    required this.status,
    required this.description,
  });

  factory YieldFactorImpactModel.fromJson(Map<String, dynamic> json) {
    return YieldFactorImpactModel(
      factor: json['factor'] ?? '',
      impactPct: json['impact_pct'] ?? '',
      status: json['status'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class YieldPredictionModel {
  final String crop;
  final double predictedYieldPerHectare;
  final String yieldUnit;
  final double totalAreaHectares;
  final double totalEstimatedProduction;
  final String productionUnit;
  final String modelAlgorithm;
  final YieldHarvestRangeModel? harvestRange;
  final YieldBenchmarkModel? benchmark;
  final YieldRevenueModel? revenueProjection;
  final List<YieldFactorImpactModel> factorImpacts;
  final List<String> optimizations;
  final Map<String, dynamic> inputSummary;
  final String limitations;
  final String timestamp;

  YieldPredictionModel({
    required this.crop,
    required this.predictedYieldPerHectare,
    required this.yieldUnit,
    required this.totalAreaHectares,
    required this.totalEstimatedProduction,
    required this.productionUnit,
    required this.modelAlgorithm,
    this.harvestRange,
    this.benchmark,
    this.revenueProjection,
    this.factorImpacts = const [],
    this.optimizations = const [],
    required this.inputSummary,
    required this.limitations,
    required this.timestamp,
  });

  factory YieldPredictionModel.fromJson(Map<String, dynamic> json) {
    List<YieldFactorImpactModel> factors = [];
    if (json['factor_impacts'] is List) {
      factors = (json['factor_impacts'] as List)
          .map((e) => YieldFactorImpactModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<String> optList = [];
    if (json['optimizations'] is List) {
      optList = (json['optimizations'] as List).map((e) => e.toString()).toList();
    }

    return YieldPredictionModel(
      crop: json['crop'] ?? '',
      predictedYieldPerHectare: (json['predicted_yield_per_hectare'] as num?)?.toDouble() ?? 0.0,
      yieldUnit: json['yield_unit'] ?? 'Quintals/Hectare',
      totalAreaHectares: (json['total_area_hectares'] as num?)?.toDouble() ?? 1.0,
      totalEstimatedProduction: (json['total_estimated_production'] as num?)?.toDouble() ?? 0.0,
      productionUnit: json['production_unit'] ?? 'Quintals',
      modelAlgorithm: json['model_algorithm'] ?? '',
      harvestRange: json['harvest_range'] != null
          ? YieldHarvestRangeModel.fromJson(json['harvest_range'])
          : null,
      benchmark: json['benchmark'] != null
          ? YieldBenchmarkModel.fromJson(json['benchmark'])
          : null,
      revenueProjection: json['revenue_projection'] != null
          ? YieldRevenueModel.fromJson(json['revenue_projection'])
          : null,
      factorImpacts: factors,
      optimizations: optList,
      inputSummary: json['input_summary'] ?? {},
      limitations: json['limitations'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }
}
