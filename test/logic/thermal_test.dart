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
}
