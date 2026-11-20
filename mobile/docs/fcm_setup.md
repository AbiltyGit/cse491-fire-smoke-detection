# Firebase Cloud Messaging (FCM) — Kurulum Durumu ve Entegrasyon Planı

**Sorumlu:** Melih Aşık (Mobile)  
**Tarih:** 20.11.2026

---

## 1. Güncel Kurulum Durumu (Toplantı Özeti)

| Adım | Durum | Açıklama |
| :--- | :---: | :--- |
| Flutter proje bağımlılıkları (`pubspec.yaml`) | ✅ Tamamlandı | `firebase_core`, `firebase_messaging`, `flutter_local_notifications`, `http`, `intl` eklendi |
| FCM istemci servisi (`lib/services/fcm_service.dart`) | ✅ Tamamlandı | İzin isteme, token alma/yenileme, foreground/background/terminated handler ve deep-link hazır |
| Ekranlar ve Bounding-Box UI (`lib/screens/`) | ✅ Tamamlandı | 4 ekran (Alerts, Alert Detail + CustomPainter, Cameras, Settings/FCM) kodlandı |
| Backend veri modelleri (`lib/models/`) | ✅ Tamamlandı | `feature/backend-api` dalındaki `CameraOut`, `EventOut`, `BoxOut` şemalarıyla birebir uyumlu |
| Platform klasörleri (`android/`, `ios/`) | ⏳ Bekliyor | Flutter SDK kurulu makinede `flutter create .` çalıştırılacak |
| Firebase Console projesi & gizli dosyalar | ⏳ Bekliyor | `google-services.json` (Android), `GoogleService-Info.plist` (iOS) ve backend için `firebase-adminsdk.json` oluşturulacak |
| Backend cihaz kayıt endpoint'i | ⏳ Backend bağımlılığı | `user_devices` tablosuna kayıt yapan `POST /devices/register` ve `POST /events/{id}/acknowledge` endpoint'leri Ali ile hizalanacak |

> **Not:** `google-services.json` henüz eklenmemiş olsa bile uygulama çökmeden **FCM Preview Mode + Demo Data** ile açılır ve `Settings` ekranından yerel test bildirimi tetiklenebilir.

---

## 2. Backend ↔ Mobile FCM Payload Sözleşmesi

FastAPI backend (`firebase-admin`) bir yangın/duman tespitini onayladığında aşağıdaki JSON yapısında FCM bildirimi göndermelidir:

```json
{
  "token": "<device_fcm_token>",
  "notification": {
    "title": "🔥 FLAME & SMOKE DETECTED",
    "body": "CAM-01 · Main Warehouse (91% conf, 5-frame streak)"
  },
  "data": {
    "event_id": "550e8400-e29b-41d4-a716-446655440000",
    "camera_id": "111e8400-e29b-41d4-a716-446655440000",
    "event_type": "both",
    "max_confidence": "0.91",
    "frame_streak": "5"
  },
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "pyroguard_fire_alerts"
    }
  }
}
```

Kullanıcı bildirime tıkladığında `FcmService.onAlertTapped` stream'i `event_id` değerini yakalar, `GET /events/{event_id}` ile olayı çeker ve doğrudan `AlertDetailScreen` ekranını açar.

---

## 3. Firebase Console Kurulum Adımları (Sonraki Adım)

1. [Firebase Console](https://console.firebase.google.com/) üzerinde `pyroguard-cse491` projesini oluştur.
2. **Android uygulaması ekle:**
   - Package name: `com.akdeniz.pyroguard`
   - İndirilen `google-services.json` dosyasını `mobile/android/app/google-services.json` konumuna koy (`.gitignore` içinde tut).
   - `AndroidManifest.xml` içine `POST_NOTIFICATIONS` izni ekle (Android 13+).
3. **iOS uygulaması ekle (opsiyonel / macOS üzerinde):**
   - `GoogleService-Info.plist` dosyasını `mobile/ios/Runner/` altına ekle ve APNs anahtarını Firebase Console'a yükle.
4. **Backend Admin SDK:**
   - Firebase Console → Project Settings → Service Accounts → *Generate new private key* ile `firebase-adminsdk.json` indirip backend ekibiyle güvenli şekilde paylaş (`.env` içindeki `FCM_CREDENTIALS_PATH` ile eşleşir).
5. **Flutter tarafında doğrulama:**
   ```bash
   cd mobile
   flutter create .
   flutter pub get
   flutter run
   ```
