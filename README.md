# Alarm Object Detection

Una alarma que solo se puede apagar fotografiando un **objeto real**. Sin botón de posponer, sin deslizar: tienes que levantarte y apuntar la cámara a algo, y el reconocimiento en el dispositivo con Google ML Kit decide si de verdad lo hiciste.

## Cómo funciona

1. Programas la alarma y se agenda una notificación local
2. Al tocar la notificación se abre la pantalla del reto en lugar de descartarla
3. Tomas una foto con la cámara (o eliges de la galería en escritorio)
4. ML Kit corre detección de objetos en el dispositivo y verifica si hay un objeto real presente
5. Si detecta uno, la alarma se apaga y te dice qué vio
6. Si no, te pide intentar de nuevo

La detección corre íntegramente en el dispositivo: ninguna imagen sale del teléfono.

## Stack

- **Flutter** — SDK 3.10.3+
- **Dart** — lenguaje principal
- **Google ML Kit Object Detection** — reconocimiento de objetos en el dispositivo
- **flutter_local_notifications** — notificaciones de alarma
- **image_picker** — acceso a cámara y galería

## Estructura

```
lib/
├── main.dart                           # Punto de entrada, inicializa notificaciones
├── screens/
│   ├── home_screen.dart                # Pantalla principal con control de alarma
│   └── alarm_screen.dart               # Reto: foto + detección con ML Kit
└── services/
    └── notification_service.dart       # Servicio de notificaciones locales
```

## Instalación

```bash
git clone https://github.com/albertfsalapi/alarm-object-detection
cd alarm-object-detection
flutter pub get
flutter run
```

## Plataformas

Android, iOS, Linux, macOS, Windows.
