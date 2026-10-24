import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/empty_state_view.dart';

class DigitalDiaryScreen extends StatefulWidget {
  const DigitalDiaryScreen({super.key});

  @override
  State<DigitalDiaryScreen> createState() => _DigitalDiaryScreenState();
}

class _DigitalDiaryScreenState extends State<DigitalDiaryScreen> {
  String _selectedCategoryFilter = "all";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farm = context.read<FarmProvider>().activeFarm;
      if (farm != null && mounted) {
        context.read<FarmingWorkflowProvider>().loadDiary(farm.farmId);
      }
    });
  }

  void _showAddEntryDialog() {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final costController = TextEditingController(text: "0");
    String selectedCategory = "irrigation_log";

    showModalBottomSheet(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "New Farm Diary Entry",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: "Activity Category"),
                  items: const [
                    DropdownMenuItem(value: "irrigation_log", child: Text("💧 Irrigation Log")),
                    DropdownMenuItem(value: "fertilizer_application", child: Text("🌱 Fertilizer Application")),
                    DropdownMenuItem(value: "activity", child: Text("🌾 General Field Operation")),
                    DropdownMenuItem(value: "disease_check", child: Text("🩺 Crop Health Check")),
                    DropdownMenuItem(value: "harvest", child: Text("🚜 Harvesting / Yield")),
                  ],
                  onChanged: (val) => setModalState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title *",
                    hintText: "e.g. Completed 2-hr Drip Irrigation Cycle",
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Notes & Observations *",
                    hintText: "Record field moisture, dosage, water run time or growth milestones...",
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Operational Cost (₹)",
                    prefixText: "₹ ",
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    Navigator.pop(ctx);

                    final farm = context.read<FarmProvider>().activeFarm;
                    if (farm == null) return;

                    await context.read<FarmingWorkflowProvider>().addDiaryEntry(farm.farmId, {
                      'category': selectedCategory,
                      'title': titleController.text.trim(),
                      'notes': notesController.text.trim(),
                      'cost': double.tryParse(costController.text) ?? 0.0,
                      'crop': farm.activeCrop,
                    });
                  },
                  child: const Text("Save Diary Entry"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'fertilizer_application':
        return Icons.eco;
      case 'irrigation_log':
        return Icons.water_drop;
      case 'disease_check':
        return Icons.health_and_safety;
      case 'harvest':
        return Icons.agriculture;
      default:
        return Icons.event_note;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'fertilizer_application':
        return AppTheme.emerald;
      case 'irrigation_log':
        return const Color(0xFF0077B6);
      case 'disease_check':
        return AppTheme.alertCoral;
      case 'harvest':
        return AppTheme.earthAmber;
      default:
        return AppTheme.primaryGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();

    final filteredEntries = workflow.diaryEntries.where((entry) {
      if (_selectedCategoryFilter == "all") return true;
      final cat = entry['category']?.toString().toLowerCase() ?? '';
      return cat == _selectedCategoryFilter.toLowerCase();
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Digital Farm Diary"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEntryDialog,
        backgroundColor: AppTheme.emerald,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_calendar),
        label: const Text("Log Activity"),
      ),
      body: Column(
        children: [
          const GradientHeader(
            title: "Farmer's Digital Diary",
            subtitle: "Maintain field operations, irrigation logs, fertilizer schedules & expenses",
            icon: Icons.book,
          ),
          // Category Quick-Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("all", "All Entries (${workflow.diaryEntries.length})", Icons.list_alt),
                const SizedBox(width: 8),
                _buildFilterChip("irrigation_log", "💧 Irrigation Logs", Icons.water_drop),
                const SizedBox(width: 8),
                _buildFilterChip("fertilizer_application", "🌱 Fertilizer", Icons.eco),
                const SizedBox(width: 8),
                _buildFilterChip("disease_check", "🩺 Health Checks", Icons.health_and_safety),
                const SizedBox(width: 8),
                _buildFilterChip("harvest", "🚜 Harvest", Icons.agriculture),
              ],
            ),
          ),
          Expanded(
            child: filteredEntries.isEmpty
                ? EmptyStateView(
                    icon: _selectedCategoryFilter == "irrigation_log" ? Icons.water_drop_outlined : Icons.book_outlined,
                    title: _selectedCategoryFilter == "irrigation_log"
                        ? "No Irrigation Logs Recorded"
                        : "No Diary Entries Found",
                    description: _selectedCategoryFilter == "irrigation_log"
                        ? "Run Irrigation Advisory or tap Log Activity to maintain root-zone watering schedules."
                        : "Keep track of sowing dates, fertilizer schedules, water applications, and expenses.",
                    buttonText: "Log First Activity",
                    onButtonPressed: _showAddEntryDialog,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final item = filteredEntries[index];
                      final cat = item['category'] ?? 'activity';
                      final color = _getCategoryColor(cat);
                      final icon = _getCategoryIcon(cat);
                      final cost = (item['cost'] as num?)?.toDouble() ?? 0.0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                      color: color.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: color, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] ?? 'Farm Activity',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                        Text(
                                          item['created_at'] != null
                                              ? item['created_at'].toString().split('T')[0]
                                              : 'Today',
                                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (cost > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        "₹${cost.toStringAsFixed(0)}",
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                              if (item['notes'] != null && item['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  item['notes'],
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.3),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, IconData icon) {
    final isSelected = _selectedCategoryFilter == filterKey;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedCategoryFilter = filterKey;
        });
      },
    );
  }
}
