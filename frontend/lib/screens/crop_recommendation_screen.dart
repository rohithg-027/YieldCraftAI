import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/crop_candidate_model.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/loading_indicator.dart';
import 'yield_prediction_screen.dart';

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({super.key});

  @override
  State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();
  final _tempController = TextEditingController();
  final _humidityController = TextEditingController();
  final _phController = TextEditingController();
  final _rainfallController = TextEditingController();

  bool _initialized = false;
  String _currentSoilType = "Loamy";

  @override

  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final workflow = context.read<FarmingWorkflowProvider>();
      final farm = context.read<FarmProvider>().activeFarm;
      final soil = workflow.latestSoilProfile;
      final weather = workflow.weather;

      _currentSoilType = farm?.soilType ?? "Loamy";
      if (soil != null) {
        _nController.text = soil.nitrogen.toStringAsFixed(0);
        _pController.text = soil.phosphorus.toStringAsFixed(0);
        _kController.text = soil.potassium.toStringAsFixed(0);
        _phController.text = soil.ph.toStringAsFixed(1);
      } else {
        final baselines = AppConstants.getBaselineReadingsForSoil(_currentSoilType);
        _nController.text = (baselines['nitrogen'] as double).toStringAsFixed(0);
        _pController.text = (baselines['phosphorus'] as double).toStringAsFixed(0);
        _kController.text = (baselines['potassium'] as double).toStringAsFixed(0);
        _phController.text = (baselines['ph'] as double).toStringAsFixed(1);
      }

      _tempController.text = weather?.temperatureC.toStringAsFixed(1) ?? "25.0";
      _humidityController.text = weather?.relativeHumidityPct.toStringAsFixed(0) ?? "65";

      // Dynamically calculate growing period rainfall from Weather API annual rainfall
      if (weather != null && weather.annualRainfallMm > 0) {
        final seasonal = (weather.annualRainfallMm * 0.11).clamp(50.0, 160.0);
        _rainfallController.text = seasonal.toStringAsFixed(0);
      } else {
        _rainfallController.text = "95";
      }

      _initialized = true;
      if (workflow.cropCandidates.isEmpty) {
        _runRecommendation();
      }
    }
  }

  void _applySoilPreset(String soilType) {
    final baselines = AppConstants.getBaselineReadingsForSoil(soilType);
    setState(() {
      _currentSoilType = soilType;
      _nController.text = (baselines['nitrogen'] as double).toStringAsFixed(0);
      _pController.text = (baselines['phosphorus'] as double).toStringAsFixed(0);
      _kController.text = (baselines['potassium'] as double).toStringAsFixed(0);
      _phController.text = (baselines['ph'] as double).toStringAsFixed(1);
      _tempController.text = (baselines['temperature'] as double).toStringAsFixed(1);
    });
    _runRecommendation();
  }

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _rainfallController.dispose();
    super.dispose();
  }

  Future<void> _runRecommendation() async {
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();

    await workflow.runCropRecommendation(
      farmId: farm?.farmId,
      nitrogen: double.tryParse(_nController.text) ?? 85.0,
      phosphorus: double.tryParse(_pController.text) ?? 40.0,
      potassium: double.tryParse(_kController.text) ?? 45.0,
      temperature: double.tryParse(_tempController.text) ?? 25.0,
      humidity: double.tryParse(_humidityController.text) ?? 65.0,
      ph: double.tryParse(_phController.text) ?? 6.6,
      rainfall: double.tryParse(_rainfallController.text) ?? 95.0,
      topN: 5,
      enrichWithGemini: true,
    );
  }


  void _showCropGuidanceModal(CropCandidateModel candidate) {
    final g = candidate.guidance;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.eco, color: AppTheme.emerald),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.cropName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            "Model Match: ${candidate.confidencePercentage}%",
                            style: const TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: g != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGuidanceSection("Overview", g.cropOverview, Icons.info_outline),
                          _buildGuidanceSection("Why Recommended", g.whyRecommended, Icons.verified_outlined),
                          _buildGuidanceSection("Soil Suitability", g.soilSuitability, Icons.layers_outlined),
                          _buildGuidanceSection("Climate & Rainfall", g.climateSuitability, Icons.wb_sunny_outlined),
                          _buildGuidanceSection("Sowing Season", g.sowingSeason, Icons.calendar_today_outlined),
                          _buildGuidanceSection("Crop Duration", g.cropDuration, Icons.timelapse),
                          _buildGuidanceSection("Water Management", g.waterManagement, Icons.water_drop_outlined),
                          _buildGuidanceSection("Nutrient Management", g.nutrientManagement, Icons.science_outlined),
                          _buildGuidanceSection("Pest & Disease Risks", g.majorRisks, Icons.pest_control_outlined),
                          _buildGuidanceSection("Harvesting Tips", g.harvestingConsiderations, Icons.agriculture_outlined),
                          _buildGuidanceSection("Market Potential", g.marketPotential, Icons.monetization_on_outlined),
                        ],
                      )
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text("Detailed agronomic guide will load with active connection."),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceSection(String title, String? content, IconData icon) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.emerald),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Intelligent Crop Recommendation"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const GradientHeader(
              title: "AI-Powered Crop Suitability",
              subtitle: "Top-5 candidates ranked by CatBoost multi-class probability",
              icon: Icons.psychology,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ExpansionTile(
                title: const Text(
                  "Review Soil & Weather Inputs",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  "Auto-filled from confirmed soil test & live local climate",
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Quick Soil Classification Presets:",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: AppConstants.soilTypes.map((st) {
                              final isSelected = st.toLowerCase() == _currentSoilType.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(st, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                  selected: isSelected,
                                  selectedColor: AppTheme.emerald,
                                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark),
                                  onSelected: (val) {
                                    if (val) _applySoilPreset(st);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _nController, decoration: const InputDecoration(labelText: "N (kg/ha)"))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _pController, decoration: const InputDecoration(labelText: "P (kg/ha)"))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _kController, decoration: const InputDecoration(labelText: "K (kg/ha)"))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextFormField(controller: _tempController, decoration: const InputDecoration(labelText: "Temp (°C)"))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _humidityController, decoration: const InputDecoration(labelText: "Humidity (%)"))),
                            const SizedBox(width: 8),
                            Expanded(child: TextFormField(controller: _rainfallController, decoration: const InputDecoration(labelText: "Rainfall (mm)"))),
                          ],
                        ),

                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: workflow.isLoading ? null : _runRecommendation,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text("Recalculate Candidates"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (workflow.isLoading)
              const AgriculturalLoadingIndicator(
                statusMessage: "Computing multi-class CatBoost probabilities & Gemini guidance...",
              )
            else if (workflow.cropCandidates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text("No recommendations available. Please recalculate.")),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: "Ranked Candidate Crops",
                      subtitle: "Tap any candidate for full agronomic guidance",
                    ),
                    ...workflow.cropCandidates.map((c) => _buildCandidateCard(c)),
                  ],
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(CropCandidateModel c) {
    final isTop = c.rank == 1;
    final farm = context.watch<FarmProvider>().activeFarm;
    final isSelectedActiveCrop = farm?.activeCrop?.trim().toLowerCase() == c.cropName.trim().toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelectedActiveCrop
              ? AppTheme.emerald
              : (isTop ? AppTheme.emerald : Colors.grey.shade200),
          width: isSelectedActiveCrop ? 2.5 : (isTop ? 2 : 1),
        ),
      ),
      elevation: isSelectedActiveCrop ? 3 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showCropGuidanceModal(c),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelectedActiveCrop
                          ? AppTheme.emerald
                          : (isTop ? AppTheme.emerald : Colors.grey.shade200),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isSelectedActiveCrop
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              "#${c.rank}",
                              style: TextStyle(
                                color: isTop ? Colors.white : AppTheme.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              c.cropName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            if (isSelectedActiveCrop) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.emerald,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "ACTIVE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          "${c.season} • Water: ${c.indicativeWaterNeed}",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${c.confidencePercentage.toStringAsFixed(1)}%",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isTop ? AppTheme.emerald : AppTheme.textDark,
                        ),
                      ),
                      const Text(
                        "Probability",
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Linear probability progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.probability,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSelectedActiveCrop
                        ? AppTheme.emerald
                        : (isTop ? AppTheme.emerald : AppTheme.mintAccent),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      c.suitabilitySummary,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        side: BorderSide(color: isTop ? AppTheme.emerald : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _showCropGuidanceModal(c),
                      icon: const Icon(Icons.info_outline, size: 15),
                      label: const Text("Agronomy Guide", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        backgroundColor: isTop ? AppTheme.primaryGreen : AppTheme.emerald,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => YieldPredictionScreen(initialCrop: c.cropName),
                          ),
                        );
                      },
                      icon: const Icon(Icons.trending_up, size: 15),
                      label: const Text("Forecast Yield →", style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: isSelectedActiveCrop
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.emerald.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: AppTheme.emerald, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Current Active Crop for this Farm",
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen, width: 1.4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(
                          "Set ${c.cropName} as Active Farm Crop",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        onPressed: () async {
                          final currentFarm = context.read<FarmProvider>().activeFarm;
                          if (currentFarm != null) {
                            final success = await context.read<FarmProvider>().setActiveCrop(c.cropName);
                            if (mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? "${c.cropName} is now set as your active crop! Updated across dashboard."
                                        : "Failed to update active crop",
                                  ),
                                  duration: const Duration(seconds: 3),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: success ? AppTheme.emerald : AppTheme.alertCoral,
                                ),
                              );
                            }
                          }
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
