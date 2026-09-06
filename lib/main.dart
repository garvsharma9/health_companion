import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/hive_storage_service.dart';
import 'services/ble_hardware_service.dart';
import 'services/emergency_sms_service.dart';
import 'services/permission_service.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ble_device_screen.dart';
import 'screens/health_insights_screen.dart';
import 'screens/emergency_sos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline Hive storage & cache
  await HiveStorageService.init();

  // Initialize TTS voice alerts
  await EmergencySmsService.initTts();

  // Initialize BLE Hardware Service & Simulation Engine
  BleHardwareService.init();

  runApp(const ProviderScope(child: HealthCompanionApp()));
}

class HealthCompanionApp extends ConsumerWidget {
  const HealthCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnboardingCompleted = ref.watch(onboardingProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Health Companion - SIH 26181',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: isOnboardingCompleted
          ? const MainShellScreen()
          : const OnboardingScreen(),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color accentColor;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.accentColor,
  });
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.requestAppPermissions();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = const [
    RepaintBoundary(child: DashboardScreen()),
    RepaintBoundary(child: BleDeviceScreen()),
    RepaintBoundary(child: EmergencySosScreen()),
  ];

  Widget _buildCardPage(int index, Widget child) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, childWidget) {
        double page = 0.0;
        if (_pageController.hasClients &&
            _pageController.position.haveDimensions) {
          page = _pageController.page ?? _currentIndex.toDouble();
        } else {
          page = _currentIndex.toDouble();
        }

        final double offset = page - index;
        final double absOffset = offset.abs().clamp(0.0, 1.0);

        // Fast & Lightweight Android Card Scale & Opacity
        final double scale = 1.0 - (absOffset * 0.04); // Subtle 4% scale
        final double opacity = 1.0 - (absOffset * 0.20); // 20% opacity fade
        final double borderRadius = absOffset * 14.0; // Subtle card corners
        final double translationX = offset * 12.0;

        return Transform.translate(
          offset: Offset(translationX, 0),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: childWidget,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: PageView.builder(
        controller: _pageController,
        physics: const LessSensitivePageScrollPhysics(
            parent: ClampingScrollPhysics()),
        itemCount: _screens.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return _buildCardPage(index, _screens[index]);
        },
      ),
      bottomNavigationBar: _buildFloatingSpatialNavBar(context),
    );
  }

  Widget _buildFloatingSpatialNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      const _NavItemData(
        label: "Dashboard",
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        accentColor: AppTheme.electricCyan,
      ),
      const _NavItemData(
        label: "Hardware",
        icon: Icons.bluetooth_outlined,
        activeIcon: Icons.bluetooth_connected_rounded,
        accentColor: AppTheme.appleOxygenCyan,
      ),
      const _NavItemData(
        label: "Emergency",
        icon: Icons.emergency_outlined,
        activeIcon: Icons.emergency_rounded,
        accentColor: AppTheme.criticalRed,
      ),
    ];

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14141E).withValues(alpha: 0.75)
                        : const Color(0xFFF5F5FA).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.black.withValues(alpha: 0.12),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      final isSelected = _currentIndex == index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _currentIndex = index);
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? item.accentColor.withValues(alpha: isDark ? 0.22 : 0.14)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                              border: isSelected
                                  ? Border.all(
                                      color: item.accentColor.withValues(alpha: 0.45),
                                      width: 1.2,
                                    )
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.10 : 1.0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    size: 20,
                                    color: isSelected
                                        ? item.accentColor
                                        : (isDark
                                            ? const Color(0xFF9898A0)
                                            : const Color(0xFF6C6C70)),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? (isDark ? Colors.white : item.accentColor)
                                          : (isDark
                                              ? const Color(0xFF9898A0)
                                              : const Color(0xFF6C6C70)),
                                      letterSpacing: isSelected ? 0.1 : -0.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LessSensitivePageScrollPhysics extends PageScrollPhysics {
  const LessSensitivePageScrollPhysics({super.parent});

  @override
  LessSensitivePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return LessSensitivePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get dragStartDistanceMotionThreshold => 8.0;
}
