import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

const String kIntensityPath = 'quake/current/intensity';
const String kSitesPath = 'evacuationSites';

const List<EvacuationSite> kFallbackSites = [
  EvacuationSite(id: 'site1', location: LatLng(14.199744, 121.094640)),
  EvacuationSite(id: 'site2', location: LatLng(14.205022, 121.097869)),
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

enum QuakeIntensity { light, moderate, strong, unknown }

QuakeIntensity parseIntensity(String? value) {
  final normalized = value?.toLowerCase().trim();
  switch (normalized) {
    case 'light':
      return QuakeIntensity.light;
    case 'moderate':
      return QuakeIntensity.moderate;
    case 'strong':
      return QuakeIntensity.strong;
    default:
      return QuakeIntensity.unknown;
  }
}

String intensityLabel(QuakeIntensity intensity) {
  switch (intensity) {
    case QuakeIntensity.light:
      return 'Light';
    case QuakeIntensity.moderate:
      return 'Moderate';
    case QuakeIntensity.strong:
      return 'Strong';
    case QuakeIntensity.unknown:
      return 'Unknown';
  }
}

bool shouldEvacuate(QuakeIntensity intensity) {
  return intensity == QuakeIntensity.moderate ||
      intensity == QuakeIntensity.strong;
}

Color intensityColor(QuakeIntensity intensity) {
  switch (intensity) {
    case QuakeIntensity.light:
      return const Color(0xFF13B219);
    case QuakeIntensity.moderate:
      return const Color(0xFFFFA500);
    case QuakeIntensity.strong:
      return const Color(0xFFFF0000);
    case QuakeIntensity.unknown:
      return Colors.blueGrey;
  }
}

class EvacuationSite {
  final String id;
  final LatLng location;

  const EvacuationSite({required this.id, required this.location});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  LatLng? currentLocation;
  List<LatLng> path = [];
  QuakeIntensity _intensity = QuakeIntensity.unknown;
  List<EvacuationSite> _sites = List<EvacuationSite>.from(kFallbackSites);
  EvacuationSite? _targetSite;

  StreamSubscription<DatabaseEvent>? _intensitySub;
  StreamSubscription<DatabaseEvent>? _sitesSub;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _listenIntensity();
    _listenSites();
  }

  Future<void> _getLocation() async {
    await Geolocator.requestPermission();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      LatLng pos = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLocation = pos;
        path.add(pos);
        _targetSite = _pickNearestSite(
          shouldEvacuate(_intensity) ? pos : null,
          _sites,
        );
      });

      _mapController.move(pos, 18);
    });
  }

  void _listenIntensity() {
    final ref = FirebaseDatabase.instance.ref(kIntensityPath);
    _intensitySub = ref.onValue.listen((event) {
      final value = event.snapshot.value;
      final intensity = parseIntensity(value?.toString());
      setState(() {
        _intensity = intensity;
        _targetSite = _pickNearestSite(
          shouldEvacuate(_intensity) ? currentLocation : null,
          _sites,
        );
      });
    });
  }

  void _listenSites() {
    final ref = FirebaseDatabase.instance.ref(kSitesPath);
    _sitesSub = ref.onValue.listen((event) {
      final value = event.snapshot.value;
      final sites = _parseSites(value);
      setState(() {
        _sites = sites.isEmpty ? List<EvacuationSite>.from(kFallbackSites) : sites;
        _targetSite = _pickNearestSite(
          shouldEvacuate(_intensity) ? currentLocation : null,
          _sites,
        );
      });
    });
  }

  List<EvacuationSite> _parseSites(Object? value) {
    if (value is Map) {
      final sites = <EvacuationSite>[];
      value.forEach((key, entry) {
        if (entry is Map) {
          final lat = entry['lat'];
          final lng = entry['lng'];
          if (lat != null && lng != null) {
            final latValue = double.tryParse(lat.toString());
            final lngValue = double.tryParse(lng.toString());
            if (latValue != null && lngValue != null) {
              sites.add(
                EvacuationSite(
                  id: key.toString(),
                  location: LatLng(latValue, lngValue),
                ),
              );
            }
          }
        }
      });
      return sites;
    }
    return [];
  }

  EvacuationSite? _pickNearestSite(
    LatLng? position,
    List<EvacuationSite> sites,
  ) {
    if (position == null || sites.isEmpty) {
      return null;
    }
    EvacuationSite? nearest;
    double? nearestMeters;
    for (final site in sites) {
      final meters = _distance(position, site.location);
      if (nearestMeters == null || meters < nearestMeters) {
        nearest = site;
        nearestMeters = meters;
      }
    }
    return nearest;
  }

  @override
  void dispose() {
    _intensitySub?.cancel();
    _sitesSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusText = shouldEvacuate(_intensity)
        ? 'Evacuate to ${_targetSite?.id ?? 'nearest site'}'
        : 'Monitoring';
    return Scaffold(
      appBar: AppBar(
        title: Text('QuakeNav - ${intensityLabel(_intensity)}'),
        backgroundColor: intensityColor(_intensity),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
          initialCenter: LatLng(14.5995, 120.9842),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.osm',
          ),

          // Marker
          if (currentLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: currentLocation!,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),

          if (_sites.isNotEmpty)
            MarkerLayer(
              markers: _sites
                  .map(
                    (site) => Marker(
                      point: site.location,
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.flag,
                        color: site == _targetSite
                            ? Colors.blueAccent
                            : Colors.green.shade700,
                        size: 32,
                      ),
                    ),
                  )
                  .toList(),
            ),

          // Polyline (Path)
          PolylineLayer(
            polylines: [
              Polyline(
                points: path,
                strokeWidth: 4,
                color: Colors.blue,
              ),
              if (shouldEvacuate(_intensity) &&
                  currentLocation != null &&
                  _targetSite != null)
                Polyline(
                  points: [currentLocation!, _targetSite!.location],
                  strokeWidth: 5,
                  color: Colors.orange,
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.65),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          statusText,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
