import os
import re
import json

lib_dir = r"d:\Sih2026\app\health_companion\lib"

files_to_check = [
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

# We want to find all strings inside quotes that are user facing
extracted_strings = set()

for rpath in files_to_check:
    fpath = os.path.join(lib_dir, rpath)
    if not os.path.exists(fpath):
        continue
    with open(fpath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Matches in ref.tr("...") or ref.tr('...')
    for m in re.finditer(r'ref\.tr\(\s*["\']([^"\']+)["\']\s*\)', content):
        extracted_strings.add(m.group(1))
        
    # 2. Text("...")
    for m in re.finditer(r'Text\(\s*["\']([^"\']+)["\']', content):
        extracted_strings.add(m.group(1))
        
    # 3. title: "...", subtitle: "...", label: "...", baseline: "...", tooltip: "..."
    for m in re.finditer(r'(?:title|subtitle|label|baseline|tooltip|name|status|description|header)\s*:\s*["\']([^"\']+)["\']', content):
        extracted_strings.add(m.group(1))

# Filter out non-user facing
ignore = {'en', 'hi', 'assets/', 'BPM', '%', '°C', 'h', 'm', 's', 'ms', 'dBm', 'v1.0.0', 'SIH 2024', 'SIH 26181', 'ESP32'}

clean_extracted = []
for s in sorted(extracted_strings):
    if s in ignore:
        continue
    if s.startswith('assets/') or s.startswith('package:') or s.startswith('http'):
        continue
    if s.isdigit():
        continue
    clean_extracted.append(s)

print(f"Total unique extracted strings to translate: {len(clean_extracted)}")
with open(r"d:\Sih2026\app\health_companion\scratch\all_extracted_strings.json", "w", encoding="utf-8") as f:
    json.dump(clean_extracted, f, indent=2, ensure_ascii=False)

print("Saved all_extracted_strings.json successfully.")
