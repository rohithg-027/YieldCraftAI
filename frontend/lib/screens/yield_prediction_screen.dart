import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/yield_prediction_model.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';

class YieldPredictionScreen extends StatefulWidget {
  final String? initialCrop;
  const YieldPredictionScreen({super.key, this.initialCrop});

  @override
  State<YieldPredictionScreen> createState() => _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends State<YieldPredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCrop = "Rice";
  String _selectedSeason = "Kharif";
  final _yearController = TextEditingController(text: "2024");
  final _areaController = TextEditingController(text: "2.5");
  final _rainfallController = TextEditingController(text: "950");
  final _fertController = TextEditingController(text: "140");
  final _pestController = TextEditingController(text: "20");
  String _areaUnit = "hectares";

  @override
  void initState() {
    super.initState();
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();
    final weather = workflow.weather;

    if (widget.initialCrop != null && widget.initialCrop!.isNotEmpty) {
      _selectedCrop = widget.initialCrop!;
    } else if (farm != null) {
      if (farm.activeCrop != null && AppConstants.supportedCrops.contains(farm.activeCrop)) {
        _selectedCrop = farm.activeCrop!;
      }
    }
    if (farm != null) {
      _areaController.text = farm.area.toString();
      _areaUnit = farm.areaUnit;
    }
    if (weather != null && weather.annualRainfallMm > 0) {
      _rainfallController.text = weather.annualRainfallMm.toStringAsFixed(0);
    }
  }


  @override
  void dispose() {
    _yearController.dispose();
    _areaController.dispose();
    _rainfallController.dispose();
    _fertController.dispose();
    _pestController.dispose();
    super.dispose();
  }

