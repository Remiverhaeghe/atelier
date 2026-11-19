import 'package:atelier/logic/floor_prep.dart';
import 'package:atelier/logic/screed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('séchage : une semaine par cm pour le ciment, plus long au-delà de 4 cm en anhydrite', () {
    expect(screedKindDryingDays(ScreedKind.dry, 30), 0);
    expect(screedKindDryingDays(ScreedKind.cement, 50), 35);
    expect(screedKindDryingDays(ScreedKind.liquidAnhydrite, 40), 28);
    expect(screedKindDryingDays(ScreedKind.liquidAnhydrite, 55), 56);
  });

  test('commande : plaques et granulats, sacs de mortier ou volume coulé', () {
    final vDry = screedOrder(ScreedKind.dry, 12, 30);
    expect(vDry.boards, 18);
    expect(vDry.grainBags, 8);
    expect(vDry.cementBags, 0);
    final vCement = screedOrder(ScreedKind.cement, 10, 50);
    expect(vCement.cementBags, 30);
    expect(vCement.volumeM3, closeTo(0.5, 1e-9));
    final vLiquid = screedOrder(ScreedKind.liquidAnhydrite, 20, 40);
    expect(vLiquid.volumeM3, closeTo(0.84, 1e-9));
    expect(vLiquid.boards + vLiquid.grainBags + vLiquid.cementBags, 0);
  });

  test('sous-couche selon le revêtement, en rouleaux de 15 m²', () {
    expect(underlayFor(Covering.floating), Underlay.foamWithFilm);
    expect(underlayFor(Covering.vinyl), Underlay.thinDense);
    expect(underlayFor(Covering.tiles), Underlay.none);
    expect(underlayFor(Covering.gluedParquet), Underlay.none);
    expect(underlayRolls(Covering.floating, 20), 2);
    expect(underlayRolls(Covering.tiles, 20), 0);
  });

  test('joints : jeu aux murs, seuils de porte et fractionnement des grandes pièces', () {
    expect(perimeterGapMm(Covering.floating), 8);
    expect(perimeterGapMm(Covering.tiles), 5);
    expect(expansionJoints(Covering.floating, 6000, 4000).extraJoints, 0);
    expect(expansionJoints(Covering.floating, 6000, 4000).doorThresholds, isTrue);
    expect(expansionJoints(Covering.floating, 12000, 4000).extraJoints, 1);
    // Carrelage de 9 × 6 m : 54 m² et plus de 8 m de long
    expect(expansionJoints(Covering.tiles, 9000, 6000).extraJoints, 1);
    expect(expansionJoints(Covering.tiles, 17000, 5000).extraJoints, 2);
    expect(expansionJoints(Covering.tiles, 9000, 6000).doorThresholds, isFalse);
    expect(expansionJoints(Covering.gluedParquet, 20000, 6000).extraJoints, 0);
  });

  test('pose possible quand la chape est assez sèche', () {
    expect(readyToLay(ScreedKind.cement, 1.8), isTrue);
    expect(readyToLay(ScreedKind.cement, 2.5), isFalse);
    expect(readyToLay(ScreedKind.liquidAnhydrite, 0.8), isFalse);
    expect(readyToLay(ScreedKind.dry, 5), isTrue);
    expect(ScreedKind.liquidAnhydrite.minThicknessMm, 30);
  });
}
