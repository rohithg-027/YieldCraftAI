import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/gps_service.dart';
import '../models/farm_model.dart';
import '../state/farm_provider.dart';

Future<FarmModel?> showCreateFarmBottomSheet(
  BuildContext context, {
  void Function(FarmModel createdFarm)? onFarmCreated,
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final areaController = TextEditingController(text: "2.5");
  final latController = TextEditingController(text: "12.9716");
  final lonController = TextEditingController(text: "77.5946");
  final villageController = TextEditingController();

  String selectedState = AppConstants.indianStates.contains('Karnataka')
      ? 'Karnataka'
      : AppConstants.indianStates.first;
  String selectedSoil = 'Loamy';
  String selectedAreaUnit = 'hectares';
  String selectedIrrigation = 'Borewell';
  String? selectedActiveCrop = 'Rice';
  bool isGpsDetected = false;
  bool isFetchingGps = false;
  String gpsStatus = "Tap to fetch high-precision coordinates";
  bool isSubmitting = false;

  return showModalBottomSheet<FarmModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (modalContext, setModalState) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_location_alt, color: AppTheme.emerald, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Create Digital Farm",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // GPS Detection Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.mintAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: AppTheme.emerald),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isGpsDetected ? "GPS Coordinates Acquired" : "Detect Current Farm Location",
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              gpsStatus,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isFetchingGps)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        TextButton(
                          onPressed: () async {
                            setModalState(() {
                              isFetchingGps = true;
                              gpsStatus = "Accessing device GPS satellites...";
                            });
                            final loc = await GpsService.getCurrentLocation();
                            setModalState(() {
                              isFetchingGps = false;
                              if (loc != null) {
                                latController.text = loc.latitude.toString();
                                lonController.text = loc.longitude.toString();
                                if (loc.village != null && loc.village!.isNotEmpty) {
                                  villageController.text = loc.village!;
                                }
                                if (loc.state != null && AppConstants.indianStates.contains(loc.state)) {
                                  selectedState = loc.state!;
                                }
                                isGpsDetected = true;
                                gpsStatus = "Lat: ${loc.latitude.toStringAsFixed(4)}, Lon: ${loc.longitude.toStringAsFixed(4)} (±${loc.accuracy.toStringAsFixed(0)}m • ${loc.isGpsHardware ? 'GPS' : 'Network'})";
                              } else {
                                gpsStatus = "Could not acquire location. Please enter manually.";
                              }
                            });
                          },
                          child: Text(isGpsDetected ? "Refresh" : "Detect GPS"),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Farm Name *",
                    hintText: "e.g. Kaveri Green Valley Farm",
                    prefixIcon: Icon(Icons.landscape_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? "Enter farm name" : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: areaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Farm Area *",
                          prefixIcon: Icon(Icons.square_foot),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Enter area";
                          if (double.tryParse(val) == null) return "Invalid number";
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedAreaUnit,
                        decoration: const InputDecoration(labelText: "Unit"),
                        items: const [
                          DropdownMenuItem(value: "hectares", child: Text("Hectares")),
                          DropdownMenuItem(value: "acres", child: Text("Acres")),
                        ],
                        onChanged: (val) => setModalState(() => selectedAreaUnit = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSoil,
                        decoration: const InputDecoration(labelText: "Soil Type"),
                        items: AppConstants.soilTypes
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) => setModalState(() => selectedSoil = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedState,
                        decoration: const InputDecoration(labelText: "State"),
                        items: AppConstants.indianStates
                            .map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (val) => setModalState(() => selectedState = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: villageController,
                  decoration: const InputDecoration(
                    labelText: "Village / Town (Optional)",
                    hintText: "e.g. Maddur, Somwarpet",
                    prefixIcon: Icon(Icons.location_city, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String?>(
                  value: selectedActiveCrop,
                  decoration: const InputDecoration(
                    labelText: "Current / Planned Crop",
                    prefixIcon: Icon(Icons.grass),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("None (Undecided)")),
                    ...AppConstants.supportedCrops.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (val) => setModalState(() => selectedActiveCrop = val),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isSubmitting = true);

                          final farmName = nameController.text.trim();
                          final lat = double.tryParse(latController.text) ?? 12.9716;
                          final lon = double.tryParse(lonController.text) ?? 77.5946;
                          final area = double.tryParse(areaController.text) ?? 2.5;
                          final village = villageController.text.trim();

                          final farmProvider = context.read<FarmProvider>();
                          final created = await farmProvider.createFarm(
                            farmName: farmName,
                            latitude: lat,
                            longitude: lon,
                            locationAccuracyMeters: 5.0,
                            area: area,
                            areaUnit: selectedAreaUnit,
                            soilType: selectedSoil,
                            state: selectedState,
                            district: null,
                            village: village,
                            irrigationSource: selectedIrrigation,
                            activeCrop: selectedActiveCrop,
                          );

                          if (modalContext.mounted) {
                            Navigator.pop(ctx, created);
                          }

                          if (!context.mounted) return;

                          if (created != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Digital Farm '${created.farmName}' created & activated!"),
                                backgroundColor: AppTheme.emerald,
                              ),
                            );
                            onFarmCreated?.call(created);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(farmProvider.errorMessage ?? "Failed to create farm. Please try again."),
                                backgroundColor: AppTheme.alertCoral,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Save & Activate Farm", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
