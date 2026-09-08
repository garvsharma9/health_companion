import os
import re

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# 1. READ AND UPDATE MAIN.DART
main_path = os.path.join(lib_dir, "main.dart")
with open(main_path, "r", encoding="utf-8") as f:
    main_code = f.read()

# Update bottom nav items labels
main_code = main_code.replace('label: ref.tr("dashboard")', 'label: ref.tr("dashboard")')
main_code = main_code.replace('label: ref.tr("hardware")', 'label: ref.tr("hardware")')
main_code = main_code.replace('label: ref.tr("emergency")', 'label: ref.tr("emergency")')

with open(main_path, "w", encoding="utf-8") as f:
    f.write(main_code)

# 2. HELPER TO REPLACE STRINGS IN UI DART FILES
def localize_file(rel_path, replacements):
    fpath = os.path.join(lib_dir, rel_path)
    if not os.path.exists(fpath):
        return
    with open(fpath, "r", encoding="utf-8") as f:
        code = f.read()

    # Make sure locale_provider is imported
    if "locale_provider.dart" not in code:
        depth = len(rel_path.split("/")) - 1
        imp = "../" * depth + "providers/locale_provider.dart"
        code = f"import '{imp}';\n" + code

    for orig, rep in replacements:
        code = code.replace(orig, rep)

    # Remove illegal 'const' before Text(ref.tr(...))
    lines = code.split("\n")
    cleaned_lines = []
    for line in lines:
        if "ref.tr(" in line and line.strip().startswith("const "):
            line = line.replace("const ", "", 1)
        cleaned_lines.append(line)
    
    code = "\n".join(cleaned_lines)
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(code)
    print(f"Localized {rel_path}")

# --- BLE DEVICE SCREEN ---
ble_replacements = [
    ('Text(\n          "Connected Devices",', 'Text(\n          ref.tr("Connected Devices"),'),
    ('Text("Connected Devices")', 'Text(ref.tr("Connected Devices"))'),
    ('"Bluetooth is Turned Off"', 'ref.tr("Bluetooth is Turned Off")'),
    ('"Turn ON Bluetooth in phone settings to pair with ESP32 wearable."', 'ref.tr("Turn ON Bluetooth in phone settings to pair with ESP32 wearable.")'),
    ('const Text(\n                      "HARDWARE SENSOR ARRAY",', 'Text(\n                      ref.tr("HARDWARE SENSOR ARRAY"),'),
    ('"HARDWARE SENSOR ARRAY"', 'ref.tr("HARDWARE SENSOR ARRAY")'),
    ('"MAX30102 HR & SpO2 Sensor"', 'ref.tr("MAX30102 HR & SpO2 Sensor")'),
    ('"DHT22 Temp & Humidity Sensor"', 'ref.tr("DHT22 Temp & Humidity Sensor")'),
    ('"MQ135 Air Quality Sensor"', 'ref.tr("MQ135 Air Quality Sensor")'),
    ('"MPU6050 Accelerometer / Fall"', 'ref.tr("MPU6050 Accelerometer / Fall")'),
    ('"GSR Skin Conductance (Stress)"', 'ref.tr("GSR Skin Conductance (Stress)")'),
    ('"NEO-6M GPS Module"', 'ref.tr("NEO-6M GPS Module")'),
    ('"Active BLE"', 'ref.tr("Active BLE")'),
    ('"Simulator Ready"', 'ref.tr("Simulator Ready")'),
    ('Text("NEARBY BLE DEVICES (${bleState.discoveredDevices.where((d) => d.name.trim().isNotEmpty).length})")', 'Text("${ref.tr("NEARBY BLE DEVICES")} (${bleState.discoveredDevices.where((d) => d.name.trim().isNotEmpty).length})")'),
    ('Text(\n                      "Note: Bluetooth Speakers / Headphones use Classic Bluetooth (A2DP Audio) and do not broadcast BLE sensor telemetry. Only BLE GATT Wearables & ESP32 sensor hardware appear in BLE scanning.",', 'Text(\n                      ref.tr("Note: Bluetooth Speakers / Headphones use Classic Bluetooth (A2DP Audio) and do not broadcast BLE sensor telemetry. Only BLE GATT Wearables & ESP32 sensor hardware appear in BLE scanning."),'),
]
localize_file("screens/ble_device_screen.dart", ble_replacements)

