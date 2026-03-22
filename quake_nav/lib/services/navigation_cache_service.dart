import 'package:latlong2/latlong.dart';

import '../models/quake_intensity.dart';

class NavigationCacheSnapshot {
  final LatLng? location;
  final QuakeIntensity intensity;
  final List<LatLng> routePoints;
  final int? etaMinutes;
  final double? routeDistanceKm;
  final String? routeDestinationName;
  final String? selectedBuilding;
  final LatLng? buildingExit;
  final LatLng? buildingDestination;
  final DateTime updatedAt;

  const NavigationCacheSnapshot({
    required this.location,
    required this.intensity,
    required this.routePoints,
    required this.etaMinutes,
    required this.routeDistanceKm,
    required this.routeDestinationName,
    required this.selectedBuilding,
    required this.buildingExit,
    required this.buildingDestination,
    required this.updatedAt,
  });
}

class NavigationCacheService {
  NavigationCacheService._();

  static final NavigationCacheService instance = NavigationCacheService._();

  LatLng? _location;
  QuakeIntensity _intensity = QuakeIntensity.unknown;
  List<LatLng> _routePoints = <LatLng>[];
  int? _etaMinutes;
  double? _routeDistanceKm;
  String? _routeDestinationName;
  String? _selectedBuilding;
  LatLng? _buildingExit;
  LatLng? _buildingDestination;
  DateTime _updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  NavigationCacheSnapshot snapshot() {
    return NavigationCacheSnapshot(
      location: _location,
      intensity: _intensity,
      routePoints: List<LatLng>.from(_routePoints),
      etaMinutes: _etaMinutes,
      routeDistanceKm: _routeDistanceKm,
      routeDestinationName: _routeDestinationName,
      selectedBuilding: _selectedBuilding,
      buildingExit: _buildingExit,
      buildingDestination: _buildingDestination,
      updatedAt: _updatedAt,
    );
  }

  void updateLocation(LatLng location) {
    _location = location;
    _touch();
  }

  void updateIntensity(QuakeIntensity intensity) {
    _intensity = intensity;
    _touch();
  }

  void updateBuilding({
    required String? selectedBuilding,
    required LatLng? buildingExit,
    required LatLng? buildingDestination,
  }) {
    _selectedBuilding = selectedBuilding;
    _buildingExit = buildingExit;
    _buildingDestination = buildingDestination;
    _touch();
  }

  void updateRoute({
    required List<LatLng> routePoints,
    required int? etaMinutes,
    required double? routeDistanceKm,
    required String? routeDestinationName,
  }) {
    _routePoints = List<LatLng>.from(routePoints);
    _etaMinutes = etaMinutes;
    _routeDistanceKm = routeDistanceKm;
    _routeDestinationName = routeDestinationName;
    _touch();
  }

  void clearRoute() {
    _routePoints = <LatLng>[];
    _etaMinutes = null;
    _routeDistanceKm = null;
    _routeDestinationName = null;
    _touch();
  }

  bool isFresh(Duration maxAge) {
    return DateTime.now().difference(_updatedAt) <= maxAge;
  }

  void _touch() {
    _updatedAt = DateTime.now();
  }
}
