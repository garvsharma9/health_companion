import os
import re
import json

lib_dir = r"d:\Sih2026\app\health_companion\lib"

# Dictionary of all English -> Hindi translations
translations_dict = {
  # Navigation & Common
  "dashboard": ("Dashboard", "डैशबोर्ड"),
  "hardware": ("Hardware", "हार्डवेयर"),
  "emergency": ("Emergency", "आपातकालीन"),
  "ai_analysis": ("AI Analysis", "AI विश्लेषण"),
  "sos": ("SOS", "आपातकालीन (SOS)"),
  "settings": ("Settings", "सेटिंग्स"),

  # Dashboard
  "BODY VITALS": ("BODY VITALS", "शरीर के महत्वपूर्ण संकेत"),
  "LIVE SENSORS": ("LIVE SENSORS", "लाइव सेंसर"),
  "ENVIRONMENTAL AWARENESS": ("ENVIRONMENTAL AWARENESS", "पर्यावरण जागरूकता"),
  "HEALTH TRENDS": ("HEALTH TRENDS", "स्वास्थ्य रुझान"),
  "Heart Rate": ("Heart Rate", "हृदय गति"),
  "SpO2 Oxygen": ("SpO2 Oxygen", "SpO2 ऑक्सीजन"),
  "Body Temp": ("Body Temp", "शरीर का तापमान"),
  "60–100 Normal": ("60–100 Normal", "60–100 सामान्य"),
  "60-100 Normal": ("60-100 Normal", "60-100 सामान्य"),
  "95–100% Safe": ("95–100% Safe", "95–100% सुरक्षित"),
  "95-100% Safe": ("95-100% Safe", "95-100% सुरक्षित"),
  "36.5–37.5°C": ("36.5–37.5°C", "36.5–37.5°C"),
  "36.5-37.5°C": ("36.5-37.5°C", "36.5-37.5°C"),
  "Ambient Temp": ("Ambient Temp", "आसपास का तापमान"),
  "Humidity": ("Humidity", "आर्द्रता"),
  "Air Quality": ("Air Quality", "वायु गुणवत्ता"),
  "View Full AI Analysis Report": ("View Full AI Analysis Report", "पूरी AI विश्लेषण रिपोर्ट देखें"),
  "Heart Rate History": ("Heart Rate History", "हृदय गति इतिहास"),
  "Blood Oxygen SpO2 History": ("Blood Oxygen SpO2 History", "रक्त ऑक्सीजन SpO2 इतिहास"),
  "Body Temperature History": ("Body Temperature History", "शरीर के तापमान का इतिहास"),
  "Settings & Demo Controls": ("Settings & Demo Controls", "सेटिंग्स और डेमो नियंत्रण"),
  "Healthy Vitals": ("Healthy Vitals", "स्वस्थ स्वास्थ्य संकेत"),
  "Moderate Caution": ("Moderate Caution", "मध्यम सावधानी"),
  "High Health Risk": ("High Health Risk", "उच्च स्वास्थ्य जोखिम"),
  "CRITICAL DISASTER ALERT": ("CRITICAL DISASTER ALERT", "गंभीर आपदा अलर्ट"),

  # AI Analysis
  "COMPREHENSIVE HEALTH SCORE": ("COMPREHENSIVE HEALTH SCORE", "व्यापक स्वास्थ्य स्कोर"),
  "Optimal & Stable": ("Optimal & Stable", "सर्वोत्तम और स्थिर"),
  "Based on last 24h biometric & sensor telemetry": ("Based on last 24h biometric & sensor telemetry", "पिछले 24 घंटों के बायोमेट्रिक और सेंसर डेटा के आधार पर"),
  "ON-DEVICE EDGE AI EXECUTION": ("ON-DEVICE EDGE AI EXECUTION", "ऑन-डिवाइस एज AI निष्पादन"),
  "100% Offline Privacy": ("100% Offline Privacy", "100% ऑफ़लाइन गोपनीयता"),
  "Detailed Executive Summary": ("Detailed Executive Summary", "विस्तृत मुख्य सारांश"),
  "Over the past 24-hour evaluation cycle, your vital signals demonstrated high homeostasis and healthy autonomic adaptability. Resting heart rate averaged 68 BPM with normal circadian dip during REM sleep cycles.": ("Over the past 24-hour evaluation cycle, your vital signals demonstrated high homeostasis and healthy autonomic adaptability. Resting heart rate averaged 68 BPM with normal circadian dip during REM sleep cycles.", "पिछले 24 घंटों के दौरान, आपके संकेतों ने उच्च स्थिरता का प्रदर्शन किया। विश्राम हृदय गति 68 BPM रही।"),
  "AI PERSONALIZED RECOMMENDATIONS": ("AI PERSONALIZED RECOMMENDATIONS", "AI व्यक्तिगत सुझाव"),
  "ACTIONABLE LIFESTYLE TIPS": ("ACTIONABLE LIFESTYLE TIPS", "कार्रवाई योग्य जीवन शैली युक्तियाँ"),
  "TELEMETRY INSIGHTS": ("TELEMETRY INSIGHTS", "टेलीमेट्री अंतर्दृष्टि"),
  "Vagal Tone & Recovery": ("Vagal Tone & Recovery", "वैगल टोन और रिकवरी"),
  "Heart rate recovery post-activity averaged 18 BPM drop in 60s, reflecting strong vagal tone.": ("Heart rate recovery post-activity averaged 18 BPM drop in 60s, reflecting strong vagal tone.", "गतिविधि के बाद हृदय गति में 60 सेकंड में औसतन 18 BPM की गिरावट आई, जो मजबूत वैगल टोन को दर्शाती है।"),
  "LOGGED HEALTH ANOMALIES": ("LOGGED HEALTH ANOMALIES", "दर्ज की गई स्वास्थ्य विसंगतियां"),
  "No health anomalies recorded yet.\nAll vitals are safe and within normal baseline.": ("No health anomalies recorded yet.\nAll vitals are safe and within normal baseline.", "अभी तक कोई स्वास्थ्य विसंगति दर्ज नहीं की गई है। सभी संकेत सुरक्षित और सामान्य हैं।"),
  "Ask AI Assistant": ("Ask AI Assistant", "AI सहायक से पूछें"),
  "Heart Rate Stability": ("Heart Rate Stability", "हृदय गति की स्थिरता"),
  "Blood Oxygen (SpO2)": ("Blood Oxygen (SpO2)", "रक्त ऑक्सीजन (SpO2)"),
  "Thermoregulation": ("Thermoregulation", "शरीर का तापमान विनियमन"),
  "Normal range (62 - 108 BPM). Peak recorded during 3:15 PM activity with rapid 8-minute recovery.": ("Normal range (62 - 108 BPM). Peak recorded during 3:15 PM activity with rapid 8-minute recovery.", "सामान्य सीमा (62 - 108 BPM)। दोपहर 3:15 बजे की गतिविधि के दौरान उच्चतम स्तर दर्ज किया गया।"),
  "Maintained high average of 98.4% without nocturnal hypoxia dips.": ("Maintained high average of 98.4% without nocturnal hypoxia dips.", "बिना किसी गिरावट के 98.4% का उच्च औसत बनाए रखा।"),
  "Body temp steady at 36.6°C. Minor 0.3°C drop observed at 3:00 AM due to room temperature dip.": ("Body temp steady at 36.6°C. Minor 0.3°C drop observed at 3:00 AM due to room temperature dip.", "शरीर का तापमान 36.6°C पर स्थिर रहा।"),

  # BLE & Hardware
  "Connected Devices": ("Connected Devices", "कनेक्टेड उपकरण"),
  "Bluetooth is Turned Off": ("Bluetooth is Turned Off", "ब्लूटूथ बंद है"),
  "Turn ON Bluetooth in phone settings to pair with ESP32 wearable.": ("Turn ON Bluetooth in phone settings to pair with ESP32 wearable.", "ESP32 वियरेबल से पेयर करने के लिए सेटिंग्स में ब्लूटूथ ऑन करें।"),
  "HARDWARE SENSOR ARRAY": ("HARDWARE SENSOR ARRAY", "हार्डवेयर सेंसर ऐरे"),
  "NEARBY BLE DEVICES": ("NEARBY BLE DEVICES", "पास के ब्लूटूथ (BLE) उपकरण"),
  "Note: Bluetooth Speakers / Headphones use Classic Bluetooth (A2DP Audio) and do not broadcast BLE sensor telemetry. Only BLE GATT Wearables & ESP32 sensor hardware appear in BLE scanning.": ("Note: Bluetooth Speakers / Headphones use Classic Bluetooth (A2DP Audio) and do not broadcast BLE sensor telemetry. Only BLE GATT Wearables & ESP32 sensor hardware appear in BLE scanning.", "नोट: ब्लूटूथ स्पीकर केवल क्लासिक ब्लूटूथ का उपयोग करते हैं। केवल वियरेबल और ESP32 सेंसर ही स्कैनिंग में दिखाई देते हैं।"),
  "MAX30102 HR & SpO2 Sensor": ("MAX30102 HR & SpO2 Sensor", "MAX30102 HR और SpO2 सेंसर"),
  "DHT22 Temp & Humidity Sensor": ("DHT22 Temp & Humidity Sensor", "DHT22 तापमान और आर्द्रता सेंसर"),
  "MQ135 Air Quality Sensor": ("MQ135 Air Quality Sensor", "MQ135 वायु गुणवत्ता सेंसर"),
  "MPU6050 Accelerometer / Fall": ("MPU6050 Accelerometer / Fall", "MPU6050 एक्सेलेरोमीटर / फॉल"),
  "GSR Skin Conductance (Stress)": ("GSR Skin Conductance (Stress)", "GSR स्किन कंडक्टेंस (तनाव)"),
  "NEO-6M GPS Module": ("NEO-6M GPS Module", "NEO-6M GPS मॉड्यूल"),
  "Active BLE": ("Active BLE", "सक्रिय BLE"),
  "Simulator Ready": ("Simulator Ready", "सिमुलेटर तैयार"),

  # Disaster & Emergency
  "CAREGIVER CONTACTS": ("CAREGIVER CONTACTS", "देखभालकर्ता संपर्क"),
  "ULTRA FAST DISASTER RESPONSE": ("ULTRA FAST DISASTER RESPONSE", "अति तीव्र आपदा प्रतिक्रिया"),
  "OFFLINE FIRST-AID DISASTER GUIDES": ("OFFLINE FIRST-AID DISASTER GUIDES", "ऑफ़लाइन प्राथमिक चिकित्सा आपदा गाइड"),
  "Flood": ("Flood", "बाढ़"),
  "Cyclone": ("Cyclone", "चक्रवात"),
  "Disaster": ("Disaster", "आपदा"),
  "General Disaster": ("General Disaster", "सामान्य आपदा"),
  "Heat Stroke Emergency Protocol": ("Heat Stroke Emergency Protocol", "हीट स्ट्रोक आपातकालीन प्रोटोकॉल"),
  "Move to shade immediately. Apply cold water to neck, armpits, and groin. Sip water slowly.": ("Move to shade immediately. Apply cold water to neck, armpits, and groin. Sip water slowly.", "तुरंत छाया में जाएं। गर्दन, कांख और जांघों पर ठंडा पानी लगाएं। धीरे-धीरे पानी पिएं।"),
  "Severe Air Pollution & Asthma First-Aid": ("Severe Air Pollution & Asthma First-Aid", "गंभीर वायु प्रदूषण और अस्थमा प्राथमिक चिकित्सा"),
  "Stay indoors with doors closed. Use prescribed bronchodilator inhaler. Wear N95 respirator.": ("Stay indoors with doors closed. Use prescribed bronchodilator inhaler. Wear N95 respirator.", "दरवाजे बंद करके घर के अंदर रहें। इनहेलर का प्रयोग करें। N95 मास्क पहनें।"),
  "Flood & Disaster Evacuation Protocol": ("Flood & Disaster Evacuation Protocol", "बाढ़ और आपदा निकासी प्रोटोकॉल"),
  "Keep wearable active. Move to elevated ground. Avoid touching electrical poles or submerged wires.": ("Keep wearable active. Move to elevated ground. Avoid touching electrical poles or submerged wires.", "वियरेबल को सक्रिय रखें। ऊंची जगह पर जाएं। बिजली के खंभों या पानी में डूबे तारों को छूने से बचें।"),
  "Help Dispatched!": ("Help Dispatched!", "मदद भेज दी गई है!"),
  "Searching for nearest Govt. Disaster Control, Army Forces, and specialized response units...": ("Searching for nearest Govt. Disaster Control, Army Forces, and specialized response units...", "निकटतम सरकारी आपदा नियंत्रण, सेना बलों और प्रतिक्रिया इकाइयों की खोज की जा रही है..."),
  "Nearest Disaster Control teams and available army forces have been notified with your exact GPS coordinates and are en route.": ("Nearest Disaster Control teams and available army forces have been notified with your exact GPS coordinates and are en route.", "निकटतम आपदा नियंत्रण टीमों और सेना बलों को आपकी सटीक स्थान जानकारी के साथ सूचित कर दिया गया है।"),

  # Activity & Sleep Details
  "Activity & Steps": ("Activity & Steps", "गतिविधि और कदम"),
  "Sleep Quality": ("Sleep Quality", "नींद की गुणवत्ता"),
  "Deep Sleep": ("Deep Sleep", "गहरी नींद"),
  "Light Sleep": ("Light Sleep", "हल्की नींद"),
  "Awake": ("Awake", "जागना"),
  "Resting": ("Resting", "आराम"),
  "Walking": ("Walking", "चलना"),
  "Running": ("Running", "दौड़ना"),
  "Inactive": ("Inactive", "निष्क्रिय"),

  # Settings & Compliance
  "ABOUT & SIH COMPLIANCE": ("ABOUT & SIH COMPLIANCE", "के बारे में और SIH अनुपालन"),
  "Qualcomm SIH 26181 Compliance": ("Qualcomm SIH 26181 Compliance", "क्वालकॉम SIH 26181 अनुपालन"),
  "SIH Problem Statement 26181": ("SIH Problem Statement 26181", "SIH समस्या कथन 26181"),
  "On-Device AI Early Warning Disaster-Resilient Health Wearable Platform (Qualcomm)": ("On-Device AI Early Warning Disaster-Resilient Health Wearable Platform (Qualcomm)", "ऑन-डिवाइस AI प्रारंभिक चेतावनी आपदा-सहनशील स्वास्थ्य वियरेबल प्लेटफॉर्म (क्वालकॉम)"),
  "Built specifically for heatwaves, floods, smog spikes, outdoor laborers, elderly individuals living alone, and rural communities with zero internet connectivity.": ("Built specifically for heatwaves, floods, smog spikes, outdoor laborers, elderly individuals living alone, and rural communities with zero internet connectivity.", "विशेष रूप से लू, बाढ़, स्मॉग, बाहरी मजदूरों, अकेले रहने वाले बुजुर्गों और बिना इंटरनेट वाले ग्रामीण समुदायों के लिए निर्मित।"),
  "8 Core Requirements Compliance Matrix": ("8 Core Requirements Compliance Matrix", "8 मुख्य आवश्यकताएं अनुपालन मैट्रिक्स"),
  "HARDWARE SIMULATOR & DEMO CONTROLS": ("HARDWARE SIMULATOR & DEMO CONTROLS", "हार्डवेयर सिमुलेटर और डेमो नियंत्रण"),
  "Hardware Simulator Mode": ("Hardware Simulator Mode", "हार्डवेयर सिमुलेटर मोड"),
  "Injects live sensor telemetry when ESP32 is not connected.": ("Injects live sensor telemetry when ESP32 is not connected.", "ESP32 से कनेक्ट न होने पर लाइव सेंसर डेटा इंजेक्ट करता है।"),
  "1-Tap Anomaly Simulation Triggers": ("1-Tap Anomaly Simulation Triggers", "1-टैप विसंगति सिमुलेशन ट्रिगर"),
  "Heat Stroke Risk": ("Heat Stroke Risk", "हीट स्ट्रोक का खतरा"),
  "Fall Detection": ("Fall Detection", "गिरने का पता लगाना"),
  "SpO2 Drop Hazard": ("SpO2 Drop Hazard", "SpO2 गिरावट का खतरा"),
  "Reset Healthy": ("Reset Healthy", "सामान्य स्थिति पर रीसेट करें"),
  "USER PERSONAL BASELINES": ("USER PERSONAL BASELINES", "उपयोगकर्ता व्यक्तिगत आधार रेखाएँ"),

  # AI Chat Bottom Sheet
  "AI Health Assistant": ("AI Health Assistant", "AI स्वास्थ्य सहायक"),
  "Online • Continuous Vitals Monitoring": ("Online • Continuous Vitals Monitoring", "ऑनलाइन • निरंतर स्वास्थ्य निगरानी"),
}

print(f"Total translation entries defined: {len(translations_dict)}")
