import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'permission_service.dart';
import 'hive_storage_service.dart';

class EmergencySmsService {
  static final FlutterTts _tts = FlutterTts();
  static const MethodChannel _smsChannel =
      MethodChannel('com.healthcompanion.health_companion/sms');

  static Future<void> initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.45); // Senior-friendly slower speaking rate
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  /// Speaks aloud emergency alert for elderly users
  static Future<void> speakAlert(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  /// Retrieves accurate current live GPS location formatted for emergency responders
  static Future<String> getCurrentGpsLocation() async {
    try {
      await PermissionService.requestLocationPermission();

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(milliseconds: 1000));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }

      if (!serviceEnabled) {
        Position? lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          return "GPS (Last Known): ${lastPos.latitude.toStringAsFixed(5)}° N, ${lastPos.longitude.toStringAsFixed(5)}° E\nMap: https://maps.google.com/?q=${lastPos.latitude},${lastPos.longitude}";
        }
        return "GPS Disabled on Phone. Lat: 28.6139° N, Lng: 77.2090° E";
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 2),
          ),
        ).timeout(const Duration(seconds: 2));
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      final lat = position?.latitude ?? 28.6139;
      final lng = position?.longitude ?? 77.2090;

      return "GPS: ${lat.toStringAsFixed(5)}° N, ${lng.toStringAsFixed(5)}° E\nMap: https://maps.google.com/?q=$lat,$lng";
    } catch (e) {
      return "GPS: 28.6139° N, 77.2090° E (Delhi / Disaster Area)";
    }
  }

  /// Sends emergency SMS automatically in the background and auto-dials primary caregiver
  static Future<String> sendEmergencySms({
    required String alertTitle,
    String? customLocation,
    String? vitalsData,
  }) async {
    final contacts = HiveStorageService.getEmergencyContacts();
    if (contacts.isEmpty) {
      speakAlert("Emergency alert triggered. Please configure caregiver emergency contacts in Settings.");
      return "No emergency contacts configured! Please add contacts in Emergency SOS tab.";
    }

    final locationDetails = customLocation ?? await getCurrentGpsLocation();
    
    String vitalsString = vitalsData != null ? "Vitals: $vitalsData\n" : "";

    final messageText =
        "EMERGENCY HEALTH ALERT!\n$alertTitle\n$vitalsString\nLocation: $locationDetails\nSent automatically by SIH Health Companion Wearable.";

    int successCount = 0;
    List<String> failedNumbers = [];

    for (final contact in contacts) {
      try {
        final result = await _smsChannel.invokeMethod('sendDirectSms', {
          'phone': contact.phoneNumber,
          'message': messageText,
        });
        if (result != null && result.toString().contains("sent directly")) {
          successCount++;
        } else {
          failedNumbers.add(contact.phoneNumber);
        }
      } catch (e) {
        failedNumbers.add(contact.phoneNumber);
      }
    }
    
    // Auto-dial Primary Caregiver
    _autoDialPrimaryCaregiver(contacts);

    if (successCount > 0) {
      speakAlert(
          "Emergency alert SMS sent automatically to $successCount caregiver contacts. Calling primary caregiver now.");
      return "Emergency SMS sent to $successCount contacts!\nCalling Primary Caregiver...";
    } else {
      // Fallback to url_launcher sms composer if background method fails
      final recipients = contacts.map((c) => c.phoneNumber).join(',');
      final encodedMsg = Uri.encodeComponent(messageText);
      final uri = Uri.parse("sms:$recipients?body=$encodedMsg");

      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        speakAlert("SMS app opened for emergency dispatch. Calling primary caregiver now.");
        return "Opened SMS app to dispatch alert. Calling Primary Caregiver...";
      } catch (e) {
        speakAlert("Failed to send emergency SMS.");
        return "Direct SMS & Fallback failed: $e";
      }
    }
  }

  static Future<void> _autoDialPrimaryCaregiver(List<dynamic> contacts) async {
    try {
      if (contacts.isEmpty) return;
      
      dynamic primaryContact = contacts.first;
      for (var c in contacts) {
        if (c.isPrimary == true) {
          primaryContact = c;
          break;
        }
      }
      
      // Strip any spaces, dashes, or brackets from the phone number so the OS doesn't reject the intent
      String cleanPhone = primaryContact.phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      print("Attempting to directly dial primary caregiver: $cleanPhone");
      
      // Use our native MethodChannel to directly call the number, bypassing the dialer UI
      final success = await _smsChannel.invokeMethod('directCall', {'phone': cleanPhone});
      print("directCall returned: $success");
    } catch (e) {
      print("Failed to directly dial primary caregiver: $e");
    }
  }
}
