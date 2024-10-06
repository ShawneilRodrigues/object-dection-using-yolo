import 'dart:convert'; // Import this library
import 'dart:html' as html; // Import for web file input
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data'; // Import for Uint8List

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  _ImageUploadScreenState createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  Uint8List? _imageBytes; // Store image bytes
  String _detectionResult = '';

  // Function to pick image from gallery (for web)
  Future<void> pickImage() async {
    // Create an input element for file selection
    final html.FileUploadInputElement uploadInput =
        html.FileUploadInputElement();
    uploadInput.accept = 'image/*';
    uploadInput.click(); // Trigger the file picker

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files; // Get the selected files
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(files[0]); // Read the file as an ArrayBuffer
      reader.onLoadEnd.listen((e) {
        setState(() {
          _imageBytes = reader.result as Uint8List; // Store the image bytes
        });
      });
    });
  }

  // Function to detect object using YOLO API
  Future<void> detectObject() async {
    if (_imageBytes == null) return;

    var uri = Uri.parse('http://192.168.0.102:5000'); // API endpoint
    var request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', _imageBytes!,
          filename: 'image.jpg'));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      setState(() {
        _detectionResult = result['object_names']
            .join(', '); // Assuming the API returns a list of object names
      });
    } else {
      setState(() {
        _detectionResult = 'Error: Could not detect object';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Detection with YOLO')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display image with a border
            _imageBytes == null
                ? const Text('No image selected.')
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _imageBytes!, // Use Image.memory for Uint8List
                        width: 300, // Set a specific width
                        height: 300, // Set a specific height
                        fit: BoxFit.cover, // Cover the container
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: pickImage,
              child: const Text('Upload Image'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: detectObject,
              child: const Text('Detect'),
            ),
            const SizedBox(height: 20),
            Text('Detected Object: $_detectionResult'),
          ],
        ),
      ),
    );
  }
}
