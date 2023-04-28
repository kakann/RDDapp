import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapMarkerNotifier extends ChangeNotifier {
  List<Marker> _markers = [];

  List<Marker> get markers => _markers;

  void addMarker(LatLng position) {
    _markers.add(
      Marker(
        width: 80.0,
        height: 80.0,
        point: position,
        builder: (ctx) => Container(
          child: Icon(Icons.location_on, color: Colors.red),
        ),
      ),
    );
    notifyListeners();
  }
}
