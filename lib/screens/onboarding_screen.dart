import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/onboarding_provider.dart';
import '../providers/locale_provider.dart';
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
      'title': 'onboarding_title_1',
      'subtitle': 'onboarding_subtitle_1',
      'icon': 'favorite',
      'accentColor': '0xFF00E676',
    },
    {
      'title': 'onboarding_title_2',
      'subtitle': 'onboarding_subtitle_2',
      'icon': 'warning_amber',
      'accentColor': '0xFFFFC107',
    },
    {
      'title': 'onboarding_title_3',
      'subtitle': 'onboarding_subtitle_3',
      'icon': 'bluetooth',
      'accentColor': '0xFF00E5FF',
    },
    {
      'title': 'onboarding_title_4',
      'subtitle': 'onboarding_subtitle_4',
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
            // Top Bar with Language Switcher and Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Language Switcher
                  Row(
                    children: [
                      const Icon(Icons.language, color: Colors.white70, size: 20),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: ref.watch(localeProvider),
                        dropdownColor: AppTheme.cardDark,
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            ref.read(localeProvider.notifier).setLocale(newValue);
                          }
                        },
                      ),
                    ],
                  ),
                  
                  // Skip Button
                  TextButton(
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).completeOnboarding();
                    },
                    child: Text(
                      ref.tr("skip"),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            ref.tr(slide['title']!),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          ref.tr(slide['subtitle']!),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
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
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricCyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
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
                        ? ref.tr("get_started")
                        : ref.tr("next"),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
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
