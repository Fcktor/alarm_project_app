# Alarm Object Detection

An alarm that can only be switched off by photographing a **real object**. No snooze button, no swipe — you have to get up and point the camera at something, and on-device recognition with Google ML Kit decides whether you actually did.

## How it works

1. Set the alarm; a local notification is scheduled
2. Tapping the notification opens the challenge screen instead of dismissing it
3. Take a photo with the camera (or pick from the gallery on desktop)
4. ML Kit runs object detection on-device and checks whether a real object is present
5. If one is detected, the alarm turns off and tells you what it saw
6. If not, it asks you to try again

Detection runs entirely on the device — no image ever leaves the phone.

## Stack

- **Flutter** — SDK 3.10.3+
- **Dart** — primary language
- **Google ML Kit Object Detection** — on-device object recognition
- **flutter_local_notifications** — alarm notifications
- **image_picker** — camera and gallery access

## Structure

```
lib/
├── main.dart                           # Entry point, notification setup
├── screens/
│   ├── home_screen.dart                # Main screen with alarm controls
│   └── alarm_screen.dart               # Challenge: photo + ML Kit detection
└── services/
    └── notification_service.dart       # Local notification service
```

## Installation

```bash
git clone https://github.com/albertfsalapi/alarm-object-detection
cd alarm-object-detection
flutter pub get
flutter run
```

## Platforms

Android, iOS, Linux, macOS, Windows.
