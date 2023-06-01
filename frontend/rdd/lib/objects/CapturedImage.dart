import 'package:camera/camera.dart';

class CapturedImage {
  final String imagePath;
  final double latitude;
  final double longitude;
  final double speed;
  final List<Map<String, dynamic>> bboxes;

  CapturedImage({
    required this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bboxes,
  });
}
