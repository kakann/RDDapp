import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rdd/objects/CapturedImage.dart';
import 'package:rdd/objects/capturedImageList.dart';

import '../utlities/MapMarkNotifier.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CapturedImageMap extends StatelessWidget {
  final List<CapturedImageList> capturedImageLists;

  CapturedImageMap({required this.capturedImageLists});

  @override
  Widget build(BuildContext context) {
    List<List<LatLng>> latLngCoordinates =
        getLatLngCoordinates(capturedImageLists);
    LatLng meanCoord = calculateMeanLatLng(latLngCoordinates);

    List<Polyline> polylines = latLngCoordinates.map((coordinates) {
      return Polyline(
        points: coordinates,
        color: Colors.green,
        strokeWidth: 4.0,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Map View")),
      body: FlutterMap(
        options: MapOptions(
          center: meanCoord,
          zoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: getMarkers(capturedImageLists),
          ),
          PolylineLayer(
            polylines: polylines,
          ),
        ],
      ),
    );
  }

  List<List<LatLng>> getLatLngCoordinates(
      List<CapturedImageList> capturedImageList) {
    List<List<LatLng>> points = [];
    for (CapturedImageList list in capturedImageLists) {
      List<LatLng> pointsInner = [];
      for (CapturedImage image in list.images) {
        LatLng coord = LatLng(image.latitude, image.longitude);
        pointsInner.add(coord);
      }
      points.add(pointsInner);
    }
    return points;
  }

  LatLng calculateMeanLatLng(List<List<LatLng>> coordinatesLists) {
    if (coordinatesLists.isEmpty) {
      throw Exception('Coordinates list is empty.');
    }

    double sumLat = 0.0;
    double sumLng = 0.0;
    int count = 0;

    for (var coordinates in coordinatesLists) {
      for (var coordinate in coordinates) {
        sumLat += coordinate.latitude;
        sumLng += coordinate.longitude;
        count++;
      }
    }

    double meanLat = sumLat / count;
    double meanLng = sumLng / count;

    return LatLng(meanLat, meanLng);
  }

  List<Marker> getMarkers(List<CapturedImageList> capturedImagesLists) {
    List<Marker> markers = [];
    for (CapturedImageList list in capturedImagesLists) {
      for (CapturedImage image in list.images) {
        markers.add(
          Marker(
            point: LatLng(image.latitude, image.longitude),
            builder: (context) => Icon(Icons.location_pin),
          ),
        );
      }
    }
    return markers;
  }
}
