import 'package:atelier/logic/condensation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('air à 20 °C et 60 % : point de rosée vers 12 °C', () {
    expect(dewPoint(20, 60), closeTo(12.0, 0.05));
    expect(dewPoint(20, 50), closeTo(9.26, 0.05));
    // Air saturé : la rosée est à la température de l'air
    expect(dewPoint(15, 100), closeTo(15, 1e-9));
  });

  test('par 0 °C dehors, le simple vitrage est à 4,9 °C côté pièce', () {
    expect(surfaceTemperature(Wall.singleGlazing, 20, 0), closeTo(4.92, 1e-9));
    expect(surfaceTemperature(Wall.insulatedWall, 20, 0), closeTo(19.22, 1e-9));
  });

  test('simple vitrage : il ruisselle ; double vitrage : à la limite ; mur isolé : sec', () {
    CondensationRisk vRisk(Wall pWall) => checkCondensation(
      pWall: pWall,
      pInsideC: 20,
      pHumidityPercent: 60,
      pOutsideC: 0,
    ).risk;
    expect(vRisk(Wall.singleGlazing), CondensationRisk.condensation);
    expect(vRisk(Wall.doubleGlazing), CondensationRisk.close);
    expect(vRisk(Wall.insulatedWall), CondensationRisk.none);
  });

  test('humidité à ne pas dépasser pour garder la paroi sèche', () {
    expect(maxHumidityFor(Wall.doubleGlazing, 20, 0), closeTo(62.9, 0.1));
    expect(maxHumidityFor(Wall.singleGlazing, 20, 0), closeTo(37.2, 0.1));
    // Pas de froid dehors : la paroi est à la température de la pièce
    expect(maxHumidityFor(Wall.bareWall, 20, 20), closeTo(100, 1e-9));
  });
}
