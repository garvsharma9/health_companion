import os
import re

lib_dir = r"d:\Sih2026\app\health_companion\lib"
trans_path = os.path.join(lib_dir, "localization", "app_translations.dart")

with open(trans_path, "r", encoding="utf-8") as f:
    code = f.read()

# Extract 'en' map content and 'hi' map content
en_match = re.search(r'"en"\s*:\s*\{([^}]+)\}', code, re.DOTALL)
hi_match = re.search(r'"hi"\s*:\s*\{([^}]+)\}', code, re.DOTALL)

def dedupe_map_str(map_str):
    seen_keys = set()
    new_lines = []
    for line in map_str.split('\n'):
        km = re.search(r'^\s*["\']([^"\']+)["\']\s*:', line)
        if km:
            key = km.group(1)
            if key in seen_keys:
                continue # Skip duplicate key line
            seen_keys.add(key)
        new_lines.append(line)
    return '\n'.join(new_lines)

if en_match and hi_match:
    new_en = dedupe_map_str(en_match.group(1))
    new_hi = dedupe_map_str(hi_match.group(1))
    
    code = code[:en_match.start(1)] + new_en + code[en_match.end(1):]
    # Re-find hi_match start/end after replacement
    hi_match2 = re.search(r'"hi"\s*:\s*\{([^}]+)\}', code, re.DOTALL)
    code = code[:hi_match2.start(1)] + new_hi + code[hi_match2.end(1):]
    
    with open(trans_path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Successfully deduped app_translations.dart")
