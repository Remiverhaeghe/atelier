import 'package:atelier/logic/attic_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combles à deux pans, 6 m entre jambettes de 80 cm, rampants à 40°', () {
    final vSection = atticSection(
      pWidthMm: 6000,
      pKneeWallMm: 800,
      pSlopeDeg: 40,
      pTwoPitches: true,
    );
    // 800 + 3000 × tan 40°
    expect(vSection.topMm, 3317);
    // 1 m à gagner à tan 40° : 1192 mm trop bas de chaque côté
    expect(vSection.lowStripMm, 1192);
    expect(vSection.usableWidthMm, 3616);
    expect(vSection.rafterLengthMm, 3916);
    expect(vSection.flatWidthMm, 0);
    expect(vSection.boardM2PerMetre, closeTo(9.432, 0.001));
  });

  test('un plafond plat à 2,50 m raccourcit les rampants', () {
    final vSection = atticSection(
      pWidthMm: 6000,
      pKneeWallMm: 800,
      pSlopeDeg: 40,
      pTwoPitches: true,
      pCeilingMm: 2500,
    );
    expect(vSection.topMm, 2500);
    expect(vSection.flatWidthMm, 1948);
    expect(vSection.rafterLengthMm, 2645);
    expect(vSection.usableWidthMm, 3616);
    expect(vSection.boardM2PerMetre, closeTo(8.838, 0.002));
  });

  test('un seul pan contre un mur droit', () {
    final vSection = atticSection(
      pWidthMm: 4000,
      pKneeWallMm: 1000,
      pSlopeDeg: 30,
      pTwoPitches: false,
    );
    expect(vSection.topMm, 3309);
    expect(vSection.usableWidthMm, 2614);
    expect(vSection.rafterLengthMm, 4619);
    expect(vSection.boardM2PerMetre, closeTo(5.619, 0.001));
  });

  test('combles trop bas : rien au-dessus de 1,80 m', () {
    final vSection = atticSection(
      pWidthMm: 4000,
      pKneeWallMm: 0,
      pSlopeDeg: 20,
      pTwoPitches: true,
    );
    expect(vSection.topMm, 728);
    expect(vSection.usableWidthMm, 0);
  });

  test('jambette déjà plus haute que 1,80 m : toute la largeur compte', () {
    final vSection = atticSection(
      pWidthMm: 3000,
      pKneeWallMm: 1900,
      pSlopeDeg: 45,
      pTwoPitches: true,
    );
    expect(vSection.lowStripMm, 0);
    expect(vSection.usableWidthMm, 3000);
  });

  test('un plafond plat plus bas que la jambette est ignoré', () {
    final vSection = atticSection(
      pWidthMm: 3000,
      pKneeWallMm: 1000,
      pSlopeDeg: 45,
      pTwoPitches: true,
      pCeilingMm: 500,
    );
    expect(vSection.topMm, 2500);
  });
}
