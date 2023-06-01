import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pytorch/pigeon.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rdd/objects/CapturedImage.dart';
import 'package:rdd/utlities/DBHelper.dart';
import 'package:rdd/utlities/MapMarkNotifier.dart';
import 'package:rdd/widgets/MyListScreen.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:geocoding/geocoding.dart';

class ImageCapturingScreen extends StatefulWidget {
  final CameraDescription camera;

  const ImageCapturingScreen({required this.camera});

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
  late Interpreter _interpreter;
  FlutterVision vision = FlutterVision();
  int nrCores = 1;
  bool firstRecording = true;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    _getCurrentLocation();
    nrCores = Platform.numberOfProcessors;

    vision.loadYoloModel(
        modelPath: "assets/yolov8m.tflite",
        labels: "assets/labels.txt",
        modelVersion: "yolov8",
        numThreads: nrCores);
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

  Future<void> getImageDimensions() async {
    final imageProvider = AssetImage('assets/Sweden_000047.jpg');

    final Completer<ImageInfo> completer = Completer<ImageInfo>();

    imageProvider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          completer.complete(info);
        },
      ),
    );

    final ImageInfo imageInfo = await completer.future;
    final int width = imageInfo.image.width;
    final int height = imageInfo.image.height;

    print('Image width: $width, height: $height');
  }

  Future<Uint8List> loadImageAsByteList(String imagePath) async {
    ByteData byteData = await rootBundle.load(imagePath);
    return byteData.buffer.asUint8List();
  }

  Future<String?> getLocalityFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      Placemark place = placemarks[0];

      print(place);
      if (place.locality != "") return place.locality;
      if (place.locality == "") return place.subLocality;
      if (place.subLocality == "") return place.administrativeArea;
    } catch (e) {
      print("Failed to get locality: $e.");
    }
  }

  void _startCapturing() async {
    await _initializeControllerFuture;
    setState(() {
      _isCapturing = true;
    });
    //ID of the list of snapshots
    int id = await DBHelper.insertCapturedImageList();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final directory = await getApplicationDocumentsDirectory();

        final XFile image = await _controller.takePicture();

        final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        final latitude = position.latitude;
        final longitude = position.longitude;
        final speed = position.speed;
        //print(position);
        //print(speed);
        //print(image.path);

        Uint8List byteList =
            await loadImageAsByteList("assets/Sweden_000047.jpg");
        Stopwatch stopwatch = Stopwatch();
        getImageDimensions();
        stopwatch.start();
        //print(byteList);
        //print("CORES:");
        //print(nrCores);
        List<Map<String, dynamic>> bboxes = await vision.yoloOnImage(
            bytesList: byteList,
            imageHeight: 600,
            imageWidth: 800,
            iouThreshold: 0.5,
            confThreshold: 0.25);
        stopwatch.stop();
        print('Elapsed time: ${stopwatch.elapsedMilliseconds} ms');
        //print(bboxes);

        // Create a CapturedImage object and add it to the CapturedImageList
        final capturedImage = CapturedImage(
            imagePath: image.path,
            latitude: latitude,
            longitude: longitude,
            speed: speed,
            bboxes: bboxes);
        // capturedImageList.addImage(capturedImage);

        if (firstRecording) {
          String? locality =
              await getLocalityFromCoordinates(latitude, longitude);
          DBHelper.setStartLocality(id, locality!);
          setState(() {
            firstRecording = false;
          });
        }

        String? locality =
            await getLocalityFromCoordinates(latitude, longitude);
        DBHelper.setEndLocality(id, locality!);

        print(locality);
        //print("locality");
        //print(locality);

        DBHelper.addImageToCapturedImageList(capturedImage, id);

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
