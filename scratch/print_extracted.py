import json

with open(r"d:\Sih2026\app\health_companion\scratch\all_extracted_strings.json", "r", encoding="utf-8") as f:
    strings = json.load(f)

print(f"Total: {len(strings)}")
for i, s in enumerate(strings):
    # Print ascii representation or slice
    safe_s = s.encode('ascii', 'backslashreplace').decode('ascii')
    print(f"{i+1:3d}. {safe_s}")