# --- AI ANALYSIS SCREEN ---
ai_replacements = [
    ('"COMPREHENSIVE HEALTH SCORE"', 'ref.tr("COMPREHENSIVE HEALTH SCORE")'),
    ('"Optimal & Stable"', 'ref.tr("Optimal & Stable")'),
    ('"Based on last 24h biometric & sensor telemetry"', 'ref.tr("Based on last 24h biometric & sensor telemetry")'),
    ('"ON-DEVICE EDGE AI EXECUTION"', 'ref.tr("ON-DEVICE EDGE AI EXECUTION")'),
    ('"100% Offline Privacy"', 'ref.tr("100% Offline Privacy")'),
    ('"Detailed Executive Summary"', 'ref.tr("Detailed Executive Summary")'),
    ('"Over the past 24-hour evaluation cycle, your vital signals demonstrated high homeostasis and healthy autonomic adaptability. Resting heart rate averaged 68 BPM with normal circadian dip during REM sleep cycles."', 'ref.tr("Over the past 24-hour evaluation cycle, your vital signals demonstrated high homeostasis and healthy autonomic adaptability. Resting heart rate averaged 68 BPM with normal circadian dip during REM sleep cycles.")'),
    ('"AI PERSONALIZED RECOMMENDATIONS"', 'ref.tr("AI PERSONALIZED RECOMMENDATIONS")'),
    ('"ACTIONABLE LIFESTYLE TIPS"', 'ref.tr("ACTIONABLE LIFESTYLE TIPS")'),
    ('"TELEMETRY INSIGHTS"', 'ref.tr("TELEMETRY INSIGHTS")'),
    ('"Vagal Tone & Recovery"', 'ref.tr("Vagal Tone & Recovery")'),
    ('"Heart rate recovery post-activity averaged 18 BPM drop in 60s, reflecting strong vagal tone."', 'ref.tr("Heart rate recovery post-activity averaged 18 BPM drop in 60s, reflecting strong vagal tone.")'),
    ('"LOGGED HEALTH ANOMALIES"', 'ref.tr("LOGGED HEALTH ANOMALIES")'),
    ('"No health anomalies recorded yet.\\nAll vitals are safe and within normal baseline."', 'ref.tr("No health anomalies recorded yet.\\nAll vitals are safe and within normal baseline.")'),
    ('"Ask AI Assistant"', 'ref.tr("Ask AI Assistant")'),
    ('"Heart Rate Stability"', 'ref.tr("Heart Rate Stability")'),
    ('"Blood Oxygen (SpO2)"', 'ref.tr("Blood Oxygen (SpO2)")'),
    ('"Thermoregulation"', 'ref.tr("Thermoregulation")'),
]
localize_file("screens/ai_analysis_screen.dart", ai_replacements)

# --- ACTIVITY & SLEEP DETAIL SCREENS ---
activity_replacements = [
    ('"Activity & Steps"', 'ref.tr("Activity & Steps")'),
]
localize_file("screens/activity_detail_screen.dart", activity_replacements)

sleep_replacements = [
    ('"Sleep Quality"', 'ref.tr("Sleep Quality")'),
]
localize_file("screens/sleep_detail_screen.dart", sleep_replacements)

# --- AI CHAT BOTTOM SHEET ---
chat_replacements = [
    ('Text(\n                      \'AI Health Assistant\',', 'Text(\n                      ref.tr(\'AI Health Assistant\'),'),
    ('Text(\n                          \'Online • Continuous Vitals Monitoring\',', 'Text(\n                          ref.tr(\'Online • Continuous Vitals Monitoring\'),'),
]
localize_file("widgets/ai_chat_bottom_sheet.dart", chat_replacements)

# --- HEALTH CHART CARD ---
chart_replacements = [
    ('title,', 'ref.tr(title),'),
]
localize_file("widgets/health_chart_card.dart", chart_replacements)

print("Applied complete app localization successfully.")
