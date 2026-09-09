import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'telemetry_provider.dart';
import 'activity_sleep_provider.dart';

final homeWidgetSyncProvider = Provider<HomeWidgetSyncService>((ref) {
  final service = HomeWidgetSyncService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class HomeWidgetSyncService {
  final Ref ref;
  Timer? _syncTimer;

  HomeWidgetSyncService(this.ref) {
    if (!kIsWeb) {
      _startSyncTimer();
    }
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final telemetry = ref.read(currentTelemetryProvider);
        final activity = ref.read(activitySleepProvider);

        if (telemetry != null) {
          await HomeWidget.saveWidgetData<String>('hr', telemetry.heartRate.toStringAsFixed(0));
          await HomeWidget.saveWidgetData<String>('spo2', telemetry.spO2.toStringAsFixed(1));
          await HomeWidget.saveWidgetData<String>('temp', telemetry.bodyTemp.toStringAsFixed(1));
        }

        final sleepHr = activity.sleepDurationMinutes ~/ 60;
        final sleepMin = activity.sleepDurationMinutes % 60;
        await HomeWidget.saveWidgetData<String>('steps', activity.steps.toString());
        await HomeWidget.saveWidgetData<String>('sleep_h', sleepHr.toString());
        await HomeWidget.saveWidgetData<String>('sleep_m', sleepMin.toString());

        await Future.wait([
          HomeWidget.updateWidget(name: 'HeartRateWidgetProvider'),
          HomeWidget.updateWidget(name: 'SpO2WidgetProvider'),
          HomeWidget.updateWidget(name: 'BodyTempWidgetProvider'),
          HomeWidget.updateWidget(name: 'SleepWidgetProvider'),
          HomeWidget.updateWidget(name: 'ActivityWidgetProvider'),
        ]);
      } catch (e) {
        debugPrint("Home Widget Sync Error: $e");
      }
    });
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}
