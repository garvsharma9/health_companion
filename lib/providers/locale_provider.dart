import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/hive_storage_service.dart';
import '../localization/app_translations.dart';

// Provides the current active language code ('en' or 'hi')
final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<String> {
  LocaleNotifier() : super('en') {
    _loadLocale();
  }

  void _loadLocale() {
    final savedLocale = HiveStorageService.getLocale();
    if (savedLocale != null && savedLocale.isNotEmpty) {
      state = savedLocale;
    }
  }

  void setLocale(String languageCode) {
    if (state != languageCode) {
      state = languageCode;
      HiveStorageService.saveLocale(languageCode);
    }
  }
}

// Extension to translate strings easily in UI
extension TranslationHelper on WidgetRef {
  String tr(String key) {
    final locale = watch(localeProvider);
    return AppTranslations.translate(key, locale);
  }
}
