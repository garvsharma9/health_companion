import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SihComplianceScreen extends StatelessWidget {
  const SihComplianceScreen({super.key});

  final List<Map<String, String>> _requirements = const [
    {
      'num': '1',
      'title': 'Continuous Health Monitoring',
      'detail':
          'Tracks Heart Rate (MAX30102), SpO2, Body Temp, Activity, and Fall vectors continuously.',
      'status': 'VERIFIED',
    },
    {
      'num': '2',
      'title': 'AI-Based Anomaly Detection',
      'detail':
          'On-device multi-factor rule engine evaluates risk scores locally without external API dependency.',
      'status': 'VERIFIED',
    },
    {
      'num': '3',
      'title': 'Disaster-Specific Health Alerts',
      'detail':
          'Heat Stroke Index (Body Temp + Ambient Temp + Humidity + HR) and Asthma Hazard alerts.',
      'status': 'VERIFIED',
    },
    {
      'num': '4',
      'title': 'Environmental Awareness',
      'detail':
          'Cross-references ambient temperature, humidity, and Air Quality Index (AQI) with physiological vitals.',
      'status': 'VERIFIED',
    },
    {
      'num': '5',
      'title': 'Privacy-Preserving Edge AI',
      'detail':
          '100% On-Device execution. Zero biometric data sent to cloud servers.',
      'status': 'VERIFIED',
    },
    {
      'num': '6',
      'title': 'Emergency Assistance & SOS',
      'detail':
          'Automated fall detection + manual Big Red SOS button triggering offline caregiver SMS.',
      'status': 'VERIFIED',
    },
    {
      'num': '7',
      'title': 'Personal Wellness Dashboard',
      'detail':
          'Senior-friendly high-contrast dark/light dashboard with clear visual risk rings.',
      'status': 'VERIFIED',
    },
    {
      'num': '8',
      'title': 'Scalable Low-Power Deployment',
      'detail':
          'Framed for Qualcomm Snapdragon / Hexagon NPU low-power edge AI microcontrollers.',
      'status': 'VERIFIED',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.cardDark : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Qualcomm SIH 26181 Compliance"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Pitch Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF0284C7), const Color(0xFF0369A1)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "SIH Problem Statement 26181",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "On-Device AI Early Warning Disaster-Resilient Health Wearable Platform (Qualcomm)",
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Built specifically for heatwaves, floods, smog spikes, outdoor laborers, elderly individuals living alone, and rural communities with zero internet connectivity.",
                    style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              "8 Core Requirements Compliance Matrix",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),

            ..._requirements.map(
              (req) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlueLight,
                      ),
                      child: Center(
                        child: Text(
                          req['num']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    req['title']!,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.healthyGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    "VERIFIED",
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.healthyGreen,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            req['detail']!,
                            style: TextStyle(
                                fontSize: 12, color: subtitleColor, height: 1.3),
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
}
