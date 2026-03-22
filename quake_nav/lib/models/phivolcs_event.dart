class PhivolcsEvent {
  final String eventId;
  final String dateTimePH;
  final double? latitude;
  final double? longitude;
  final double? depthKm;
  final double? magnitude;
  final String locationText;
  final int? updatedAtMs;

  const PhivolcsEvent({
    required this.eventId,
    required this.dateTimePH,
    required this.latitude,
    required this.longitude,
    required this.depthKm,
    required this.magnitude,
    required this.locationText,
    required this.updatedAtMs,
  });
}
