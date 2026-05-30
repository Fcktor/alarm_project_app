# Alarm Object App

Alarma inteligente que solo se puede desactivar tomando una foto de un **objeto real** usando reconocimiento de imágenes con Google ML Kit.

## Cómo funciona

1. Presionas "Set Test Alarm" y se programa una notificación.
2. Al tocar la notificación, se abre un reto: tomar una foto de un **objeto**.
3. Tomas una foto con la cámara (o seleccionas de la galería en desktop).
4. ML Kit analiza la imagen usando el modelo YOLO y detecta si hay un objeto presente.
5. Si detecta un objeto, la alarma se desactiva y te dice qué objeto detectó.
6. Si no detecta nada, te pide intentar de nuevo.

## Tecnologías

- **Flutter** — SDK 3.10.3+
- **Dart** — Lenguaje principal
- **Google ML Kit Object Detection** — Reconocimiento de objetos (YOLO)
- **flutter_local_notifications** — Notificaciones de alarma
- **image_picker** — Cámara y galería

## Instalación

```bash
git clone git@github.com:Fcktor/alarm_project_app.git
cd alarm_project_app
flutter pub get
flutter run
```

## Estructura

```
lib/
├── main.dart                           # Punto de entrada, inicializa notificaciones
├── screens/
│   ├── home_screen.dart                # Pantalla principal con botón de alarma
│   └── alarm_screen.dart               # Reto: foto + detección de objetos con ML Kit
└── services/
    └── notification_service.dart       # Servicio de notificaciones locales
```

## Plataformas

Android, iOS, Linux, macOS, Windows, Web.
