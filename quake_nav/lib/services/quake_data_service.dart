import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

import '../models/evacuation_site.dart';
import '../models/phivolcs_event.dart';
import '../models/quake_intensity.dart';

class QuakeDataService {
  final DatabaseReference _intensityRef;
  final DatabaseReference _sitesRef;
  final DatabaseReference _phivolcsLatestRef;
  final DatabaseReference _phivolcsEventsRef;

  QuakeDataService({
    String intensityPath = 'quake_history',
    String sitesPath = 'evacuationSites',
    String phivolcsLatestPath = 'phivolcs/latest',
    String phivolcsEventsPath = 'phivolcs/events',
  })  : _intensityRef = FirebaseDatabase.instance.ref(intensityPath),
        _sitesRef = FirebaseDatabase.instance.ref(sitesPath),
        _phivolcsLatestRef = FirebaseDatabase.instance.ref(phivolcsLatestPath),
        _phivolcsEventsRef = FirebaseDatabase.instance.ref(phivolcsEventsPath);

  Stream<QuakeIntensity> intensityStream() {
    return intensityEventStream().map((event) => event.intensity);
  }

  Stream<IntensityEvent> intensityEventStream() {
    return _intensityRef.onValue.map((event) {
      final value = event.snapshot.value;
      final extracted = _extractLatestIntensityData(value);
      return IntensityEvent(
        intensity: extracted.intensity,
        sourceTimestamp: extracted.timestamp,
        receivedAt: DateTime.now(),
      );
    });
  }

  Stream<List<EvacuationSite>> sitesStream(
      List<EvacuationSite> fallbackSites) {
    return _sitesRef.onValue.map((event) {
      final value = event.snapshot.value;
      final sites = _parseSites(value);
      return sites.isEmpty ? List<EvacuationSite>.from(fallbackSites) : sites;
    });
  }

  Stream<PhivolcsEvent?> phivolcsLatestStream() {
    return _phivolcsLatestRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      final data = Map<Object?, Object?>.from(value);
      return _mapToPhivolcsEvent('latest', data);
    });
  }

  Stream<List<PhivolcsEvent>> phivolcsEventsStream({int limit = 10}) {
    return _phivolcsEventsRef.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return const <PhivolcsEvent>[];
      final root = Map<Object?, Object?>.from(value);
      final items = <PhivolcsEvent>[];
      root.forEach((key, raw) {
        if (raw is! Map) return;
        final data = Map<Object?, Object?>.from(raw);
        final item = _mapToPhivolcsEvent(key.toString(), data);
        items.add(item);
      });
      items.sort((a, b) {
        final at = a.updatedAtMs ?? 0;
        final bt = b.updatedAtMs ?? 0;
        return bt.compareTo(at);
      });
      if (items.length <= limit) return items;
      return items.take(limit).toList(growable: false);
    });
  }

  PhivolcsEvent _mapToPhivolcsEvent(String eventId, Map<Object?, Object?> data) {
    double? toDouble(Object? value) => double.tryParse((value ?? '').toString());
    int? toInt(Object? value) => int.tryParse((value ?? '').toString());

    return PhivolcsEvent(
      eventId: eventId,
      dateTimePH: (data['dateTimePH'] ?? '').toString(),
      latitude: toDouble(data['latitude']),
      longitude: toDouble(data['longitude']),
      depthKm: toDouble(data['depthKm']),
      magnitude: toDouble(data['magnitude']),
      locationText: (data['locationText'] ?? '').toString(),
      updatedAtMs: toInt(data['updatedAt']),
    );
  }

  _ExtractedIntensity _extractLatestIntensityData(Object? value) {
    if (value is String) {
      return _ExtractedIntensity(
        intensity: parseIntensity(value),
        timestamp: null,
      );
    }
    if (value is Map) {
      // Case A: snapshot is already a single event object:
      // { intensity: "...", timestamp: "...", esp_epoch_ms: ... }
      if (value['intensity'] != null) {
        final intensity = parseIntensity(value['intensity']?.toString());
        final ts = _extractEventTimestamp(value);
        return _ExtractedIntensity(
          intensity: intensity,
          timestamp: ts,
        );
      }

      // Case B: snapshot is a history map keyed by id/timestamp.
      String? bestKey;
      DateTime? bestTime;
      String? bestIntensity;

      value.forEach((key, entry) {
        if (entry is Map && entry['intensity'] != null) {
          final intensity = entry['intensity'].toString();
          final ts = _extractEventTimestamp(entry);

          if (ts != null) {
            if (bestTime == null || ts.isAfter(bestTime!)) {
              bestTime = ts;
              bestIntensity = intensity;
            }
            return;
          }

          final keyText = key.toString();
          if (bestKey == null || keyText.compareTo(bestKey!) > 0) {
            bestKey = keyText;
            bestIntensity = intensity;
          }
        }
      });

      if (bestIntensity != null) {
        return _ExtractedIntensity(
          intensity: parseIntensity(bestIntensity),
          timestamp: bestTime,
        );
      }
    }
    return _ExtractedIntensity(
      intensity: QuakeIntensity.unknown,
      timestamp: null,
    );
  }

  DateTime? _extractEventTimestamp(Map event) {
    final epoch = event['esp_epoch_ms'];
    if (epoch != null) {
      final epochMs = int.tryParse(epoch.toString());
      if (epochMs != null && epochMs > 0) {
        return DateTime.fromMillisecondsSinceEpoch(epochMs);
      }
    }

    final tsRaw = event['timestamp'];
    final tsText = tsRaw?.toString();
    if (tsText == null || tsText.isEmpty) {
      return null;
    }
    return DateTime.tryParse(
      tsText.contains(' ') ? tsText.replaceFirst(' ', 'T') : tsText,
    );
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
}

class IntensityEvent {
  final QuakeIntensity intensity;
  final DateTime? sourceTimestamp;
  final DateTime receivedAt;

  const IntensityEvent({
    required this.intensity,
    required this.sourceTimestamp,
    required this.receivedAt,
  });
}

class _ExtractedIntensity {
  final QuakeIntensity intensity;
  final DateTime? timestamp;

  const _ExtractedIntensity({
    required this.intensity,
    required this.timestamp,
  });
}
