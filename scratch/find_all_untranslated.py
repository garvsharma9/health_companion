import os
import re
import json

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# Load app_translations.dart
trans_file = os.path.join(lib_dir, "localization", "app_translations.dart")
with open(trans_file, "r", encoding="utf-8") as f:
    trans_content = f.read()

# Extract keys in 'en' map
en_map_match = re.search(r'"en"\s*:\s*\{([^}]+)\}', trans_content, re.DOTALL)
hi_map_match = re.search(r'"hi"\s*:\s*\{([^}]+)\}', trans_content, re.DOTALL)

en_keys = set(re.findall(r'"([^"]+)":', en_map_match.group(1))) if en_map_match else set()

print(f"Total existing keys in app_translations.dart: {len(en_keys)}")

# Let's inspect every dart file in screens/ and widgets/ and main.dart
target_files = [
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

results = {}

for rel_path in target_files:
    filepath = os.path.join(lib_dir, rel_path)
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check ref.tr calls
    tr_matches = re.findall(r'ref\.tr\(\s*["\']([^"\']+)["\']\s*\)', content)
    
    # Check Text("...")
    text_matches = re.findall(r'Text\(\s*["\']([^"\']+)["\']', content)
    
    results[rel_path] = {
        'tr_keys': list(set(tr_matches)),
        'text_strings': list(set(text_matches))
    }

with open(r"d:\Sih2026\app\health_companion\scratch\untranslated_analysis.json", "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)

print("Saved untranslated_analysis.json successfully.")
