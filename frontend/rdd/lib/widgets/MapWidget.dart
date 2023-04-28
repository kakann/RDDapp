import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../utlities/MapMarkNotifier.dart';

class MapWidget extends StatelessWidget {
  final LatLng position;

  MapWidget({required this.position});

  @override
  Widget build(BuildContext context) {
    final mapMarkers = Provider.of<MapMarkerNotifier>(context);

    return FlutterMap(
      options: MapOptions(
        center: position,
        zoom: 15.0,
      ),
      children: [
        TileLayer(
          //tileProvider: NonCachingNetworkTileProvider(),
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayer(markers: mapMarkers.markers),
      ],
    );
  }
}
