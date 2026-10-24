import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/soil_probe_wizard_dialog.dart';

class IrrigationScreen extends StatefulWidget {
  const IrrigationScreen({super.key});

  @override
  State<IrrigationScreen> createState() => _IrrigationScreenState();
}

class _IrrigationScreenState extends State<IrrigationScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCrop = "Rice";
  String _selectedStage = "Vegetative";
  String _irrigationType = "Drip";
  String _waterSource = "Borewell";
  String _mulching = "No";
  bool _autoSaveToDiary = true;

  final _moistureController = TextEditingController(text: "48");
  final _phController = TextEditingController(text: "6.6");
  final _tempController = TextEditingController(text: "26.4");
  final _humidityController = TextEditingController(text: "65");
  final _rainfallController = TextEditingController(text: "10");
  final _windController = TextEditingController(text: "12");

  @override
  void initState() {
    super.initState();
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();
    final soil = workflow.latestSoilProfile;
    final weather = workflow.weather;

    if (farm?.activeCrop != null && AppConstants.supportedCrops.contains(farm!.activeCrop)) {
      _selectedCrop = farm.activeCrop!;
    }
    if (farm?.irrigationSource != null) {
      _waterSource = farm!.irrigationSource!;
    }
    if (soil != null) {
      if (soil.moisture != null) _moistureController.text = soil.moisture!.toStringAsFixed(0);
      if (soil.soilTemperature != null) {
        _tempController.text = soil.soilTemperature!.toStringAsFixed(1);
      } else if (weather != null) {
        _tempController.text = weather.temperatureC.toStringAsFixed(1);
      }
      if (soil.ph != 0) _phController.text = soil.ph.toStringAsFixed(1);
    } else {
      final baselines = AppConstants.getBaselineReadingsForSoil(farm?.soilType ?? 'Loamy');
      _moistureController.text = (baselines['moisture'] as double).toStringAsFixed(0);
      _tempController.text = weather != null ? weather.temperatureC.toStringAsFixed(1) : (baselines['temperature'] as double).toStringAsFixed(1);
      _phController.text = (baselines['ph'] as double).toStringAsFixed(1);
    }
    if (weather != null) {
      _humidityController.text = weather.relativeHumidityPct.toStringAsFixed(0);
      _windController.text = weather.windSpeedKmh.toStringAsFixed(0);
      _rainfallController.text = weather.annualRainfallMm.toStringAsFixed(0);
    }
  }

  void _syncFromSoilTest() {
    final workflow = context.read<FarmingWorkflowProvider>();
    final soil = workflow.latestSoilProfile;
    if (soil != null) {
      setState(() {
        if (soil.moisture != null) _moistureController.text = soil.moisture!.toStringAsFixed(0);
        if (soil.soilTemperature != null) _tempController.text = soil.soilTemperature!.toStringAsFixed(1);
        if (soil.ph != 0) _phController.text = soil.ph.toStringAsFixed(1);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Synced moisture (${_moistureController.text}%) & temp (${_tempController.text}°C) from Soil Test!"),
          backgroundColor: AppTheme.emerald,
        ),
      );
    } else {
      showSoilProbeWizardDialog(context, onComplete: (results) {
        setState(() {
          _moistureController.text = results['moisture'].toString();
          _tempController.text = results['soil_temperature'].toString();
          _phController.text = results['ph'].toString();
        });
      });
    }
  }

  @override
  void dispose() {
    _moistureController.dispose();
    _phController.dispose();
    _tempController.dispose();
    _humidityController.dispose();
    _rainfallController.dispose();
    _windController.dispose();
    super.dispose();
  }

  Future<void> _submitIrrigation() async {
    if (!_formKey.currentState!.validate()) return;
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();
    final soil = workflow.latestSoilProfile;
    final weather = workflow.weather;

    final soilType = farm?.soilType ?? "Loamy";
    final n = soil?.nitrogen ?? 80.0;
    final p = soil?.phosphorus ?? 40.0;
    final k = soil?.potassium ?? 140.0;
    final dynamicOc = AppConstants.calculateOrganicCarbon(n, soilType);
    final dynamicEc = AppConstants.calculateElectricalConductivity(n, p, k);
    final annualRain = weather != null && weather.annualRainfallMm > 0 ? weather.annualRainfallMm : 1150.0;

    final ok = await workflow.requestIrrigationAdvisory(
      farmId: farm?.farmId,
      soilType: soilType,
      soilPh: double.tryParse(_phController.text) ?? 6.6,
      soilMoisture: double.tryParse(_moistureController.text) ?? 38.0,
      organicCarbon: dynamicOc,
      electricalConductivity: dynamicEc,
      temperatureC: double.tryParse(_tempController.text) ?? 26.0,
      humidity: double.tryParse(_humidityController.text) ?? 65.0,
      rainfallMm: annualRain,
      sunlightHours: 7.5,
      windSpeedKmh: double.tryParse(_windController.text) ?? 12.0,
      cropType: _selectedCrop,
      cropGrowthStage: _selectedStage,
      season: "Kharif",
      irrigationType: _irrigationType,
      waterSource: _waterSource,
      fieldAreaHectare: farm?.area ?? 1.0,
      mulchingUsed: _mulching,
      previousIrrigationMm: 50.0,
      region: "South",
    );


    if (ok && _autoSaveToDiary && farm != null && workflow.irrigationAdvisory != null) {
      final adv = workflow.irrigationAdvisory!;
      await workflow.addDiaryEntry(farm.farmId, {
        'category': 'irrigation_log',
        'title': '${adv.irrigationNeed} Irrigation Plan for $_selectedCrop',
        'notes': 'Method: $_irrigationType\nAction: ${adv.recommendedAction}\nTip: ${adv.waterConservationTip}',
        'crop': _selectedCrop,
        'cost': 0.0,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Irrigation plan auto-recorded in Farm Diary!"),
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

  Color _getNeedColor(String need) {
    switch (need.toLowerCase()) {
      case 'high':
        return AppTheme.alertCoral;
      case 'medium':
        return AppTheme.earthOrange;
      default:
        return AppTheme.emerald;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();
    final advisory = workflow.irrigationAdvisory;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Daily Irrigation Advisory"),
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
              title: "Smart Water Management",
              subtitle: "ML root-zone hydration assessment based on soil moisture and weather",
              icon: Icons.water_drop,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (advisory != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getNeedColor(advisory.irrigationNeed).withOpacity(0.4),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _getNeedColor(advisory.irrigationNeed).withOpacity(0.08),
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
                                        color: _getNeedColor(advisory.irrigationNeed).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.opacity, color: _getNeedColor(advisory.irrigationNeed)),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Assessed Need",
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                        Text(
                                          "${advisory.irrigationNeed} Requirement",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: _getNeedColor(advisory.irrigationNeed),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "Moisture: ${advisory.soilMoisture.toInt()}%",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            const Text(
                              "Field Action",
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              advisory.recommendedAction,
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.sageLight.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.eco_outlined, color: AppTheme.emerald, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    advisory.waterConservationTip,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.3),
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
                                          'category': 'irrigation_log',
                                          'title': '${advisory.irrigationNeed} Irrigation Action Logged',
                                          'notes': 'Method: $_irrigationType\nAction: ${advisory.recommendedAction}\nTip: ${advisory.waterConservationTip}',
                                          'crop': _selectedCrop,
                                          'cost': 0.0,
                                        });
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(success ? "Irrigation plan logged to your Farm Diary!" : "Failed to log entry"),
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

                    // Soil Test & Probes Telemetry Ingestion Banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.emerald.withOpacity(0.35), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.emerald.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.sageLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.water_drop, color: AppTheme.emerald, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Telemetry from Soil Test",
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                                ),
                                Text(
                                  "Moisture: ${_moistureController.text}% • Soil Temp: ${_tempController.text}°C",
                                  style: const TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.emerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _syncFromSoilTest,
                            icon: const Icon(Icons.sync, size: 14),
                            label: const Text("Sync Test", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    const SectionHeader(
                      title: "Soil & Microclimate Inputs",
                      subtitle: "Auto-synced with local weather and soil sensors",
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

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _irrigationType,
                            decoration: const InputDecoration(labelText: "Irrigation Method"),
                            items: const [
                              DropdownMenuItem(value: "Drip", child: Text("Drip Irrigation")),
                              DropdownMenuItem(value: "Sprinkler", child: Text("Sprinkler")),
                              DropdownMenuItem(value: "Flood", child: Text("Flood / Basin")),
                              DropdownMenuItem(value: "Furrow", child: Text("Furrow")),
                            ],
                            onChanged: (val) => setState(() => _irrigationType = val!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _mulching,
                            decoration: const InputDecoration(labelText: "Mulching Used"),
                            items: const [
                              DropdownMenuItem(value: "No", child: Text("No")),
                              DropdownMenuItem(value: "Yes", child: Text("Yes")),
                            ],
                            onChanged: (val) => setState(() => _mulching = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _moistureController, decoration: const InputDecoration(labelText: "Soil Moisture (%)"))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _tempController, decoration: const InputDecoration(labelText: "Temp (°C)"))),
                        const SizedBox(width: 8),
                        Expanded(child: TextFormField(controller: _humidityController, decoration: const InputDecoration(labelText: "Humidity (%)"))),
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
                          "Saves irrigation recommendations to your digital diary automatically",
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        value: _autoSaveToDiary,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (val) => setState(() => _autoSaveToDiary = val),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton.icon(
                      onPressed: workflow.isLoading ? null : _submitIrrigation,
                      icon: const Icon(Icons.water_drop_outlined),
                      label: Text(workflow.isLoading ? "Analyzing..." : "Generate Irrigation Advisory"),
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
