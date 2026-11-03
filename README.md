# ai_safety_app
# RakshAI 

**RakshAI** is a proactive, intelligent personal safety application built with Flutter and Dart. 
Designed to operate reliably in high-stress and critical emergency situations, RakshAI provides continuous background location tracking, automated sensor-fusion fall detection, and low-latency voice distress recognition to protect users without requiring manual intervention.

---

## Key Features

* **Continuous Background Location Tracking:** Low-power background services track position metrics continuously without being killed by the operating system.
* **Automated Fall Detection:** Sensor-fusion algorithms analyze accelerometer and gyroscope telemetry in real-time to detect rapid impact and sudden orientation changes.
* **Voice Distress Recognition:** Low-latency acoustic model processes key voice triggers to automatically signal alerts in emergency situations.
* **Instant Emergency Notifications:** Automatically triggers alerts and dispatches real-time location updates to designated trusted contacts during detected emergencies.
* **Cross-Platform Foundation:** High-performance, reactive user interface developed with Flutter and Dart.

---

## Tech Stack & Dependencies
**Framework:** Flutter (Dart)
**Architecture:** BLoC / Provider Pattern for scalable state management
**Hardware Interfacing:** sensors_plus, geolocator, flutter_background_service
**Machine Learning:** TFLite / Audio classification models for voice distress recognition

**Prerequisites**
Flutter SDK: >=3.0.0
Dart SDK: >=3.0.0
Android Studio or VS Code with Flutter extensions enabled
An Android physical device or AVD running API level 24+

**Local Setup**
Install Dependencies:
flutter pub get
Run the Application:
flutter run

**Building the Release APK**
To generate an installable standalone release package for testing:
flutter build apk --release
The output file will be generated at:
build/app/outputs/flutter-apk/app-release.apk

## License & Terms of Use
Copyright (c) 2026 Krisha Patel. All Rights Reserved.

This repository and its source code are made available strictly for academic review, portfolio evaluation, and code inspection.
