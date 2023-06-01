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

  Map<String, int> getDamagesPerClass() {
    Map<String, int> damages = {};
    for (CapturedImage image in images) {
      for (var box in image.bboxes) {
        if (damages[box["tag"]] == null) {
          damages[box["tag"]] = 1;
        } else {
          damages[box["tag"]] = (damages[box["tag"]]! + 1);
        }
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

  double calculateBBoxArea(bbox) {
    double width = bbox["box"][2] - bbox["box"][0];
    double height = bbox["box"][3] - bbox["box"][1];
    return width * height;
  }

  Map<String, double> getRoadQualityScores() {
    Map<String, double> roadQualityScores = {};

    /*
    Different damages have different weights. The size of the damage is also weighted against the confidence of the prediction.

    so that for each location:
    */

    // Define weights for each damage class.
    Map<String, double> damageWeights = {
      'D40': 1.5, // Assuming these are more severe.
      'D20': 1.5,
      'D00': 1.0, // Less severe.
      'D10': 1.0
    };

    for (int i = 0; i < images.length; i++) {
      double damageScore = 0;
      for (var bbox in images[i].bboxes) {
        double confidence = bbox["box"][4];
        double weight = damageWeights[bbox['tag']] ??
            1.0; // Default weight is 1.0 if class is not found in damageWeights.
        damageScore +=
            (calculateBBoxArea(bbox) * 0.7 + confidence * 0.3) * weight;
      }
      damageScore /= images[i].bboxes.length;
      String key = "${images[i].latitude},${images[i].longitude}";
      roadQualityScores[key] = damageScore;
    }

    Map<String, double> smoothedRoadQualityScores = {};
    for (int i = 0; i < images.length; i++) {
      String currentKey = "${images[i].latitude},${images[i].longitude}";
      String previousKey = i > 0
          ? "${images[i - 1].latitude},${images[i - 1].longitude}"
          : currentKey;
      String nextKey = i < images.length - 1
          ? "${images[i + 1].latitude},${images[i + 1].longitude}"
          : currentKey;

      double previousScore = roadQualityScores[previousKey]!;
      double nextScore = roadQualityScores[nextKey]!;
      double currentScore = roadQualityScores[currentKey]!;
      smoothedRoadQualityScores[currentKey] =
          (previousScore + currentScore + nextScore) / 3.0;
    }

    return smoothedRoadQualityScores;
  }
}
