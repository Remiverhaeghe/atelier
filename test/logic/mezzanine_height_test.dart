import 'package:atelier/logic/mezzanine.dart';
import 'package:atelier/logic/mezzanine_height.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vPlan = planMezzanine(const Mezzanine());

  test('le plancher au plus bas qui laisse 2,20 m sous la poutre', () {
    // Poutre de 225 mm plus haute que les solives de 145 mm, panneau de 18 mm
    final vSplit = splitHeight(5000, vPlan, 18);

    expect(vSplit.structureMm, 243);
    expect(vSplit.floorTopMm, 2443);
    expect(vSplit.clearBelowMm, 2200);
    expect(vSplit.clearAboveMm, 2557);
    expect(vSplit.fits, isTrue);
    expect(vSplit.standingAbove, isTrue);
  });

  test('assez haut pour une surface habitable, pas pour tenir debout partout', () {
    final vSplit = splitHeight(4300, vPlan, 18);

    expect(vSplit.clearAboveMm, 1857);
    expect(vSplit.fits, isTrue);
    expect(vSplit.standingAbove, isFalse);
  });

  test('pièce trop basse pour une mezzanine habitable', () {
    expect(splitHeight(4000, vPlan, 18).fits, isFalse);
  });

  test('entre deux murs : seules les solives comptent', () {
    final vWalls = planMezzanine(const Mezzanine(support: MezzanineSupport.twoWalls));

    expect(splitHeight(5000, vWalls, 18).structureMm, 163);
  });
}
