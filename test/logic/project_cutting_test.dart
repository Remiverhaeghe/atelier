import 'package:atelier/logic/bar_cutting.dart';
import 'package:atelier/logic/eaves_storage.dart';
import 'package:atelier/logic/mezzanine.dart';
import 'package:atelier/logic/panel_cutting.dart';
import 'package:atelier/logic/project_cutting.dart';
import 'package:atelier/logic/shelf.dart';
import 'package:atelier/logic/wood_window.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectPiece bar(int pLength, {int pCount = 1, int pWidth = 45, int pThickness = 70}) => (
  name: PieceName.custom,
  kind: StockKind.bar,
  lengthMm: pLength,
  widthMm: pWidth,
  thicknessMm: pThickness,
  count: pCount,
);

void main() {
  test('trois morceaux de 1,50 m : une seule barre de 5 m plutôt que trois de 2 m', () {
    final vPlan = bestBarPlan([1500, 1500, 1500], 3);
    expect(vPlan.bars.length, 1);
    expect(vPlan.bars.single.barMm, 5000);
    expect(barCuts(vPlan.bars.single, 3), 3);
    expect(barPlanLengthMm(vPlan), 5000);
  });

  test('une barre à moitié vide est raccourcie à la longueur vendue juste au-dessus', () {
    final vPlan = shortenBars(planBars([2500, 900], 3000, 3), barStockMm);
    expect([for (final vBar in vPlan.bars) vBar.barMm], [2500, 2000]);
    expect(vPlan.kerfMm, 3);
  });

  test('un morceau plus long que tout ce qui est vendu reste à commander à part', () {
    final vPlan = bestBarPlan([7000, 1000], 3);
    expect(vPlan.tooLong, [0]);
    expect(vPlan.bars.single.barMm, 2000);
  });

  test('sans morceau, aucune barre', () {
    expect(bestBarPlan(const [], 3).bars, isEmpty);
    expect(barCuts(CutBar(2000), 3), 0);
  });

  test('le dernier morceau au ras du bout de la barre économise un trait de scie', () {
    final vBar = CutBar(2000)
      ..pieceIndexes.addAll([0, 1])
      ..pieceLengths.addAll([997, 1000]);
    expect(barCuts(vBar, 3), 1);
  });

  test('châssis de 100 × 120 cm : cadre et parcloses dans une barre de 2,40 m et une de 2 m', () {
    final vWindow = planWoodWindow(pWidthMm: 1000, pHeightMm: 1200);
    final vPieces = woodWindowPieces(vWindow);
    expect(vPieces.length, 4);
    final vPlan = planProjectCutting(vPieces);
    expect(vPlan.panels, isEmpty);
    expect(vPlan.bars.length, 2);

    final vFrame = vPlan.bars.first;
    expect((vFrame.widthMm, vFrame.thicknessMm), (58, 70));
    expect([for (final vBar in vFrame.plan.bars) vBar.barMm], [2400, 2000]);
    expect(vFrame.cuts, 4);
    expect(vFrame.kerfLossMm, 12);
    expect(vFrame.pieceOf.length, 4);
    expect(barsToBuy(vFrame.plan), [(lengthMm: 2400, count: 1), (lengthMm: 2000, count: 1)]);

    final vBeads = vPlan.bars.last;
    expect((vBeads.widthMm, vBeads.thicknessMm), (beadThicknessMm, beadThicknessMm));
    expect(barPlanLengthMm(vBeads.plan), 4400);
  });

  test('étagère : montants et tablettes dans un panneau de 244 × 122, fond à part', () {
    final vPieces = shelfPieces(const ShelfDesign());
    expect(
      [for (final vPiece in vPieces) vPiece.name],
      [PieceName.side, PieceName.shelf, PieceName.back],
    );
    expect(vPieces.last.thicknessMm, shelfBackMm);
    final vPlan = planProjectCutting(vPieces);
    expect(vPlan.bars, isEmpty);
    expect(vPlan.panels.length, 2);

    final vBoard = vPlan.panels.first;
    expect(vBoard.thicknessMm, 18);
    expect((vBoard.lengthMm, vBoard.widthMm), (2440, 1220));
    expect(vBoard.plan.panels.length, 1);
    expect(vBoard.plan.panels.single.parts.length, 7);
    expect(vBoard.cuts, 11);
    expect(vBoard.kerfLossMm, 33);
    expect(vBoard.pieceOf, [0, 1]);

    final vBack = vPlan.panels.last;
    expect(vBack.thicknessMm, shelfBackMm);
    expect(vBack.plan.tooBig, isEmpty);
  });

  test('une pièce trop grande pour les petits formats choisit un format où elle rentre', () {
    final vPlan = planProjectCutting([
      (
        name: PieceName.custom,
        kind: StockKind.panel,
        lengthMm: 2600,
        widthMm: 900,
        thicknessMm: 18,
        count: 1,
      ),
    ]);
    expect((vPlan.panels.single.lengthMm, vPlan.panels.single.widthMm), (2800, 2070));
    expect(vPlan.panels.single.plan.tooBig, isEmpty);
  });

  test('pièces vides ignorées, sections différentes débitées à part', () {
    final vPlan = planProjectCutting([
      bar(800, pCount: 2),
      bar(0),
      bar(600, pCount: 0),
      bar(1000, pWidth: 27, pThickness: 27),
      bar(500),
    ]);
    expect(vPlan.bars.length, 2);
    expect(vPlan.bars.first.pieceOf, [0, 0, 4]);
    expect(vPlan.bars.last.pieceOf, [3]);
    expect(vPlan.bars.first.plan.bars.single.barMm, 2400);
  });

  test('coupes d\'un panneau : une pièce au bord en économise une', () {
    final vPanel = CutPanel(1000, 500)
      ..parts.addAll(<PlacedPart>[(partIndex: 0, xMm: 0, yMm: 0, lengthMm: 1000, widthMm: 500)]);
    expect(panelCuts(vPanel), 0);
    final vSecond = CutPanel(1000, 500)
      ..parts.addAll(<PlacedPart>[
        (partIndex: 0, xMm: 0, yMm: 0, lengthMm: 400, widthMm: 200),
        (partIndex: 0, xMm: 403, yMm: 0, lengthMm: 597, widthMm: 200),
      ]);
    expect(panelCuts(vSecond), 2);
  });

  test('mezzanine : solives, lambourde et poteaux de la même section ensemble', () {
    const vMezzanine = Mezzanine(support: MezzanineSupport.freestanding);
    final vPlan = planMezzanine(vMezzanine);
    final vPieces = mezzaninePieces(vMezzanine, vPlan);
    expect(vPieces.first.name, PieceName.joist);
    expect(vPieces.first.count, vPlan.joists);
    expect(vPieces.any((pPiece) => pPiece.name == PieceName.ledger), isFalse);
    expect(vPieces.last.name, PieceName.post);
    expect(vPieces.last.count, vPlan.postsPerBeam * vPlan.beams);

    final vOneWall = planMezzanine(const Mezzanine());
    final vWall = mezzaninePieces(const Mezzanine(), vOneWall);
    expect(vWall.where((pPiece) => pPiece.name == PieceName.ledger).single.count, 1);
    final vCut = planProjectCutting(vWall);
    expect(vCut.bars.first.plan.tooLong, isEmpty);
  });

  test('placard sous rampant : montants, fond, portes et tablette en 18 mm', () {
    final vPlan = planEavesStorage(
      pKneeWallMm: 600,
      pSlopeDeg: 45,
      pLengthMm: 2400,
      pFrontMm: 1200,
    )!;
    final vPieces = eavesPieces(vPlan, pFrontMm: 1200, pLengthMm: 2400);
    expect(
      [for (final vPiece in vPieces) vPiece.name],
      [PieceName.eavesSide, PieceName.eavesFloor, PieceName.door, PieceName.shelf],
    );
    expect(vPieces.first.count, 5);
    expect(vPieces[2].count, 4);
    final vCut = planProjectCutting(vPieces);
    expect(vCut.panels.single.thicknessMm, eavesBoardMm);
    expect(vCut.panels.single.plan.tooBig, isEmpty);

    // Façade basse : plus la place d'une tablette au-dessus des bacs
    final vLow = planEavesStorage(pKneeWallMm: 600, pSlopeDeg: 45, pLengthMm: 2400, pFrontMm: 700)!;
    expect(eavesPieces(vLow, pFrontMm: 700, pLengthMm: 2400).length, 3);
  });
}
