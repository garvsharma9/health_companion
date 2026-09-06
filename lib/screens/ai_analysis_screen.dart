import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_companion/theme/app_theme.dart';
import 'package:health_companion/widgets/glass_card.dart';
import '../models/anomaly_event.dart';
import '../providers/ml_risk_provider.dart';
import '../widgets/ai_chat_bottom_sheet.dart';

class AIAnalysisScreen extends ConsumerStatefulWidget {
  const AIAnalysisScreen({super.key});

  @override
  ConsumerState<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends ConsumerState<AIAnalysisScreen> {
  bool _isAnomaliesExpanded = false;

  void _openChatbot(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AIChatBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    
    // Providers for Analytics sections
    final mlResult = ref.watch(mlInferenceProvider);
    final anomalyHistory = ref.watch(anomalyHistoryProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          'AI Health Analysis Report',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Stack(
        children: [
          // Background ambient glows
          if (isDark) ...[
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.electricCyan.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 120,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.visionPurple.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],

          // Main content scroll view
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallScore(context),
                const SizedBox(height: 24),
                
                // Analytics Components Merged Here
                _buildEdgeAIExecution(context, mlResult),
                const SizedBox(height: 24),
                
                
                _buildDetailedSummary(context),
                const SizedBox(height: 24),
                
                _buildRecommendationsList(context),
                const SizedBox(height: 24),
                
                _buildActionableTips(context),
                const SizedBox(height: 24),
                
                _buildKeyInsights(context),
                const SizedBox(height: 24),
                
                _buildAnomalyHistory(context, anomalyHistory),
              ],
            ),
          ),

          // --- IN-BUILT AI CHATBOT BUTTON AT BOTTOM LEFT CORNER ---
          Positioned(
            left: 20,
            bottom: 24,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openChatbot(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.electricCyan, AppTheme.visionPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.electricCyan.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Ask AI Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallScore(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black54;
    final scoreNumColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;

    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      glowColor: AppTheme.healthyGreen,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'COMPREHENSIVE HEALTH SCORE',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: const [
                      Text(
                        'Optimal & Stable',
                        style: TextStyle(
                          color: AppTheme.healthyGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.check_circle, color: AppTheme.healthyGreen, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on last 24h biometric & sensor telemetry',
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 68,
                width: 68,
                child: CircularProgressIndicator(
                  value: 0.88,
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppTheme.healthyGreen.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.healthyGreen),
                ),
              ),
              Text(
                '88',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scoreNumColor,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildEdgeAIExecution(BuildContext context, dynamic mlResult) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ON-DEVICE EDGE AI EXECUTION",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8E8E93),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.memory,
                    color: AppTheme.electricCyan, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mlResult.modelName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on,
                                size: 12, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              "Inference: ${mlResult.inferenceTimeMs} ms",
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.amber, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock,
                                size: 12, color: AppTheme.healthyGreen),
                            SizedBox(width: 3),
                            Text(
                              "100% Offline Privacy",
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.healthyGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailedSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final bodyColor = isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF2C2C2E);

    return GlassCard(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: AppTheme.electricCyan, size: 22),
              const SizedBox(width: 10),
              Text(
                'Detailed Executive Summary',
                style: TextStyle(
                  color: headerColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Over the past 24-hour evaluation cycle, your vital signals demonstrated high homeostasis and healthy autonomic adaptability. Resting heart rate averaged 68 BPM with normal circadian dip during REM sleep cycles.",
            style: TextStyle(
              color: bodyColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _buildBulletPoint(context, "Heart Rate Stability", "Normal range (62 - 108 BPM). Peak recorded during 3:15 PM activity with rapid 8-minute recovery."),
          _buildBulletPoint(context, "Blood Oxygen (SpO2)", "Maintained high average of 98.4% without nocturnal hypoxia dips."),
          _buildBulletPoint(context, "Thermoregulation", "Body temp steady at 36.6°C. Minor 0.3°C drop observed at 3:00 AM due to room temperature dip."),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String label, String detail) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final detailColor = isDark ? Colors.white70 : const Color(0xFF3C3C43);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.electricCyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, height: 1.4, color: detailColor),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: TextStyle(fontWeight: FontWeight.bold, color: labelColor),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark ? const Color(0xFF9898A0) : Colors.black54;
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final descColor = isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF3C3C43);

    final recs = [
      {
        'priority': 'HIGH',
        'color': AppTheme.appleHeartRed,
        'title': 'Hydration Boost Needed',
        'desc': 'Ambient humidity dropped to 35% this afternoon. Increase water intake by 500ml to offset dry air respiratory stress.',
      },
      {
        'priority': 'MEDIUM',
        'color': AppTheme.warningAmber,
        'title': 'Adjust Nocturnal Temperature',
        'desc': 'Room temperature fell to 18°C around 3 AM. Set room thermostat to 20°C–21°C for optimal deep sleep continuity.',
      },
      {
        'priority': 'LOW',
        'color': AppTheme.healthyGreen,
        'title': 'Maintain Daily Light Walking',
        'desc': 'Your morning 25-minute brisk walk improved cardiac recovery speed by 15%. Keep this consistent!',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI PERSONALIZED RECOMMENDATIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: sectionTitleColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        ...recs.map(
          (rec) => Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GlassCard(
              padding: const EdgeInsets.all(16.0),
              glowColor: rec['color'] as Color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (rec['color'] as Color).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: (rec['color'] as Color).withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          rec['priority'] as String,
                          style: TextStyle(
                            color: rec['color'] as Color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec['title'] as String,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                     rec['desc'] as String,
                    style: TextStyle(
                      color: descColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionableTips(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark ? const Color(0xFF9898A0) : Colors.black54;
    final tipTextColor = isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF2C2C2E);

    final tips = [
      {
        'icon': Icons.nightlight_round,
        'color': AppTheme.visionPurple,
        'title': 'Sleep Hygiene',
        'tip': 'Maintain consistent 10:30 PM bedtimes to optimize slow-wave sleep duration.',
      },
      {
        'icon': Icons.water_drop,
        'color': AppTheme.appleOxygenCyan,
        'title': 'Hydration Schedule',
        'tip': 'Sip water hourly rather than gulping large volumes at once for better cell retention.',
      },
      {
        'icon': Icons.directions_run,
        'color': AppTheme.healthyGreen,
        'title': 'Cardio Pacing',
        'tip': 'Keep zone-2 heart rate (110–125 BPM) during light exercise to build cardiovascular endurance.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACTIONABLE LIFESTYLE TIPS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: sectionTitleColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(14.0),
                  glowColor: tip['color'] as Color,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(tip['icon'] as IconData, color: tip['color'] as Color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            tip['title'] as String,
                            style: TextStyle(
                              color: tip['color'] as Color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tip['tip'] as String,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: tipTextColor,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeyInsights(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sectionTitleColor = isDark ? const Color(0xFF9898A0) : Colors.black54;
    final titleColor = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final detailColor = isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF3C3C43);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TELEMETRY INSIGHTS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: sectionTitleColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.appleHeartRed.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: AppTheme.appleHeartRed, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vagal Tone & Recovery',
                      style: TextStyle(color: titleColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Heart rate recovery post-activity averaged 18 BPM drop in 60s, reflecting strong vagal tone.',
                      style: TextStyle(color: detailColor, fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnomalyHistory(BuildContext context, List<dynamic> anomalyHistory) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1E);

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final filteredAnomalyHistory = anomalyHistory.where((event) {
      if (event.riskType == RiskType.heatStroke) {
        return event.timestamp.isAfter(sevenDaysAgo);
      }
      return true;
    }).toList();

    final displayList = !_isAnomaliesExpanded && filteredAnomalyHistory.length > 5
        ? filteredAnomalyHistory.take(5).toList()
        : filteredAnomalyHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  "LOGGED HEALTH ANOMALIES",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh,
                  color: AppTheme.electricCyan, size: 20),
              onPressed: () {
                ref.read(anomalyHistoryProvider.notifier).refresh();
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredAnomalyHistory.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                "No health anomalies recorded yet.\nAll vitals are safe and within normal baseline.",
                textAlign: TextAlign.center,
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ),
          )
        else ...[
          ...displayList.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                glowColor: _getSeverityColor(event.severity),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getAnomalyIcon(event.riskType),
                      color: _getSeverityColor(event.severity),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _getSeverityColor(event.severity),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.description,
                            style: TextStyle(
                                fontSize: 12, color: textColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Recommendation: ${event.recommendation}",
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: subtitleColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTimestamp(event.timestamp),
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (filteredAnomalyHistory.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAnomaliesExpanded = !_isAnomaliesExpanded;
                    });
                  },
                  icon: Icon(
                    _isAnomaliesExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.electricCyan,
                  ),
                  label: Text(
                    _isAnomaliesExpanded ? "View Less" : "View More (${filteredAnomalyHistory.length - 5})",
                    style: const TextStyle(
                      color: AppTheme.electricCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan.withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ),
        ]
      ],
    );
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.low:
        return AppTheme.healthyGreen;
      case AnomalySeverity.medium:
        return AppTheme.warningAmber;
      case AnomalySeverity.high:
        return Colors.orange;
      case AnomalySeverity.critical:
        return AppTheme.criticalRed;
    }
  }

  IconData _getAnomalyIcon(RiskType riskType) {
    switch (riskType) {
      case RiskType.heatStroke:
        return Icons.wb_sunny;
      case RiskType.respiratory:
        return Icons.masks;
      case RiskType.cardiac:
        return Icons.favorite;
      case RiskType.fallDetected:
        return Icons.accessibility_new;
      case RiskType.environmentalSpike:
        return Icons.air;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _formatTimestamp(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')} - ${time.day}/${time.month}/${time.year}";
  }
}
