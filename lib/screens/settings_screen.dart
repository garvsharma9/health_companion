import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/ble_provider.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';
import 'sih_compliance_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final bleState = ref.watch(bleProvider);
    final isDark = themeMode == ThemeMode.dark;

    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardBg = Theme.of(context).cardTheme.color ?? Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings & Preferences"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. APPEARANCE & THEME SWITCHER ---
            const Text(
              "Appearance",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark ? Colors.amberAccent : AppTheme.primaryBlueLight,
                ),
                title: Text(
                  "Dark Mode Theme",
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                ),
                subtitle: Text(
                  isDark ? "Dark Midnight Palette" : "Clean White Porcelain Theme (Default)",
                  style: TextStyle(fontSize: 12, color: subtitleColor),
                ),
                value: isDark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme(val);
                },
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. DEMO SIMULATION CONTROLS (Discreet presentation hub) ---
            Row(
              children: [
                const Icon(Icons.build_circle, size: 18, color: AppTheme.primaryBlueLight),
                const SizedBox(width: 6),
                Text(
                  "Hardware Simulator & Demo Controls",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      "Hardware Simulator Mode",
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    subtitle: Text(
                      "Injects live sensor telemetry when ESP32 is not connected.",
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                    value: bleState.isSimulating,
                    onChanged: (val) {
                      ref.read(bleProvider.notifier).toggleSimulator(val);
                    },
                  ),
                  const Divider(height: 20),
                  Text(
                    "1-Tap Anomaly Simulation Triggers",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSimChip(
                        context,
                        ref,
                        label: "Heat Stroke Risk",
                        icon: Icons.wb_sunny,
                        color: Colors.orange,
                        type: "heat",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: "SpO2 Drop Hazard",
                        icon: Icons.masks,
                        color: Colors.purple,
                        type: "spo2",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: "Fall Detection",
                        icon: Icons.accessibility_new,
                        color: Colors.red,
                        type: "fall",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: "Reset Healthy",
                        icon: Icons.refresh,
                        color: AppTheme.healthyGreen,
                        type: "normal",
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 3. USER PROFILE BASELINES ---
            Text(
              "User Personal Baselines",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  _buildProfileRow("Target User Segment", "Elderly / Outdoor Worker", textColor, subtitleColor),
                  const Divider(height: 16),
                  _buildProfileRow("Normal Resting HR", "60 - 90 BPM", textColor, subtitleColor),
                  const Divider(height: 16),
                  _buildProfileRow("Baseline SpO2", "95% - 100%", textColor, subtitleColor),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 4. APP MANAGEMENT & ABOUT SIH ---
            Text(
              "About & SIH Compliance",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_outlined, color: AppTheme.healthyGreen),
                    title: Text("SIH Problem 26181 Compliance Matrix",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text("View hackathon hardware & software evaluation matrix",
                        style: TextStyle(fontSize: 12, color: subtitleColor)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SihComplianceScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: AppTheme.primaryBlueLight),
                    title: Text("Re-open Feature Onboarding Guide",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    subtitle: Text("View the Opera-style walkthrough slides again",
                        style: TextStyle(fontSize: 12, color: subtitleColor)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ref.read(onboardingProvider.notifier).resetOnboarding();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Version Footer
            Center(
              child: Column(
                children: [
                  Text(
                    "SIH Problem Statement 26181",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subtitleColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Personal Health Companion • v1.0.0 (On-Device AI)",
                    style: TextStyle(fontSize: 11, color: subtitleColor.withValues(alpha: 0.7)),
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

  Widget _buildProfileRow(String label, String value, Color textColor, Color subtitleColor) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: subtitleColor)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  Widget _buildSimChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required IconData icon,
    required Color color,
    required String type,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      backgroundColor: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      onPressed: () {
        ref.read(bleProvider.notifier).injectAnomaly(type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Simulated $label Payload Injected!"),
            duration: const Duration(seconds: 1),
            backgroundColor: color.withValues(alpha: 0.9),
          ),
        );
      },
    );
  }
}
