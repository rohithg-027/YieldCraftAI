import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/farm_model.dart';
import '../state/farm_provider.dart';

Future<bool?> showEditFarmBottomSheet(
  BuildContext context, {
  required FarmModel farm,
  void Function(FarmModel updatedFarm)? onFarmUpdated,
}) {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: farm.farmName);
  final villageController = TextEditingController(text: farm.village ?? '');
  final areaController = TextEditingController(text: farm.area.toString());

  String selectedState = AppConstants.indianStates.contains(farm.state)
      ? farm.state
      : (AppConstants.indianStates.isNotEmpty ? AppConstants.indianStates.first : 'Karnataka');
  String selectedSoil = farm.soilType;
  String selectedAreaUnit = farm.areaUnit;
  String selectedIrrigation = farm.irrigationSource ?? 'Borewell';
  String? selectedActiveCrop = farm.activeCrop;
  bool isSubmitting = false;

  return showModalBottomSheet<bool>(
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
                        Icon(Icons.edit_location_alt, color: AppTheme.emerald, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Edit Farm Details",
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

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Farm Name *",
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

                          final farmProvider = context.read<FarmProvider>();
                          final updates = {
                            'farm_name': nameController.text.trim(),
                            'village': villageController.text.trim(),
                            'state': selectedState,
                            'area': double.tryParse(areaController.text) ?? farm.area,
                            'area_unit': selectedAreaUnit,
                            'soil_type': selectedSoil,
                            'irrigation_source': selectedIrrigation,
                            'active_crop': selectedActiveCrop,
                          };

                          final ok = await farmProvider.updateFarm(farm.farmId, updates);
                          if (modalContext.mounted) {
                            Navigator.pop(ctx, ok);
                          }

                          if (!context.mounted) return;
                          if (ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Farm location and profile updated!"),
                                backgroundColor: AppTheme.emerald,
                              ),
                            );
                            if (farmProvider.activeFarm != null && onFarmUpdated != null) {
                              onFarmUpdated(farmProvider.activeFarm!);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Changes", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                const SizedBox(height: 12),

                // Delete Farm Profile Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.alertCoral,
                    side: const BorderSide(color: AppTheme.alertCoral),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text("Delete Farm Profile", style: TextStyle(fontWeight: FontWeight.w700)),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: modalContext,
                            builder: (dCtx) => AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppTheme.alertCoral),
                                  SizedBox(width: 8),
                                  Text("Delete Farm?"),
                                ],
                              ),
                              content: Text(
                                "Are you sure you want to permanently delete \"${farm.farmName}\"? All associated telemetry and diary logs will be removed.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: const Text("Cancel"),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.alertCoral,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  child: const Text("Delete Permanently"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setModalState(() => isSubmitting = true);
                            final farmProvider = context.read<FarmProvider>();
                            final deleted = await farmProvider.deleteFarm(farm.farmId);
                            if (modalContext.mounted) {
                              Navigator.pop(ctx, deleted);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(deleted
                                      ? "Farm \"${farm.farmName}\" was deleted successfully."
                                      : "Failed to delete farm."),
                                  backgroundColor: deleted ? AppTheme.emerald : AppTheme.alertCoral,
                                ),
                              );
                              if (deleted && onFarmUpdated != null && farmProvider.activeFarm != null) {
                                onFarmUpdated(farmProvider.activeFarm!);
                              }
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
