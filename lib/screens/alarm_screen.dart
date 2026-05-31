import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  File? _image;
  bool _isProcessing = false;

  static const String challenge = "Toma una foto de un objeto para apagar la alarma";

  Future pickImage() async {
    final useCamera = Platform.isAndroid || Platform.isIOS;
    final source = useCamera ? ImageSource.camera : ImageSource.gallery;

    try {
      final picked = await ImagePicker().pickImage(source: source);
      if (!mounted) return;
      if (picked != null) {
        setState(() => _image = File(picked.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not access ${useCamera ? "camera" : "gallery"}: $e'),
        ),
      );
    }
  }

  Future<void> validate() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Toma una foto primero.")),
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
        final obj = objects.first;
        final label = obj.labels.isNotEmpty ? obj.labels.first.text : "objeto";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("¡Alarma desactivada! Detecté: $label")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No detecté ningún objeto. Intenta de nuevo."),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                challenge,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            _image != null
                ? Image.file(_image!, height: 200)
                : const Text(
                    "Toma una foto para apagar la alarma",
                    style: TextStyle(color: Colors.white),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : pickImage,
              child: const Text("Abrir cámara"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isProcessing ? null : validate,
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Validar"),
            ),
          ],
        ),
      ),
    );
  }
}
