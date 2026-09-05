import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency_contact.dart';
import '../services/hive_storage_service.dart';
import '../services/emergency_sms_service.dart';

class EmergencyNotifier extends StateNotifier<List<EmergencyContact>> {
  EmergencyNotifier() : super(HiveStorageService.getEmergencyContacts());

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
    return await EmergencySmsService.sendEmergencySms(
      alertTitle: alertTitle,
    );
  }
}

final emergencyProvider =
    StateNotifierProvider<EmergencyNotifier, List<EmergencyContact>>((ref) {
  return EmergencyNotifier();
});
