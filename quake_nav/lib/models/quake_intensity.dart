import 'package:flutter/material.dart';

enum QuakeIntensity { light, moderate, strong, unknown }

QuakeIntensity parseIntensity(String? value) {
  final normalized = value?.toLowerCase().trim();
  switch (normalized) {
    case 'light':
    case 'weak':
      return QuakeIntensity.light;
    case 'moderate':
    case 'moderately strong':
    case 'moderately_strong':
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
      return 'Weak';
    case QuakeIntensity.moderate:
      return 'Moderately Strong';
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
      return Colors.green.shade700;
    case QuakeIntensity.moderate:
      return const Color(0xFFB08A4A);
    case QuakeIntensity.strong:
      return Colors.red.shade700;
    case QuakeIntensity.unknown:
      return Colors.blueGrey;
  }
}
