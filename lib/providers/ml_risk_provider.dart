import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/anomaly_event.dart';
import '../services/local_ml_engine_service.dart';
import '../services/hive_storage_service.dart';
import 'telemetry_provider.dart';

final mlInferenceProvider = Provider<MlInferenceResult>((ref) {
  final telemetry = ref.watch(currentTelemetryProvider);
  final result = LocalMlEngineService.processTelemetry(telemetry);

  // Automatically cache any newly detected critical/high anomaly events into Hive
  for (var anomaly in result.activeAnomalies) {
    HiveStorageService.logAnomaly(anomaly);
  }

  return result;
});

class AnomalyHistoryNotifier extends StateNotifier<List<AnomalyEvent>> {
  AnomalyHistoryNotifier() : super(HiveStorageService.getAnomalyHistory());

  void refresh() {
    state = HiveStorageService.getAnomalyHistory();
  }
}

final anomalyHistoryProvider =
    StateNotifierProvider<AnomalyHistoryNotifier, List<AnomalyEvent>>((ref) {
  return AnomalyHistoryNotifier();
});
