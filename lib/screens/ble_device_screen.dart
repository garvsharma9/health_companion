import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ble_provider.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          "Connected Devices",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // Ambient Glows
          if (isDark) ...[
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.electricCyan.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.visionPurple.withValues(alpha: 0.12),
                ),
              ),
            ),
          ],
          StreamBuilder<BleStatus>(
            stream: PermissionService.bleStatusStream,
            initialData: PermissionService.currentBleStatus,
            builder: (context, snapshot) {
              final status = snapshot.data ?? BleStatus.ready;
              final bool isBluetoothOff = status == BleStatus.poweredOff;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
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
                    const Text(
                      "HARDWARE SENSOR ARRAY",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8E8E93),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GlassCard(
                      glowColor: AppTheme.electricCyan,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        children: [
                          _buildSensorRow(
                            name: "MAX30102 HR & SpO2 Sensor",
                            bus: "I2C Address 0x57",
                            status: bleState.isConnected ? "Active BLE" : "Simulator Ready",
                            color: AppTheme.healthyGreen,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            isActive: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(height: 1, thickness: 0.5, color: Colors.white24),
                          ),
                          _buildSensorRow(
                            name: "DHT22 Temp & Humidity Sensor",
                            bus: "GPIO 14 Digital",
                            status: bleState.isConnected ? "Active BLE" : "Simulator Ready",
                            color: AppTheme.healthyGreen,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            isActive: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(height: 1, thickness: 0.5, color: Colors.white24),
                          ),
                          _buildSensorRow(
                            name: "MQ135 Air Quality Sensor",
                            bus: "ADC Pin 34",
                            status: bleState.isConnected ? "Active BLE" : "Simulator Ready",
                            color: AppTheme.healthyGreen,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            isActive: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(height: 1, thickness: 0.5, color: Colors.white24),
                          ),
                          _buildSensorRow(
                            name: "MPU6050 Accelerometer / Fall",
                            bus: "I2C Address 0x68",
                            status: bleState.isConnected ? "Active BLE" : "Simulator Ready",
                            color: AppTheme.healthyGreen,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            isActive: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(height: 1, thickness: 0.5, color: Colors.white24),
                          ),
                          _buildSensorRow(
                            name: "GSR Skin Conductance (Stress)",
                            bus: "ADC Pin 35 (Expansion)",
                            status: "Inactive",
                            color: Colors.grey,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            isActive: false,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Divider(height: 1, thickness: 0.5, color: Colors.white24),
                          ),
                          _buildSensorRow(
                            name: "NEO-6M GPS Module",
                            bus: "UART RX/TX (Not connected)",
                            status: "Inactive",
                            color: Colors.grey,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                            isActive: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- 3. BLE SCANNER SECTION ---
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "NEARBY BLE DEVICES (${bleState.discoveredDevices.where((d) => d.name.trim().isNotEmpty).length})",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8E8E93),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: bleState.isScanning 
                                      ? [AppTheme.criticalRed, Colors.redAccent] 
                                      : [AppTheme.primaryBlueLight, AppTheme.electricCyan],
                                ),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: (bleState.isScanning ? AppTheme.criticalRed : AppTheme.electricCyan).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (bleState.isScanning)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.search, size: 18, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    bleState.isScanning ? "STOP SCAN" : "SCAN BLE",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Device List Render
                    if (bleState.discoveredDevices.where((d) => d.name.trim().isNotEmpty).isEmpty)
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            bleState.isScanning
                                ? "Scanning for named BLE & ESP32 devices...\nEnsure ESP32 is powered ON."
                                : "Tap 'SCAN BLE' above to scan for nearby ESP32 & wearable devices.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: subtitleColor, fontSize: 13, height: 1.4),
                          ),
                        ),
                      )
                    else
                      ...bleState.discoveredDevices
                          .where((d) => d.name.trim().isNotEmpty)
                          .map(
                        (device) => Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GlassCard(
                            padding: EdgeInsets.zero,
                            glowColor: AppTheme.primaryBlueLight,
                            child: ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlueLight.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.bluetooth_searching,
                                    color: AppTheme.primaryBlueLight, size: 20),
                              ),
                              title: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  device.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold, color: textColor, fontSize: 14),
                                ),
                              ),
                              subtitle: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "ID: ${device.id} • RSSI: ${device.rssi} dBm",
                                  style: TextStyle(fontSize: 11, color: subtitleColor),
                                ),
                              ),
                              trailing: _buildConnectButton(context, ref, device, bleState),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Note explaining Classic Bluetooth (Speaker) vs BLE Wearable scanner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlueLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryBlueLight.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppTheme.primaryBlueLight, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Note: Bluetooth Speakers / Headphones use Classic Bluetooth (A2DP Audio) and do not broadcast BLE sensor telemetry. Only BLE GATT Wearables & ESP32 sensor hardware appear in BLE scanning.",
                              style: TextStyle(fontSize: 11, color: subtitleColor, height: 1.4),
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
        ],
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
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(isActive ? Icons.check_circle : Icons.cancel, color: color, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? textColor : subtitleColor),
                ),
                Text(
                  bus,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                status,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ),
        ],
      ),
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
          backgroundColor: AppTheme.warningAmber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 0,
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
            SizedBox(width: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("CONNECTING...",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    if (isConnectedThis) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.healthyGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 0,
        ),
        onPressed: () {
          ref.read(bleProvider.notifier).disconnect();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check, size: 14),
            SizedBox(width: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text("CONNECTED",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.electricCyan,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 0,
      ),
      onPressed: () {
        ref.read(bleProvider.notifier).connect(device);
      },
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text("CONNECT",
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
    );
  }
}
