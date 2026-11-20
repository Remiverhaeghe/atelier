import 'package:atelier/logic/thermal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque défaut a sa préconisation', () {
    expect(ThermalIssue.values.map(fixFor).toSet(), ThermalFix.values.toSet());
    expect(fixFor(ThermalIssue.doorGap), ThermalFix.doorSweep);
    expect(needsQuote(ThermalIssue.ceiling), isTrue);
    expect(needsQuote(ThermalIssue.outlet), isFalse);
  });

  test('une zone compte si elle est plus froide d\'au moins 3 °C', () {
    expect(isNotable(15, 19), isTrue);
    expect(isNotable(17.5, 19), isFalse);
  });

  test('facteur de température : 1 comme la pièce, 0 comme dehors', () {
    expect(temperatureFactor(20, 20, 0), 1);
    expect(temperatureFactor(0, 20, 0), 0);
    expect(temperatureFactor(12, 20, 0), closeTo(0.6, 1e-9));
  });

  test('relevé : de rien à signaler jusqu\'à la condensation', () {
    ThermalSeverity? vSeverity(double pSpot, double pWall, {double? pHumidity}) => readThermal(
      spotC: pSpot,
      wallC: pWall,
      insideC: 20,
      outsideC: 0,
      humidityPercent: pHumidity,
    )?.severity;

    expect(vSeverity(17, 19), ThermalSeverity.none);
    expect(vSeverity(15, 19), ThermalSeverity.mild);
    expect(vSeverity(12, 19), ThermalSeverity.mouldRisk);
    // À 20 °C et 60 % d'humidité, l'eau se dépose sous 12 °C environ
    expect(vSeverity(11, 19, pHumidity: 60), ThermalSeverity.condensation);
    expect(vSeverity(15, 19, pHumidity: 60), ThermalSeverity.mild);
  });

  test('pas de conclusion sans 10 °C d\'écart entre dedans et dehors', () {
    expect(readThermal(spotC: 11, wallC: 14, insideC: 15, outsideC: 10), isNull);
    expect(readThermal(spotC: 11, wallC: 14, insideC: 20, outsideC: 10), isNotNull);
  });
}
