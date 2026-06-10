import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../services/alarm_service.dart';
import '../widgets/wave_painters.dart';

const int _kTargetReps = 10;

class AlarmScreen extends StatefulWidget {
  final int alarmId;
  const AlarmScreen({super.key, required this.alarmId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cam;
  PoseDetector? _detector;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _switchingCamera = false;

  bool _isProcessing = false;
  bool _done = false;
  bool _poseVisible = false;
  bool _flash = false;

  int _count = 0;
  bool _isDown = false;
  double _minY = double.infinity;
  double _maxY = double.negativeInfinity;
  double _imageHeight = 1;

  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera({int index = 0}) async {
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
      }
      if (_cameras.isEmpty) return;

      _detector ??= PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      );

      final previous = _cam;
      if (previous != null) {
        await previous.stopImageStream();
        await previous.dispose();
      }

      _cameraIndex = index;
      _cam = CameraController(
        _cameras[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cam!.initialize();
      if (!mounted) return;
      setState(() {});
      _cam!.startImageStream(_onFrame);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _switchingCamera) return;
    setState(() => _switchingCamera = true);
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _initCamera(index: nextIndex);
    if (mounted) setState(() => _switchingCamera = false);
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_isProcessing || _done) return;
    _isProcessing = true;
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      _imageHeight = image.height.toDouble();
      final poses = await _detector!.processImage(inputImage);
      if (!mounted) return;

      final visible = poses.isNotEmpty;
      if (_poseVisible != visible) setState(() => _poseVisible = visible);
      if (visible) _processPose(poses.first);
    } finally {
      _isProcessing = false;
    }
  }

  void _processPose(Pose pose) {
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final shoulder = _best(ls, rs);
    if (shoulder == null || shoulder.likelihood < 0.45) return;

    final y = shoulder.y / _imageHeight;

    if (!_isDown) {
      if (y < _minY) _minY = y;
      // Shoulder dropped 8% below its highest point → DOWN phase
      if (y > _minY + 0.08) {
        setState(() => _isDown = true);
        _maxY = y;
      }
    } else {
      if (y > _maxY) _maxY = y;
      // Shoulder rose 8% above its lowest point → rep completed
      if (y < _maxY - 0.08) {
        _minY = y;
        setState(() {
          _isDown = false;
          _count++;
          _flash = true;
        });
        Future.delayed(const Duration(milliseconds: 400),
            () { if (mounted) setState(() => _flash = false); });
        if (_count >= _kTargetReps) _finish();
      }
    }
  }

  PoseLandmark? _best(PoseLandmark? a, PoseLandmark? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.likelihood >= b.likelihood ? a : b;
  }

  Future<void> _finish() async {
    if (_done) return;
    setState(() => _done = true);
    await _cam?.stopImageStream();
    await AlarmService.stopAlarm(widget.alarmId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('¡Increíble! $_kTargetReps planchas completadas 💪'),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 3),
    ));
    Navigator.pop(context);
  }

  InputImage? _buildInputImage(CameraImage image) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
              _cam!.description.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final WriteBuffer buf = WriteBuffer();
      for (final plane in image.planes) {
        buf.putUint8List(plane.bytes);
      }

      return InputImage.fromBytes(
        bytes: buf.done().buffer.asUint8List(),
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _cam?.stopImageStream();
    _cam?.dispose();
    _detector?.close();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady = _cam != null && _cam!.value.isInitialized;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview or gradient fallback
          if (cameraReady)
            CameraPreview(_cam!)
          else
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

          // Dark overlay so UI is readable over camera feed
          Container(color: Colors.black.withValues(alpha: 0.5)),

          // Wave decoration
          CustomPaint(
            painter: const WavePainter(
              lines: 42,
              opacity: 0.08,
              strokeWidth: 1.3,
              ampBase: 4.0,
              ampFactor: 7.0,
              iFreqFactor: 1.1,
              iPhaseOffset: 0.5,
              freqBase: 0.05,
              freqStep: 0.007,
              freqMod: 7,
              xPhase: 0.6,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top bar ──────────────────────────────────────────
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
                      if (_cameras.length > 1)
                        GestureDetector(
                          onTap: _switchingCamera ? null : _switchCamera,
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: _switchingCamera
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.flip_camera_ios_rounded,
                                    color: Colors.white, size: 20),
                          ),
                        ),
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

                const SizedBox(height: 20),

                // ── Title ────────────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '¡Es hora\nde despertar!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Challenge badge ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💪  ', style: TextStyle(fontSize: 16)),
                        Text(
                          'Haz $_kTargetReps planchas para apagar',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── Pose detection warning ───────────────────────────
                if (cameraReady && !_poseVisible)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.6)),
                    ),
                    child: const Text(
                      '🔍 Apunta la cámara hacia tu cuerpo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),

                // ── Counter circle ────────────────────────────────────
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _flash
                          ? Colors.green.withValues(alpha: 0.35)
                          : Colors.white
                              .withValues(alpha: 0.12 + _pulse.value * 0.06),
                      border: Border.all(
                        color: _isDown
                            ? Colors.orange
                                .withValues(alpha: 0.6 + _pulse.value * 0.4)
                            : _poseVisible
                                ? Colors.greenAccent
                                    .withValues(alpha: 0.5 + _pulse.value * 0.3)
                                : Colors.white
                                    .withValues(alpha: 0.3 + _pulse.value * 0.2),
                        width: 2.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 68,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        Text(
                          'de $_kTargetReps',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── Phase indicator ───────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey(_isDown),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isDown
                          ? Colors.orange.withValues(alpha: 0.3)
                          : Colors.green.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isDown
                            ? Colors.orange.withValues(alpha: 0.7)
                            : Colors.green.withValues(alpha: 0.7),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _isDown ? '⬇  Abajo — sube ahora' : '⬆  Posición inicial',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),

                const Spacer(),

                // ── Position hint ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Text(
                    'Coloca el teléfono en el suelo de lado\napuntando hacia ti',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 13,
                        height: 1.5),
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

