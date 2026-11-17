import 'package:atelier/logic/height_safety.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bas : escabeau ; haut : garde-corps et échafaudage freiné', () {
    expect(heightChecks(600), [HeightCheck.notAlone, HeightCheck.stepladder, HeightCheck.zoneBelow]);
    expect(heightChecks(3000), [
      HeightCheck.notAlone,
      HeightCheck.guardrails,
      HeightCheck.towerBraked,
      HeightCheck.zoneBelow,
    ]);
  });

  test('sur un toit : harnais et météo', () {
    expect(heightChecks(4000, pRoof: true), [
      HeightCheck.notAlone,
      HeightCheck.guardrails,
      HeightCheck.zoneBelow,
      HeightCheck.harness,
      HeightCheck.weather,
    ]);
  });
}
