import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact.dart';
import '../services/hive_storage_service.dart';
import '../services/emergency_sms_service.dart';
import '../providers/telemetry_provider.dart';

class EmergencyNotifier extends StateNotifier<List<EmergencyContact>> {
  final Ref ref;
  EmergencyNotifier(this.ref) : super(HiveStorageService.getEmergencyContacts());

  void addContact(String name, String phone, String relationship) async {
    final contact = EmergencyContact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phoneNumber: phone,
      relationship: relationship,
      isPrimary: state.isEmpty,
    );
    await HiveStorageService.saveContact(contact);
    state = HiveStorageService.getEmergencyContacts();
  }

  void deleteContact(String id) async {
    await HiveStorageService.deleteContact(id);
    state = HiveStorageService.getEmergencyContacts();
  }

  Future<String> triggerEmergencySos(String alertTitle) async {
    final telemetry = ref.read(currentTelemetryProvider);
    String vitals = "HR: ${telemetry.heartRate.toStringAsFixed(1)} BPM, SpO2: ${telemetry.spO2.toStringAsFixed(1)}%";
    
    return await EmergencySmsService.sendEmergencySms(
      alertTitle: alertTitle,
      vitalsData: vitals,
    );
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, List<EmergencyContact>>((ref) {
  return EmergencyNotifier(ref);
});
