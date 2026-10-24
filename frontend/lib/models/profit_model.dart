class ScenarioDetailModel {
  final String scenarioName;
  final double assumedYieldPerHa;
  final double assumedPricePerQuintal;
  final double totalProductionQuintals;
  final double grossRevenue;
  final double totalExpenses;
  final double netProfit;
  final double profitMarginPct;
  final String description;

  ScenarioDetailModel({
    required this.scenarioName,
    required this.assumedYieldPerHa,
    required this.assumedPricePerQuintal,
    required this.totalProductionQuintals,
    required this.grossRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMarginPct,
    required this.description,
  });

  factory ScenarioDetailModel.fromJson(Map<String, dynamic> json) {
    return ScenarioDetailModel(
      scenarioName: json['scenario_name'] ?? '',
      assumedYieldPerHa: (json['assumed_yield_per_ha'] as num?)?.toDouble() ?? 0.0,
      assumedPricePerQuintal: (json['assumed_price_per_quintal'] as num?)?.toDouble() ?? 0.0,
      totalProductionQuintals: (json['total_production_quintals'] as num?)?.toDouble() ?? 0.0,
      grossRevenue: (json['gross_revenue'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      netProfit: (json['net_profit'] as num?)?.toDouble() ?? 0.0,
      profitMarginPct: (json['profit_margin_pct'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
    );
  }
}

class ProfitEstimationModel {
  final String crop;
  final double areaHectares;
  final double expectedProductionQuintals;
  final double marketPricePerQuintal;
  final String marketName;
  final double totalExpenses;
  final double baseGrossRevenue;
  final double baseNetProfit;
  final double profitMarginPercentage;
  final Map<String, ScenarioDetailModel> scenarios;
  final String disclaimer;
  final String calculatedAt;

  ProfitEstimationModel({
    required this.crop,
    required this.areaHectares,
    required this.expectedProductionQuintals,
    required this.marketPricePerQuintal,
    required this.marketName,
    required this.totalExpenses,
    required this.baseGrossRevenue,
    required this.baseNetProfit,
    required this.profitMarginPercentage,
    required this.scenarios,
    required this.disclaimer,
    required this.calculatedAt,
  });

  factory ProfitEstimationModel.fromJson(Map<String, dynamic> json) {
    final rawScenarios = json['scenarios'] as Map<String, dynamic>? ?? {};
    final sc = <String, ScenarioDetailModel>{};
    rawScenarios.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        sc[k] = ScenarioDetailModel.fromJson(v);
      }
    });

    return ProfitEstimationModel(
      crop: json['crop'] ?? '',
      areaHectares: (json['area_hectares'] as num?)?.toDouble() ?? 1.0,
      expectedProductionQuintals: (json['expected_production_quintals'] as num?)?.toDouble() ?? 0.0,
      marketPricePerQuintal: (json['market_price_per_quintal'] as num?)?.toDouble() ?? 0.0,
      marketName: json['market_name'] ?? 'Mandi',
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      baseGrossRevenue: (json['base_gross_revenue'] as num?)?.toDouble() ?? 0.0,
      baseNetProfit: (json['base_net_profit'] as num?)?.toDouble() ?? 0.0,
      profitMarginPercentage: (json['profit_margin_percentage'] as num?)?.toDouble() ?? 0.0,
      scenarios: sc,
      disclaimer: json['disclaimer'] ?? '',
      calculatedAt: json['calculated_at'] ?? '',
    );
  }
}
