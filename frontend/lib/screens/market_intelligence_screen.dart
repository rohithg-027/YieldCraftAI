import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/market_model.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';

class MarketIntelligenceScreen extends StatefulWidget {
  const MarketIntelligenceScreen({super.key});

  @override
  State<MarketIntelligenceScreen> createState() => _MarketIntelligenceScreenState();
}

class _MarketIntelligenceScreenState extends State<MarketIntelligenceScreen> {
  final _commodityController = TextEditingController();
  final _districtController = TextEditingController();
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    final farm = context.read<FarmProvider>().activeFarm;
    _selectedState = farm?.state;
    _commodityController.text = farm?.activeCrop ?? "Rice";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchPrices();
    });
  }

  @override
  void dispose() {
    _commodityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _searchPrices() {
    final workflow = context.read<FarmingWorkflowProvider>();
    workflow.fetchMarketPrices(
      commodity: _commodityController.text.trim(),
      state: _selectedState,
      district: _districtController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Government Mandi Intelligence"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          const GradientHeader(
            title: "APMC Mandi Commodity Rates",
            subtitle: "Official Agmarknet wholesale arrivals & modal price observations",
            icon: Icons.storefront,
          ),
          // Search & Filter Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _commodityController,
                        decoration: const InputDecoration(
                          labelText: "Commodity",
                          hintText: "e.g. Rice, Wheat, Cotton",
                          prefixIcon: Icon(Icons.search, size: 20),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onFieldSubmitted: (_) => _searchPrices(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        value: _selectedState,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: "State",
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text("All States")),
                          ...AppConstants.indianStates.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedState = val);
                          _searchPrices();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        decoration: InputDecoration(
                          labelText: "Market / District (Optional)",
                          hintText: "Search specific mandi or leave blank",
                          prefixIcon: const Icon(Icons.storefront, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          suffixIcon: _districtController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() => _districtController.clear());
                                    _searchPrices();
                                  },
                                )
                              : null,
                        ),
                        onFieldSubmitted: (_) => _searchPrices(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppTheme.emerald),
                      onPressed: _searchPrices,
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quick Commodity Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.clear_all, size: 14),
                        label: const Text("All APMC Markets"),
                        onPressed: () {
                          setState(() => _districtController.clear());
                          _searchPrices();
                        },
                      ),
                      const SizedBox(width: 6),
                      ...['Rice', 'Wheat', 'Cotton', 'Maize', 'Soybean', 'Chickpea', 'Groundnut', 'Sugarcane', 'Tomato', 'Onion', 'Potato', 'Pomegranate', 'Coffee'].map((crop) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(Icons.eco, size: 13, color: AppTheme.emerald),
                              label: Text(crop),
                              backgroundColor: _commodityController.text.toLowerCase() == crop.toLowerCase()
                                  ? AppTheme.sageLight
                                  : null,
                              onPressed: () {
                                setState(() => _commodityController.text = crop);
                                _searchPrices();
                              },
                            ),
                          )),

                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Source and Freshness Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.sageLight.withOpacity(0.4),
            child: const Row(
              children: [
                Icon(Icons.verified, size: 14, color: AppTheme.emerald),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Source: Ministry of Agriculture & data.gov.in (9ef84268-d588-465a-a308-a864a43d0070)",
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

          // Price List
          Expanded(
            child: workflow.isLoading
                ? const Center(child: CircularProgressIndicator())
                : workflow.marketPrices.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text(
                                "No Mandi observations found",
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Try searching by commodity name or selecting 'All States'",
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: workflow.marketPrices.length,
                        itemBuilder: (context, index) {
                          final p = workflow.marketPrices[index];
                          return _buildPriceCard(p);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(MarketPriceRecordModel p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.sageLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.grass, color: AppTheme.emerald, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.commodity,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          "Variety: ${p.variety}",
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${p.modalPrice.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      p.priceUnit,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.store, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      "${p.market}, ${p.district} (${p.state})",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Text(
                  "Range: ₹${p.minPrice.toInt()} - ₹${p.maxPrice.toInt()}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Arrival: ${p.arrivalDate}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                const Text(
                  "Verified APMC",
                  style: TextStyle(fontSize: 10, color: AppTheme.emerald, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
