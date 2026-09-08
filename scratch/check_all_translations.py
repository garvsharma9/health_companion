import os
import re

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# Load app_translations.dart
trans_file = os.path.join(lib_dir, "localization", "app_translations.dart")
with open(trans_file, "r", encoding="utf-8") as f:
    trans_content = f.read()

# Extract keys in 'en' map
en_map_match = re.search(r'"en"\s*:\s*\{([^}]+)\}', trans_content, re.DOTALL)
hi_map_match = re.search(r'"hi"\s*:\s*\{([^}]+)\}', trans_content, re.DOTALL)

en_keys = set(re.findall(r'"([^"]+)":', en_map_match.group(1))) if en_map_match else set()
hi_keys = set(re.findall(r'"([^"]+)":', hi_map_match.group(1))) if hi_map_match else set()

print(f"Total EN keys in dictionary: {len(en_keys)}")
print(f"Total HI keys in dictionary: {len(hi_keys)}")

tr_pattern = re.compile(r'ref\.tr\(\s*["\']([^"\']+)["\']\s*\)')

all_tr_used = set()
hardcoded_texts = []

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and file != 'app_translations.dart':
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                rel_path = os.path.relpath(filepath, lib_dir)
                
                # find ref.tr calls
                for m in tr_pattern.finditer(content):
                    all_tr_used.add((m.group(1), rel_path))
                
                # find raw Text("...") or Text('...')
                raw_texts = re.findall(r'Text\(\s*["\']([^"\']+)["\']', content)
                for t in raw_texts:
                    if not t.startswith("$") and not t.isdigit() and len(t) > 1:
                        hardcoded_texts.append((t, rel_path))

print("\n--- Missing keys in EN dictionary ---")
missing_en = set()
for key, filepath in all_tr_used:
    if key not in en_keys:
        missing_en.add(key)
        print(f"Missing EN key: '{key}' (used in {filepath})")

print("\n--- Missing keys in HI dictionary ---")
missing_hi = set()
for key, filepath in all_tr_used:
    if key not in hi_keys:
        missing_hi.add(key)
        print(f"Missing HI key: '{key}' (used in {filepath})")

print(f"\n--- Hardcoded Text(...) strings ({len(hardcoded_texts)}) ---")
for t, filepath in hardcoded_texts[:30]:
    print(f"[{filepath}] Text('{t}')")
