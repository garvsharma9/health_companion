import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static final FlutterReactiveBle _ble = FlutterReactiveBle();

  /// Requests all necessary permissions (Location, SMS, Bluetooth)
  static Future<bool> requestAppPermissions() async {
    if (kIsWeb) return true;
    try {
      final permissions = [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.sms,
        Permission.phone,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ];

      Map<Permission, PermissionStatus> statuses = await permissions.request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted && !status.isLimited) {
          allGranted = false;
        }
      });

      return allGranted;
    } catch (_) {
      return true;
    }
  }

  /// Check if location permission is currently granted
  static Future<bool> isLocationGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Request location permission specifically
  static Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await openAppSettings();
      return false;
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Check current Bluetooth hardware adapter status
  static Stream<BleStatus> get bleStatusStream => _ble.statusStream;

  static BleStatus get currentBleStatus => _ble.status;

  static const _smsChannel =
      MethodChannel('com.healthcompanion.health_companion/sms');

  /// Programmatically enables phone Bluetooth hardware adapter
  static Future<bool> enableBluetoothAdapter() async {
    try {
      final result = await _smsChannel.invokeMethod('enableBluetooth');
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
