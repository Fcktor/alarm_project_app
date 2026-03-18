import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  File? _image;

  final String challenge = "Find something red";

  Future pickImage() async {
    // Linux/desktop builds require a cameraDelegate for ImageSource.camera.
    // Fallback to the gallery to avoid a runtime exception.
    final source = (Platform.isAndroid || Platform.isIOS)
        ? ImageSource.camera
        : ImageSource.gallery;

    if (source == ImageSource.gallery) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera is not supported on this platform; opening gallery instead.',
          ),
        ),
      );
    }

    final picked = await ImagePicker().pickImage(
      source: source,
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> validate() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Take a photo first.")),
      );
      return;
    }

    final bytes = await _image!.readAsBytes();

    if (!mounted) return;

    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not read image.")),
      );
      return;
    }

    // Sample pixels to avoid spending too much time on large photos.
    const step = 10; // check every 10th pixel horizontally and vertically.
    double redSum = 0;
    double greenSum = 0;
    double blueSum = 0;
    var count = 0;

    for (var y = 0; y < decoded.height; y += step) {
      for (var x = 0; x < decoded.width; x += step) {
        final pixel = decoded.getPixel(x, y);
        redSum += pixel.r;
        greenSum += pixel.g;
        blueSum += pixel.b;
        count++;
      }
    }

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image too small to analyze.")),
      );
      return;
    }

    final avgRed = redSum / count;
    final avgGreen = greenSum / count;
    final avgBlue = blueSum / count;

    // A simple heuristic: require red to be noticeably higher than green/blue.
    if (avgRed > avgGreen * 1.2 && avgRed > avgBlue * 1.2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alarm dismissed!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That doesn't look red enough. Try again!")),
      );
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
            Text(
              challenge,
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            _image != null
                ? Image.file(_image!, height: 200)
                : const Text(
                    "Take a photo to dismiss alarm",
                    style: TextStyle(color: Colors.white),
                  ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickImage,
              child: const Text("Open Camera"),
            ),

            ElevatedButton(
              onPressed: validate,
              child: const Text("Validate"),
            ),
          ],
        ),
      ),
    );
  }
}