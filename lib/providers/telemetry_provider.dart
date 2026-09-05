import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/telemetry_data.dart';
import '../services/ble_hardware_service.dart';
import '../services/hive_storage_service.dart';

final telemetryStreamProvider = StreamProvider<TelemetryData>((ref) {
  return BleHardwareService.telemetryStream;
});

final currentTelemetryProvider = Provider<TelemetryData>((ref) {
  final asyncData = ref.watch(telemetryStreamProvider);
  return asyncData.when(
    data: (data) => data,
    loading: () => HiveStorageService.getLatestTelemetry(),
    error: (_, __) => HiveStorageService.getLatestTelemetry(),
  );
});
