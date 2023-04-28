import 'package:camera/camera.dart';

class CapturedImage {
  final XFile imagePath;
  final double latitude;
  final double longitude;
  final double speed;

  CapturedImage({
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.speed,
  });
}
