import 'package:flutter/material.dart';
import 'package:health_companion/theme/app_theme.dart';

class AIChatBottomSheet extends StatefulWidget {
  const AIChatBottomSheet({super.key});

  @override
  State<AIChatBottomSheet> createState() => _AIChatBottomSheetState();
}

class _AIChatBottomSheetState extends State<AIChatBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': "Hello! I am your AI Health Companion. I've analyzed your 24-hour vitals and environmental metrics. How can I assist your wellness journey today?",
      'time': 'Just now',
    },
  ];

  final List<String> _quickPrompts = [
    "Why did my HR spike at 3 PM?",
    "How is my SpO2 level today?",
    "Tips for better sleep tonight",
    "Explain my environmental AQI impact",
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text.trim(),
        'time': 'Just now',
      });
      _textController.clear();
    });

    // Simulate AI response after short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': _generateResponse(text),
          'time': 'Just now',
        });
      });
    });
  }

  String _generateResponse(String userQuery) {
    final query = userQuery.toLowerCase();
    if (query.contains('hr') || query.contains('heart rate') || query.contains('spike')) {
      return "Your heart rate reached 108 BPM around 3:15 PM during your light afternoon activity. It quickly recovered to normal (72 BPM) within 8 minutes, indicating healthy cardiac elasticity!";
    } else if (query.contains('spo2') || query.contains('oxygen')) {
      return "Your SpO2 averaged 98.4% today, which is excellent! Oxygen levels remained steady even during rest, showing healthy respiratory output.";
    } else if (query.contains('sleep') || query.contains('night')) {
      return "To optimize sleep tonight: keep your bedroom temperature between 19°C–21°C, avoid heavy meals 2 hours before bedtime, and maintain ambient room humidity around 45%–50%.";
    } else if (query.contains('aqi') || query.contains('environment') || query.contains('temp')) {
      return "Current indoor AQI is 38 (Good). Humidity dropped to 35% in the afternoon—we recommend keeping a humidifier nearby or drinking extra water to stay hydrated.";
    } else {
      return "Based on your telemetric logs, your overall health parameters are stable with an 88/100 score. Stay hydrated, keep active, and reach out if you feel any fatigue!";
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14141B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppTheme.electricCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Health Assistant',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.healthyGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online • Continuous Vitals Monitoring',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1),

          // Quick Prompt Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _quickPrompts.length,
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(
                      prompt,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    backgroundColor: AppTheme.electricCyan.withValues(alpha: 0.15),
                    side: BorderSide(color: AppTheme.electricCyan.withValues(alpha: 0.3)),
                    onPressed: () => _sendMessage(prompt),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Chat Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] as bool;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppTheme.electricCyan
                          : (isDark ? const Color(0xFF22222E) : const Color(0xFFF2F2F7)),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      border: isUser
                          ? null
                          : Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12,
                            ),
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: TextStyle(
                        color: isUser ? Colors.white : (isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    onSubmitted: _sendMessage,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Ask about your vitals, sleep, or tips...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E28) : const Color(0xFFF2F2F7),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                  ),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
