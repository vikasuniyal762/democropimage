import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionPage extends StatefulWidget {
  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  CameraController? _cameraController;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _cameraController = CameraController(camera, ResolutionPreset.high);
    await _cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }
///PICK IMAGE
  void _pickImage() async {
    final pickedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  void _detectAndCropFace() async {
    if (_selectedImage == null) {
      print('No image selected');
      return;
    }

    final inputImage = InputImage.fromFilePath(_selectedImage!.path);

    // Create the face detector options if you want to customize the detection behavior.
    final faceDetectorOptions = FaceDetectorOptions(
     // mode: FaceDetectorMode.accurate, // You can use 'fast' for faster detection
      performanceMode: FaceDetectorMode.accurate,
      enableContours: true, // Set to true if you want to detect facial contours as well
      enableLandmarks: true, // Set to true if you want to detect facial landmarks as well
    );

    final options = FaceDetectorOptions();
    final faceDetector = FaceDetector(options: options);

    try {
      final List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        print('No faces detected');
        return;
      }

      // Assuming only one face is detected in this example
      final face = faces.first;
      final left = face.boundingBox.left.toInt();
      final top = face.boundingBox.top.toInt();
      final width = face.boundingBox.width.toInt();
      final height = face.boundingBox.height.toInt();

      // Get the face image and save it to a new file
      final croppedImage = await _cropFaceImage(left, top, width, height);
      // Now you have the cropped face image in the croppedImage variable.
    } catch (e) {
      print('Error during face detection: $e');
    } finally {
      faceDetector.close(); // Don't forget to close the detector to release resources
    }
  }

  Future<File> _cropFaceImage(int left, int top, int width, int height) async {
    final originalImage = img.decodeImage(await _selectedImage!.readAsBytes());
    final faceImage = img.copyCrop(originalImage!, x:left, y:top, width:width, height:height);
    final croppedPath = _selectedImage!.path.replaceFirst('.jpg', '_cropped.jpg');
    return File(croppedPath).writeAsBytes(img.encodeJpg(faceImage));
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController!.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      appBar: AppBar(title: Text('Face Detection')),
      body: Column(
        children: [
          Expanded(
            child: _selectedImage != null
                ? Image.file(_selectedImage!)
                : CameraPreview(_cameraController!),
          ),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Select Image'),
          ),
          ElevatedButton(
            onPressed: _detectAndCropFace,
            child: Text('Detect and Crop Face'),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FaceDetectionPage(),
  ));
}
