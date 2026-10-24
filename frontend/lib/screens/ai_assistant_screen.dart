import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/farm_provider.dart';
import '../state/farming_workflow_provider.dart';
import '../core/app_theme.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _includeFarmContext = true;
  bool _isSending = false;

  final List<String> _promptSuggestions = [
    'Recommend best crops for my current soil pH and NPK',
    'How do I treat yellow leaf spots on Tomato naturally?',
    'What is the ideal irrigation schedule for Wheat heading stage?',
    'Explain the current Mandi price trends for Soybean',
    'Tips to improve organic carbon in clay soil',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textOverride]) async {
    final text = (textOverride ?? _messageController.text).trim();
    if (text.isEmpty || _isSending) return;

    final farm = Provider.of<FarmProvider>(context, listen: false).selectedFarm;
    final workflow = Provider.of<FarmingWorkflowProvider>(context, listen: false);

    _messageController.clear();
    setState(() => _isSending = true);
    _scrollToBottom();

    Map<String, dynamic>? farmContext;
    if (_includeFarmContext && farm != null) {
      farmContext = {
        'farm_name': farm.name,
        'location': farm.village != null && farm.village!.isNotEmpty ? '${farm.village}, ${farm.state}' : farm.state,
        'area': '${farm.area} ${farm.areaUnit}',
        'soil_type': farm.soilType,
        'irrigation_source': farm.irrigationSource ?? "Rainfed",
        'active_crop': farm.activeCrop ?? "None",
        if (workflow.latestSoilProfile != null)
          'soil_metrics': {
            'N': workflow.latestSoilProfile!.nitrogen,
            'P': workflow.latestSoilProfile!.phosphorus,
            'K': workflow.latestSoilProfile!.potassium,
            'pH': workflow.latestSoilProfile!.ph,
            'moisture': workflow.latestSoilProfile!.moisture,
          },
      };
    }

    await workflow.sendAssistantMessage(
      text,
      farmId: farm?.id,
      farmContext: farmContext,
    );

    if (mounted) {
      setState(() => _isSending = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final farm = Provider.of<FarmProvider>(context).selectedFarm;
    final workflow = Provider.of<FarmingWorkflowProvider>(context);
    final theme = Theme.of(context);

    final messages = workflow.chatMessages;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Dashboard",
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Farming Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              farm != null ? 'Grounded in ${farm.name} context' : 'General Agronomy Expert',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation',
            onPressed: () {
              workflow.clearChat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Context indicator bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.emerald.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.hub, size: 16, color: AppTheme.emerald),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    farm != null
                        ? 'Using live sensors, soil & weather context from ${farm.name}'
                        : 'No farm selected. Advice will be general.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
                  ),
                ),
                FilterChip(
                  label: const Text('Farm Context', style: TextStyle(fontSize: 11)),
                  selected: _includeFarmContext,
                  onSelected: (val) {
                    setState(() => _includeFarmContext = val);
                  },
                ),
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyWelcome(theme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isSending) {
                        return _buildTypingIndicator();
                      }
                      final msg = messages[index];
                      final isUser = msg['role'] == 'user';
                      return _buildMessageBubble(isUser, msg['content'] ?? '');
                    },
                  ),
          ),

          // Suggested Prompts
          if (messages.length <= 2)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _promptSuggestions.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  return ActionChip(
                    avatar: Icon(Icons.auto_awesome, size: 14, color: AppTheme.emerald),
                    label: Text(_promptSuggestions[idx], style: const TextStyle(fontSize: 12)),
                    onPressed: () => _sendMessage(_promptSuggestions[idx]),
                  );
                },
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask anything about crops, pests, soil, prices...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.emerald,
                    radius: 22,
                    child: IconButton(
                      icon: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _isSending ? null : () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWelcome(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology, size: 48, color: AppTheme.emerald),
            ),
            const SizedBox(height: 16),
            Text(
              'YieldCraft Agricultural AI Assistant',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Grounded in your farm soil metrics, local Mandi commodities, and verified agricultural guidance.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Tap a suggestion below or type your inquiry:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(bool isUser, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.emerald,
              child: const Icon(Icons.eco, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.emerald : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser ? null : Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.earthAmber,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.emerald,
            child: const Icon(Icons.eco, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.emerald),
                ),
                const SizedBox(width: 10),
                const Text('Consulting agronomy models & Gemini...', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