  Future<void> _runYieldPrediction() async {
    if (!_formKey.currentState!.validate()) return;
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();

    await workflow.predictYield(
      farmId: farm?.farmId,
      crop: _selectedCrop,
      cropYear: int.tryParse(_yearController.text) ?? 2024,
      season: _selectedSeason,
      state: farm?.state ?? "Karnataka",
      area: double.tryParse(_areaController.text) ?? 2.5,
      areaUnit: _areaUnit,
      annualRainfall: double.tryParse(_rainfallController.text) ?? 950.0,
      fertilizer: double.tryParse(_fertController.text) ?? 140.0,
      pesticide: double.tryParse(_pestController.text) ?? 20.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();
    final farmProvider = context.watch<FarmProvider>();
    final farm = farmProvider.activeFarm;
    final pred = workflow.yieldPrediction;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Crop Yield & Harvest Forecast"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const GradientHeader(
              title: "AI Harvest Yield Intelligence",
              subtitle: "Statistical Random Forest Regressor calibrated on agroclimatic soil & climate vectors",
              icon: Icons.trending_up,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Result Display Sections if predicted
                    if (pred != null) ...[
                      _buildHeroYieldCard(pred, farm),
                      const SizedBox(height: 16),
                      if (pred.harvestRange != null) ...[
                        _buildHarvestScenariosCard(pred.harvestRange!, pred.yieldUnit, pred.productionUnit),
                        const SizedBox(height: 16),
                      ],
                      if (pred.benchmark != null) ...[
                        _buildBenchmarkCard(pred.benchmark!, pred.predictedYieldPerHectare),
                        const SizedBox(height: 16),
                      ],
                      if (pred.revenueProjection != null) ...[
                        _buildRevenueProjectionCard(pred.revenueProjection!),
                        const SizedBox(height: 16),
                      ],
                      if (pred.factorImpacts.isNotEmpty) ...[
                        _buildFactorDriversCard(pred.factorImpacts),
                        const SizedBox(height: 16),
                      ],
                      if (pred.optimizations.isNotEmpty) ...[
                        _buildOptimizationsCard(pred.optimizations),
                        const SizedBox(height: 16),
                      ],
                    ],

                    // Recommended Crops Selector Section
                    if (workflow.cropCandidates.isNotEmpty) ...[
                      const SectionHeader(
                        title: "AI Recommended Crops",
                        subtitle: "Tap a candidate to run yield forecast & sync as active farm crop",
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 94,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: workflow.cropCandidates.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final c = workflow.cropCandidates[idx];
                            final isSelected = _selectedCrop.trim().toLowerCase() == c.cropName.trim().toLowerCase();
                            final isFarmActive = farm?.activeCrop?.trim().toLowerCase() == c.cropName.trim().toLowerCase();

                            return InkWell(
                              onTap: () async {
                                setState(() {
                                  _selectedCrop = c.cropName;
                                  if (c.season.isNotEmpty && AppConstants.seasons.contains(c.season)) {
                                    _selectedSeason = c.season;
                                  }
                                });
                                final farmProv = context.read<FarmProvider>();
                                final currentFarm = farmProv.activeFarm;
                                if (currentFarm != null && currentFarm.activeCrop?.trim().toLowerCase() != c.cropName.trim().toLowerCase()) {
                                  final messenger = ScaffoldMessenger.of(context);
                                  await farmProv.setActiveCrop(c.cropName);
                                  if (!mounted) return;
                                  messenger.hideCurrentSnackBar();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("${c.cropName} is now set as your active farm crop!"),
                                      duration: const Duration(seconds: 3),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppTheme.emerald,
                                    ),
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 164,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [AppTheme.primaryGreen, AppTheme.emerald],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.emerald : Colors.grey.shade300,
                                    width: isSelected ? 2.4 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppTheme.primaryGreen.withOpacity(0.35)
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: isSelected ? 12 : 4,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white.withOpacity(0.25) : AppTheme.sageLight,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "#${c.rank} Match",
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: isSelected ? Colors.white : AppTheme.primaryGreen,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle, color: Colors.white, size: 18)
                                        else if (isFarmActive)
                                          const Icon(Icons.star, color: AppTheme.earthAmber, size: 16)
                                        else
                                          Text(
                                            "${c.confidencePercentage.toStringAsFixed(0)}%",
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      c.cropName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? Colors.white : AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      c.season.isNotEmpty ? c.season : "Recommended",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isSelected ? Colors.white.withOpacity(0.85) : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    const SectionHeader(
                      title: "Agroclimatic & Input Parameters",
                      subtitle: "Configure farm area, annual precipitation, and fertigation inputs",
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCrop,
                            decoration: const InputDecoration(labelText: "Target Crop"),
                            items: AppConstants.supportedCrops
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedCrop = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedSeason,
                            decoration: const InputDecoration(labelText: "Season"),
                            items: AppConstants.seasons
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedSeason = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _areaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Cultivated Area",
                              suffixText: _areaUnit,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _rainfallController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Annual Rainfall",
                              suffixText: "mm",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _fertController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Fertilizer Dosage",
                              suffixText: "kg/ha",
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _pestController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Pesticide Usage",
                              suffixText: "kg/ha",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: workflow.isLoading ? null : _runYieldPrediction,
                      icon: const Icon(Icons.analytics_outlined),
                      label: Text(workflow.isLoading ? "Predicting with ML Model..." : "Forecast Crop Yield"),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Premium Hero Harvest Intelligence Card
  Widget _buildHeroYieldCard(YieldPredictionModel pred, dynamic farm) {
    final isFarmActive = farm?.activeCrop?.trim().toLowerCase() == pred.crop.trim().toLowerCase();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    pred.crop,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  if (isFarmActive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.mintAccent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.mintAccent.withOpacity(0.6)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check, color: AppTheme.mintAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            "ACTIVE CROP",
                            style: TextStyle(
                              color: AppTheme.mintAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_graph, color: AppTheme.mintAccent, size: 14),
                    SizedBox(width: 5),
                    Text(
                      "R² 0.9516 • 95.2% ACC",
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Expected Yield per Hectare",
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            pred.predictedYieldPerHectare.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Qtl / Ha",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 52,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Harvest (${pred.totalAreaHectares} Ha)",
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            pred.totalEstimatedProduction.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.earthAmber,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Quintals",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, color: AppTheme.mintAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Calibrated RandomForest pipeline • State ${pred.inputSummary['state'] ?? 'Karnataka'} Season: ${pred.inputSummary['season'] ?? 'Kharif'}",
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Three-Scenario Harvest Confidence Range Card
  Widget _buildHarvestScenariosCard(YieldHarvestRangeModel range, String yieldUnit, String prodUnit) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                "Harvest Production Range",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Confidence interval accounting for seasonal moisture variability and pest pressure",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Conservative
              Expanded(
                child: _buildScenarioTier(
                  title: "Conservative",
                  yieldVal: range.conservativeYield,
                  totalVal: range.conservativeTotal,
                  badge: "-15% Risk",
                  badgeColor: AppTheme.earthOrange,
                  bgColor: const Color(0xFFFFF7ED),
                ),
              ),
              const SizedBox(width: 10),
              // Expected
              Expanded(
                child: _buildScenarioTier(
                  title: "Target Yield",
                  yieldVal: range.expectedYield,
                  totalVal: range.expectedTotal,
                  badge: "Baseline",
                  badgeColor: AppTheme.emerald,
                  bgColor: AppTheme.sageLight.withOpacity(0.5),
                  isHighlight: true,
                ),
              ),
              const SizedBox(width: 10),
              // Optimistic
              Expanded(
                child: _buildScenarioTier(
                  title: "Optimistic",
                  yieldVal: range.optimisticYield,
                  totalVal: range.optimisticTotal,
                  badge: "+15% Peak",
                  badgeColor: AppTheme.primaryGreen,
                  bgColor: const Color(0xFFF0FDF4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioTier({
    required String title,
    required double yieldVal,
    required double totalVal,
    required String badge,
    required Color badgeColor,
    required Color bgColor,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? AppTheme.emerald : Colors.transparent,
          width: isHighlight ? 1.8 : 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badge,
              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              "${yieldVal.toStringAsFixed(1)} Q/Ha",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isHighlight ? AppTheme.primaryGreen : AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${totalVal.toStringAsFixed(0)} Qtl",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isHighlight ? AppTheme.earthAmber : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Regional Benchmark Comparison Card
  Widget _buildBenchmarkCard(YieldBenchmarkModel bench, double myYield) {
    final isAbove = bench.performanceVsStatePct >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech, color: AppTheme.earthAmber, size: 22),
                  SizedBox(width: 8),
                  Text(
                    "State & Regional Benchmark",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAbove ? AppTheme.sageLight : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${isAbove ? '+' : ''}${bench.performanceVsStatePct.toStringAsFixed(1)}% vs State",
                  style: TextStyle(
                    color: isAbove ? AppTheme.primaryGreen : AppTheme.alertCoral,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildBenchmarkBar("Your Farm Yield", myYield, myYield, AppTheme.emerald),
          const SizedBox(height: 10),
          _buildBenchmarkBar("State Average", bench.stateAverageYield, myYield, const Color(0xFF64748B)),
          const SizedBox(height: 10),
          _buildBenchmarkBar("National Median", bench.nationalAverageYield, myYield, const Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildBenchmarkBar(String label, double value, double maxValue, Color color) {
    final maxRatio = maxValue > 0 ? (value / (maxValue * 1.15)).clamp(0.05, 1.0) : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
            Text("${value.toStringAsFixed(1)} Qtl/Ha", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: maxRatio,
            minHeight: 8,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // 4. Financial Market Value & Revenue Projection Card
  Widget _buildRevenueProjectionCard(YieldRevenueModel rev) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF264653), Color(0xFF2A9D8F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF264653).withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.currency_rupee, color: AppTheme.mintAccent, size: 22),
                  SizedBox(width: 6),
                  Text(
                    "Gross Harvest Market Value",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rev.marketName,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Modal Market Price", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                    Text(
                      "₹${rev.modalPricePerQuintal.toStringAsFixed(0)} / Qtl",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Expected Gross Revenue", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "₹${rev.estimatedGrossRevenue.toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.earthAmber),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Revenue Range: ₹${rev.conservativeRevenue.toStringAsFixed(0)} — ₹${rev.optimisticRevenue.toStringAsFixed(0)}",
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.mintAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () => Navigator.pushNamed(context, '/profit'),
                icon: const Icon(Icons.arrow_forward, size: 14),
                label: const Text("Net Profit →", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Key Yield Drivers & Factor Impacts Card
  Widget _buildFactorDriversCard(List<YieldFactorImpactModel> factors) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dashboard_customize_outlined, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: 8),
              Text(
                "Model Factor Drivers & Impact",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Feature importance contribution toward realizing this harvest forecast",
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 14),
          ...factors.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.sageLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(f.factor, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark)),
                              Text(f.impactPct, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.emerald, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(f.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // 6. Actionable Agronomic Yield Maximization Checklist
  Widget _buildOptimizationsCard(List<String> optimizations) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FEE7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBEF264)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.energy_savings_leaf, color: Color(0xFF4D7C0F), size: 22),
              SizedBox(width: 8),
              Text(
                "Yield Maximization Directives",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF365314)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Agronomic field interventions to elevate your harvest toward the peak optimistic tier",
            style: TextStyle(fontSize: 12, color: Color(0xFF4D7C0F)),
          ),
          const SizedBox(height: 12),
          ...optimizations.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, color: Color(0xFF65A30D), size: 20),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF365314), height: 1.35, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
