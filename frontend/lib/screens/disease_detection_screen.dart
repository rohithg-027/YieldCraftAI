import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/disease_model.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../widgets/custom_cards.dart';
import '../widgets/loading_indicator.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({super.key});

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  String _selectedCrop = "Rice";
  String _plantPart = "Leaves";
  final _symptomsController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageBase64;
  String? _imageFileName;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final farm = context.read<FarmProvider>().activeFarm;
    if (farm?.activeCrop != null && AppConstants.supportedCrops.contains(farm!.activeCrop)) {
      _selectedCrop = farm.activeCrop!;
    }
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageBase64 = base64Encode(bytes);
          _imageFileName = file.name;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      source == ImageSource.camera
                          ? "Photo captured! Tap 'Run AI Health Diagnostic' below."
                          : "Photo selected! Ready for Gemini diagnostic.",
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.emerald,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not access camera/photo: $e"),
            backgroundColor: AppTheme.alertCoral,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imageBase64 = null;
      _imageFileName = null;
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Upload Plant Foliage Photo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select photo capture source for Gemini AI disease analysis",
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.emerald),
                ),
                title: const Text("Take Photo with Camera", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Capture live symptoms on farm in daylight", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.sageLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.emerald),
                ),
                title: const Text("Choose from Gallery / Files", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Upload saved leaf photo from your phone", style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyzeDisease() async {
    if (_imageBase64 == null) {
      _showImageSourceSheet();
      return;
    }

    final farm = context.read<FarmProvider>().activeFarm;
    final workflow = context.read<FarmingWorkflowProvider>();

    final success = await workflow.analyzeDisease(
      farmId: farm?.farmId,
      crop: _selectedCrop,
      plantPart: _plantPart,
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      imageBase64: _imageBase64!,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(workflow.errorMessage ?? "Diagnostic failed. Please check network connection."),
          backgroundColor: AppTheme.alertCoral,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = context.watch<FarmingWorkflowProvider>();
    final analysis = workflow.latestDiseaseAnalysis;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("AI Crop Doctor"),
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
              title: "Multimodal Crop Pathology",
              subtitle: "Gemini Vision foliage analysis, disease detection & IPM treatment plan",
              icon: Icons.health_and_safety,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Photo Capture / Preview Box
                  _buildPhotoSection(),
                  const SizedBox(height: 16),

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
                          value: _plantPart,
                          decoration: const InputDecoration(labelText: "Plant Part"),
                          items: const [
                            DropdownMenuItem(value: "Leaves", child: Text("Leaves")),
                            DropdownMenuItem(value: "Stem", child: Text("Stem")),
                            DropdownMenuItem(value: "Fruit", child: Text("Fruit")),
                            DropdownMenuItem(value: "Flower", child: Text("Flower")),
                            DropdownMenuItem(value: "Root", child: Text("Root")),
                          ],
                          onChanged: (val) => setState(() => _plantPart = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _symptomsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Observed Symptoms & Notes (Optional)",
                      hintText: "e.g. Yellowing leaf margins, dark concentric spots, fungal powder",
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Diagnostic Action Button
                  if (_imageBase64 == null)
                    OutlinedButton.icon(
                      onPressed: _showImageSourceSheet,
                      icon: const Icon(Icons.add_a_photo, color: AppTheme.emerald),
                      label: const Text(
                        "Upload Photo to Enable AI Diagnostic",
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.emerald),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.emerald, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: workflow.isLoading ? null : _analyzeDisease,
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(
                        workflow.isLoading ? "Diagnosing with Gemini Vision..." : "Run AI Health Diagnostic (Gemini Model)",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.emerald,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (workflow.isLoading)
                    const AgriculturalLoadingIndicator(
                      statusMessage: "Examining foliar lesions with Gemini Multimodal AI & matching pathology databases...",
                    )
                  else if (analysis != null)
                    _buildDiagnosticReport(analysis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    if (_imageBytes != null) {
      // Photo Uploaded & Previewed
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.emerald, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.emerald.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Stack(
              children: [
                Image.memory(
                  _imageBytes!,
                  height: 210,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.mintAccent, size: 14),
                        SizedBox(width: 6),
                        Text(
                          "Photo Uploaded (Ready for Gemini)",
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                    tooltip: "Remove Photo",
                    onPressed: _clearImage,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppTheme.sageLight.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _imageFileName ?? "Leaf image ready",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, size: 16, color: AppTheme.emerald),
                    label: const Text("Retake", style: TextStyle(fontSize: 12, color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library, size: 16, color: AppTheme.emerald),
                    label: const Text("Gallery", style: TextStyle(fontSize: 12, color: AppTheme.emerald, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // No Photo Yet: Prominent Capture Card
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.sageLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.emerald, size: 36),
          ),
          const SizedBox(height: 12),
          const Text(
            "Upload or Capture Crop Photo",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            "Photograph diseased foliage, spots, or discoloration to activate Gemini Vision pathology",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text("Take Photo"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppTheme.emerald),
                  label: const Text("From Gallery", style: TextStyle(color: AppTheme.emerald)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.emerald),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.sageLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.emerald),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Tip: Close-up focus under natural light gives best accuracy",
                    style: TextStyle(fontSize: 11, color: AppTheme.textDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticReport(DiseaseAnalysisModel a) {
    final bool isHealthy = a.isHealthy;
    final Color statusColor = isHealthy ? AppTheme.emerald : (a.severity.toLowerCase() == 'severe' ? AppTheme.alertCoral : AppTheme.earthAmber);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Condition & Severity
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isHealthy ? Icons.eco : Icons.healing,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          a.cropIdentified.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.mintAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "${a.confidenceLevel} Confidence",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.conditionDetected,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  a.severity.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // Model Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.sageLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppTheme.emerald, size: 14),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Diagnosed by Google Gemini Multimodal Vision & Plant Pathology Engine",
                    style: TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          _buildListSection("Visible Symptoms Observed", a.visibleSymptoms, Icons.visibility_outlined),
          _buildListSection("Possible Causes & Pathogens", a.possibleCauses, Icons.help_outline),
          _buildListSection("Recommended Treatment Plan (IPM)", a.treatmentPlan, Icons.medical_services_outlined),
          _buildListSection("Preventive Cultural Practices", a.preventionMeasures, Icons.shield_outlined),

          if (a.expertAdvice.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.mintAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.emerald.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.school_outlined, color: AppTheme.emerald, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Agronomic Extension Advisory",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.expertAdvice,
                          style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.sageLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.book_outlined, color: AppTheme.emerald, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Auto-logged into your farm's digital diary history",
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppTheme.emerald),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 13)),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.3)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
