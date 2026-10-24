import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/farm_model.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../state/auth_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/create_farm_dialog.dart';
import '../widgets/edit_farm_dialog.dart';
import '../widgets/soil_probe_wizard_dialog.dart';

import 'auth_screen.dart';
import 'farm_selection_screen.dart';
import 'soil_test_screen.dart';
import 'crop_recommendation_screen.dart';
import 'yield_prediction_screen.dart';
import 'fertilizer_screen.dart';
import 'irrigation_screen.dart';
import 'disease_detection_screen.dart';
import 'market_intelligence_screen.dart';
import 'profit_estimator_screen.dart';
import 'digital_diary_screen.dart';
import 'decision_support_screen.dart';
import 'ai_assistant_screen.dart';
import 'weather_detail_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    final farmProvider = context.read<FarmProvider>();
    final workflow = context.read<FarmingWorkflowProvider>();
    final farm = farmProvider.activeFarm;

    if (farm != null) {
      workflow.fetchWeather(farm.latitude, farm.longitude);
      workflow.loadSoilProfiles(farm.farmId);
      workflow.loadDiary(farm.farmId);
      workflow.fetchMarketPrices(
        commodity: farm.activeCrop ?? 'Rice',
        state: farm.state,
        district: farm.district,
      );
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _confirmDeleteCurrentFarm(FarmModel farm) async {
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
          "Are you sure you want to permanently delete \"${farm.farmName}\"? All associated telemetry and soil profiles will be removed.",
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
        _loadDashboardData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmProvider = context.watch<FarmProvider>();
    final workflow = context.watch<FarmingWorkflowProvider>();
    final auth = context.watch<AuthProvider>();
    final farm = farmProvider.activeFarm;
    final hasFarms = farmProvider.hasFarms;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          tooltip: hasFarms ? "Manage Digital Farms" : "Digital Agriculture",
          icon: Icon(
            hasFarms ? Icons.agriculture_rounded : Icons.eco_rounded,
            color: AppTheme.emerald,
          ),
          onPressed: () {
            if (hasFarms) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FarmSelectionScreen()),
              );
            } else {
              showCreateFarmBottomSheet(
                context,
                onFarmCreated: (_) => _loadDashboardData(),
              );
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (farm != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppTheme.emerald),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      farm.farmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  showEditFarmBottomSheet(context, farm: farm, onFarmUpdated: (_) => _loadDashboardData());
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        farm.village != null && farm.village!.isNotEmpty
                            ? "${farm.village}, ${farm.state} • ${farm.area} ${farm.areaUnit}"
                            : "${farm.state} • ${farm.area} ${farm.areaUnit}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit, size: 11, color: AppTheme.emerald),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                "YieldCraft AI Dashboard",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Text(
                "Smart Precision Agriculture",
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ],
        ),
        actions: [
          if (hasFarms) ...[
            if (farm != null)
              IconButton(
                tooltip: "Edit / Delete Farm",
                icon: const Icon(Icons.edit_location_alt_outlined, color: AppTheme.emerald),
                onPressed: () async {
                  final res = await showEditFarmBottomSheet(context, farm: farm, onFarmUpdated: (_) => _loadDashboardData());
                  if (res == true && mounted) {
                    _loadDashboardData();
                  }
                },
              ),
            IconButton(
              tooltip: "Switch / Manage Farms",
              icon: const Icon(Icons.swap_horiz, color: AppTheme.textDark),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FarmSelectionScreen()),
                );
              },
            ),
            IconButton(
              tooltip: "Agro Weather Details",
              icon: const Icon(Icons.cloud_outlined, color: AppTheme.emerald),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WeatherDetailScreen()),
                );
              },
            ),
            IconButton(
              tooltip: "AI Assistant",
              icon: const Icon(Icons.smart_toy_outlined, color: AppTheme.emerald),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
                );
              },
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () => showCreateFarmBottomSheet(
                context,
                onFarmCreated: (_) => _loadDashboardData(),
              ),
              icon: const Icon(Icons.add, size: 16, color: AppTheme.emerald),
              label: const Text(
                "Add Farm",
                style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          PopupMenuButton<String>(
            tooltip: "User Profile & Options",
            icon: const Icon(Icons.more_vert, color: AppTheme.textDark),
            onSelected: (val) {
              if (val == 'edit_farm' && farm != null) {
                showEditFarmBottomSheet(context, farm: farm, onFarmUpdated: (_) => _loadDashboardData());
              } else if (val == 'delete_farm' && farm != null) {
                _confirmDeleteCurrentFarm(farm);
              } else if (val == 'farms') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FarmSelectionScreen()),
                );
              } else if (val == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.userFullName ?? "YieldCraft Farmer",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                    Text(
                      auth.userEmail ?? "",
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              if (hasFarms) ...[
                if (farm != null) ...[
                  const PopupMenuItem(
                    value: 'edit_farm',
                    child: Row(
                      children: [
                        Icon(Icons.edit_location_alt, size: 18, color: AppTheme.emerald),
                        SizedBox(width: 10),
                        Text("Edit Farm Profile"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_farm',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 18, color: AppTheme.alertCoral),
                        const SizedBox(width: 10),
                        Text("Delete Current Farm", style: TextStyle(color: AppTheme.alertCoral.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'farms',
                  child: Row(
                    children: [
                      Icon(Icons.landscape, size: 18, color: AppTheme.emerald),
                      SizedBox(width: 10),
                      Text("Manage All Farms"),
                    ],
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppTheme.alertCoral),
                    SizedBox(width: 10),
                    Text("Sign Out", style: TextStyle(color: AppTheme.alertCoral)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AiAssistantScreen()),
          );
        },
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text("Ask AI Assistant"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await farmProvider.loadFarms();
          _loadDashboardData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (farmProvider.isLoading && !hasFarms)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: AppTheme.emerald),
                        SizedBox(height: 16),
                        Text(
                          "Loading your digital farms...",
                          style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                )
              else if (!hasFarms || farm == null)
                _buildEmptyFarmDashboard(auth)
              else ...[
                // 1. PRIMARY SOIL TEST & CONNECT SENSORS CUSTOM CARD (First on Dashboard)
                _buildSoilTestPrimaryCard(farm, workflow.latestSoilProfile, workflow),

                // 2. Digital Farms Carousel (Switch & Add)
                _buildFarmsCarousel(farmProvider),

                // 3. Weather Snapshot Card for active farm
                _buildWeatherCard(workflow.weather),

                // 4. Active Crop & Soil Quick Metric Strip
                _buildFarmQuickMetrics(farm, workflow.latestSoilProfile),

                const SizedBox(height: 12),
                const SectionHeader(
                  title: "Digital Farming Modules",
                  subtitle: "Integrated AI predictions and precision agriculture workflows",
                ),

                // 5. Grid of 10 Interactive Modules
                _buildModuleGrid(activeFarm: farm),

                const SizedBox(height: 20),

                // 6. Quick Highlights: Latest Mandi Price Highlight
                _buildMandiHighlight(workflow),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // EMPTY STATE DASHBOARD: User has no farms yet
  // -------------------------------------------------------------
  Widget _buildEmptyFarmDashboard(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Onboarding Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.emerald],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 14),
                Text(
                  "Welcome${auth.userFullName != null && auth.userFullName!.isNotEmpty ? ', ${auth.userFullName}' : ''}!",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "You haven't registered any digital farms yet. Create your first farm with GPS coordinates to unlock precision AI analytics, live weather forecasting, CatBoost irrigation models, and Mandi market rates.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mintAccent,
                    foregroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: () => showCreateFarmBottomSheet(
                    context,
                    onFarmCreated: (_) => _loadDashboardData(),
                  ),
                  icon: const Icon(Icons.add_location_alt, size: 20),
                  label: const Text(
                    "Create Your First Farm",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Benefits & Platform Capabilities
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.emerald, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "What You Can Do With YieldCraft AI",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildBenefitRow(
                  Icons.wb_sunny_outlined,
                  "Hyper-Local Weather & Forecasts",
                  "Automated rainfall, humidity, and agro-meteorological advisories based on your farm's GPS coordinates.",
                ),
                const SizedBox(height: 10),
                _buildBenefitRow(
                  Icons.psychology_outlined,
                  "ML Crop Recommendations",
                  "Machine learning crop suggestions trained on NPK, pH, and agro-climatic parameters.",
                ),
                const SizedBox(height: 10),
                _buildBenefitRow(
                  Icons.water_drop_outlined,
                  "Daily Precision Irrigation",
                  "CatBoost AI moisture planning calculating exact water requirements per hectare.",
                ),
                const SizedBox(height: 10),
                _buildBenefitRow(
                  Icons.health_and_safety_outlined,
                  "Crop Doctor & Live Mandi Prices",
                  "Gemini multimodal leaf vision diagnostics and official daily trading prices from data.gov.in.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const SectionHeader(
            title: "Digital Farming Modules",
            subtitle: "Create a digital farm to unlock real-time predictions and analytics",
          ),

          // Disabled preview of modules
          _buildModuleGrid(activeFarm: null),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.sageLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.emerald, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // FARMS CAROUSEL: Shows user's digital farms with quick switch
  // -------------------------------------------------------------
  Widget _buildFarmsCarousel(FarmProvider farmProvider) {
    final farms = farmProvider.farms;
    final activeFarm = farmProvider.activeFarm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.landscape, size: 18, color: AppTheme.emerald),
                  const SizedBox(width: 8),
                  Text(
                    "Your Digital Farms (${farms.length})",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => showCreateFarmBottomSheet(
                  context,
                  onFarmCreated: (_) => _loadDashboardData(),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 16, color: AppTheme.emerald),
                label: const Text(
                  "Add Farm",
                  style: TextStyle(
                    color: AppTheme.emerald,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 136,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: farms.length + 1,
            itemBuilder: (context, index) {
              if (index == farms.length) {
                return _buildAddFarmMiniCard();
              }
              final f = farms[index];
              final isSelected = activeFarm?.farmId == f.farmId;
              return _buildFarmCardItem(f, isSelected, farmProvider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFarmCardItem(FarmModel f, bool isSelected, FarmProvider farmProvider) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.emerald : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppTheme.emerald.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            if (!isSelected) {
              await farmProvider.selectFarm(f);
              _loadDashboardData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Switched active farm to '${f.farmName}'"),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppTheme.emerald,
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.emerald : AppTheme.sageLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.agriculture,
                        color: isSelected ? Colors.white : AppTheme.emerald,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f.farmName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.sageLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "ACTIVE",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  f.village != null && f.village!.isNotEmpty
                      ? "${f.village}, ${f.state}"
                      : f.state,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${f.area} ${f.areaUnit}",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.mintAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        f.activeCrop ?? "Unset",
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddFarmMiniCard() {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12, bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.sageLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.mintAccent.withValues(alpha: 0.5),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showCreateFarmBottomSheet(
            context,
            onFarmCreated: (_) => _loadDashboardData(),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_location_alt_outlined, color: AppTheme.emerald, size: 26),
                SizedBox(height: 6),
                Text(
                  "+ Add Farm",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppTheme.emerald,
                  ),
                ),
                Text(
                  "GPS Auto-Detect",
                  style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 10 MODULES GRID
  // -------------------------------------------------------------
  Widget _buildModuleGrid({required FarmModel? activeFarm}) {
    void handleModuleTap(Widget destination) {
      if (activeFarm == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Register your digital farm to unlock this AI module!"),
            backgroundColor: AppTheme.alertCoral,
            action: SnackBarAction(
              label: "Create Farm",
              textColor: Colors.white,
              onPressed: () => showCreateFarmBottomSheet(
                context,
                onFarmCreated: (_) => _loadDashboardData(),
              ),
            ),
          ),
        );
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: [
          FeatureModuleTile(
            title: "Soil Test & IoT",
            subtitle: "NPK lab records & ESP32 sensors",
            icon: Icons.science_outlined,
            accentColor: const Color(0xFFD4A373),
            onTap: () => handleModuleTap(const SoilTestScreen()),
          ),
          FeatureModuleTile(
            title: "Crop Selection",
            subtitle: "Top-5 ML candidates with probabilities",
            icon: Icons.psychology_outlined,
            accentColor: AppTheme.emerald,
            onTap: () => handleModuleTap(const CropRecommendationScreen()),
          ),
          FeatureModuleTile(
            title: "Yield Prediction",
            subtitle: "Forecast production per hectare",
            icon: Icons.trending_up,
            accentColor: const Color(0xFF2A9D8F),
            onTap: () => handleModuleTap(const YieldPredictionScreen()),
          ),
          FeatureModuleTile(
            title: "Fertilizer Plan",
            subtitle: "Stage-based application & caution",
            icon: Icons.eco_outlined,
            accentColor: const Color(0xFF457B9D),
            onTap: () => handleModuleTap(const FertilizerScreen()),
          ),
          FeatureModuleTile(
            title: "Daily Irrigation",
            subtitle: "CatBoost moisture requirement",
            icon: Icons.water_drop_outlined,
            accentColor: const Color(0xFF0077B6),
            onTap: () => handleModuleTap(const IrrigationScreen()),
          ),
          FeatureModuleTile(
            title: "Crop Doctor",
            subtitle: "Gemini multimodal vision diagnostics",
            icon: Icons.health_and_safety_outlined,
            accentColor: AppTheme.alertCoral,
            onTap: () => handleModuleTap(const DiseaseDetectionScreen()),
          ),
          FeatureModuleTile(
            title: "Mandi Market",
            subtitle: "Official data.gov.in commodity rates",
            icon: Icons.storefront_outlined,
            accentColor: const Color(0xFFE76F51),
            onTap: () => handleModuleTap(const MarketIntelligenceScreen()),
          ),
          FeatureModuleTile(
            title: "Profit Estimator",
            subtitle: "Itemized costs & 3 revenue scenarios",
            icon: Icons.account_balance_wallet_outlined,
            accentColor: const Color(0xFF386641),
            onTap: () => handleModuleTap(const ProfitEstimatorScreen()),
          ),
          FeatureModuleTile(
            title: "Digital Diary",
            subtitle: "Activity logs, milestones & expenses",
            icon: Icons.book_outlined,
            accentColor: const Color(0xFF6A4C93),
            onTap: () => handleModuleTap(const DigitalDiaryScreen()),
          ),
          FeatureModuleTile(
            title: "Decision Report",
            subtitle: "Consolidated farm health summary",
            icon: Icons.assessment_outlined,
            accentColor: AppTheme.primaryGreen,
            onTap: () => handleModuleTap(const DecisionSupportScreen()),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // WEATHER SNAPSHOT CARD
  // -------------------------------------------------------------
  Widget _buildWeatherCard(dynamic weather) {
    if (weather == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                "Retrieving real-time weather...",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WeatherDetailScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, AppTheme.emerald],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
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
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_outlined, color: Colors.white, size: 28),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                weather.weatherCondition,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(
                                "Tap for 7-Day Forecast & Advisories →",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${weather.temperatureC.toStringAsFixed(1)}°C",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWeatherMetric("Humidity", "${weather.relativeHumidityPct.toStringAsFixed(0)}%"),
                  _buildWeatherMetric("Precipitation", "${weather.precipitationMm.toStringAsFixed(1)} mm"),
                  _buildWeatherMetric("Wind Speed", "${weather.windSpeedKmh.toStringAsFixed(0)} km/h"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // QUICK METRICS STRIP
  // -------------------------------------------------------------
  Widget _buildFarmQuickMetrics(FarmModel farm, dynamic soil) {
    final npkText = soil != null
        ? "${soil.nitrogen.toInt()}-${soil.phosphorus.toInt()}-${soil.potassium.toInt()}"
        : "Pending Test";
    final phText = soil != null ? "pH ${soil.ph.toStringAsFixed(1)}" : "pH --";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: StatMetricCard(
              title: "Active Crop",
              value: farm.activeCrop ?? "Undecided",
              icon: Icons.grass,
              iconColor: AppTheme.emerald,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatMetricCard(
              title: "Soil NPK & pH",
              value: npkText,
              unit: phText,
              icon: Icons.science,
              iconColor: const Color(0xFFD4A373),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // MANDI PRICE HIGHLIGHT
  // -------------------------------------------------------------
  Widget _buildMandiHighlight(FarmingWorkflowProvider workflow) {
    if (workflow.marketPrices.isEmpty) return const SizedBox.shrink();

    final record = workflow.marketPrices.first;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.sageLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.price_check, color: AppTheme.emerald, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Latest Mandi Price: ${record.commodity}",
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  "${record.market} (${record.district}) • ${record.arrivalDate}",
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            "₹${record.modalPrice.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryGreen,
            ),
          ),
          const Text(" /Qtl", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PRIMARY SOIL TEST & CONNECT SENSORS CUSTOM CARD
  // -------------------------------------------------------------
  Widget _buildSoilTestPrimaryCard(FarmModel farm, dynamic soil, FarmingWorkflowProvider workflow) {
    final hasSoil = soil != null;
    final tempVal = soil?.soilTemperature ?? (workflow.weather?.temperatureC ?? 26.4);
    final tempText = "${tempVal.toStringAsFixed(1)}°C";
    final moistText = soil?.moisture != null ? "${soil.moisture!.toStringAsFixed(0)}%" : "48%";
    final npkText = hasSoil
        ? "${soil.nitrogen.toInt()}-${soil.phosphorus.toInt()}-${soil.potassium.toInt()}"
        : "88-42-44";
    final phText = hasSoil ? "pH ${soil.ph.toStringAsFixed(1)}" : "pH 6.6";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.emerald.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emerald.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 5),
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.sageLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.sensors, color: AppTheme.emerald, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Soil Test & IoT Node (ESP32)",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.emerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            "Probes Ready • DS18B20 Temp Active",
                            style: TextStyle(color: AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.emerald),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  showSoilProbeWizardDialog(context, onComplete: (_) => _loadDashboardData());
                },
                icon: const Icon(Icons.play_arrow, size: 14, color: AppTheme.emerald),
                label: const Text(
                  "Check Probes",
                  style: TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // 4 Probe Quick Metric Tiles
          Row(
            children: [
              Expanded(
                child: _buildProbeQuickTile(
                  "Soil Temp",
                  tempText,
                  "DS18B20 Live",
                  Icons.thermostat,
                  Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProbeQuickTile(
                  "Moisture",
                  moistText,
                  "Root Zone",
                  Icons.water_drop,
                  Colors.blue.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProbeQuickTile(
                  "NPK Ratio",
                  npkText,
                  "kg/ha",
                  Icons.science,
                  const Color(0xFFD4A373),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildProbeQuickTile(
                  "Soil pH",
                  phText,
                  farm.soilType,
                  Icons.biotech,
                  Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 1,
                  ),
                  onPressed: () {
                    showSoilProbeWizardDialog(context, onComplete: (_) => _loadDashboardData());
                  },
                  icon: const Icon(Icons.touch_app, size: 18),
                  label: const Text(
                    "Connect My Sensors (Probe-by-Probe)",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SoilTestScreen()));
                },
                child: const Text("Full Lab Data", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProbeQuickTile(String title, String val, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.sageLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
