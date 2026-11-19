import 'package:atelier/logic/wood_defects.dart';
import 'package:flutter_test/flutter_test.dart';

BoardReading board({
  int pBow = 0,
  int pTwist = 0,
  int pCup = 0,
  int pKnot = 0,
  bool pLoose = false,
  int pSplit = 0,
  int pMoisture = 10,
}) => (
  lengthMm: 2400,
  widthMm: 120,
  bowMm: pBow,
  twistMm: pTwist,
  cupMm: pCup,
  knotMm: pKnot,
  looseKnot: pLoose,
  splitMm: pSplit,
  moisturePercent: pMoisture,
);

Verdict verdictOf(List<BoardFinding> pFindings, WoodDefect pDefect) =>
    pFindings.firstWhere((pFinding) => pFinding.defect == pDefect).verdict;

void main() {
  test('planche saine : bonne pour un meuble', () {
    final vFindings = inspectBoard(board(), WoodUse.furniture);
    expect(vFindings.length, 6);
    expect(boardVerdict(vFindings), Verdict.ok);
  });

  test('flèche de 4 mm sur 2 m : à laisser pour un meuble, bonne pour une ossature', () {
    expect(
      verdictOf(inspectBoard(board(pBow: 4), WoodUse.furniture), WoodDefect.bow),
      Verdict.refuse,
    );
    expect(verdictOf(inspectBoard(board(pBow: 4), WoodUse.joinery), WoodDefect.bow), Verdict.watch);
    expect(verdictOf(inspectBoard(board(pBow: 4), WoodUse.structure), WoodDefect.bow), Verdict.ok);
  });

  test('gauchissement et tuilage notés à part', () {
    final vFindings = inspectBoard(board(pTwist: 3, pCup: 1), WoodUse.furniture);
    expect(verdictOf(vFindings, WoodDefect.twist), Verdict.refuse);
    expect(verdictOf(vFindings, WoodDefect.cup), Verdict.watch);
    expect(boardVerdict(vFindings), Verdict.refuse);
  });

  test('nœud : selon sa taille, et refusé s\'il bouge sauf en structure', () {
    expect(
      verdictOf(inspectBoard(board(pKnot: 10), WoodUse.furniture), WoodDefect.knot),
      Verdict.ok,
    );
    expect(
      verdictOf(inspectBoard(board(pKnot: 20), WoodUse.furniture), WoodDefect.knot),
      Verdict.watch,
    );
    expect(
      verdictOf(inspectBoard(board(pKnot: 40), WoodUse.furniture), WoodDefect.knot),
      Verdict.refuse,
    );
    expect(
      verdictOf(inspectBoard(board(pKnot: 10, pLoose: true), WoodUse.joinery), WoodDefect.knot),
      Verdict.refuse,
    );
    expect(
      verdictOf(inspectBoard(board(pKnot: 10, pLoose: true), WoodUse.structure), WoodDefect.knot),
      Verdict.watch,
    );
  });

  test('fente en bout : on coupe la fente et 5 cm de plus', () {
    final vBoard = board(pSplit: 150);
    expect(usableLengthMm(vBoard), 2200);
    expect(verdictOf(inspectBoard(vBoard, WoodUse.joinery), WoodDefect.split), Verdict.watch);
    expect(
      verdictOf(inspectBoard(vBoard, WoodUse.joinery, pNeededMm: 2300), WoodDefect.split),
      Verdict.refuse,
    );
    expect(
      verdictOf(inspectBoard(vBoard, WoodUse.joinery, pNeededMm: 2000), WoodDefect.split),
      Verdict.watch,
    );
    expect(usableLengthMm(board(pSplit: 3000)), 0);
  });

  test('humidité : un peu trop, on laisse sécher ; beaucoup trop, on refuse', () {
    expect(
      verdictOf(inspectBoard(board(pMoisture: 12), WoodUse.furniture), WoodDefect.moisture),
      Verdict.ok,
    );
    expect(
      verdictOf(inspectBoard(board(pMoisture: 16), WoodUse.furniture), WoodDefect.moisture),
      Verdict.watch,
    );
    expect(
      verdictOf(inspectBoard(board(pMoisture: 22), WoodUse.furniture), WoodDefect.moisture),
      Verdict.refuse,
    );
    expect(
      verdictOf(inspectBoard(board(pMoisture: 18), WoodUse.structure), WoodDefect.moisture),
      Verdict.ok,
    );
  });

  test('liste de contrôle finie quand tout est coché', () {
    expect(checklistDone({ShopCheck.sight}), isFalse);
    expect(checklistDone(ShopCheck.values.toSet()), isTrue);
  });
}
