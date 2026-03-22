import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  final String baseUrl;

  OsrmService({this.baseUrl = 'https://router.project-osrm.org'});

  Future<RouteResult> fetchRouteResult({
    required LatLng from,
    required LatLng to,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/route/v1/driving/${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson&steps=false',
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('OSRM request failed (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) {
      throw Exception('OSRM returned no routes');
    }

    final route = routes.first as Map<String, dynamic>;
    final distance = (route['distance'] as num?)?.toDouble();
    final duration = (route['duration'] as num?)?.toDouble();
    final geometry = route['geometry'];
    if (distance == null || duration == null) {
      throw Exception('OSRM distance/duration missing');
    }
    if (geometry is! Map || geometry['coordinates'] is! List) {
      throw Exception('OSRM geometry missing');
    }

    final coords = geometry['coordinates'] as List;
    final points = coords
        .whereType<List>()
        .map((pair) => LatLng(
              (pair[1] as num).toDouble(),
              (pair[0] as num).toDouble(),
            ))
        .toList();

    return RouteResult(
      points: points,
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  Future<List<LatLng>> fetchRoute({
    required LatLng from,
    required LatLng to,
  }) async {
    final result = await fetchRouteResult(from: from, to: to);
    return result.points;
  }
}

class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}
