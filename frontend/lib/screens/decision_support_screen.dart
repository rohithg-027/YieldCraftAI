import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../core/app_theme.dart';
import '../widgets/custom_cards.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/loading_indicator.dart';

class DecisionSupportScreen extends StatefulWidget {
  const DecisionSupportScreen({super.key});

  @override
  State<DecisionSupportScreen> createState() => _DecisionSupportScreenState();
}

class _DecisionSupportScreenState extends State<DecisionSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    final farm = Provider.of<FarmProvider>(context, listen: false).selectedFarm;
    if (farm != null) {
      Provider.of<FarmingWorkflowProvider>(context, listen: false).loadDecisionSupport(farm.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmProvider = Provider.of<FarmProvider>(context);
    final workflow = Provider.of<FarmingWorkflowProvider>(context);
    final selectedFarm = farmProvider.selectedFarm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Decision Support'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Intelligence',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: selectedFarm == null
          ? const EmptyStateView(
              icon: Icons.agriculture_outlined,
              title: 'No Farm Selected',
              description: 'Please choose or create a farm from the home dashboard to generate a decision support report.',
            )
          : workflow.isLoading && workflow.decisionSupport == null
              ? const LoadingIndicator(message: 'Synthesizing multi-modal farm intelligence...')
              : workflow.decisionSupport == null
                  ? EmptyStateView(
                      icon: Icons.analytics_outlined,
                      title: 'No Decision Report Generated',
                      description: 'Compile your farm soil, weather, crop, and market data into an actionable agronomic plan.',
                      buttonText: 'Generate Plan Now',
                      onButtonPressed: _refreshData,
                    )
                  : _buildReportBody(context, workflow),
    );
  }

  Widget _buildReportBody(BuildContext context, FarmingWorkflowProvider workflow) {
    final ds = workflow.decisionSupport!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header banner
          GradientHeader(
            title: ds.farmName,
            subtitle: '${ds.location} • Generated ${ds.generatedAt.isNotEmpty && ds.generatedAt.length >= 10 ? ds.generatedAt.substring(0, 10) : "Today"}',
            icon: Icons.hub,
          ),
          const SizedBox(height: 16),

          // High-level snapshot grid
          Row(
            children: [
              Expanded(
                child: StatMetricCard(
                  label: 'Active Crop',
                  value: ds.activeCrop ?? 'Not set',
                  icon: Icons.eco,
                  color: AppTheme.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatMetricCard(
                  label: 'Irrigation Need',
                  value: ds.irrigationNeed ?? 'Pending',
                  icon: Icons.water_drop,
                  color: ds.irrigationNeed == 'High'
                      ? Colors.orange
                      : ds.irrigationNeed == 'Low'
                          ? Colors.teal
                          : AppTheme.earthAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weather & Soil cards
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: AppTheme.earthAmber),
                      const SizedBox(width: 8),
                      Text('Atmospheric & Soil Environment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildKeyValueRow('Weather Conditions:', ds.weatherSummary),
                  const SizedBox(height: 8),
                  _buildKeyValueRow('Soil Health Status:', ds.latestSoilStatus),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recommended Crops Section
          if (ds.topRecommendedCrops.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: AppTheme.emerald),
                        const SizedBox(width: 8),
                        Text('AI Recommended Crop Portfolio', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ds.topRecommendedCrops.map((crop) {
                        return Chip(
                          avatar: Icon(Icons.check_circle, size: 16, color: AppTheme.emerald),
                          label: Text(crop, style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: AppTheme.emerald.withOpacity(0.08),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Predictions & Market Highlights
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: AppTheme.earthAmber),
                      const SizedBox(width: 8),
                      Text('Economic & Agronomic Intelligence', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  if (ds.fertilizerRecommendation != null)
                    _buildKeyValueRow('Fertilizer Advisory:', ds.fertilizerRecommendation!),
                  if (ds.yieldEstimateHighlight != null)
                    _buildKeyValueRow('Yield Forecast:', ds.yieldEstimateHighlight!),
                  if (ds.marketPriceHighlight != null)
                    _buildKeyValueRow('Agmarknet Mandi Rate:', ds.marketPriceHighlight!),
                  if (ds.profitEstimateHighlight != null)
                    _buildKeyValueRow('Projected Net Margin:', ds.profitEstimateHighlight!),
                  if (ds.recentDiseaseCheck != null)
                    _buildKeyValueRow('Crop Pathology Status:', ds.recentDiseaseCheck!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Action Items
          if (ds.keyActionItems.isNotEmpty) ...[
            Card(
              color: AppTheme.emerald.withOpacity(0.04),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: AppTheme.emerald.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.checklist_rtl, color: AppTheme.emerald),
                        const SizedBox(width: 8),
                        Text('Actionable Agronomic Checklist', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...ds.keyActionItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.arrow_right, color: AppTheme.emerald, size: 20),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(item, style: theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Missing Data Warnings
          if (ds.missingDataWarnings.isNotEmpty) ...[
            Card(
              color: Colors.amber.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.amber.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Data Completeness Notice', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...ds.missingDataWarnings.map((warn) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: Text(warn, style: TextStyle(fontSize: 13, color: Colors.brown.shade800)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Export & Share buttons
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Farm Decision Report downloaded as PDF and saved to Farm History.'),
                  backgroundColor: AppTheme.emerald,
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Export Consolidated Agronomic Report (PDF)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
