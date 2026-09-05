import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';

class BleDeviceScreen extends ConsumerStatefulWidget {
  const BleDeviceScreen({super.key});

  @override
  ConsumerState<BleDeviceScreen> createState() => _BleDeviceScreenState();
}

class _BleDeviceScreenState extends ConsumerState<BleDeviceScreen>
    with AutomaticKeepAliveClientMixin {
  final List<String> _terminalLogs = [];
  final ScrollController _logScrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bleState = ref.watch(bleProvider);
    final terminalStream = ref.watch(terminalLogsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardTheme.color ?? (isDark ? AppTheme.cardDark : Colors.white);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final subtitleColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    terminalStream.whenData((log) {
      if (_terminalLogs.isEmpty || _terminalLogs.last != log) {
        _terminalLogs.add(log);
        if (_terminalLogs.length > 80) _terminalLogs.removeAt(0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_logScrollController.hasClients) {
            _logScrollController.jumpTo(_logScrollController.position.maxScrollExtent);
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hardware & BLE Hub"),
      ),
      body: StreamBuilder<BleStatus>(
        stream: PermissionService.bleStatusStream,
        initialData: PermissionService.currentBleStatus,
        builder: (context, snapshot) {
          final status = snapshot.data ?? BleStatus.ready;
          final bool isBluetoothOff = status == BleStatus.poweredOff;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. BLUETOOTH ADAPTER OFF WARNING BANNER ---
                if (isBluetoothOff) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bluetooth_disabled, color: Colors.orange, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Bluetooth is Turned Off",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Turn ON Bluetooth in phone settings to pair with ESP32 wearable.",
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- 2. ESP32 HARDWARE SENSOR ARRAY CHECKLIST ---
                Text(
                  "ESP32 Hardware Sensor Array",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _buildSensorRow(
                        name: "MAX30102 HR & SpO2 Sensor",
                        bus: "I2C Address 0x57",
                        status: bleState.isConnected ? "Active BLE" : "Simulator Ready",
                        color: AppTheme.healthyGreen,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const Divider(height: 16),
                      _buildSensorRow(
                        name: "DHT22 Temp & Humidity Sensor",
                        bus: "GPIO 14 Digital",
                        status: bleState.isConnected ? "Active BLE" : "Simulator Ready",
                        color: AppTheme.healthyGreen,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                      const Divider(height: 16),
                      _buildSensorRow(
                        name: "MPU6050 Accelerometer / Fall",
                        bus: "I2C Address 0x68",
                        status: bleState.isConnected ? "Active BLE" : "Simulator Ready",
                        color: AppTheme.healthyGreen,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- 3. BLE SCANNER SECTION ---
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Nearby Named Devices (${bleState.discoveredDevices.where((d) => d.name.trim().isNotEmpty).length})",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bleState.isScanning ? Colors.redAccent : AppTheme.primaryBlueLight,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        await PermissionService.requestAppPermissions();
                        var status = PermissionService.currentBleStatus;
                        if (status == BleStatus.poweredOff) {
                          await PermissionService.enableBluetoothAdapter();
                          for (int i = 0; i < 15; i++) {
                            await Future.delayed(const Duration(milliseconds: 200));
                            if (PermissionService.currentBleStatus == BleStatus.ready) {
                              break;
                            }
                          }
                        }
                        if (bleState.isScanning) {
                          ref.read(bleProvider.notifier).stopScanning();
                        } else {
                          ref.read(bleProvider.notifier).startScanning();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (bleState.isScanning)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          else
                            const Icon(Icons.search, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            bleState.isScanning ? "STOP SCAN" : "SCAN BLE",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Device List Render
                if (bleState.discoveredDevices.where((d) => d.name.trim().isNotEmpty).isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                    ),
                    child: Center(
                      child: Text(
                        bleState.isScanning
                            ? "Scanning for named BLE & ESP32 devices...\nEnsure ESP32 is powered ON."
                            : "Tap 'SCAN BLE' above to scan for nearby ESP32 & wearable devices.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: subtitleColor, fontSize: 12),
                      ),
                    ),
                  )
                else
                  ...bleState.discoveredDevices
                      .where((d) => d.name.trim().isNotEmpty)
                      .map(
                    (device) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryBlueLight.withValues(alpha: 0.25)),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: const Icon(Icons.bluetooth_searching,
                            color: AppTheme.primaryBlueLight, size: 20),
                        title: Text(
                          device.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          "ID: ${device.id} • RSSI: ${device.rssi} dBm",
                          style: TextStyle(fontSize: 10, color: subtitleColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: _buildConnectButton(context, ref, device, bleState),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),

                // Note explaining Classic Bluetooth (Speaker) vs BLE Wearable scanner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppTheme.primaryBlueLight, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Note: Bluetooth Speakers / Headphones use Classic Bluetooth (A2DP Audio) and do not broadcast BLE sensor telemetry. Only BLE GATT Wearables & ESP32 sensor hardware appear in BLE scanning.",
                          style: TextStyle(fontSize: 11, color: subtitleColor, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSensorRow({
    required String name,
    required String bus,
    required String status,
    required Color color,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Row(
      children: [
        Icon(Icons.check_circle, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
              Text(
                bus,
                style: TextStyle(fontSize: 11, color: subtitleColor),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            status,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectButton(
    BuildContext context,
    WidgetRef ref,
    DiscoveredDevice device,
    BleState bleState,
  ) {
    final bool isConnectingThis = !bleState.isSimulating && bleState.connectingDeviceId == device.id;
    final bool isConnectedThis = !bleState.isSimulating &&
        bleState.isConnected &&
        bleState.connectedDeviceId == device.id;

    if (isConnectingThis) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        onPressed: null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 4),
            Text("CONNECTING...",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (isConnectedThis) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.healthyGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        onPressed: () {
          ref.read(bleProvider.notifier).disconnect();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check, size: 12),
            SizedBox(width: 2),
            Text("CONNECTED",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryBlueLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      onPressed: () {
        ref.read(bleProvider.notifier).connect(device);
      },
      child: const Text("CONNECT",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
