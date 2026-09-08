import os

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# 1. Update AppTranslations
trans_path = os.path.join(lib_dir, "localization", "app_translations.dart")
with open(trans_path, "r", encoding="utf-8") as f:
    code = f.read()

# Add missing activity/sleep strings to EN and HI maps
new_en_entries = '''      "Duration": "Duration",
      "Quality Score": "Quality Score",
      "Active kCal": "Active kCal",
      "24-HOUR ACTIVITY INTENSITY": "24-HOUR ACTIVITY INTENSITY",
      "7-DAY ACTIVITY TREND": "7-DAY ACTIVITY TREND",
      "LAST NIGHT'S SLEEP STAGES": "LAST NIGHT'S SLEEP STAGES",
      "7-DAY SLEEP TREND": "7-DAY SLEEP TREND",
      "Resting": "Resting",
      "Walking": "Walking",
      "Running": "Running",
      "Exercise": "Exercise",
      "Inactive": "Inactive",
      "Deep Sleep": "Deep Sleep",
      "Light Sleep": "Light Sleep",
      "Awake": "Awake",'''

new_hi_entries = '''      "Duration": "अवधि",
      "Quality Score": "गुणवत्ता स्कोर",
      "Active kCal": "सक्रिय कैलोरी",
      "24-HOUR ACTIVITY INTENSITY": "24-घंटे की गतिविधि की तीव्रता",
      "7-DAY ACTIVITY TREND": "7-दिवसीय गतिविधि रुझान",
      "LAST NIGHT'S SLEEP STAGES": "कल रात की नींद के चरण",
      "7-DAY SLEEP TREND": "7-दिवसीय नींद का रुझान",
      "Resting": "आराम",
      "Walking": "चलना",
      "Running": "दौड़ना",
      "Exercise": "व्यायाम",
      "Inactive": "निष्क्रिय",
      "Deep Sleep": "गहरी नींद",
      "Light Sleep": "हल्की नींद",
      "Awake": "जागना",'''

if '"Duration"' not in code:
    code = code.replace('"en": {', '"en": {\n' + new_en_entries)
    code = code.replace('"hi": {', '"hi": {\n' + new_hi_entries)
    with open(trans_path, "w", encoding="utf-8") as f:
        f.write(code)
    print("Added activity & sleep entries to app_translations.dart")

# 2. Update dashboard_screen.dart
dash_path = os.path.join(lib_dir, "screens", "dashboard_screen.dart")
with open(dash_path, "r", encoding="utf-8") as f:
    dcode = f.read()

dcode = dcode.replace('Text(activitySleepState.activityLevel,', 'Text(ref.tr(activitySleepState.activityLevel),')
dcode = dcode.replace('Text(activitySleepState.sleepState,', 'Text(ref.tr(activitySleepState.sleepState),')

with open(dash_path, "w", encoding="utf-8") as f:
    f.write(dcode)
print("Updated dashboard_screen.dart activity & sleep pills")

# 3. Update activity_detail_screen.dart
act_path = os.path.join(lib_dir, "screens", "activity_detail_screen.dart")
with open(act_path, "r", encoding="utf-8") as f:
    acode = f.read()

acode = acode.replace('Text(\n                    activityState.activityLevel,', 'Text(\n                    ref.tr(activityState.activityLevel),')
acode = acode.replace('Text(activityState.activityLevel,', 'Text(ref.tr(activityState.activityLevel),')
acode = acode.replace('_buildMetricBox("Steps",', '_buildMetricBox(ref.tr("steps_normal"),')
acode = acode.replace('_buildMetricBox("Active kCal",', '_buildMetricBox(ref.tr("Active kCal"),')
acode = acode.replace('_is24h ? "24-HOUR ACTIVITY INTENSITY" : "7-DAY ACTIVITY TREND"', 'ref.tr(_is24h ? "24-HOUR ACTIVITY INTENSITY" : "7-DAY ACTIVITY TREND")')

with open(act_path, "w", encoding="utf-8") as f:
    f.write(acode)
print("Updated activity_detail_screen.dart")

# 4. Update sleep_detail_screen.dart
sleep_path = os.path.join(lib_dir, "screens", "sleep_detail_screen.dart")
with open(sleep_path, "r", encoding="utf-8") as f:
    scode = f.read()

scode = scode.replace('Text(\n                    sleepState.sleepState,', 'Text(\n                    ref.tr(sleepState.sleepState),')
scode = scode.replace('Text(sleepState.sleepState,', 'Text(ref.tr(sleepState.sleepState),')
scode = scode.replace('_buildMetricBox("Duration",', '_buildMetricBox(ref.tr("Duration"),')
scode = scode.replace('_buildMetricBox("Quality Score",', '_buildMetricBox(ref.tr("Quality Score"),')
scode = scode.replace('_is24h ? "LAST NIGHT\'S SLEEP STAGES" : "7-DAY SLEEP TREND"', 'ref.tr(_is24h ? "LAST NIGHT\'S SLEEP STAGES" : "7-DAY SLEEP TREND")')

with open(sleep_path, "w", encoding="utf-8") as f:
    f.write(scode)
print("Updated sleep_detail_screen.dart")
