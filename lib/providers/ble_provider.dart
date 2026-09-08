import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ble_hardware_service.dart';

class BleState {
  final bool isSimulating;
  final bool isConnected;
  final bool isScanning;
  final String statusMessage;
  final String deviceName;
  final String? connectingDeviceId;
  final String? connectedDeviceId;
  final List<DiscoveredDevice> discoveredDevices;

  BleState({
    required this.isSimulating,
    required this.isConnected,
    this.isScanning = false,
    required this.statusMessage,
    required this.deviceName,
    this.connectingDeviceId,
    this.connectedDeviceId,
    required this.discoveredDevices,
  });

  BleState copyWith({
    bool? isSimulating,
    bool? isConnected,
    bool? isScanning,
    String? statusMessage,
    String? deviceName,
    String? connectingDeviceId,
    String? connectedDeviceId,
    List<DiscoveredDevice>? discoveredDevices,
    bool resetConnecting = false,
  }) {
    return BleState(
      isSimulating: isSimulating ?? this.isSimulating,
      isConnected: isConnected ?? this.isConnected,
      isScanning: isScanning ?? this.isScanning,
      statusMessage: statusMessage ?? this.statusMessage,
      deviceName: deviceName ?? this.deviceName,
      connectingDeviceId:
          resetConnecting ? null : (connectingDeviceId ?? this.connectingDeviceId),
      connectedDeviceId: connectedDeviceId ?? this.connectedDeviceId,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
    );
  }
}

class BleNotifier extends StateNotifier<BleState> {
  StreamSubscription? _connectionStateSub;

  BleNotifier()
      : super(BleState(
          isSimulating: BleHardwareService.isSimulating,
          isConnected: BleHardwareService.isConnected,
          isScanning: false,
          statusMessage: BleHardwareService.connectionStatusText,
          deviceName: BleHardwareService.deviceName,
          connectingDeviceId: BleHardwareService.connectingDeviceId,
          connectedDeviceId: BleHardwareService.connectedDeviceId,
          discoveredDevices: [],
        )) {
    _initConnectionListener();
  }

  void _initConnectionListener() {
    _connectionStateSub?.cancel();
    _connectionStateSub = BleHardwareService.connectionStateStream.listen((update) {
      if (update.connectionState == DeviceConnectionState.connecting) {
        state = state.copyWith(
          isScanning: false,
          connectingDeviceId: update.deviceId,
          statusMessage: "Connecting to ${update.deviceId}...",
        );
      } else if (update.connectionState == DeviceConnectionState.connected) {
        state = state.copyWith(
          isConnected: true,
          isScanning: false,
          connectedDeviceId: update.deviceId,
          resetConnecting: true,
          statusMessage: "Connected to ${BleHardwareService.deviceName}",
        );
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        state = state.copyWith(
          isConnected: false,
          isScanning: false,
          connectedDeviceId: null,
          resetConnecting: true,
          deviceName: BleHardwareService.deviceName,
          statusMessage: BleHardwareService.connectionStatusText,
        );
      }
    });
  }

  void toggleSimulator(bool enableSim) {
    BleHardwareService.toggleSimulationMode(enableSim);
    state = state.copyWith(
      isSimulating: enableSim,
      isConnected: enableSim,
      isScanning: false,
      statusMessage: BleHardwareService.connectionStatusText,
      deviceName: BleHardwareService.deviceName,
      discoveredDevices: enableSim ? [] : state.discoveredDevices,
      resetConnecting: true,
    );
  }

  void injectAnomaly(String type) {
    BleHardwareService.injectSimulatedAnomaly(type);
    state = state.copyWith(
      statusMessage: "Simulated Anomaly Injected: $type",
    );
  }

  void startScanning() {
    state = state.copyWith(
      isScanning: true,
      discoveredDevices: [],
      statusMessage: "scanning_devices",
    );
    BleHardwareService.startBleScan((device) {
      final list = List<DiscoveredDevice>.from(state.discoveredDevices);
      if (!list.any((d) => d.id == device.id)) {
        list.add(device);
        state = state.copyWith(discoveredDevices: list);
      }
    });
  }

  void stopScanning() {
    BleHardwareService.stopScan();
    state = state.copyWith(
      isScanning: false,
      statusMessage: BleHardwareService.connectionStatusText,
    );
  }

  void connect(DiscoveredDevice device) async {
    state = state.copyWith(
      isScanning: false,
      connectingDeviceId: device.id,
      statusMessage: "Connecting to ${device.name}...",
    );
    await BleHardwareService.connectToDevice(device);
  }

  void disconnect() {
    BleHardwareService.disconnectRealDevice();
    state = state.copyWith(
      isConnected: false,
      isScanning: false,
      connectedDeviceId: null,
      connectingDeviceId: null,
      resetConnecting: true,
      deviceName: "No BLE Device",
      statusMessage: "Disconnected from device",
    );
  }

  @override
  void dispose() {
    _connectionStateSub?.cancel();
    super.dispose();
  }
}

final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  return BleNotifier();
});

final terminalLogsProvider = StreamProvider<String>((ref) {
  return BleHardwareService.terminalLogStream;
});
