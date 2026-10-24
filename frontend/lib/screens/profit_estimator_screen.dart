import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../models/profit_model.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';

class ProfitEstimatorScreen extends StatefulWidget {
  const ProfitEstimatorScreen({super.key});

  @override
  State<ProfitEstimatorScreen> createState() => _ProfitEstimatorScreenState();
}

class _ProfitEstimatorScreenState extends State<ProfitEstimatorScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cropController = TextEditingController(text: "Rice");
  final _areaController = TextEditingController(text: "2.5");
  final _yieldController = TextEditingController(text: "35");
  final _priceController = TextEditingController(text: "3800");

  final _seedsController = TextEditingController(text: "5000");
  final _fertController = TextEditingController(text: "12000");
  final _protectionController = TextEditingController(text: "6000");
  final _irrigCostController = TextEditingController(text: "4000");
  final _labourController = TextEditingController(text: "25000");
  final _machineryController = TextEditingController(text: "10000");
  final _transportController = TextEditingController(text: "5000");
  final _miscController = TextEditingController(text: "3000");

  @override
  void initState() {
    super.initState();
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();

    if (farm != null) {
      if (farm.activeCrop != null) _cropController.text = farm.activeCrop!;
      _areaController.text = farm.area.toString();
    }
    if (workflow.yieldPrediction != null) {
      _yieldController.text = workflow.yieldPrediction!.predictedYieldPerHectare.toStringAsFixed(1);
    }
    if (workflow.marketPrices.isNotEmpty) {
      _priceController.text = workflow.marketPrices.first.modalPrice.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _cropController.dispose();
    _areaController.dispose();
    _yieldController.dispose();
    _priceController.dispose();
    _seedsController.dispose();
    _fertController.dispose();
    _protectionController.dispose();
    _irrigCostController.dispose();
    _labourController.dispose();
    _machineryController.dispose();
    _transportController.dispose();
    _miscController.dispose();
    super.dispose();
  }

  Future<void> _calculateProfit() async {
    if (!_formKey.currentState!.validate()) return;
    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();

    final expenses = {
      'seeds': double.tryParse(_seedsController.text) ?? 0.0,
      'fertilizer': double.tryParse(_fertController.text) ?? 0.0,
      'crop_protection': double.tryParse(_protectionController.text) ?? 0.0,
      'irrigation': double.tryParse(_irrigCostController.text) ?? 0.0,
      'labour': double.tryParse(_labourController.text) ?? 0.0,
      'machinery': double.tryParse(_machineryController.text) ?? 0.0,
      'transport': double.tryParse(_transportController.text) ?? 0.0,
      'miscellaneous': double.tryParse(_miscController.text) ?? 0.0,
    };

    await workflow.estimateProfit(
      farmId: farm?.farmId,
      crop: _cropController.text.trim(),
      areaHectares: double.tryParse(_areaController.text) ?? 2.5,
      predictedYieldPerHectare: double.tryParse(_yieldController.text) ?? 35.0,
      marketPricePerQuintal: double.tryParse(_priceController.text) ?? 3800.0,
      expenses: expenses,
    );
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();
    final profit = workflow.profitEstimate;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Profit & Scenario Optimization"),
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
              title: "Financial Return Modeling",
              subtitle: "Gross revenues, itemized costs, net margins & 3 risk scenarios",
              icon: Icons.account_balance_wallet,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Result Overview Card
                    if (profit != null) ...[
                      _buildProfitSummaryCard(profit),
                      const SizedBox(height: 20),
                      _buildScenariosView(profit),
                      const SizedBox(height: 20),
                    ],

                    const SectionHeader(
                      title: "Production & Market Basis",
                      subtitle: "Synced with ML yield and current Mandi rates",
                    ),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _cropController, decoration: const InputDecoration(labelText: "Crop"))),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(controller: _areaController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Area (Ha)"))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _yieldController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Yield (Qtl/Ha)"))),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (₹/Qtl)"))),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const SectionHeader(
                      title: "Itemized Cultivation Expenses (₹)",
                      subtitle: "Input your actual or budgeted farm costs",
                    ),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _seedsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Seeds / Seedlings"))),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(controller: _fertController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Fertilizers"))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _protectionController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Crop Protection"))),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(controller: _irrigCostController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Irrigation Cost"))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _labourController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Labour / Hired Hands"))),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(controller: _machineryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Machinery / Diesel"))),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(child: TextFormField(controller: _transportController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Transport to Mandi"))),
                        const SizedBox(width: 10),
                        Expanded(child: TextFormField(controller: _miscController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Miscellaneous"))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: workflow.isLoading ? null : _calculateProfit,
                      icon: const Icon(Icons.analytics_outlined),
                      label: Text(workflow.isLoading ? "Calculating..." : "Compute Financial Projection"),
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

  Widget _buildProfitSummaryCard(ProfitEstimationModel p) {
    return Container(
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
            color: AppTheme.emerald.withOpacity(0.3),
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
              Text(
                "Base Net Profit (${p.crop})",
                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.earthAmber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${p.profitMarginPercentage.toStringAsFixed(1)}% Margin",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "₹${p.baseNetProfit.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricSub("Gross Revenue", "₹${p.baseGrossRevenue.toStringAsFixed(0)}"),
              _buildMetricSub("Cultivation Costs", "₹${p.totalExpenses.toStringAsFixed(0)}"),
              _buildMetricSub("Expected Harvest", "${p.expectedProductionQuintals.toStringAsFixed(0)} Qtl"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSub(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildScenariosView(ProfitEstimationModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: "Scenario Stress Testing",
          subtitle: "Conservative vs Base vs Optimistic outcomes",
        ),
        Row(
          children: [
            if (p.scenarios.containsKey('conservative'))
              Expanded(
                child: _buildScenarioCard(p.scenarios['conservative']!, AppTheme.alertCoral),
              ),
            const SizedBox(width: 8),
            if (p.scenarios.containsKey('base'))
              Expanded(
                child: _buildScenarioCard(p.scenarios['base']!, AppTheme.emerald),
              ),
            const SizedBox(width: 8),
            if (p.scenarios.containsKey('optimistic'))
              Expanded(
                child: _buildScenarioCard(p.scenarios['optimistic']!, const Color(0xFF2A9D8F)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildScenarioCard(ScenarioDetailModel sc, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sc.scenarioName.split(' ')[0],
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: accent),
          ),
          const SizedBox(height: 6),
          Text(
            "₹${(sc.netProfit / 1000).toStringAsFixed(1)}k",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark),
          ),
          const SizedBox(height: 2),
          Text(
            "${sc.profitMarginPct.toInt()}% margin",
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            "${sc.totalProductionQuintals.toInt()} Qtl @ ₹${sc.assumedPricePerQuintal.toInt()}",
            style: const TextStyle(fontSize: 9.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
