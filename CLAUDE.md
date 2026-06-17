# CLAUDE.md

Este archivo proporciona orientación a Claude Code (claude.ai/code) al trabajar con el código de este repositorio.

## Descripción del proyecto

Aplicación Flutter (Dart) que funciona como despertador: para desactivar la alarma, el usuario debe completar 10 flexiones detectadas en tiempo real mediante la cámara y Google ML Kit (estimación de pose).

## Comandos

```bash
flutter pub get          # Instalar dependencias
flutter run              # Ejecutar en dispositivo/emulador conectado
flutter build apk        # Compilar APK de Android
flutter build appbundle  # Compilar App Bundle de Android

flutter test             # Ejecutar tests
flutter analyze          # Análisis estático (flutter_lints)
```

Android requiere Java 17, compileSdk 36, minSdk 24. El desugaring de la biblioteca central está habilitado.

## Arquitectura

Sin biblioteca de gestión de estado — todo el estado vive en `StatefulWidget`/`setState`. Sin backend; la persistencia se realiza con `SharedPreferences`.

**Ciclo de vida de la alarma:**
1. `AlarmService` (clase estática en [lib/services/alarm_service.dart](lib/services/alarm_service.dart)) programa un `AlarmSettings` mediante el paquete `alarm` y persiste los IDs de alarma en `SharedPreferences`.
2. `main.dart` se suscribe al stream `Alarm.ringing` y navega a `AlarmScreen` cuando suena una alarma.
3. `AlarmScreen` inicia el stream de la cámara, ejecuta `PoseDetector` (Google ML Kit) en cada fotograma, cuenta repeticiones de subida/bajada de hombros y llama a `AlarmService.stopAlarm()` al llegar a 10 repeticiones.

**Estructura de fuentes:**
- [lib/main.dart](lib/main.dart) — punto de entrada; inicializa el paquete `Alarm` y configura el listener de `Alarm.ringing`.
- [lib/screens/home_screen.dart](lib/screens/home_screen.dart) — UI de lista de alarmas, controles para añadir/eliminar/probar.
- [lib/screens/alarm_screen.dart](lib/screens/alarm_screen.dart) — detección de pose con cámara, contador de repeticiones, desactivación de alarma.
- [lib/services/alarm_service.dart](lib/services/alarm_service.dart) — helpers estáticos para programar alarmas, permisos y persistencia en SharedPreferences.
- [lib/widgets/wave_painters.dart](lib/widgets/wave_painters.dart) — `WavePainter`, pintor personalizado para los fondos con ondas.

## Dependencias clave

| Paquete | Propósito |
|---|---|
| `alarm` 5.4.1 | Programación de alarmas con foreground service en Android |
| `google_mlkit_pose_detection` 0.10.0 | Detección de landmarks de hombros en tiempo real |
| `google_mlkit_object_detection` 0.11.0 | Importado pero no integrado en el flujo del desafío |
| `camera` 0.12.0+1 | Stream de cámara en vivo |
| `permission_handler` 11.3.0 | Permisos en tiempo de ejecución (cámara, notificaciones, batería) |
| `shared_preferences` 2.3.3 | Persistencia de IDs de alarma |

## Lógica de detección de pose

`AlarmScreen` procesa fotogramas de cámara con `PoseDetector`. Rastrea `PoseLandmarkType.leftShoulder` / `rightShoulder` (confianza ≥ 0.45). Se cuenta una repetición cuando el hombro baja más del 8% de la altura del fotograma desde su punto máximo y luego sube más del 8% desde su punto mínimo. Al llegar a 10 repeticiones, la alarma se detiene.

## Notas de UI

- Los textos de la interfaz están en español.
- El estilo visual usa tarjetas con gradientes y el painter `WavePainter` — sin biblioteca de animación de terceros; usa `AnimationController` directamente.
- `google_mlkit_object_detection` está declarado como dependencia pero su integración en el desafío de la alarma no está implementada.
