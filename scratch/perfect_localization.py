import os
import re

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# Update app_translations.dart with smart _sanitize matching
app_trans_path = os.path.join(lib_dir, "localization", "app_translations.dart")
with open(app_trans_path, "r", encoding="utf-8") as f:
    trans_code = f.read()

# Replace translate method with ultra-resilient version
old_translate = re.search(r'static String translate\(String key, String locale\)\s*\{.*?\n  \}', trans_code, re.DOTALL)
new_translate_code = '''static String _sanitize(String s) {
    return s.replaceAll('•', ' ').replaceAll('\\u2022', ' ').replaceAll('-', ' ').replaceAll(RegExp(r'\\s+'), ' ').trim().toLowerCase();
  }

  static String translate(String key, String locale) {
    if (locale != 'hi') {
      return key;
    }
    
    // Direct match
    if (translations["hi"]?[key] != null) {
      return translations["hi"]![key]!;
    }
    
    // Sanitized case-insensitive match
    final cleanKey = _sanitize(key);
    for (final entry in translations["hi"]!.entries) {
      if (_sanitize(entry.key) == cleanKey) {
        return entry.value;
      }
    }
    
    return key;
  }'''

if old_translate:
    trans_code = trans_code.replace(old_translate.group(0), new_translate_code)
    with open(app_trans_path, "w", encoding="utf-8") as f:
        f.write(trans_code)
    print("Updated AppTranslations.translate with ultra-resilient matching.")

# Now scan all screens and widgets to convert remaining raw Text("...") calls to Text(ref.tr("..."))
files_to_check = [
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

def wrap_text_in_file(rel_path):
    fpath = os.path.join(lib_dir, rel_path)
    if not os.path.exists(fpath):
        return
    with open(fpath, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    new_lines = []
    modified_count = 0
    for line in lines:
        # Match Text("...") or Text('...') where string inside is English words and not already ref.tr
        if 'ref.tr(' in line:
            new_lines.append(line)
            continue
            
        def replancer(match):
            nonlocal modified_count
            full_match = match.group(0)
            prefix = match.group(1) # e.g. Text( or const Text(
            quote = match.group(2)
            content = match.group(3)
            
            # Check if content should be translated
            content_clean = content.strip()
            if not content_clean or content_clean.isdigit() or content_clean in ['BPM', '%', '°C', 'h', 'm', 's', 'ms', 'dBm', '24h', '7d', 'AQI']:
                return full_match
            if re.match(r'^\$\{.*?\}\%?$', content_clean):
                return full_match
            if re.match(r'^\d+\s*-\s*\d+.*$', content_clean):
                return full_match
            if len(content_clean) <= 1:
                return full_match
                
            modified_count += 1
            # Return non-const Text(ref.tr("..."))
            return f'Text(ref.tr({quote}{content}{quote}))'

        # Regex for Text("...") or Text('...')
        pattern = re.compile(r'(const\s+Text|Text)\(\s*(["\'])(.*?)\2\s*\)')
        line_mod = pattern.sub(replancer, line)
        
        # Remove leading const if line now contains ref.tr
        if 'ref.tr(' in line_mod and line_mod.strip().startswith('const '):
            line_mod = line_mod.replace('const ', '', 1)
            
        new_lines.append(line_mod)

    if modified_count > 0:
        with open(fpath, "w", encoding="utf-8") as f:
            f.writelines(new_lines)
        print(f"Wrapped {modified_count} strings in {rel_path}")

for rpath in files_to_check:
    wrap_text_in_file(rpath)

print("Perfect localization wrapping completed.")
