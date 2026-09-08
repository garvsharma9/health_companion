import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/ble_provider.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'sih_compliance_screen.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final bleState = ref.watch(bleProvider);
    final isDark = themeMode == ThemeMode.dark;

    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: Text(
          ref.tr("app_settings"),
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Stack(
        children: [
          // Background ambient glows
          if (isDark) ...[
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryBlueLight.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.visionPurple.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
          SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. APPEARANCE & THEME SWITCHER ---
            Text(
              ref.tr("appearance"),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              glowColor: isDark ? Colors.amberAccent : AppTheme.electricCyan,
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: isDark ? Colors.amberAccent : AppTheme.electricCyan,
                  ),
                  title: Text(
                    ref.tr("dark_mode"),
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Text(
                    isDark ? ref.tr("apple_oled") : ref.tr("clean_white"),
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                  value: isDark,
                  onChanged: (val) {
                    ref.read(themeProvider.notifier).toggleTheme(val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 1.5 LANGUAGE SWITCHER ---
            Text(
              ref.tr("language"),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              glowColor: isDark ? Colors.blueAccent : AppTheme.primaryBlueLight,
              child: Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  secondary: Icon(
                    Icons.language,
                    color: isDark ? Colors.blueAccent : AppTheme.primaryBlueLight,
                  ),
                  title: Text(
                    "हिन्दी (Hindi)",
                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                  ),
                  subtitle: Text(
                    "Switch app language to Hindi",
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                  value: ref.watch(localeProvider) == 'hi',
                  onChanged: (val) {
                    ref.read(localeProvider.notifier).setLocale(val ? 'hi' : 'en');
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. DEMO SIMULATION CONTROLS ---
            const Text(
              "HARDWARE SIMULATOR & DEMO CONTROLS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
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
                        label: ref.tr("Heat Stroke Risk"),
                        icon: Icons.wb_sunny,
                        color: Colors.orange,
                        type: "heat",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: ref.tr("SpO2 Drop Hazard"),
                        icon: Icons.masks,
                        color: Colors.purple,
                        type: "spo2",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: ref.tr("Fall Detection"),
                        icon: Icons.accessibility_new,
                        color: Colors.red,
                        type: "fall",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: ref.tr("Walking"),
                        icon: Icons.directions_walk,
                        color: Colors.lightGreen,
                        type: "walking",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: ref.tr("Deep Sleep"),
                        icon: Icons.bedtime,
                        color: Colors.indigoAccent,
                        type: "sleep",
                      ),
                      _buildSimChip(
                        context,
                        ref,
                        label: ref.tr("Reset Healthy"),
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
            const Text(
              "USER PERSONAL BASELINES",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
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
            const Text(
              "ABOUT & SIH COMPLIANCE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.verified_outlined, color: AppTheme.healthyGreen),
                      title: Text(ref.tr("sih_info"),
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      subtitle: Text(ref.tr("sih_info_desc"),
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
                      leading: const Icon(Icons.help_outline, color: AppTheme.electricCyan),
                      title: Text(ref.tr("reopen_onboarding"),
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      subtitle: Text(ref.tr("reopen_onboarding_desc"),
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
      ],
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
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.4)),
      ),
      onPressed: () {
        ref.read(bleProvider.notifier).injectAnomaly(type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ref.tr("simulated_payload").replaceAll("{label}", label)),
            duration: const Duration(seconds: 1),
            backgroundColor: color.withValues(alpha: 0.9),
          ),
        );
      },
    );
  }
}
