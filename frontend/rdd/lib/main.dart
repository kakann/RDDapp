import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rdd/objects/CapturedImage.dart';
import 'package:rdd/utlities/MapMarkNotifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  MyApp({required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageCapturingScreen(camera: camera),
    );
  }
}

class ImageCapturingScreen extends StatefulWidget {
  final CameraDescription camera;

  ImageCapturingScreen({required this.camera});

  @override
  _ImageCapturingScreenState createState() => _ImageCapturingScreenState();
}

class _ImageCapturingScreenState extends State<ImageCapturingScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  LatLng? _currentPosition;
  Timer? _timer;
  bool _isCapturing = false;
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print("Error getting current location: $e");
      return LatLng(0, 0);
    }
  }

  void _startCapturing() async {
    await _initializeControllerFuture;
    setState(() {
      _isCapturing = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final directory = await getApplicationDocumentsDirectory();

        final imagePath = await _controller.takePicture();

        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        final latitude = position.latitude;
        final longitude = position.longitude;
        final speed = position.speed;
        print(position);
        print(speed);
        print(imagePath);
        // Create a CapturedImage object and add it to the CapturedImageList
        final capturedImage = CapturedImage(
            imagePath: imagePath,
            latitude: latitude,
            longitude: longitude,
            speed: speed);
        // capturedImageList.addImage(capturedImage);

        // Process the image with your machine learning model and get the objects found in the image
        // ...

        // Add a marker for the captured image on the map
        setState(() {
          _markers.add(
            Marker(
              width: 80.0,
              height: 80.0,
              point: LatLng(latitude, longitude),
              builder: (ctx) => Container(
                child: const Icon(Icons.location_on, color: Colors.red),
              ),
            ),
          );
        });
      } catch (e) {
        print('Error capturing image: $e');
      }
    });
  }

  void _stopCapturing() {
    _timer?.cancel();
    setState(() {
      _isCapturing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapMarkerNotifier(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Image Capturing'),
        ),
        body: Stack(
          children: [
            FutureBuilder<LatLng>(
                future: _getCurrentLocation(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return FlutterMap(
                      options: MapOptions(
                        center: snapshot.data,
                        zoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          //tileProvider: NonCachingNetworkTileProvider(),
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        MarkerLayer(markers: _markers),
                      ],
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                }),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isCapturing ? null : _startCapturing,
                    child: const Text('Start'),
                  ),
                  ElevatedButton(
                    onPressed: _isCapturing ? _stopCapturing : null,
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
