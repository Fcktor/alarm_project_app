import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../services/alarm_service.dart';

class AlarmScreen extends StatefulWidget {
  final int alarmId;
  const AlarmScreen({super.key, required this.alarmId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  File? _image;
  bool _isProcessing = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: Platform.isAndroid || Platform.isIOS
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (!mounted) return;
      if (picked != null) setState(() => _image = File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo acceder a la cámara: $e')),
      );
    }
  }

  Future<void> _validate() async {
    if (_image == null) return;
    setState(() => _isProcessing = true);
    try {
      final inputImage = InputImage.fromFilePath(_image!.path);
      final detector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: false,
        ),
      );
      final objects = await detector.processImage(inputImage);
      await detector.close();
      if (!mounted) return;

      if (objects.isNotEmpty) {
        final label = objects.first.labels.isNotEmpty
            ? objects.first.labels.first.text
            : 'objeto';
        await AlarmService.stopAlarm(widget.alarmId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Alarma apagada! Detecté: $label'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context);
      } else {
        setState(() => _image = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No detecté ningún objeto. Intenta de nuevo.'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF7971E),
                  Color(0xFFFFD200),
                  Color(0xFFFF6B6B),
                  Color(0xFF9B59B6),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          // Wave overlay
          CustomPaint(painter: _AlarmWavePainter()),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '⏰ Alarma',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '¡Es hora\nde despertar!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                const Spacer(),

                // Photo area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) {
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.3 + _pulse.value * 0.3),
                            width: 1.5,
                          ),
                          color: Colors.white
                              .withValues(alpha: 0.1 + _pulse.value * 0.05),
                        ),
                        child: child,
                      );
                    },
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.file(_image!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_outlined,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  size: 44),
                              const SizedBox(height: 14),
                              Text(
                                'Toma una foto de cualquier\nobjeto para apagar la alarma',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 15,
                                    height: 1.4),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                  child: Row(
                    children: [
                      if (_image != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _image = null),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh_rounded,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      Expanded(
                        child: GestureDetector(
                          onTap: _isProcessing
                              ? null
                              : (_image == null ? _pickImage : _validate),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFF9B59B6)),
                                    )
                                  : Text(
                                      _image == null
                                          ? 'Abrir cámara'
                                          : 'Verificar foto',
                                      style: const TextStyle(
                                        color: Color(0xFF0D0D0D),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wave Painter ──────────────────────────────────────────────────────────────

class _AlarmWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const lines = 42;
    for (int i = 0; i < lines; i++) {
      final x = size.width * i / lines;
      final path = Path();
      path.moveTo(x, 0);
      for (double y = 0; y <= size.height; y += 2) {
        final amp = 4.0 + sin(i * 1.1 + 0.5) * 7;
        final freq = 0.05 + (i % 7) * 0.007;
        path.lineTo(x + sin(y * freq + i * 0.6) * amp, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
