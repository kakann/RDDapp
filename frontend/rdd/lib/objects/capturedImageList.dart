import 'package:geolocator/geolocator.dart';
import 'package:rdd/objects/CapturedImage.dart';

class CapturedImageList {
  late List<CapturedImage> images;
  late String start_locality;
  late String end_locality;
  late DateTime date;

  CapturedImageList() {
    images = [];
    start_locality = '';
    end_locality = '';
    date = DateTime.now();
  }

  void addImage(CapturedImage image) {
    images.add(image);
  }

  void setStartLocality(String locality) {
    start_locality = locality;
  }

  void setEndLocality(String locality) {
    end_locality = locality;
  }

  int getTotalDamages() {
    int damages = 0;
    for (CapturedImage image in images) {
      for (var box in image.bboxes) {
        damages++;
      }
    }
    return damages;
  }

  Future<double> calculateTotalDistance() async {
    double totalDistance = 0;

    for (int i = 0; i < images.length - 1; i++) {
      double startLatitude = images[i].latitude;
      double startLongitude = images[i].longitude;
      double endLatitude = images[i + 1].latitude;
      double endLongitude = images[i + 1].longitude;

      totalDistance += Geolocator.distanceBetween(
          startLatitude, startLongitude, endLatitude, endLongitude);
    }

    return totalDistance / 1000; // Returns total distance in kilometers
  }
}
