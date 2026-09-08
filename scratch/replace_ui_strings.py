import os
import re

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# Strings to wrap with ref.tr(...)
target_strings = [
  "BODY VITALS", "LIVE SENSORS", "ENVIRONMENTAL AWARENESS", "HEALTH TRENDS",
  "Heart Rate", "SpO2 Oxygen", "Body Temp", "60–100 Normal", "60-100 Normal",
  "95–100% Safe", "95-100% Safe", "36.5–37.5°C", "36.5-37.5°C",
  "Ambient Temp", "Humidity", "Air Quality", "View Full AI Analysis Report",
  "Heart Rate History", "Blood Oxygen SpO2 History", "Body Temperature History",
  "Settings & Demo Controls", "Healthy Vitals", "Moderate Caution", "High Health Risk", "CRITICAL DISASTER ALERT",
  "COMPREHENSIVE HEALTH SCORE", "Optimal & Stable", "Based on last 24h biometric & sensor telemetry",
  "ON-DEVICE EDGE AI EXECUTION", "100% Offline Privacy", "Detailed Executive Summary",
  "AI PERSONALIZED RECOMMENDATIONS", "ACTIONABLE LIFESTYLE TIPS", "TELEMETRY INSIGHTS",
  "Vagal Tone & Recovery", "LOGGED HEALTH ANOMALIES", "Ask AI Assistant",
  "Connected Devices", "Bluetooth is Turned Off",
  "Turn ON Bluetooth in phone settings to pair with ESP32 wearable.",
  "HARDWARE SENSOR ARRAY", "NEARBY BLE DEVICES",
  "CAREGIVER CONTACTS", "ULTRA FAST DISASTER RESPONSE", "OFFLINE FIRST-AID DISASTER GUIDES",
  "Flood", "Cyclone", "Disaster", "General Disaster", "Heat Stroke Emergency Protocol",
  "Severe Air Pollution & Asthma First-Aid", "Flood & Disaster Evacuation Protocol",
  "Help Dispatched!", "Activity & Steps", "Sleep Quality", "Deep Sleep", "Light Sleep", "Awake", "Resting", "Walking", "Running", "Inactive",
  "ABOUT & SIH COMPLIANCE", "Qualcomm SIH 26181 Compliance", "SIH Problem Statement 26181",
  "8 Core Requirements Compliance Matrix", "HARDWARE SIMULATOR & DEMO CONTROLS",
  "Hardware Simulator Mode", "Injects live sensor telemetry when ESP32 is not connected.",
  "1-Tap Anomaly Simulation Triggers", "Heat Stroke Risk", "Fall Detection", "SpO2 Drop Hazard", "Reset Healthy",
  "USER PERSONAL BASELINES", "AI Health Assistant", "Online • Continuous Vitals Monitoring",
  "Heart Rate Stability", "Blood Oxygen (SpO2)", "Thermoregulation"
]

# Sort strings by length descending to prevent substring collisions
target_strings.sort(key=len, reverse=True)

files_to_update = [
    'main.dart',
    'screens/activity_detail_screen.dart',
    'screens/ai_analysis_screen.dart',
    'screens/ble_device_screen.dart',
    'screens/dashboard_screen.dart',
    'screens/disaster_search_screen.dart',
    'screens/emergency_sos_screen.dart',
    'screens/onboarding_screen.dart',
    'screens/settings_screen.dart',
    'screens/sih_compliance_screen.dart',
    'screens/sleep_detail_screen.dart',
    'widgets/ai_chat_bottom_sheet.dart',
    'widgets/glass_card.dart',
    'widgets/health_chart_card.dart'
]

for rpath in files_to_update:
    fpath = os.path.join(lib_dir, rpath)
    if not os.path.exists(fpath):
        continue
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Ensure locale_provider import
    if 'locale_provider.dart' not in content and 'app_translations.dart' not in content:
        # Determine relative path to locale_provider
        depth = len(rpath.split('/')) - 1
        import_path = '../' * depth + 'providers/locale_provider.dart' if depth > 0 else 'providers/locale_provider.dart'
        content = f"import '{import_path}';\n" + content

    modified = content
    for s in target_strings:
        # Pattern for Text("s") or Text('s')
        # Replace Text("s") -> Text(ref.tr("s"))
        # Also handle const Text("s") -> Text(ref.tr("s"))
        p1 = re.compile(rf'const\s+Text\(\s*(["\']){re.escape(s)}\1\s*\)')
        modified = p1.sub(rf'Text(ref.tr("{s}"))', modified)

        p2 = re.compile(rf'Text\(\s*(["\']){re.escape(s)}\1\s*\)')
        modified = p2.sub(rf'Text(ref.tr("{s}"))', modified)
        
        # Handle title: "s", label: "s", baseline: "s"
        p3 = re.compile(rf'title\s*:\s*(["\']){re.escape(s)}\1')
        modified = p3.sub(rf'title: ref.tr("{s}")', modified)
        
        p4 = re.compile(rf'label\s*:\s*(["\']){re.escape(s)}\1')
        modified = p4.sub(rf'label: ref.tr("{s}")', modified)

        p5 = re.compile(rf'baseline\s*:\s*(["\']){re.escape(s)}\1')
        modified = p5.sub(rf'baseline: ref.tr("{s}")', modified)

    # Clean up any leftover illegal `const` inside widgets where ref.tr is used
    # e.g., const Row(children: [Text(ref.tr(...))])
    # A simple regex to fix const elements containing ref.tr
    lines = modified.split('\n')
    new_lines = []
    for line in lines:
        if 'ref.tr(' in line and line.strip().startswith('const '):
            line = line.replace('const ', '', 1)
        new_lines.append(line)
    
    modified = '\n'.join(new_lines)

    if modified != content:
        with open(fpath, 'w', encoding='utf-8') as f:
            f.write(modified)
        print(f"Successfully updated {rpath}")

print("Replacement complete.")
