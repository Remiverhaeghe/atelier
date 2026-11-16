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
    expect(matchDoor(pOpeningWidthMm: 680, pOpeningHeightMm: 2100, pWallMm: 100).leafWidthMm, isNull);
    final vMatch = matchDoor(pOpeningWidthMm: 815, pOpeningHeightMm: 2050, pWallMm: 160);
    expect(vMatch.leafWidthMm, 730);
    expect(vMatch.widthGapMm, 15);
    expect(vMatch.heightFits, isFalse);
    expect(vMatch.heightGapMm, -50);
    expect(vMatch.adjustableFrame, isTrue);
  });
}
