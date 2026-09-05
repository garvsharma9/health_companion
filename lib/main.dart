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
    RepaintBoundary(child: HealthInsightsScreen()),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_outlined),
            activeIcon: Icon(Icons.bluetooth),
            label: 'Hardware & BLE',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sos_outlined),
            activeIcon: Icon(Icons.sos),
            label: 'Emergency SOS',
          ),
        ],
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
