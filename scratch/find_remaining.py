import os
import re

lib_dir = r"d:\Sih2026\app\health_companion\lib"

unwrapped = []

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and file != 'app_translations.dart':
            fpath = os.path.join(root, file)
            rel_path = os.path.relpath(fpath, lib_dir)
            with open(fpath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            for lno, line in enumerate(lines, 1):
                if 'Text(' in line and 'ref.tr(' not in line:
                    matches = re.findall(r'Text\(\s*["\']([^"\']+)["\']', line)
                    for m in matches:
                        if m.strip() and not m.startswith('$') and not m.isdigit() and len(m) > 1 and m not in ['%', '°C', 'BPM', '24h', '7d']:
                            unwrapped.append((rel_path, lno, m, line.strip()))

print(f"Total remaining unwrapped Text strings: {len(unwrapped)}\n")
for rel, lno, val, line in unwrapped:
    print(f"[{rel}:{lno}] '{val}' | Code: {line}")
