import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../services/alarm_service.dart';

const Color kBackground = Color(0xFFFFF0A0);
const Color kAlarmGold = Color(0xFFFFB300);
const Color kDark = Color(0xFF2D2D2D);

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
  late AnimationController _wobble;
  late Animation<double> _wobbleAnim;

  @override
  void initState() {
    super.initState();
    _wobble = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _wobbleAnim = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _wobble, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _wobble.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final useCamera = Platform.isAndroid || Platform.isIOS;
    final source = useCamera ? ImageSource.camera : ImageSource.gallery;
    try {
      final picked = await ImagePicker().pickImage(source: source);
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
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toma una foto primero.')),
      );
      return;
    }
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
        final label =
            objects.first.labels.isNotEmpty ? objects.first.labels.first.text : 'objeto';
        await AlarmService.stopAlarm(widget.alarmId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Alarma desactivada! Detecté: $label')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No detecté ningún objeto. Intenta de nuevo.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Text(
              '¡Despierta!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: kDark,
              ),
            ),
            _AlarmIcon(wobble: _wobbleAnim),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Toma una foto de un objeto para apagar la alarma',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: kDark),
              ),
            ),
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_image!, height: 160, fit: BoxFit.cover),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoundButton(
                  color: Colors.red,
                  icon: Icons.close,
                  onTap: _isProcessing
                      ? null
                      : () async {
                          final nav = Navigator.of(context);
                          await AlarmService.stopAlarm(widget.alarmId);
                          nav.pop();
                        },
                ),
                const SizedBox(width: 24),
                _RoundButton(
                  color: Colors.green,
                  icon: _image == null ? Icons.camera_alt : Icons.check,
                  onTap: _isProcessing
                      ? null
                      : (_image == null ? _pickImage : _validate),
                  isLoading: _isProcessing,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmIcon extends StatelessWidget {
  final Animation<double> wobble;
  const _AlarmIcon({required this.wobble});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: wobble,
      builder: (_, _) => Transform.rotate(
        angle: wobble.value,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ondas de sonido
            _SoundWaves(),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: kAlarmGold,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: kAlarmGold.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.alarm, size: 64, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundWaves extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAlarmGold.withValues(alpha: 0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    for (int i = 1; i <= 2; i++) {
      final r = 68.0 + i * 18;
      // left arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        pi * 0.65,
        pi * 0.7,
        false,
        paint,
      );
      // right arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        pi * 1.65,
        pi * 0.7,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoundButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _RoundButton({
    required this.color,
    required this.icon,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.4) : color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
