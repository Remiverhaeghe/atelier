import 'package:atelier/logic/doors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ouverture de 90 × 212 dans une cloison de 72 : bloc-porte de 83', () {
    final vMatch = matchDoor(pOpeningWidthMm: 900, pOpeningHeightMm: 2120, pWallMm: 72);

    expect(vMatch.leafWidthMm, 830);
    expect(vMatch.widthGapMm, 0);
    expect(vMatch.heightFits, isTrue);
    expect(vMatch.heightGapMm, 20);
    expect(vMatch.adjustableFrame, isFalse);
  });

  test('ouverture étroite, basse, mur épais', () {
    expect(
      matchDoor(pOpeningWidthMm: 680, pOpeningHeightMm: 2100, pWallMm: 100).leafWidthMm,
      isNull,
    );
    final vMatch = matchDoor(pOpeningWidthMm: 815, pOpeningHeightMm: 2050, pWallMm: 160);
    expect(vMatch.leafWidthMm, 730);
    expect(vMatch.widthGapMm, 15);
    expect(vMatch.heightFits, isFalse);
    expect(vMatch.heightGapMm, -50);
    expect(vMatch.adjustableFrame, isTrue);
  });

  test('jeu sous la porte : on recoupe ce que le nouveau sol mange', () {
    // 12 mm de jeu, parquet de 14 mm : il faut 12 mm de moins pour garder 1 cm
    expect(doorTrimMm(pCurrentGapMm: 12, pNewFloorMm: 14), 12);
    expect(doorTrimMm(pCurrentGapMm: 30, pNewFloorMm: 8), 0);
  });

  test('poignée confortable entre 90 et 130 cm du sol fini', () {
    expect(handleHeightOk(handleHeightMm), isTrue);
    expect(handleHeightOk(850), isFalse);
    expect(handleHeightOk(1350), isFalse);
  });

  test('sens d\'ouverture déduit des paumelles et du côté où l\'on se tient', () {
    expect(doorHandFrom(pHingesRight: true, pPushing: true), DoorHand.pushRight);
    expect(doorHandFrom(pHingesRight: true, pPushing: false), DoorHand.pushLeft);
    expect(doorHandFrom(pHingesRight: false, pPushing: true), DoorHand.pushLeft);
    expect(doorHandFrom(pHingesRight: false, pPushing: false), DoorHand.pushRight);
  });
}
