# Mobile Client (Flutter) — PyroGuard

Cross-platform Flutter application for receiving real-time Firebase Cloud Messaging (FCM) fire/smoke alerts, inspecting YOLO bounding-box snapshots, monitoring RTSP cameras, and browsing incident history.

## Documentation (Meeting Deliverables)
- **UI Wireframes & Navigation Flow:** [`docs/wireframes.md`](docs/wireframes.md)
- **Firebase / FCM Setup Status & Payload Contract:** [`docs/fcm_setup.md`](docs/fcm_setup.md)

## Directory Structure
```text
mobile/
├── pubspec.yaml
├── README.md
├── docs/
│   ├── wireframes.md                  # Screen wireframes & alert deep-link flow
│   └── fcm_setup.md                   # FCM setup checklist & backend payload contract
└── lib/
    ├── main.dart                      # App entry point & FCM bootstrap
    ├── models/
    │   ├── camera.dart                # Aligned with backend CameraOut schema
    │   └── detection_event.dart       # Aligned with backend EventOut & BoxOut schemas
    ├── services/
    │   ├── api_service.dart           # FastAPI client (/health, /cameras, /events) + demo fallback
    │   └── fcm_service.dart           # FCM permissions, token sync, foreground/background handlers
    └── screens/
        ├── home_screen.dart           # Bottom NavigationBar shell + notification deep-linking
        ├── alerts_screen.dart         # Dashboard status banner, filters & event history
        ├── alert_detail_screen.dart   # Annotated snapshot viewer (CustomPainter) + acknowledge
        ├── cameras_screen.dart        # Monitored RTSP cameras & thresholds
        └── settings_screen.dart       # FCM status, token viewer, test alert & API URL config
```

## Local Setup & Run
1. Generate platform scaffolding (`android/`, `ios/`) using Flutter SDK:
   ```bash
   cd mobile
   flutter create .
   flutter pub get
   ```
2. *(Optional for live push notifications)* Add Firebase config files as described in [`docs/fcm_setup.md`](docs/fcm_setup.md):
   - `mobile/android/app/google-services.json`
   - `mobile/ios/Runner/GoogleService-Info.plist`
3. Run the application:
   ```bash
   flutter run
   ```

> If the FastAPI backend or Firebase config files are not yet available locally, the app gracefully runs in **Demo / FCM Preview Mode** so all screens, bounding-box overlays, and local test alerts can still be demonstrated.
