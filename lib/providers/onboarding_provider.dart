import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_storage_service.dart';

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(HiveStorageService.isOnboardingCompleted());

  void completeOnboarding() async {
    await HiveStorageService.setOnboardingCompleted(true);
    state = true;
  }

  void resetOnboarding() async {
    await HiveStorageService.setOnboardingCompleted(false);
    state = false;
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});
