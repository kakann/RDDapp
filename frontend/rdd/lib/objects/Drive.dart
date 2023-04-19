import 'package:rdd/objects/PositionImgSnap.dart';

class Drive {
  List<PositionImgSnap> positionImgSnaps;
  Duration totalTime;
  int totalImages;
  int totalDamages;

  Drive({
    required this.positionImgSnaps,
    required this.totalTime,
    required this.totalImages,
    required this.totalDamages,
  });
}
