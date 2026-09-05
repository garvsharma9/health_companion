import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anomaly_event.dart';
import '../providers/ml_risk_provider.dart';
import '../services/hive_storage_service.dart';
import '../theme/app_theme.dart';

class HealthInsightsScreen extends ConsumerStatefulWidget {
  const HealthInsightsScreen({super.key});

  @override
  ConsumerState<HealthInsightsScreen> createState() => _HealthInsightsScreenState();
}

class _HealthInsightsScreenState extends ConsumerState<HealthInsightsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mlResult = ref.watch(mlInferenceProvider);
    final anomalyHistory = ref.watch(anomalyHistoryProvider);
    final cachedHistory = HiveStorageService.getCachedTelemetryHistory();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.cardDark : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Analytics & AI Insights"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. ON-DEVICE AI EXECUTION METRICS ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlueLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlueLight.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.memory,
                        color: AppTheme.primaryBlueLight, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mlResult.modelName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.flash_on,
                                    size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  "Inference: ${mlResult.inferenceTimeMs} ms",
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.lock,
                                    size: 12, color: AppTheme.healthyGreen),
                                SizedBox(width: 2),
                                Text(
                                  "100% Offline / Zero-Cloud",
                                  style: TextStyle(
                                      fontSize: 11, color: AppTheme.healthyGreen, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),

            // --- 2. VITALS TREND CHART ---
            Text(
              "Heart Rate Trends (Recent Packets)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 140,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: cachedHistory.isEmpty
                  ? Center(
                      child: Text(
                        "Collecting vitals telemetry for graph...",
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        cachedHistory.take(12).length,
                        (index) {
                          final item = cachedHistory[index];
                          final normalizedHrHeight =
                              (item.heartRate / 160.0 * 75.0).clamp(10.0, 75.0);
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: 10,
                                height: normalizedHrHeight,
                                decoration: BoxDecoration(
                                  color: item.heartRate > 100
                                      ? AppTheme.criticalRed
                                      : AppTheme.primaryBlueLight,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.heartRate.toStringAsFixed(0),
                                style: TextStyle(
                                    fontSize: 9, color: subtitleColor),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // --- 3. HISTORICAL ANOMALY EVENT TIMELINE ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Logged Health Anomalies (Hive Storage)",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppTheme.primaryBlueLight, size: 20),
                  onPressed: () {
                    ref.read(anomalyHistoryProvider.notifier).refresh();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (anomalyHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: Center(
                  child: Text(
                    "No health anomalies recorded yet.\nAll vitals are safe and within normal baseline.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ),
              )
            else
              ...anomalyHistory.map(
                (event) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _getSeverityColor(event.severity).withValues(alpha: 0.4),
                    ),
                  ),
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
                                  fontSize: 10, color: subtitleColor.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
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
