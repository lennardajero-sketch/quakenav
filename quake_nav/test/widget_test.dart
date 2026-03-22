import 'package:flutter_test/flutter_test.dart';
import 'package:quake_nav/main.dart';

void main() {
  test('parseIntensity handles known values case-insensitively', () {
    expect(parseIntensity('light'), QuakeIntensity.light);
    expect(parseIntensity(' Moderate '), QuakeIntensity.moderate);
    expect(parseIntensity('STRONG'), QuakeIntensity.strong);
  });

  test('unknown intensity does not trigger evacuation', () {
    expect(parseIntensity(null), QuakeIntensity.unknown);
    expect(parseIntensity('bad data'), QuakeIntensity.unknown);
    expect(shouldEvacuate(QuakeIntensity.unknown), isFalse);
  });

  test('moderate and strong intensity trigger evacuation', () {
    expect(shouldEvacuate(QuakeIntensity.light), isFalse);
    expect(shouldEvacuate(QuakeIntensity.moderate), isTrue);
    expect(shouldEvacuate(QuakeIntensity.strong), isTrue);
  });
}
