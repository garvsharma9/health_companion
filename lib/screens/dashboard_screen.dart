import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anomaly_event.dart';
import '../providers/telemetry_provider.dart';
import '../providers/ml_risk_provider.dart';
import '../providers/ble_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'settings_screen.dart';
import '../providers/health_trends_provider.dart';
import '../widgets/health_chart_card.dart';
import 'ai_analysis_screen.dart';

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
    final trendsState = ref.watch(healthTrendsProvider);

    final Color riskColor = _getRiskColor(mlResult.overallSeverity);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
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
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.battery_charging_full, size: 18, color: AppTheme.healthyGreen),
            const SizedBox(width: 3),
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
      body: Stack(
        children: [
          // visionOS Ambient Spatial Light Glows
          if (isDark) ...[
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.electricCyan.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.visionPurple.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. OVERALL RISK GAUGE & EARLY WARNING RING (Glass Card) ---
                GlassCard(
                  glowColor: riskColor,
                  borderRadius: 24,
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
                              strokeCap: StrokeCap.round,
                              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E5EA),
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
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                              Text(
                                "RISK",
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF9898A0) : Colors.black54,
                                ),
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
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mlResult.primaryRecommendation,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87,
                                height: 1.35,
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
                    (anomaly) => GlassCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      glowColor: _getSeverityColor(anomaly.severity),
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

                // --- 3. LIVE VITALS GRID (visionOS Glass Style) ---
                Row(
                  children: const [
                    Text(
                      "BODY VITALS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9898A0),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Spacer(),
                    Text(
                      "LIVE SENSORS",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.healthyGreen,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
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
                        baseline: "60–100 Normal",
                        icon: Icons.favorite,
                        iconColor: AppTheme.appleHeartRed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildVitalCard(
                        context,
                        title: "SpO2 Oxygen",
                        value: telemetry.spO2.toStringAsFixed(1),
                        unit: "%",
                        baseline: "95–100% Safe",
                        icon: Icons.water_drop,
                        iconColor: AppTheme.appleOxygenCyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildVitalCard(
                        context,
                        title: "Body Temp",
                        value: telemetry.bodyTemp.toStringAsFixed(1),
                        unit: "°C",
                        baseline: "36.5–37.5°C",
                        icon: Icons.thermostat,
                        iconColor: AppTheme.appleTempAmber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- 4. ENVIRONMENTAL AWARENESS ---
                const Text(
                  "ENVIRONMENTAL AWARENESS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9898A0),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
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
                        color: AppTheme.electricCyan,
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
                const SizedBox(height: 24),
                // --- 5. HEALTH TRENDS & AI ANALYSIS ---
                _buildHealthTrendsSection(context, trendsState),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthTrendsSection(BuildContext context, HealthTrendsState trends) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final is24h = trends.selectedTimeFrame == TimeFrame.hours24;

    final sectionTitleColor = isDark ? const Color(0xFF9898A0) : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "HEALTH TRENDS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: sectionTitleColor,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(healthTrendsProvider.notifier).setTimeFrame(TimeFrame.hours24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: is24h
                            ? (isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: is24h && !isDark
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        '24h',
                        style: TextStyle(
                          fontSize: 12,
                          color: is24h ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(healthTrendsProvider.notifier).setTimeFrame(TimeFrame.days7),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: !is24h
                            ? (isDark ? Colors.white.withValues(alpha: 0.25) : Colors.white)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: !is24h && !isDark
                            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]
                            : null,
                      ),
                      child: Text(
                        '7d',
                        style: TextStyle(
                          fontSize: 12,
                          color: !is24h ? (isDark ? Colors.white : Colors.black) : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AIAnalysisScreen()));
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.electricCyan, AppTheme.visionPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricCyan.withValues(alpha: isDark ? 0.4 : 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  'View Full AI Analysis Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        HealthChartCard(
          title: "Heart Rate History",
          currentValue: "${(trends.heartRateData.fold(0.0, (s, p) => s + p.y) / (trends.heartRateData.isEmpty ? 1 : trends.heartRateData.length)).toStringAsFixed(0)} Avg",
          unit: "BPM",
          accentColor: AppTheme.appleHeartRed,
          chart: LineChartHelper.buildLineChart(
            context,
            trends.heartRateData,
            AppTheme.appleHeartRed,
            50,
            130,
            trends.selectedTimeFrame,
            "BPM",
            yInterval: 20,
          ),
        ),
        HealthChartCard(
          title: "Blood Oxygen SpO2 History",
          currentValue: "${(trends.spO2Data.fold(0.0, (s, p) => s + p.y) / (trends.spO2Data.isEmpty ? 1 : trends.spO2Data.length)).toStringAsFixed(1)} Avg",
          unit: "%",
          accentColor: AppTheme.appleOxygenCyan,
          chart: LineChartHelper.buildLineChart(
            context,
            trends.spO2Data,
            AppTheme.appleOxygenCyan,
            90,
            100,
            trends.selectedTimeFrame,
            "%",
            yInterval: 2.5,
          ),
        ),
        HealthChartCard(
          title: "Body Temperature History",
          currentValue: "${(trends.temperatureData.fold(0.0, (s, p) => s + p.y) / (trends.temperatureData.isEmpty ? 1 : trends.temperatureData.length)).toStringAsFixed(1)} Avg",
          unit: "°C",
          accentColor: AppTheme.appleTempAmber,
          chart: LineChartHelper.buildLineChart(
            context,
            trends.temperatureData,
            AppTheme.appleTempAmber,
            35.5,
            38.5,
            trends.selectedTimeFrame,
            "°C",
            yInterval: 1.0,
          ),
        ),
      ],
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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      glowColor: iconColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: iconColor),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF9898A0) : Colors.black54,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                baseline,
                style: TextStyle(
                  fontSize: 9.5,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
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
