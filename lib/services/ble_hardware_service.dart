import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../models/telemetry_data.dart';
import 'hive_storage_service.dart';

class BleHardwareService {
  static final FlutterReactiveBle _ble = FlutterReactiveBle();

  // BLE Service & Characteristic UUIDs for ESP32
  static final Uuid _serviceUuid =
      Uuid.parse("0000ffe0-0000-1000-8000-00805f9b34fb");
  static final Uuid _characteristicUuid =
      Uuid.parse("0000ffe1-0000-1000-8000-00805f9b34fb");

  static final StreamController<TelemetryData> _telemetryStreamController =
      StreamController<TelemetryData>.broadcast();

  static final StreamController<String> _rawTerminalLogController =
      StreamController<String>.broadcast();

  static final StreamController<ConnectionStateUpdate> _connectionStateController =
      StreamController<ConnectionStateUpdate>.broadcast();

  static StreamSubscription? _scanSubscription;
  static StreamSubscription? _connectionSubscription;
  static StreamSubscription? _notifySubscription;
  static StreamSubscription? _connectedDeviceSubscription;
  static Timer? _simulationTimer;

  static bool isConnected = false;
  static bool isSimulating = true;
  static String deviceName = "Disconnected";
  static String connectionStatusText = "Disconnected (Hardware Sim Active)";
  static String? connectingDeviceId;
  static String? connectedDeviceId;

  static Stream<TelemetryData> get telemetryStream =>
      _telemetryStreamController.stream;
  static Stream<String> get terminalLogStream =>
      _rawTerminalLogController.stream;
  static Stream<ConnectionStateUpdate> get connectionStateStream =>
      _connectionStateController.stream;

  static TelemetryData _currentTelemetry = TelemetryData.initial();
  static TelemetryData get currentTelemetry => _currentTelemetry;

  /// Initialize BLE & Hardware Simulator
  static void init() {
    isSimulating = HiveStorageService.isHardwareSimMode();
    _currentTelemetry = HiveStorageService.getLatestTelemetry();

    _listenToSystemConnectedDevices();

    if (isSimulating) {
      startSimulator();
    }
  }

  /// Listens to system Bluetooth connections (e.g. connected via Phone Settings menu)
  static void _listenToSystemConnectedDevices() {
    _connectedDeviceSubscription?.cancel();
    _connectedDeviceSubscription = _ble.connectedDeviceStream.listen((update) {
      _connectionStateController.add(update);
      if (update.connectionState == DeviceConnectionState.connected) {
        if (!isSimulating) {
          isConnected = true;
          connectedDeviceId = update.deviceId;
          connectingDeviceId = null;
          connectionStatusText = "Connected to System BLE Device";
          _rawTerminalLogController
              .add("[BLE SYSTEM MATCH] System Bluetooth paired with ${update.deviceId}");
          _subscribeToCharacteristic(update.deviceId);
        }
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        if (connectedDeviceId == update.deviceId) {
          isConnected = false;
          connectedDeviceId = null;
          connectingDeviceId = null;
          connectionStatusText = "Disconnected from device";
          _rawTerminalLogController.add("[BLE] System device disconnected.");
        }
      }
    });
  }

