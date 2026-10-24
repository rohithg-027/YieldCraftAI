import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/soil_probe_wizard_dialog.dart';

class FertilizerScreen extends StatefulWidget {
  const FertilizerScreen({super.key});

  @override
  State<FertilizerScreen> createState() => _FertilizerScreenState();
}

class _FertilizerScreenState extends State<FertilizerScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCrop = "Rice";
  String _selectedStage = "Vegetative";
  String _selectedSoil = "Loamy";
  bool _autoSaveToDiary = true;

  final _nController = TextEditingController(text: "88");
  final _pController = TextEditingController(text: "42");
  final _kController = TextEditingController(text: "44");
  final _phController = TextEditingController(text: "6.6");
  final _moistController = TextEditingController(text: "48");
  final _tempController = TextEditingController(text: "26.4");
  final _humController = TextEditingController(text: "70");
  final _rainController = TextEditingController(text: "150");

  @override
  void initState() {
    super.initState();
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();
    final soil = workflow.latestSoilProfile;
    final weather = workflow.weather;

    if (farm != null) {
      if (farm.activeCrop != null && AppConstants.supportedCrops.contains(farm.activeCrop)) {
        _selectedCrop = farm.activeCrop!;
      }
      _selectedSoil = farm.soilType;
    }
    if (soil != null) {
      _nController.text = soil.nitrogen.toStringAsFixed(0);
      _pController.text = soil.phosphorus.toStringAsFixed(0);
      _kController.text = soil.potassium.toStringAsFixed(0);
      _phController.text = soil.ph.toStringAsFixed(1);
      if (soil.moisture != null) _moistController.text = soil.moisture!.toStringAsFixed(0);
      if (soil.soilTemperature != null) {
        _tempController.text = soil.soilTemperature!.toStringAsFixed(0);
      } else if (weather != null) {
        _tempController.text = weather.temperatureC.toStringAsFixed(0);
      }
    } else {
      final baselines = AppConstants.getBaselineReadingsForSoil(_selectedSoil);
      _nController.text = (baselines['nitrogen'] as double).toStringAsFixed(0);
      _pController.text = (baselines['phosphorus'] as double).toStringAsFixed(0);
      _kController.text = (baselines['potassium'] as double).toStringAsFixed(0);
      _phController.text = (baselines['ph'] as double).toStringAsFixed(1);
      _moistController.text = (baselines['moisture'] as double).toStringAsFixed(0);
      _tempController.text = weather != null ? weather.temperatureC.toStringAsFixed(0) : (baselines['temperature'] as double).toStringAsFixed(0);
    }
    if (weather != null) {
      _humController.text = weather.relativeHumidityPct.toStringAsFixed(0);
    }

  }

  void _syncFromSoilTest() {
    final workflow = context.read<FarmingWorkflowProvider>();
    final soil = workflow.latestSoilProfile;
    if (soil != null) {
      setState(() {
        _nController.text = soil.nitrogen.toStringAsFixed(0);
        _pController.text = soil.phosphorus.toStringAsFixed(0);
        _kController.text = soil.potassium.toStringAsFixed(0);
        _phController.text = soil.ph.toStringAsFixed(1);
        if (soil.moisture != null) _moistController.text = soil.moisture!.toStringAsFixed(0);
        if (soil.soilTemperature != null) _tempController.text = soil.soilTemperature!.toStringAsFixed(0);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Synced NPK (${_nController.text}-${_pController.text}-${_kController.text}) & pH (${_phController.text}) from Soil Test!"),
          backgroundColor: AppTheme.emerald,
        ),
      );
    } else {
      showSoilProbeWizardDialog(context, onComplete: (results) {
        setState(() {
          _nController.text = results['nitrogen'].toString();
          _pController.text = results['phosphorus'].toString();
          _kController.text = results['potassium'].toString();
          _phController.text = results['ph'].toString();
          _moistController.text = results['moisture'].toString();
          _tempController.text = results['soil_temperature'].toString();
        });
      });
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    _humController.dispose();
    _rainController.dispose();
    _moistController.dispose();
    _phController.dispose();
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    super.dispose();
  }

  Future<void> _submitFertilizerReq() async {
    if (!_formKey.currentState!.validate()) return;
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();

    final ok = await workflow.runFertilizerRecommendation(
      farmId: farm?.farmId,
      temperature: double.tryParse(_tempController.text) ?? 28.0,
      humidity: double.tryParse(_humController.text) ?? 70.0,
      rainfall: double.tryParse(_rainController.text) ?? 150.0,
      moisture: double.tryParse(_moistController.text) ?? 45.0,
      soilType: _selectedSoil,
      soilPh: double.tryParse(_phController.text) ?? 6.5,
      nitrogen: double.tryParse(_nController.text) ?? 80.0,
      phosphorus: double.tryParse(_pController.text) ?? 40.0,
      potassium: double.tryParse(_kController.text) ?? 40.0,
      cropType: _selectedCrop,
      growthStage: _selectedStage,
    );

    if (ok && _autoSaveToDiary && farm != null && workflow.fertilizerRecommendation != null) {
      final fert = workflow.fertilizerRecommendation!;
      await workflow.addDiaryEntry(farm.farmId, {
        'category': 'fertilizer_application',
        'title': 'Recommended ${fert.fertilizerName} for $_selectedCrop',
        'notes': 'Stage: ${fert.growthStage}\nGuidance: ${fert.applicationGuidance}\nSafety: ${fert.safetyCautions}',
        'crop': _selectedCrop,
        'cost': 0.0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Fertilizer schedule auto-saved to Farm Diary!"),
            backgroundColor: AppTheme.emerald,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: "View Diary",
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.pushNamed(context, '/diary');
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();
    final fert = workflow.fertilizerRecommendation;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Nutrient & Fertilizer Plan"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.book_outlined),
            tooltip: "Farm Diary",
            onPressed: () => Navigator.pushNamed(context, '/diary'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const GradientHeader(
              title: "Scientific Fertilizer Scheduling",
              subtitle: "Optimal macronutrient balances matching growth stages",
              icon: Icons.eco,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (fert != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.emerald.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.emerald.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sageLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.check_circle, color: AppTheme.emerald),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Recommended Fertilizer",
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                        Text(
                                          fert.fertilizerName,
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.sageLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    fert.growthStage,
                                    style: const TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            const Text(
                              "Application Guidance",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fert.applicationGuidance,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.alertCoral.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.alertCoral.withOpacity(0.2)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: AppTheme.alertCoral, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      fert.safetyCautions,
                                      style: const TextStyle(
                                        color: AppTheme.textDark,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryGreen,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                                    label: const Text("Save to Diary", style: TextStyle(fontWeight: FontWeight.w700)),
                                    onPressed: () async {
                                      final farm = context.read<FarmProvider>().activeFarm;
                                      if (farm != null) {
                                        final success = await workflow.addDiaryEntry(farm.farmId, {
                                          'category': 'fertilizer_application',
                                          'title': 'Recommended ${fert.fertilizerName} Application',
                                          'notes': 'Stage: ${fert.growthStage}\nGuidance: ${fert.applicationGuidance}\nSafety: ${fert.safetyCautions}',
                                          'crop': _selectedCrop,
                                          'cost': 0.0,
                                        });
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success ? "Fertilizer recommendation logged to your Farm Diary!" : "Failed to log entry"),
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
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryGreen,
                                    side: const BorderSide(color: AppTheme.primaryGreen),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                                  ),
                                  icon: const Icon(Icons.book_outlined, size: 18),
                                  label: const Text("View Diary"),
                                  onPressed: () => Navigator.pushNamed(context, '/diary'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Soil Test Linked Telemetry Banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.sageLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.emerald.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.science, color: AppTheme.emerald, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Soil Test Linked Telemetry",
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                                ),
                                Text(
                                  "NPK: ${_nController.text}-${_pController.text}-${_kController.text} kg/ha • pH: ${_phController.text}",
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.emerald,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.sync, size: 16),
                            label: const Text("Sync Test", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            onPressed: _syncFromSoilTest,
                          ),
                        ],
                      ),
                    ),

                    const SectionHeader(
                      title: "Crop & Stage Parameters",
                      subtitle: "Target nutrients according to crop physiology",
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCrop,
                            decoration: const InputDecoration(labelText: "Crop"),
                            items: AppConstants.supportedCrops
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedCrop = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStage,
                            decoration: const InputDecoration(labelText: "Growth Stage"),
                            items: AppConstants.growthStages
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedStage = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedSoil,
                      decoration: const InputDecoration(labelText: "Soil Type"),
                      items: AppConstants.soilTypes
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _selectedSoil = val;
                          final baselines = AppConstants.getBaselineReadingsForSoil(val);
                          _nController.text = (baselines['nitrogen'] as double).toStringAsFixed(0);
                          _pController.text = (baselines['phosphorus'] as double).toStringAsFixed(0);
                          _kController.text = (baselines['potassium'] as double).toStringAsFixed(0);
                          _moistController.text = (baselines['moisture'] as double).toStringAsFixed(0);
                          _phController.text = (baselines['ph'] as double).toStringAsFixed(1);
                        });
                      },

                    ),
                    const SizedBox(height: 8),

                    // Dynamic pH Profile Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.sageLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.science_outlined, size: 16, color: AppTheme.emerald),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Dynamic pH Profile: ${AppConstants.getSoilPhDescription(_selectedSoil)}",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const SectionHeader(
                      title: "Soil Test Lab Values",
                      subtitle: "Macronutrient profile (Available N-P-K)",
                    ),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _nController, decoration: const InputDecoration(labelText: "N (kg/ha)"))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _pController, decoration: const InputDecoration(labelText: "P (kg/ha)"))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _kController, decoration: const InputDecoration(labelText: "K (kg/ha)"))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _phController, decoration: const InputDecoration(labelText: "Soil pH"))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _moistController, decoration: const InputDecoration(labelText: "Moisture (%)"))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _tempController, decoration: const InputDecoration(labelText: "Temp (°C)"))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Auto-record to diary switch
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        title: const Text(
                          "Auto-maintain in Digital Farm Diary",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text(
                          "Saves fertilizer schedules to your digital diary automatically",
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        value: _autoSaveToDiary,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (val) => setState(() => _autoSaveToDiary = val),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: workflow.isLoading ? null : _submitFertilizerReq,
                      icon: const Icon(Icons.recommend_outlined),
                      label: Text(workflow.isLoading ? "Computing..." : "Generate Fertilizer Schedule"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
