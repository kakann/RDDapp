import 'package:rdd/objects/CapturedImage.dart';

class CapturedImageList {
  List<CapturedImage> images;

  CapturedImageList() : images = [];

  void addImage(CapturedImage image) {
    images.add(image);
  }
}
