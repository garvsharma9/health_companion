import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Continuous Offline Health Tracking',
      'subtitle':
          'Monitors Heart Rate (BPM), SpO2, Body Temp, and Movement 24/7 without needing internet or cloud connectivity.',
      'icon': 'favorite',
      'accentColor': '0xFF00E676',
    },
    {
      'title': 'On-Device AI Early Warning System',
      'subtitle':
          'Detects heat stroke hazards, pollution spikes, and respiratory risks before medical emergencies occur.',
      'icon': 'warning_amber',
      'accentColor': '0xFFFFC107',
    },
    {
      'title': 'Hardware Simulation & ESP32 BLE',
      'subtitle':
          'Connect to physical ESP32 wristband via Bluetooth, or test all features instantly using built-in Hardware Simulator Mode.',
      'icon': 'bluetooth',
      'accentColor': '0xFF00E5FF',
    },
    {
      'title': 'Emergency SOS & Caregiver Alerts',
      'subtitle':
          'Automatic fall detection initiates direct offline SMS alerts and GPS location to your configured caregiver contacts.',
      'icon': 'sos',
      'accentColor': '0xFFFF5252',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    ref.read(onboardingProvider.notifier).completeOnboarding();
                  },
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final Color iconColor =
                      Color(int.parse(slide['accentColor']!));

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: iconColor.withValues(alpha: 0.15),
                            border: Border.all(color: iconColor, width: 2),
                          ),
                          child: Icon(
                            _getIconData(slide['icon']!),
                            size: 60,
                            color: iconColor,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          slide['title']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide['subtitle']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.electricCyan
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    if (_currentPage < _slides.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      ref
                          .read(onboardingProvider.notifier)
                          .completeOnboarding();
                    }
                  },
                  child: Text(
                    _currentPage == _slides.length - 1
                        ? 'GET STARTED'
                        : 'NEXT',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'favorite':
        return Icons.favorite;
      case 'warning_amber':
        return Icons.warning_amber_rounded;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'sos':
        return Icons.sos;
      default:
        return Icons.health_and_safety;
    }
  }
}
