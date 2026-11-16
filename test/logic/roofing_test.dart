import 'package:atelier/logic/roofing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pan de 6 m sur 4,50 m en tuiles à emboîtement', () {
    final vNeeds = roofNeeds(const RoofPan());

    expect(vNeeds.areaM2, closeTo(28.8, 1e-9));
    expect(vNeeds.rafters, 11);
    expect(vNeeds.rafterLengthMm, 4800);
    expect(vNeeds.battenRows, 16);
    expect(vNeeds.battens, 26);
    expect(vNeeds.counterBattens, 13);
    expect(vNeeds.coverings, 394);
    expect(vNeeds.ridgePieces, 15);
    expect(vNeeds.vergePieces, 29);
    expect(vNeeds.membraneRolls, 1);
  });

  test('ardoises : plus de rangs, entraxe resserré', () {
    final vNeeds = roofNeeds(
      const RoofPan().copyWith(covering: RoofCovering.slate, spacingMm: 400, overhangMm: 0),
    );

    expect(vNeeds.rafters, 16);
    expect(vNeeds.battenRows, 21);
    expect(vNeeds.coverings, 851);
    expect(roofNeeds(const RoofPan(spacingMm: 0)).rafters, 0);
  });
}
