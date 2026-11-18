import 'package:atelier/logic/wood_species.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dehors, ni sapin ni hêtre sans traitement', () {
    final vOutdoor = speciesFor(UseClass.outdoor);
    expect(vOutdoor.first, WoodSpecies.douglas);
    expect(vOutdoor, isNot(contains(WoodSpecies.spruce)));
    expect(vOutdoor, isNot(contains(WoodSpecies.beech)));
    expect(vOutdoor, contains(WoodSpecies.oak));
  });

  test('au contact du sol, seul le bois exotique tient sans traitement', () {
    expect(speciesFor(UseClass.groundContact), [WoodSpecies.tropical]);
  });

  test('à l\'intérieur au sec, tout convient, le moins cher d\'abord', () {
    final vIndoor = speciesFor(UseClass.indoorDry);
    expect(vIndoor.length, WoodSpecies.values.length);
    expect(vIndoor.take(2), [WoodSpecies.spruce, WoodSpecies.pine]);
  });

  test('poids d\'un chevron de chêne', () {
    // 63 × 75 mm sur 3 m : 0,014 m³ à 700 kg/m³
    expect(woodKg(WoodSpecies.oak, 63, 75, 3000), closeTo(9.92, 0.01));
  });
}
