import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../providers/user_provider.dart';
import '../services/alarm_service.dart';
import '../services/user_service.dart';
import '../widgets/wave_painters.dart';

class AlarmScreen extends StatefulWidget {
  final int alarmId;
  const AlarmScreen({super.key, required this.alarmId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {

  // ── Exercise state ────────────────────────────────────────────────────────
  Exercise? _exercise;
  bool _loadingExercise = true;

  // ── Camera / pose (auto-detected exercises) ───────────────────────────────
  CameraController? _cam;
  PoseDetector? _detector;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _switchingCamera = false;
  bool _isProcessing = false;
  bool _poseVisible = false;

  // ── Rep counting ──────────────────────────────────────────────────────────
  int _count = 0;
  bool _isDown = false;
  double _minY = double.infinity;
  double _maxY = double.negativeInfinity;
  double _imageHeight = 1;

  // ── UI ────────────────────────────────────────────────────────────────────
  bool _done = false;
  bool _flash = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _loadExercise();
  }

  Future<void> _loadExercise() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    Exercise exercise;

    if (uid != null) {
      try {
        final user = await UserService().getUser(uid);
        final pool = user?.unlocked ?? unlockedExercises(0);
        exercise = pool[Random().nextInt(pool.length)];
      } catch (_) {
        exercise = kExercises.first;
      }
    } else {
      exercise = kExercises.first;
    }

    setState(() {
      _exercise = exercise;
      _loadingExercise = false;
    });

    if (exercise.isAutoDetected) _initCamera();
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _initCamera({int index = 0}) async {
    try {
      if (_cameras.isEmpty) _cameras = await availableCameras();
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
    await _initCamera(index: (_cameraIndex + 1) % _cameras.length);
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
      if (y > _minY + 0.08) {
        setState(() => _isDown = true);
        _maxY = y;
      }
    } else {
      if (y > _maxY) _maxY = y;
      if (y < _maxY - 0.08) {
        _minY = y;
        setState(() { _isDown = false; _count++; _flash = true; });
        Future.delayed(const Duration(milliseconds: 400),
            () { if (mounted) setState(() => _flash = false); });
        if (_count >= _exercise!.targetReps) _finish();
      }
    }
  }

  PoseLandmark? _best(PoseLandmark? a, PoseLandmark? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.likelihood >= b.likelihood ? a : b;
  }

  // ── Manual tap counter ────────────────────────────────────────────────────

  void _onManualTap() {
    if (_done) return;
    setState(() { _count++; _flash = true; });
    Future.delayed(const Duration(milliseconds: 300),
        () { if (mounted) setState(() => _flash = false); });
    if (_count >= _exercise!.targetReps) _finish();
  }

  // ── Completion ────────────────────────────────────────────────────────────

  Future<void> _finish() async {
    if (_done) return;
    setState(() => _done = true);
    await _cam?.stopImageStream();
    await AlarmService.stopAlarm(widget.alarmId);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    CompleteResult? result;
    if (uid != null && _exercise != null) {
      try {
        result = await UserService().completeExercise(uid, _exercise!);
        if (mounted) {
          context.read<UserProvider>().load(uid);
        }
      } catch (_) {}
    }

    if (!mounted) return;
    _showCompletionDialog(result);
  }

  void _showCompletionDialog(CompleteResult? result) {
    final pts = result?.pointsEarned ?? 0;
    final unlocked = result?.newlyUnlocked ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              '¡Ejercicio completado!',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            if (pts > 0) ...[
              const SizedBox(height: 8),
              Text(
                '+$pts puntos',
                style: const TextStyle(
                    color: Color(0xFF38EF7D),
                    fontSize: 28,
                    fontWeight: FontWeight.w900),
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 4),
              Text(
                '🔥 Racha: ${result.newStreak} día${result.newStreak == 1 ? '' : 's'}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
              ),
            ],
            if (unlocked.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD200).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFFFD200).withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Text('🔓 ¡Ejercicios desbloqueados!',
                        style: TextStyle(
                            color: Color(0xFFFFD200),
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    ...unlocked.map((e) => Text(
                          '${e.emoji} ${e.name}',
                          style: const TextStyle(color: Colors.white),
                        )),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cerrar dialog
              Navigator.pop(context); // volver a home
            },
            child: const Text('Continuar',
                style: TextStyle(
                    color: Color(0xFF0057FF), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  InputImage? _buildInputImage(CameraImage image) {
    try {
      final rotation = InputImageRotationValue.fromRawValue(
              _cam!.description.sensorOrientation) ??
          InputImageRotation.rotation0deg;
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;
      final WriteBuffer buf = WriteBuffer();
      for (final plane in image.planes) { buf.putUint8List(plane.bytes); }
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loadingExercise) return _buildLoading();

    final exercise = _exercise!;
    final isAuto = exercise.isAutoDetected;
    final cameraReady = _cam != null && _cam!.value.isInitialized;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            if (isAuto && cameraReady)
              CameraPreview(_cam!)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF7971E), Color(0xFFFFD200),
                      Color(0xFFFF6B6B), Color(0xFF9B59B6),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
              ),

            Container(color: Colors.black.withValues(alpha: 0.5)),
            CustomPaint(
              painter: const WavePainter(
                lines: 42, opacity: 0.08, strokeWidth: 1.3,
                ampBase: 4.0, ampFactor: 7.0, iFreqFactor: 1.1,
                iPhaseOffset: 0.5, freqBase: 0.05, freqStep: 0.007,
                freqMod: 7, xPhase: 0.6,
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Top bar ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                                'Completa el ejercicio para apagar la alarma'),
                            duration: Duration(seconds: 2),
                          )),
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        const Spacer(),
                        if (isAuto && _cameras.length > 1)
                          GestureDetector(
                            onTap: _switchingCamera ? null : _switchCamera,
                            child: Container(
                              width: 40, height: 40,
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
                          child: const Text('⏰ Alarma',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Title ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '¡Es hora\nde despertar!',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 38,
                        fontWeight: FontWeight.w900, height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Exercise badge ────────────────────────────────────────
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
                          Text('${exercise.emoji}  ',
                              style: const TextStyle(fontSize: 16)),
                          Text(
                            'Haz ${exercise.targetReps} ${exercise.name.toLowerCase()} para apagar',
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

                  // ── Pose warning (auto only) ───────────────────────────────
                  if (isAuto && cameraReady && !_poseVisible)
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
                      child: const Text('🔍 Apunta la cámara hacia tu cuerpo',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),

                  // ── Counter circle ────────────────────────────────────────
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (context, child) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _flash
                            ? Colors.green.withValues(alpha: 0.35)
                            : Colors.white
                                .withValues(alpha: 0.12 + _pulse.value * 0.06),
                        border: Border.all(
                          color: _isDown
                              ? Colors.orange.withValues(
                                  alpha: 0.6 + _pulse.value * 0.4)
                              : (isAuto && _poseVisible) || !isAuto
                                  ? Colors.greenAccent.withValues(
                                      alpha: 0.5 + _pulse.value * 0.3)
                                  : Colors.white.withValues(
                                      alpha: 0.3 + _pulse.value * 0.2),
                          width: 2.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_count',
                            style: const TextStyle(
                              color: Colors.white, fontSize: 68,
                              fontWeight: FontWeight.w900, height: 1,
                            ),
                          ),
                          Text(
                            'de ${exercise.targetReps}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 15, fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Phase / tap area ─────────────────────────────────────
                  if (isAuto)
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
                    )
                  else
                    GestureDetector(
                      onTap: _onManualTap,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 18),
                        decoration: BoxDecoration(
                          color: _flash
                              ? Colors.green.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: Text(
                          '${exercise.emoji}  TAP',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // ── Hint ─────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: Text(
                      isAuto
                          ? 'Coloca el teléfono en el suelo de lado\napuntando hacia ti'
                          : 'Toca el botón cada vez que completes una repetición',
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
      ),
    );
  }

  Widget _buildLoading() {
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⏰', style: TextStyle(fontSize: 48)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
