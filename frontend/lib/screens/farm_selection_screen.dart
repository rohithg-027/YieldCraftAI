import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/farm_model.dart';
import '../state/farm_provider.dart';
import '../state/auth_provider.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/create_farm_dialog.dart';
import '../widgets/edit_farm_dialog.dart';
import 'home_dashboard_screen.dart';
import 'auth_screen.dart';

class FarmSelectionScreen extends StatefulWidget {
  const FarmSelectionScreen({super.key});

  @override
  State<FarmSelectionScreen> createState() => _FarmSelectionScreenState();
}

class _FarmSelectionScreenState extends State<FarmSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmProvider>().loadFarms();
    });
  }

  void _showCreateFarmDialog() {
    showCreateFarmBottomSheet(
      context,
      onFarmCreated: (farm) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
          );
        }
      },
    );
  }

  Future<void> _confirmDeleteFarm(FarmModel farm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.alertCoral),
            SizedBox(width: 8),
            Text("Delete Farm?"),
          ],
        ),
        content: Text(
          "Are you sure you want to permanently delete \"${farm.farmName}\"? All associated soil profiles and sensor readings will be permanently removed.",
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

    if (confirm == true && mounted) {
      final farmProvider = context.read<FarmProvider>();
      final ok = await farmProvider.deleteFarm(farm.farmId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok
                ? "Farm \"${farm.farmName}\" was deleted successfully."
                : (farmProvider.errorMessage ?? "Failed to delete farm.")),
            backgroundColor: ok ? AppTheme.emerald : AppTheme.alertCoral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmProvider = context.watch<FarmProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Your Digital Farms"),
        leading: farmProvider.hasFarms
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: "Back to Dashboard",
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                  );
                },
              )
            : null,
        actions: [
          IconButton(
            tooltip: "Sign Out",
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateFarmDialog,
        backgroundColor: AppTheme.emerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text("Create Farm"),
      ),
      body: farmProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !farmProvider.hasFarms
              ? EmptyStateView(
                  icon: Icons.landscape_outlined,
                  title: "No Farms Registered Yet",
                  description: "Create your first digital farm with GPS coordinates to enable AI crop recommendations, weather forecasting, and market analysis.",
                  buttonText: "Create First Farm",
                  onButtonPressed: _showCreateFarmDialog,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: farmProvider.farms.length,
                  itemBuilder: (context, index) {
                    final farm = farmProvider.farms[index];
                    final isSelected = farmProvider.activeFarm?.farmId == farm.farmId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? AppTheme.emerald : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await farmProvider.selectFarm(farm);
                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.emerald
                                          : AppTheme.primaryGreen.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.agriculture,
                                      color: isSelected ? Colors.white : AppTheme.primaryGreen,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          farm.farmName,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                        Text(
                                          farm.village != null && farm.village!.isNotEmpty
                                              ? "${farm.village}, ${farm.state}"
                                              : farm.state,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.sageLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        "ACTIVE",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    tooltip: "Edit Farm Location & Details",
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondary),
                                    onPressed: () {
                                      showEditFarmBottomSheet(context, farm: farm);
                                    },
                                  ),
                                  IconButton(
                                    tooltip: "Delete Farm",
                                    icon: const Icon(Icons.delete_outline, size: 19, color: AppTheme.alertCoral),
                                    onPressed: () => _confirmDeleteFarm(farm),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildChip(Icons.crop_square, "${farm.area} ${farm.areaUnit}"),
                                  _buildChip(Icons.layers_outlined, "${farm.soilType} Soil"),
                                  _buildChip(
                                    Icons.grass,
                                    farm.activeCrop != null ? farm.activeCrop! : "Unset",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
