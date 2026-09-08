import json

with open(r"d:\Sih2026\app\health_companion\scratch\untranslated_analysis.json", "r", encoding="utf-8") as f:
    data = json.load(f)

for fpath, info in data.items():
    print(f"=== {fpath} ===")
    print(f"  tr_keys: {info['tr_keys']}")
    print(f"  text_strings: {info['text_strings']}")
    print()
