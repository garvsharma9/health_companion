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

  static Future<void> init() async {
    await Hive.initFlutter();
    _vitalsBox = await Hive.openBox(_vitalsBoxName);
    _anomaliesBox = await Hive.openBox(_anomaliesBoxName);
    _contactsBox = await Hive.openBox(_contactsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

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

  // --- Vitals Cache (Instant UI rendering) ---
  static Future<void> cacheLatestTelemetry(TelemetryData data) async {
    await _vitalsBox.put('latest_telemetry', jsonEncode(data.toJson()));

    // Store in history array (limit to max 50 recent entries for fast query)
    final historyList = getCachedTelemetryHistory();
    historyList.insert(0, data);
    if (historyList.length > 50) {
      historyList.removeLast();
    }
    final encodedHistory =
        historyList.map((e) => jsonEncode(e.toJson())).toList();
    await _vitalsBox.put('telemetry_history', encodedHistory);
  }

  static TelemetryData getLatestTelemetry() {
    final raw = _vitalsBox.get('latest_telemetry');
    if (raw != null) {
      try {
        return TelemetryData.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    return TelemetryData.initial();
  }

  static List<TelemetryData> getCachedTelemetryHistory() {
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
  static bool isOnboardingCompleted() {
    return _settingsBox.get('onboarding_completed', defaultValue: false);
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    await _settingsBox.put('onboarding_completed', value);
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
