import os
import re

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# Matches strings inside quotes: '...' or "..." or '''...''' or """..."""
# We ignore imports, export, keys, assets, icon names, provider names, colors, font families, routes, etc.
ignore_exact = {
    'en', 'hi', 'assets/', 'package:', 'dart:', 'UTF-8', 'BPM', '%', '°C', 'h', 'm', 's', 'ms', 'dBm', 'v1.0.0', 'SIH 2024', 'SIH 26181', 'ESP32'
}

def is_user_facing(s):
    s_clean = s.strip()
    if not s_clean:
        return False
    if s_clean in ignore_exact:
        return False
    if s_clean.startswith('assets/') or s_clean.startswith('package:') or s_clean.startswith('http'):
        return False
    if re.match(r'^[a-zA-Z0-9_\-\./\:]+$', s_clean) and (' ' not in s_clean and '_' in s_clean):
        # Likely an identifier, key or asset path
        return False
    if s_clean.startswith('#') or (len(s_clean) == 1 and not s_clean.isalpha()):
        return False
    # Check if contains letters
    if not re.search(r'[a-zA-Z]', s_clean):
        return False
    return True

file_strings = {}

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            rel_path = os.path.relpath(filepath, lib_dir)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
                
            found_in_file = []
            for line_no, line in enumerate(lines, 1):
                # Skip import/export lines
                if line.strip().startswith('import ') or line.strip().startswith('export '):
                    continue
                # Skip comments
                if line.strip().startswith('//'):
                    continue
                
                # Find all string literals
                matches = re.findall(r"'(.*?)'|\"(.*?)\"", line)
                for m in matches:
                    val = m[0] if m[0] else m[1]
                    if is_user_facing(val):
                        # Filter out key lookups like ref.tr("key") or Map keys in app_translations.dart
                        if 'app_translations.dart' in rel_path:
                            continue
                        if 'ref.tr(' in line and f'"{val}"' in line or f"'{val}'" in line:
                            continue
                        found_in_file.append((line_no, val, line.strip()))
            
            if found_in_file:
                file_strings[rel_path] = found_in_file

print(f"Found non-translated user facing strings in {len(file_strings)} files:\n")
for fpath, string_list in file_strings.items():
    print(f"=== {fpath} ({len(string_list)} un-translated candidates) ===")
    for lno, val, line in string_list[:15]:
        print(f"  Line {lno:3d}: '{val}' | Code: {line[:80]}")
    if len(string_list) > 15:
        print(f"  ... and {len(string_list) - 15} more.")
    print()
