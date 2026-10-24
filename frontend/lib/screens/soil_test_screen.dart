import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/soil_probe_wizard_dialog.dart';

class SoilTestScreen extends StatefulWidget {
  const SoilTestScreen({super.key});

  @override
  State<SoilTestScreen> createState() => _SoilTestScreenState();
}

class _SoilTestScreenState extends State<SoilTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nController = TextEditingController(text: "88");
  final _pController = TextEditingController(text: "42");
  final _kController = TextEditingController(text: "44");
  final _phController = TextEditingController(text: "6.6");
  final _moistureController = TextEditingController(text: "48");
  final _tempController = TextEditingController(text: "26.4");
  final _ecController = TextEditingController(text: "1.1");
  final _ocController = TextEditingController(text: "0.58");
  final _labController = TextEditingController(text: "YieldCraft ESP32 Sensor Pod #01");

  String _selectedSoil = "Loamy";
  String _entrySource = "ESP32 IoT Probes";
  bool _showManualEcOc = false;

  @override
  void initState() {
    super.initState();
    _nController.addListener(_updateEcAndOc);
    _pController.addListener(_updateEcAndOc);
    _kController.addListener(_updateEcAndOc);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farm = context.read<FarmProvider>().activeFarm;
      final initialSoil = (farm != null && farm.soilType.isNotEmpty) ? farm.soilType : "Loamy";
      _applySoilTypeBaselines(initialSoil, overwriteControllers: true);
    });
  }

  void _applySoilTypeBaselines(String soilType, {bool overwriteControllers = true}) {
    final baselines = AppConstants.getBaselineReadingsForSoil(soilType);
    setState(() {
      _selectedSoil = soilType;
      if (overwriteControllers) {
        _nController.text = (baselines['nitrogen'] as double).toStringAsFixed(0);
        _pController.text = (baselines['phosphorus'] as double).toStringAsFixed(0);
        _kController.text = (baselines['potassium'] as double).toStringAsFixed(0);
        _phController.text = (baselines['ph'] as double).toStringAsFixed(1);
        _moistureController.text = (baselines['moisture'] as double).toStringAsFixed(0);
        _tempController.text = (baselines['temperature'] as double).toStringAsFixed(1);
      }
      _updateEcAndOc();
    });
  }

  void _updateEcAndOc() {
    final n = double.tryParse(_nController.text) ?? 80.0;
    final p = double.tryParse(_pController.text) ?? 40.0;
    final k = double.tryParse(_kController.text) ?? 140.0;
    final oc = AppConstants.calculateOrganicCarbon(n, _selectedSoil);
    final ec = AppConstants.calculateElectricalConductivity(n, p, k);

    _ocController.text = oc.toStringAsFixed(2);
    _ecController.text = ec.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _nController.removeListener(_updateEcAndOc);
    _pController.removeListener(_updateEcAndOc);
    _kController.removeListener(_updateEcAndOc);

    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _phController.dispose();
    _moistureController.dispose();
    _tempController.dispose();
    _ecController.dispose();
    _ocController.dispose();
    _labController.dispose();
    super.dispose();
  }

  Future<void> _submitSoilTest() async {
    if (!_formKey.currentState!.validate()) return;

    final farm = context.read<FarmProvider>().activeFarm;
    if (farm == null) return;

    final workflow = context.read<FarmingWorkflowProvider>();
    final data = {
      'nitrogen': double.tryParse(_nController.text) ?? 88.0,
      'phosphorus': double.tryParse(_pController.text) ?? 42.0,
      'potassium': double.tryParse(_kController.text) ?? 44.0,
      'ph': double.tryParse(_phController.text) ?? 6.6,
      'moisture': double.tryParse(_moistureController.text) ?? 48.0,
      'soil_temperature': double.tryParse(_tempController.text) ?? 26.4,
      'electrical_conductivity': double.tryParse(_ecController.text) ?? 1.1,
      'organic_carbon': double.tryParse(_ocController.text) ?? 0.58,
      'soil_type': _selectedSoil,
      'lab_name': _labController.text.trim(),
      'source': _entrySource,
    };

    final success = await workflow.addSoilProfile(farm.farmId, data);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Soil Profile test record saved successfully!"),
          backgroundColor: AppTheme.emerald,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(workflow.errorMessage ?? "Failed to save profile"),
          backgroundColor: AppTheme.alertCoral,
        ),
      );
    }
  }

  void _openProbeWizard() {
    showSoilProbeWizardDialog(
      context,
      onComplete: (results) {
        setState(() {
          _entrySource = "ESP32 IoT Probes";
          _nController.text = results['nitrogen'].toString();
          _pController.text = results['phosphorus'].toString();
          _kController.text = results['potassium'].toString();
          _phController.text = results['ph'].toString();
          _moistureController.text = results['moisture'].toString();
          _tempController.text = results['soil_temperature'].toString();
          _labController.text = "YieldCraft ESP32 IoT Node (ZTS-3002 NPK + DS18B20 + Hygrometer)";
          _updateEcAndOc();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();
    final baselines = AppConstants.getBaselineReadingsForSoil(_selectedSoil);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Soil Test & Laboratory Data"),
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
              title: "Soil Chemistry Profile",
              subtitle: "Primary foundation for AI crop and fertilizer recommendations",
              icon: Icons.science,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step 1: Soil Type Selection (FIRST)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.emerald, width: 1.8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.emerald.withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.sageLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.terrain, color: AppTheme.emerald, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Step 1: Select Soil Classification",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                    ),
                                    Text(
                                      "Loads characteristic NPK, pH, moisture & temperature baselines",
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedSoil,
                            decoration: const InputDecoration(
                              labelText: "Soil Type",
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: AppConstants.soilTypes
                                .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600))))
                                .toList(),
                            onChanged: (val) {
                              if (val == null) return;
                              _applySoilTypeBaselines(val, overwriteControllers: true);
                            },
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.sageLight.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: AppTheme.emerald),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "${baselines['description'] ?? ''} • ${AppConstants.getSoilPhDescription(_selectedSoil)}",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // IoT Probe Wizard Banner Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.sageLight, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.sageLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.sensors, color: AppTheme.emerald, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "ESP32 IoT Sensor Probes",
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                                Text(
                                  "Optional probe-by-probe live telemetry ingestion",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.emerald,
                              side: const BorderSide(color: AppTheme.emerald),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: _openProbeWizard,
                            icon: const Icon(Icons.touch_app, size: 15),
                            label: const Text("Probe Wizard", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const SectionHeader(
                      title: "Step 2: Soil Macronutrients & Moisture",
                      subtitle: "Pre-filled with soil type readings • Tweak as required",
                    ),

                    // Primary NPK Inputs
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Nitrogen (N)",
                              suffixText: "kg/ha",
                            ),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _pController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Phosphorus (P)",
                              suffixText: "kg/ha",
                            ),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _kController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Potassium (K)",
                              suffixText: "kg/ha",
                            ),
                            validator: (val) => val == null || val.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Soil pH, Moisture, and Temperature
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Soil pH (0-14)",
                              hintText: "e.g. 6.6",
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return "Required";
                              final n = double.tryParse(val);
                              if (n == null || n < 0 || n > 14) return "0-14";
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _moistureController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Moisture",
                              suffixText: "%",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _tempController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Soil Temp",
                              suffixText: "°C",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Step 3: Auto-calculated EC & OC section (Replaces manual input requirement)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.sageLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_graph, color: AppTheme.emerald, size: 18),
                              const SizedBox(width: 8),
                              const Text(
                                "Auto-Calculated Chemistry Indicators",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setState(() => _showManualEcOc = !_showManualEcOc),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                                child: Text(_showManualEcOc ? "Hide Manual" : "Edit Values", style: const TextStyle(fontSize: 11, color: AppTheme.emerald)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Organic Carbon (OC)", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text("${_ocController.text}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.emerald)),
                                      const Text("Dynamic from N & Soil", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("Elec. Conductivity (EC)", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text("${_ecController.text} dS/m", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.emerald)),
                                      const Text("Dynamic from NPK salts", style: TextStyle(fontSize: 9, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_showManualEcOc) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _ocController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Manual OC (%)",
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _ecController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Manual EC (dS/m)",
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _labController,
                      decoration: const InputDecoration(
                        labelText: "Soil Testing Laboratory / Reference",
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: workflow.isLoading ? null : _submitSoilTest,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(workflow.isLoading ? "Saving..." : "Save Confirmed Soil Test"),
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

