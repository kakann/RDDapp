import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<List<LatLng>> fetchSnappedCoordinates(List<LatLng> coordinates) async {
  // Replace with your OSRM server URL
  const String osrmServerUrl = 'https://my-osrm-server.com/';

  // Convert LatLng coordinates to OSRM's lon,lat format
  String coords = coordinates
      .map((coord) => '${coord.longitude},${coord.latitude}')
      .join(';');

  // Build the API URL
  String apiUrl =
      '${osrmServerUrl}match/v1/driving/$coords?overview=full&geometries=geojson&timestamps=0';

  // Send a GET request to the OSRM API
  final response = await http.get(Uri.parse(apiUrl));

  // Check if the request was successful
  if (response.statusCode == 200) {
    // Parse the response JSON
    Map<String, dynamic> jsonData = json.decode(response.body);

    // Extract the snapped coordinates
    List<dynamic> snappedCoords =
        jsonData['matchings'][0]['geometry']['coordinates'];

    // Convert the snapped coordinates to LatLng format
    List<LatLng> snappedLatLngs =
        snappedCoords.map((coord) => LatLng(coord[1], coord[0])).toList();

    return snappedLatLngs;
  } else {
    throw Exception('Failed to fetch snapped coordinates');
  }
}
