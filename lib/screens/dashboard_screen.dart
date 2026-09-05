import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anomaly_event.dart';
import '../providers/telemetry_provider.dart';
import '../providers/ml_risk_provider.dart';
import '../providers/ble_provider.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final telemetry = ref.watch(currentTelemetryProvider);
    final mlResult = ref.watch(mlInferenceProvider);
    final bleState = ref.watch(bleProvider);

    final Color riskColor = _getRiskColor(mlResult.overallSeverity);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.cardDark : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bleState.isConnected
                    ? AppTheme.healthyGreen.withValues(alpha: 0.15)
                    : (bleState.isScanning
                        ? Colors.amber.withValues(alpha: 0.15)
                        : Colors.grey.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: bleState.isConnected
                      ? AppTheme.healthyGreen
                      : (bleState.isScanning ? Colors.amber : Colors.grey),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    bleState.isConnected
                        ? Icons.bluetooth_connected
                        : (bleState.isScanning
                            ? Icons.bluetooth_searching
                            : Icons.bluetooth_disabled),
                    size: 14,
                    color: bleState.isConnected
                        ? AppTheme.healthyGreen
                        : (bleState.isScanning ? Colors.amber : Colors.grey),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    bleState.isConnected
                        ? "ESP32 WEARABLE ACTIVE"
                        : (bleState.isScanning
                            ? "SCANNING FOR WEARABLE"
                            : "WEARABLE DISCONNECTED"),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: bleState.isConnected
                          ? AppTheme.healthyGreen
                          : (bleState.isScanning ? Colors.amber : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Icon(Icons.battery_charging_full, size: 18, color: AppTheme.healthyGreen),
            const SizedBox(width: 4),
            Text(
              "${telemetry.batteryLevel}%",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "Settings & Demo Controls",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. OVERALL RISK GAUGE & EARLY WARNING RING ---
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: riskColor.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: riskColor.withValues(alpha: 0.08),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Circular Score Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: mlResult.riskScore / 100.0,
                          strokeWidth: 8,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            child: Text(
                              "${mlResult.riskScore.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: riskColor,
                              ),
                            ),
                          ),
                          Text(
                            "RISK",
                            style: TextStyle(
                                fontSize: 9, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSeverityLabel(mlResult.overallSeverity),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mlResult.primaryRecommendation,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. ACTIVE ANOMALY ALERT BANNER ---
            if (mlResult.activeAnomalies.isNotEmpty) ...[
              ...mlResult.activeAnomalies.map(
                (anomaly) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(anomaly.severity).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getSeverityColor(anomaly.severity),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: _getSeverityColor(anomaly.severity),
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anomaly.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _getSeverityColor(anomaly.severity),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              anomaly.description,
                              style: TextStyle(
                                  fontSize: 12, color: textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // --- 3. LIVE VITALS GRID ---
            Text(
              "Body Vitals",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildVitalCard(
                    context,
                    title: "Heart Rate",
                    value: telemetry.heartRate.toStringAsFixed(0),
                    unit: "BPM",
                    baseline: "60-100 BPM",
                    icon: Icons.favorite,
                    iconColor: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVitalCard(
                    context,
                    title: "SpO2 Oxygen",
                    value: telemetry.spO2.toStringAsFixed(1),
                    unit: "%",
                    baseline: "95-100%",
                    icon: Icons.water_drop,
                    iconColor: AppTheme.primaryBlueLight,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildVitalCard(
                    context,
                    title: "Body Temp",
                    value: telemetry.bodyTemp.toStringAsFixed(1),
                    unit: "°C",
                    baseline: "36.5-37.5°C",
                    icon: Icons.thermostat,
                    iconColor: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- 4. ENVIRONMENTAL AWARENESS ---
            Text(
              "Environmental Awareness",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEnvItem(
                    context,
                    label: "Ambient Temp",
                    value: "${telemetry.ambientTemp.toStringAsFixed(1)}°C",
                    icon: Icons.wb_sunny_outlined,
                    color: Colors.amber,
                  ),
                  Container(width: 1, height: 35, color: isDark ? Colors.white12 : Colors.black12),
                  _buildEnvItem(
                    context,
                    label: "Humidity",
                    value: "${telemetry.humidity.toStringAsFixed(0)}%",
                    icon: Icons.cloud_queue,
                    color: AppTheme.primaryBlueLight,
                  ),
                  Container(width: 1, height: 35, color: isDark ? Colors.white12 : Colors.black12),
                  _buildEnvItem(
                    context,
                    label: "Air Quality",
                    value: "AQI ${telemetry.aqi.toStringAsFixed(0)}",
                    icon: Icons.air,
                    color: _getAqiColor(telemetry.aqi),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalCard(
    BuildContext context, {
    required String title,
    required String value,
    required String unit,
    required String baseline,
    required IconData icon,
    required Color iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.cardDark : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: iconColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              baseline,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? Colors.white54 : Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54),
        ),
      ],
    );
  }

  Color _getRiskColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.low:
        return AppTheme.healthyGreen;
      case AnomalySeverity.medium:
        return AppTheme.warningAmber;
      case AnomalySeverity.high:
        return Colors.orangeAccent;
      case AnomalySeverity.critical:
        return AppTheme.criticalRed;
    }
  }

  Color _getSeverityColor(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.low:
        return AppTheme.healthyGreen;
      case AnomalySeverity.medium:
        return AppTheme.warningAmber;
      case AnomalySeverity.high:
        return Colors.orangeAccent;
      case AnomalySeverity.critical:
        return AppTheme.criticalRed;
    }
  }

  String _getSeverityLabel(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.low:
        return "Healthy Vitals";
      case AnomalySeverity.medium:
        return "Moderate Caution";
      case AnomalySeverity.high:
        return "High Health Risk";
      case AnomalySeverity.critical:
        return "CRITICAL DISASTER ALERT";
    }
  }

  Color _getAqiColor(double aqi) {
    if (aqi <= 50) return AppTheme.healthyGreen;
    if (aqi <= 100) return Colors.amber;
    if (aqi <= 150) return Colors.orange;
    return AppTheme.criticalRed;
  }
}
