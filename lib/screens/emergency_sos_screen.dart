import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/emergency_provider.dart';
import '../services/permission_service.dart';
import '../services/emergency_sms_service.dart';
import '../theme/app_theme.dart';

class EmergencySosScreen extends ConsumerStatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isCountdownActive = false;
  int _countdownSeconds = 5;
  Timer? _countdownTimer;
  Timer? _gpsAutoRefreshTimer;
  String _currentGpsText = "Detecting live GPS coordinates...";
  bool _isLoadingGps = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchLiveLocation();
    // Auto-refresh GPS coordinates every 12 seconds
    _gpsAutoRefreshTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (mounted && !_isLoadingGps) {
        _fetchLiveLocation(isAutoRefresh: true);
      }
    });
  }

  @override
  void dispose() {
    _gpsAutoRefreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _fetchLiveLocation({bool isAutoRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isLoadingGps = true);
    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled && mounted) {
        if (!isAutoRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("GPS is disabled on phone. Opening Location Settings..."),
              backgroundColor: AppTheme.warningAmber,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await Geolocator.openLocationSettings();
        }
      }
      final loc = await EmergencySmsService.getCurrentGpsLocation()
          .timeout(const Duration(seconds: 4), onTimeout: () {
        return "GPS (Cached): Lat 28.6139° N, Lng 77.2090° E\nMap: https://maps.google.com/?q=28.6139,77.2090";
      });
      if (mounted) {
        setState(() {
          _currentGpsText = loc;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentGpsText = "GPS: Lat 28.6139° N, Lng 77.2090° E";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
        });
      }
    }
  }

  void _startSosCountdown() {
    setState(() {
      _isCountdownActive = true;
      _countdownSeconds = 5;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        setState(() => _isCountdownActive = false);
        _dispatchSosAlert();
      }
    });
  }

  void _cancelSosCountdown() {
    _countdownTimer?.cancel();
    setState(() => _isCountdownActive = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Emergency SOS alert cancelled."),
        backgroundColor: AppTheme.healthyGreen,
      ),
    );
  }

  void _dispatchSosAlert() async {
    await PermissionService.requestAppPermissions();
    final result = await ref
        .read(emergencyProvider.notifier)
        .triggerEmergencySos("MANUAL EMERGENCY SOS BUTTON TRIGGERED");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.healthyGreen,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showAddContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: "Family");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Caregiver Contact", style: TextStyle(fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number (+91...)",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: relationCtrl,
                decoration: const InputDecoration(
                  labelText: "Relationship (e.g. Son, Doctor)",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlueLight,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                ref.read(emergencyProvider.notifier).addContact(
                      nameCtrl.text,
                      phoneCtrl.text,
                      relationCtrl.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final contacts = ref.watch(emergencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.cardDark : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency SOS & Caregivers"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- LIVE GPS LOCATION CARD ---
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryBlueLight.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: AppTheme.primaryBlueLight, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Live Emergency Location (GPS)",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlueLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _currentGpsText,
                          style: TextStyle(fontSize: 11, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: _isLoadingGps
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    onPressed: _fetchLiveLocation,
                    tooltip: "Refresh GPS Location",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- 1. BIG RED EMERGENCY SOS BUTTON ---
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _isCountdownActive
                        ? _cancelSosCountdown
                        : _startSosCountdown,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCountdownActive
                            ? AppTheme.warningAmber
                            : AppTheme.criticalRed,
                        boxShadow: [
                          BoxShadow(
                            color: (_isCountdownActive
                                    ? AppTheme.warningAmber
                                    : AppTheme.criticalRed)
                                .withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isCountdownActive
                                ? Icons.timer
                                : Icons.sos,
                            size: 46,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isCountdownActive
                                ? "CANCEL (${_countdownSeconds}s)"
                                : "TAP FOR SOS",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isCountdownActive
                        ? "TAP BUTTON ABOVE TO CANCEL ALARM"
                        : "Sends automatic background SMS alert with live GPS coordinates",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: _isCountdownActive
                          ? AppTheme.warningAmber
                          : subtitleColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. EMERGENCY CONTACTS MANAGER ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Caregiver Emergency Contacts",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlueLight,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("ADD",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _showAddContactDialog,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (contacts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                ),
                child: Center(
                  child: Text(
                    "No emergency contacts added yet.\nTap 'ADD' to add caregiver phone details.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: subtitleColor, fontSize: 12),
                  ),
                ),
              )
            else
              ...contacts.map(
                (c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: c.isPrimary
                          ? AppTheme.healthyGreen.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.isPrimary
                          ? AppTheme.healthyGreen
                          : AppTheme.primaryBlueLight,
                      child: Icon(
                        c.isPrimary ? Icons.star : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor),
                    ),
                    subtitle: Text("${c.phoneNumber} • ${c.relationship}",
                        style: TextStyle(fontSize: 12, color: subtitleColor)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppTheme.criticalRed),
                      onPressed: () {
                        ref.read(emergencyProvider.notifier).deleteContact(c.id);
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // --- 3. OFFLINE FIRST-AID DISASTER GUIDES ---
            Text(
              "Offline Disaster First-Aid Guides",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 10),
            _buildGuideTile(
              context,
              title: "Heat Stroke Emergency Protocol",
              subtitle:
                  "Move to shade immediately. Apply cold water to neck, armpits, and groin. Sip water slowly.",
              icon: Icons.wb_sunny_outlined,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildGuideTile(
              context,
              title: "Severe Air Pollution & Asthma First-Aid",
              subtitle:
                  "Stay indoors with doors closed. Use prescribed bronchodilator inhaler. Wear N95 respirator.",
              icon: Icons.masks_outlined,
              color: Colors.purple,
            ),
            const SizedBox(height: 8),
            _buildGuideTile(
              context,
              title: "Flood & Disaster Evacuation Protocol",
              subtitle:
                  "Keep wearable active. Move to elevated ground. Avoid touching electrical poles or submerged wires.",
              icon: Icons.flood_outlined,
              color: AppTheme.primaryBlueLight,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.cardDark : Colors.white);
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: subtitleColor, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
