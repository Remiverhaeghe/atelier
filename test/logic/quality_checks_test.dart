import 'package:atelier/logic/quality_checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la tolérance suit la longueur, jamais sous 1 mm', () {
    // Aplomb : 5 mm sur 2,50 m, donc 2 mm sur 1 m et 1 mm sur 10 cm
    expect(toleranceFor(QualityCheck.studsPlumb, 2500), 5);
    expect(toleranceFor(QualityCheck.studsPlumb, 1000), 2);
    expect(toleranceFor(QualityCheck.studsPlumb, 100), 1);
  });

  test('à la règle, la tolérance ne grandit pas avec la surface', () {
    expect(toleranceFor(QualityCheck.floorFlat, 6000), 5);
    expect(toleranceFor(QualityCheck.tileLippage, 3000), 1);
  });

  test('un écart dans la tolérance est bon, au-delà il faut reprendre', () {
    expect(checkGap(QualityCheck.shelfLevel, 1, 800), (gapMm: 1, toleranceMm: 2, ok: true));
    expect(checkGap(QualityCheck.shelfLevel, -3, 800).ok, isFalse);
    expect(checkGap(QualityCheck.shelfLevel, -3, 800).gapMm, 3);
  });

  test('diagonales : écart toléré selon la plus longue', () {
    // 1 mm par mètre de diagonale : 5 mm pour une pièce de 3 × 4 m
    final vRoom = checkDiagonals(QualityCheck.layoutSquare, 5000, 4996);
    expect(vRoom, (gapMm: 4, toleranceMm: 5, ok: true));
    expect(checkDiagonals(QualityCheck.frameSquare, 1200, 1205).ok, isFalse);
  });

  test('contrôles cochés retrouvés parmi les étapes de la pièce', () {
    final vDone = doneChecks([
      'firstRow',
      qualityKey(QualityCheck.floorFlat),
      qualityKey(QualityCheck.doorPlumb),
      'quality.inconnu',
    ]);
    expect(vDone, {QualityCheck.floorFlat, QualityCheck.doorPlumb});
    expect(qualityKey(QualityCheck.floorFlat), 'quality.floorFlat');

    final vProgress = stageProgress(vDone);
    expect(vProgress.keys, QualityStage.values);
    expect(vProgress[QualityStage.support], (done: 1, total: 2));
    expect(vProgress[QualityStage.layout], (done: 0, total: 2));
  });

  test('chaque étape a au moins un contrôle', () {
    for (final vStage in QualityStage.values) {
      expect(QualityCheck.values.where((pCheck) => pCheck.stage == vStage), isNotEmpty);
    }
  });
}
