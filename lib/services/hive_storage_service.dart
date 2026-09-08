import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/telemetry_data.dart';
import '../models/anomaly_event.dart';
import '../models/emergency_contact.dart';

class HiveStorageService {
  static const String _vitalsBoxName = 'vitals_cache_box';
  static const String _anomaliesBoxName = 'anomalies_box';
  static const String _contactsBoxName = 'contacts_box';
  static const String _settingsBoxName = 'app_settings_box';

  static late Box _vitalsBox;
  static late Box _anomaliesBox;
  static late Box _contactsBox;
  static late Box _settingsBox;

  static TelemetryData? _latestTelemetryCache;
  static List<TelemetryData>? _historyCache;
  static DateTime _lastVitalsDiskSave = DateTime.fromMillisecondsSinceEpoch(0);
  static DateTime _lastAnomalyLogTime = DateTime.fromMillisecondsSinceEpoch(0);
  static String? _lastAnomalyTitle;

  static Future<void> init() async {
    await Hive.initFlutter();
    _vitalsBox = await Hive.openBox(_vitalsBoxName);
    _anomaliesBox = await Hive.openBox(_anomaliesBoxName);
    _contactsBox = await Hive.openBox(_contactsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Warm up memory cache on startup
    _latestTelemetryCache = _getLatestTelemetryFromDisk();
    _historyCache = _getCachedTelemetryHistoryFromDisk();

    // Populate default emergency contact if box is empty
    if (_contactsBox.isEmpty) {
      final defaultContact = EmergencyContact(
        id: '1',
        name: 'Caregiver / Family Member',
        phoneNumber: '+91 9876543210',
        relationship: 'Primary Guardian',
        isPrimary: true,
      );
      await saveContact(defaultContact);
    }
  }

  // --- Vitals Cache (Instant UI rendering & zero main-thread jank) ---
  static void cacheLatestTelemetry(TelemetryData data) {
    _latestTelemetryCache = data;

    _historyCache ??= [];
    _historyCache!.insert(0, data);
    if (_historyCache!.length > 50) {
      _historyCache!.removeLast();
    }

    // Throttle heavy JSON disk serialization to at most once every 10 seconds
    final now = DateTime.now();
    if (now.difference(_lastVitalsDiskSave).inSeconds >= 10) {
      _lastVitalsDiskSave = now;
      _persistVitalsToDisk();
    }
  }

  static void _persistVitalsToDisk() async {
    try {
      if (_latestTelemetryCache != null) {
        await _vitalsBox.put('latest_telemetry', jsonEncode(_latestTelemetryCache!.toJson()));
      }
      if (_historyCache != null) {
        final encodedHistory = _historyCache!.map((e) => jsonEncode(e.toJson())).toList();
        await _vitalsBox.put('telemetry_history', encodedHistory);
      }
    } catch (_) {}
  }

  static TelemetryData getLatestTelemetry() {
    if (_latestTelemetryCache != null) return _latestTelemetryCache!;
    return _getLatestTelemetryFromDisk();
  }

  static TelemetryData _getLatestTelemetryFromDisk() {
    final raw = _vitalsBox.get('latest_telemetry');
    if (raw != null) {
      try {
        return TelemetryData.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return TelemetryData.initial();
  }

  static List<TelemetryData> getCachedTelemetryHistory() {
    if (_historyCache != null) return List.unmodifiable(_historyCache!);
    return _getCachedTelemetryHistoryFromDisk();
  }

  static List<TelemetryData> _getCachedTelemetryHistoryFromDisk() {
    final rawList = _vitalsBox.get('telemetry_history');
    if (rawList is List) {
      return rawList
          .map((e) {
            try {
              return TelemetryData.fromJson(jsonDecode(e));
            } catch (_) {
              return null;
            }
          })
          .whereType<TelemetryData>()
          .toList();
    }
    return [];
  }

  // --- Anomalies Log ---
  static Future<void> logAnomaly(AnomalyEvent anomaly) async {
    // Throttle logging identical anomaly titles within 30 seconds to prevent disk spamming
    final now = DateTime.now();
    if (_lastAnomalyTitle == anomaly.title &&
        now.difference(_lastAnomalyLogTime).inSeconds < 30) {
      return;
    }
    _lastAnomalyTitle = anomaly.title;
    _lastAnomalyLogTime = now;

    await _anomaliesBox.put(anomaly.id, jsonEncode(anomaly.toJson()));
  }

  static List<AnomalyEvent> getAnomalyHistory() {
    final list = <AnomalyEvent>[];
    for (var key in _anomaliesBox.keys) {
      final raw = _anomaliesBox.get(key);
      if (raw != null) {
        try {
          list.add(AnomalyEvent.fromJson(jsonDecode(raw)));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // --- Emergency Contacts ---
  static Future<void> saveContact(EmergencyContact contact) async {
    await _contactsBox.put(contact.id, jsonEncode(contact.toJson()));
  }

  static Future<void> deleteContact(String id) async {
    await _contactsBox.delete(id);
  }

  static List<EmergencyContact> getEmergencyContacts() {
    final list = <EmergencyContact>[];
    for (var key in _contactsBox.keys) {
      final raw = _contactsBox.get(key);
      if (raw != null) {
        try {
          list.add(EmergencyContact.fromJson(jsonDecode(raw)));
        } catch (_) {}
      }
    }
    return list;
  }

  // --- App Preferences & Onboarding ---
  static Future<void> setOnboardingCompleted(bool complete) async {
    await _settingsBox.put('onboarding_complete', complete);
  }

  static bool isOnboardingCompleted() {
    return _settingsBox.get('onboarding_complete', defaultValue: false);
  }

  static Future<void> saveLocale(String localeCode) async {
    await _settingsBox.put('app_locale', localeCode);
  }

  static String? getLocale() {
    return _settingsBox.get('app_locale');
  }

  static bool isHardwareSimMode() {
    return _settingsBox.get('hardware_sim_mode', defaultValue: true);
  }

  static Future<void> setHardwareSimMode(bool value) async {
    await _settingsBox.put('hardware_sim_mode', value);
  }

  static bool isDarkMode() {
    return _settingsBox.get('dark_mode_active', defaultValue: false);
  }

  static Future<void> setDarkMode(bool value) async {
    await _settingsBox.put('dark_mode_active', value);
  }
}