  // --- HARDWARE SIMULATION ENGINE ---
  static void startSimulator() {
    _simulationTimer?.cancel();
    isSimulating = true;
    connectionStatusText = "Simulated ESP32 (Hardware Sim Mode)";
    deviceName = "ESP32_Simulator_Device";
    isConnected = true;

    _rawTerminalLogController
        .add("[SIM] Hardware Simulation Engine Started.");

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _currentTelemetry = _currentTelemetry.copyWithFluctuations(customSim: true);
      _telemetryStreamController.add(_currentTelemetry);
      HiveStorageService.cacheLatestTelemetry(_currentTelemetry);

      _rawTerminalLogController.add(
          "[SIM RX] HR:${_currentTelemetry.heartRate.toStringAsFixed(0)} BPM | SpO2:${_currentTelemetry.spO2.toStringAsFixed(1)}% | Temp:${_currentTelemetry.bodyTemp.toStringAsFixed(1)}°C | AQI:${_currentTelemetry.aqi.toStringAsFixed(0)}");
    });
  }

  static void stopSimulator() {
    _simulationTimer?.cancel();
    isSimulating = false;
  }

  /// Inject specific anomaly for testing without hardware
  static void injectSimulatedAnomaly(String type) {
    if (!isSimulating) startSimulator();

    switch (type) {
      case 'heat':
        _currentTelemetry = _currentTelemetry.copyWithFluctuations(
          customBodyTemp: 39.2,
          customAmbientTemp: 41.5,
          customHr: 118.0,
        );
        _rawTerminalLogController
            .add("[INJECT] Heat Stroke Hazard Payload Injected!");
        break;
      case 'spo2':
        _currentTelemetry = _currentTelemetry.copyWithFluctuations(
          customSpO2: 89.0,
          customAqi: 245.0,
        );
        _rawTerminalLogController
            .add("[INJECT] Respiratory / SpO2 Drop Injected!");
        break;
      case 'fall':
        _currentTelemetry = _currentTelemetry.copyWithFluctuations(
          customAccelZ: 26.5,
        );
        _rawTerminalLogController
            .add("[INJECT] MPU6050 High-G Fall Vector Injected!");
        break;
      case 'cardiac':
        _currentTelemetry = _currentTelemetry.copyWithFluctuations(
          customHr: 152.0,
          customSpO2: 91.0,
        );
        _rawTerminalLogController
            .add("[INJECT] Tachycardia Cardiac Anomaly Injected!");
        break;
      case 'normal':
        _currentTelemetry = TelemetryData.initial();
        _rawTerminalLogController
            .add("[INJECT] Reset to Healthy Baseline Telemetry.");
        break;
    }
    _telemetryStreamController.add(_currentTelemetry);
    HiveStorageService.cacheLatestTelemetry(_currentTelemetry);
  }

  // --- REAL ESP32 BLE CONNECTION ---
  static void toggleSimulationMode(bool enableSim) {
    HiveStorageService.setHardwareSimMode(enableSim);
    if (enableSim) {
      disconnectRealDevice();
      startSimulator();
    } else {
      stopSimulator();
      isConnected = false;
      connectedDeviceId = null;
      connectingDeviceId = null;
      connectionStatusText = "Ready to Scan real ESP32 BLE";
      deviceName = "No BLE Device";
    }
  }

  static Future<void> startBleScan(
      Function(DiscoveredDevice) onDeviceDiscovered) async {
    if (isSimulating) stopSimulator();

    connectionStatusText = "Scanning for ESP32 BLE...";
    _rawTerminalLogController.add("[BLE] Scanning for Health Companion ESP32...");

    _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {
      if (device.name.trim().isNotEmpty) {
        onDeviceDiscovered(device);
      }
    }, onError: (e) {
      connectionStatusText = "BLE Scan Error: $e";
      _rawTerminalLogController.add("[BLE ERROR] $e");
    });
  }

  static void stopScan() {
    _scanSubscription?.cancel();
    if (!isConnected && !isSimulating) {
      connectionStatusText = "Scan Stopped";
    }
  }

  static Future<void> connectToDevice(DiscoveredDevice device) async {
    stopScan();
    stopSimulator();

    connectingDeviceId = device.id;
    deviceName = device.name.isEmpty ? "ESP32_Health_Companion" : device.name;
    connectionStatusText = "Connecting to ${device.name}...";
    _rawTerminalLogController.add("[BLE] Connecting to ${device.id}");

    _connectionStateController.add(ConnectionStateUpdate(
      deviceId: device.id,
      connectionState: DeviceConnectionState.connecting,
      failure: null,
    ));

    _connectionSubscription?.cancel();
    _connectionSubscription = _ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 12),
    )
        .listen((connectionState) {
      _connectionStateController.add(connectionState);
      switch (connectionState.connectionState) {
        case DeviceConnectionState.connecting:
          connectingDeviceId = device.id;
          connectionStatusText = "Connecting to ${device.name}...";
          break;
        case DeviceConnectionState.connected:
          isConnected = true;
          connectingDeviceId = null;
          connectedDeviceId = device.id;
          connectionStatusText = "Connected to $deviceName";
          _rawTerminalLogController
              .add("[BLE CONNECTED] Subscribing to telemetry characteristic...");
          _subscribeToCharacteristic(device.id);
          break;
        case DeviceConnectionState.disconnecting:
          connectionStatusText = "Disconnecting...";
          break;
        case DeviceConnectionState.disconnected:
          isConnected = false;
          connectingDeviceId = null;
          connectedDeviceId = null;
          deviceName = "Disconnected";
          connectionStatusText = "Disconnected from device";
          _rawTerminalLogController.add("[BLE] Disconnected.");
          break;
      }
    }, onError: (e) {
      connectingDeviceId = null;
      connectedDeviceId = null;
      isConnected = false;
      deviceName = "Disconnected";
      connectionStatusText = "Connection Failed: $e";
      _rawTerminalLogController.add("[BLE ERROR] $e");
      _connectionStateController.add(ConnectionStateUpdate(
        deviceId: device.id,
        connectionState: DeviceConnectionState.disconnected,
        failure: GenericFailure(
            code: ConnectionError.unknown, message: e.toString()),
      ));
    });
  }

  static void _subscribeToCharacteristic(String deviceId) {
    final characteristic = QualifiedCharacteristic(
      serviceId: _serviceUuid,
      characteristicId: _characteristicUuid,
      deviceId: deviceId,
    );

    _notifySubscription?.cancel();
    _notifySubscription = _ble.subscribeToCharacteristic(characteristic).listen(
      (data) {
        try {
          final payloadStr = utf8.decode(data);
          _rawTerminalLogController.add("[BLE RX] $payloadStr");

          final json = jsonDecode(payloadStr);
          _currentTelemetry = TelemetryData.fromJson(json);
          _telemetryStreamController.add(_currentTelemetry);
          HiveStorageService.cacheLatestTelemetry(_currentTelemetry);
        } catch (e) {
          _rawTerminalLogController
              .add("[BLE PARSE WARN] Non-JSON payload: $data");
        }
      },
      onError: (e) {
        _rawTerminalLogController.add("[BLE NOTIFY ERROR] $e");
      },
    );
  }

  static void disconnectRealDevice() {
    final prevId = connectedDeviceId ?? connectingDeviceId;
    _notifySubscription?.cancel();
    _connectionSubscription?.cancel();
    _scanSubscription?.cancel();
    isConnected = false;
    connectingDeviceId = null;
    connectedDeviceId = null;
    deviceName = "No BLE Device";
    connectionStatusText = "Disconnected from device";
    if (prevId != null) {
      _connectionStateController.add(ConnectionStateUpdate(
        deviceId: prevId,
        connectionState: DeviceConnectionState.disconnected,
        failure: null,
      ));
    }
  }
}
