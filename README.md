# Alarm Object App

Alarma inteligente que se desactiva solo cuando tomas una foto de un **objeto rojo**. Creada con Flutter.

## Cómo funciona

1. Presionas "Set Test Alarm" y se programa una notificación.
2. Al tocarla, se abre un reto: **"Find something red"**.
3. Tomas una foto con la cámara (o seleccionas de la galería en desktop).
4. La app analiza los píxeles de la imagen. Si predomina el color rojo, la alarma se apaga.
5. Si no hay suficiente rojo, te pide que intentes de nuevo.

## Tecnologías

- **Flutter** — SDK 3.10.3+
- **Dart** — Lenguaje principal
- **flutter_local_notifications** — Notificaciones de alarma
- **image_picker** — Cámara y galería
- **image** — Análisis de píxeles (RGB)

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
│   └── alarm_screen.dart               # Reto: foto + validación de color rojo
└── services/
    └── notification_service.dart       # Servicio de notificaciones locales
```

## Plataformas

Android, iOS, Linux, macOS, Windows, Web.
