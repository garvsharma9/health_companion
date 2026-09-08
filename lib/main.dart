import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'services/hive_storage_service.dart';
import 'services/ble_hardware_service.dart';
import 'services/emergency_sms_service.dart';
import 'services/permission_service.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/home_widget_provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/ble_device_screen.dart';
import 'screens/emergency_sos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint("Failed to set high refresh rate: $e");
    }
  }

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
    ref.watch(homeWidgetSyncProvider);

    return MaterialApp(
      title: 'Health Companion - SIH 26181',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      home: isOnboardingCompleted
          ? const MainShellScreen()
          : const OnboardingScreen(),
    );
  }
}

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
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

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
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
          return _screens[index];
        },
      ),
      bottomNavigationBar: _buildFloatingSpatialNavBar(context),
    );
  }

  Widget _buildFloatingSpatialNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      _NavItemData(
        label: ref.tr("dashboard"),
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        accentColor: AppTheme.electricCyan,
      ),
      _NavItemData(
        label: ref.tr("hardware"),
        icon: Icons.bluetooth_outlined,
        activeIcon: Icons.bluetooth_connected_rounded,
        accentColor: AppTheme.appleOxygenCyan,
      ),
      _NavItemData(
        label: ref.tr("emergency"),
        icon: Icons.emergency_outlined,
        activeIcon: Icons.emergency_rounded,
        accentColor: AppTheme.criticalRed,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                  child: Stack(
                    children: [
                      // Liquid Glass Bubble Layer (Synced with Swipe)
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double page = _currentIndex.toDouble();
                            if (_pageController.hasClients && _pageController.position.haveDimensions) {
                              page = _pageController.page ?? _currentIndex.toDouble();
                            }
                            
                            final int nearestIndex = page.round().clamp(0, items.length - 1);

                            return Align(
                              alignment: Alignment(-1.0 + (2.0 / (items.length - 1)) * page, 0),
                              child: FractionallySizedBox(
                                widthFactor: 1 / items.length,
                                heightFactor: 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: items[nearestIndex].accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: items[nearestIndex].accentColor.withValues(alpha: 0.5),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: items[nearestIndex].accentColor.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Icons Layer
                      Row(
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
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                color: Colors.transparent,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      scale: isSelected ? 1.15 : 1.0,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutBack,
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
                    ],
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
  double get dragStartDistanceMotionThreshold => 45.0;
}
