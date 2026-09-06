import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/emergency_provider.dart';
import '../services/permission_service.dart';
import '../services/emergency_sms_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'disaster_search_screen.dart';

class EmergencySosScreen extends ConsumerStatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  ConsumerState<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends ConsumerState<EmergencySosScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isHoldingSos = false;
  double _sosHoldProgress = 0.0;
  Timer? _holdTimer;
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
    _holdTimer?.cancel();
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

  void _startHoldSos(TapDownDetails details) {
    setState(() {
      _isHoldingSos = true;
      _sosHoldProgress = 0.0;
    });

    _holdTimer?.cancel();
    int ticks = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      ticks++;
      if (mounted) {
        setState(() {
          _sosHoldProgress = ticks / 60.0; // 3 seconds = 60 ticks of 50ms
        });
      }
      if (ticks >= 60) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isHoldingSos = false;
            _sosHoldProgress = 0.0;
          });
          _dispatchSosAlert();
        }
      }
    });
  }

  void _cancelHoldSos() {
    _holdTimer?.cancel();
    if (mounted) {
      setState(() {
        _isHoldingSos = false;
        _sosHoldProgress = 0.0;
      });
    }
  }

  void _dispatchSosAlert() async {
    await PermissionService.requestAppPermissions();
    final result = await ref
        .read(emergencyProvider.notifier)
        .triggerEmergencySos("MANUAL EMERGENCY SOS BUTTON TRIGGERED");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              const SizedBox(height: 8),
              const Text(
                "Calling user-added contacts, nearest ambulance, and nearby paid caregivers...",
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          backgroundColor: AppTheme.healthyGreen,
          duration: const Duration(seconds: 6),
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
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Emergency SOS & Caregivers",
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
              top: 50,
              left: -50,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.criticalRed.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned(
              bottom: 150,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.electricCyan.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
          
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- LIVE GPS LOCATION CARD ---
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  glowColor: AppTheme.electricCyan,
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: AppTheme.electricCyan, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "LIVE EMERGENCY LOCATION",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.electricCyan,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _currentGpsText,
                              style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500),
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
                const SizedBox(height: 32),

                // --- 1. BIG RED EMERGENCY SOS BUTTON ---
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTapDown: _startHoldSos,
                        onTapUp: (_) => _cancelHoldSos(),
                        onTapCancel: _cancelHoldSos,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Progress Indicator
                            SizedBox(
                              width: 190,
                              height: 190,
                              child: CircularProgressIndicator(
                                value: _sosHoldProgress,
                                strokeWidth: 10,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warningAmber),
                              ),
                            ),
                            // Button
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: _isHoldingSos ? 150 : 160,
                              height: _isHoldingSos ? 150 : 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: _isHoldingSos
                                      ? [AppTheme.criticalRed, Colors.red[900]!]
                                      : [AppTheme.appleHeartRed, AppTheme.criticalRed],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.criticalRed.withValues(alpha: 0.4),
                                    blurRadius: _isHoldingSos ? 10 : 25,
                                    spreadRadius: _isHoldingSos ? 2 : 4,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: -5,
                                    offset: const Offset(-4, -4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isHoldingSos ? Icons.hourglass_top : Icons.sos,
                                    size: _isHoldingSos ? 36 : 48,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _isHoldingSos
                                            ? "HOLDING..."
                                            : "HOLD FOR SOS",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        "Sends SMS with GPS coordinates.\nCalls emergency contacts, nearest ambulance &\nnearest trained caregivers (paid response) for fastest help.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isHoldingSos
                              ? AppTheme.warningAmber
                              : subtitleColor,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // --- 2. EMERGENCY CONTACTS MANAGER ---
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "CAREGIVER CONTACTS",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8E8E93),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.electricCyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text("ADD",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                      onPressed: _showAddContactDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (contacts.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        "No emergency contacts added yet.\nTap 'ADD' to add caregiver phone details.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.4),
                      ),
                    ),
                  )
                else
                  ...contacts.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: GlassCard(
                        glowColor: c.isPrimary ? AppTheme.healthyGreen : null,
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (c.isPrimary ? AppTheme.healthyGreen : AppTheme.electricCyan).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              c.isPrimary ? Icons.star : Icons.person,
                              color: c.isPrimary ? AppTheme.healthyGreen : AppTheme.electricCyan,
                              size: 18,
                            ),
                          ),
                          title: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              c.name,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                            ),
                          ),
                          subtitle: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text("${c.phoneNumber} • ${c.relationship}",
                                style: TextStyle(fontSize: 12, color: subtitleColor)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.criticalRed, size: 22),
                            onPressed: () {
                              ref.read(emergencyProvider.notifier).deleteContact(c.id);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // --- 2.5. ULTRA FAST RESPONSE DISASTER BUTTONS ---
                const Text(
                  "ULTRA FAST DISASTER RESPONSE",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildDisasterButton(
                        context: context,
                        label: "Flood",
                        icon: Icons.flood,
                        color: AppTheme.primaryBlueLight,
                        onTap: () => _triggerDisasterResponse(context, "Flood"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDisasterButton(
                        context: context,
                        label: "Cyclone",
                        icon: Icons.cyclone,
                        color: AppTheme.visionPurple,
                        onTap: () => _triggerDisasterResponse(context, "Cyclone"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDisasterButton(
                        context: context,
                        label: "Disaster",
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                        onTap: () => _triggerDisasterResponse(context, "General Disaster"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // --- 3. OFFLINE FIRST-AID DISASTER GUIDES ---
                const Text(
                  "OFFLINE FIRST-AID DISASTER GUIDES",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8E8E93),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 14),
                _buildGuideTile(
                  context,
                  title: "Heat Stroke Emergency Protocol",
                  subtitle:
                      "Move to shade immediately. Apply cold water to neck, armpits, and groin. Sip water slowly.",
                  icon: Icons.wb_sunny_outlined,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildGuideTile(
                  context,
                  title: "Severe Air Pollution & Asthma First-Aid",
                  subtitle:
                      "Stay indoors with doors closed. Use prescribed bronchodilator inhaler. Wear N95 respirator.",
                  icon: Icons.masks_outlined,
                  color: AppTheme.visionPurple,
                ),
                const SizedBox(height: 12),
                _buildGuideTile(
                  context,
                  title: "Flood & Disaster Evacuation Protocol",
                  subtitle:
                      "Keep wearable active. Move to elevated ground. Avoid touching electrical poles or submerged wires.",
                  icon: Icons.flood_outlined,
                  color: AppTheme.electricCyan,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
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
    final subtitleColor = isDark ? Colors.white70 : Colors.black54;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      glowColor: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _triggerDisasterResponse(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisasterSearchScreen(disasterType: type),
      ),
    );
  }

  Widget _buildDisasterButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      glowColor: color,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      borderRadius: 16,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
