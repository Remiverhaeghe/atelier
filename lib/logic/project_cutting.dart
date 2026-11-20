/// Débit de toutes les pièces d'un projet dans les bois et panneaux du commerce : chaque bois
/// d'une même section et chaque épaisseur de panneau sont optimisés à part, trait de scie compté.
///
/// Les longueurs et formats vendus varient d'un magasin à l'autre : ce sont des valeurs
/// courantes, à vérifier au rayon.
library;

import 'bar_cutting.dart';
import 'eaves_storage.dart';
import 'mezzanine.dart';
import 'panel_cutting.dart';
import 'shelf.dart';
import 'wood_window.dart';

/// Bois en barre (tasseau, chevron, planche) ou panneau (contreplaqué, aggloméré, MDF).
enum StockKind { bar, panel }

/// Nom des pièces des projets modèles, traduit à l'affichage ; [custom] pour une pièce saisie.
enum PieceName {
  stile,
  rail,
  bead,
  side,
  shelf,
  back,
  joist,
  ledger,
  post,
  eavesSide,
  eavesFloor,
  door,
  custom,
}

/// Une pièce à débiter, [count] fois. Pour une barre, [widthMm] × [thicknessMm] est la
/// section ; pour un panneau, [widthMm] est la largeur de la pièce et [thicknessMm] celle
/// du panneau.
typedef ProjectPiece = ({
  PieceName name,
  StockKind kind,
  int lengthMm,
  int widthMm,
  int thicknessMm,
  int count,
});

/// Longueurs de bois vendues couramment, des tasseaux aux bois de charpente.
const barStockMm = [2000, 2400, 2500, 3000, 4000, 4500, 5000, 6000];

/// Formats de panneaux courants : longueur × largeur.
const panelSizesMm = <(int, int)>[(2500, 1250), (2440, 1220), (2800, 2070), (1220, 610)];

/// Trait de scie par défaut : lame de scie circulaire.
const defaultKerfMm = 3;

/// Débit d'une section de bois : les barres (de longueurs parfois différentes) et leurs
/// morceaux. [pieceOf] donne, pour chaque morceau du plan, la pièce du projet d'où il vient.
typedef BarStockPlan = ({
  int widthMm,
  int thicknessMm,
  BarPlan plan,
  List<int> pieceOf,

  /// Traits de scie donnés en tout, et longueur qu'ils mangent.
  int cuts,
  int kerfLossMm,
});

/// Débit d'une épaisseur de panneau : format retenu, plan et coupes.
typedef PanelStockPlan = ({
  int thicknessMm,
  int lengthMm,
  int widthMm,
  PanelPlan plan,
  List<int> pieceOf,
  int cuts,
  int kerfLossMm,
});

typedef ProjectCutPlan = ({List<BarStockPlan> bars, List<PanelStockPlan> panels});

/// Longueur totale de bois achetée pour un plan.
int barPlanLengthMm(BarPlan pPlan) => pPlan.bars.fold(0, (pSum, pBar) => pSum + pBar.barMm);

/// Chaque barre prend la plus courte longueur vendue qui contient ses morceaux : une barre
/// à moitié vide de 3 m devient une barre de 2 m.
BarPlan shortenBars(BarPlan pPlan, List<int> pStockMm) {
  final vStock = [...pStockMm]..sort();
  final vBars = <CutBar>[];
  for (final vBar in pPlan.bars) {
    final vUsed = vBar.usedMm(pPlan.kerfMm);
    final vShortest = vStock.where((pLength) => pLength >= vUsed).firstOrNull ?? vBar.barMm;
    final vLength = vShortest < vBar.barMm ? vShortest : vBar.barMm;
    vBars.add(
      CutBar(vLength)
        ..pieceIndexes.addAll(vBar.pieceIndexes)
        ..pieceLengths.addAll(vBar.pieceLengths),
    );
  }
  final rPlan = BarPlan(bars: vBars, kerfMm: pPlan.kerfMm, tooLong: pPlan.tooLong);

  return rPlan;
}

/// Meilleur débit de [pLengths] : on essaie chaque longueur vendue comme barre de départ,
/// on raccourcit les barres, et on garde le moins de bois acheté, puis le moins de barres.
BarPlan bestBarPlan(List<int> pLengths, int pKerfMm, {List<int> pStockMm = barStockMm}) {
  final vLongest = pLengths.fold(0, (pMax, pLength) => pLength > pMax ? pLength : pMax);
  final vSorted = [...pStockMm]..sort();
  final vFitting = vSorted.where((pStock) => pStock >= vLongest).toList();
  final vCandidates = vFitting.isEmpty ? [vSorted.last] : vFitting;
  BarPlan? rPlan;
  for (final vStock in vCandidates) {
    final vPlan = shortenBars(planBars(pLengths, vStock, pKerfMm), vSorted);
    final vBetter =
        rPlan == null ||
        barPlanLengthMm(vPlan) < barPlanLengthMm(rPlan) ||
        (barPlanLengthMm(vPlan) == barPlanLengthMm(rPlan) && vPlan.bars.length < rPlan.bars.length);
    if (vBetter) {
      rPlan = vPlan;
    }
  }

  return rPlan!;
}

/// Traits de scie d'une barre : un par morceau, sauf si le dernier finit au bout de la barre.
int barCuts(CutBar pBar, int pKerfMm) {
  if (pBar.pieceLengths.isEmpty) {
    return 0;
  }
  final rCuts = pBar.pieceLengths.length - (pBar.offcutMm(pKerfMm) == 0 ? 1 : 0);

  return rCuts < 0 ? 0 : rCuts;
}

/// Traits de scie d'un panneau coupé en bandes : un trait de refente par bande, un trait
/// de tronçonnage par pièce ; une pièce au bord du panneau en économise un.
int panelCuts(CutPanel pPanel) {
  final vStrips = {for (final vPart in pPanel.parts) vPart.yMm};
  var rCuts = 0;
  for (final vY in vStrips) {
    final vStripParts = pPanel.parts.where((pPart) => pPart.yMm == vY).toList();
    final vHeight = vStripParts.fold(
      0,
      (pMax, pPart) => pPart.widthMm > pMax ? pPart.widthMm : pMax,
    );
    if (vY + vHeight < pPanel.widthMm) {
      rCuts++;
    }
    for (final vPart in vStripParts) {
      if (vPart.xMm + vPart.lengthMm < pPanel.lengthMm) {
        rCuts++;
      }
    }
  }

  return rCuts;
}

/// Débit du projet : barres regroupées par section, panneaux par épaisseur, dans l'ordre où
/// les sections et épaisseurs apparaissent.
ProjectCutPlan planProjectCutting(
  List<ProjectPiece> pPieces, {
  int pKerfMm = defaultKerfMm,
  bool pRotate = false,
  List<int> pStockMm = barStockMm,
  List<(int, int)> pPanelSizes = panelSizesMm,
}) {
  final vSections = <(int, int)>[];
  final vThicknesses = <int>[];
  for (final vPiece in pPieces) {
    if (vPiece.count <= 0 || vPiece.lengthMm <= 0 || vPiece.widthMm <= 0) {
      continue;
    }
    if (vPiece.kind == StockKind.bar) {
      final vSection = (vPiece.widthMm, vPiece.thicknessMm);
      if (!vSections.contains(vSection)) {
        vSections.add(vSection);
      }
    } else if (!vThicknesses.contains(vPiece.thicknessMm)) {
      vThicknesses.add(vPiece.thicknessMm);
    }
  }

  final vBars = <BarStockPlan>[];
  for (final (vWidth, vThickness) in vSections) {
    final vLengths = <int>[];
    final vPieceOf = <int>[];
    for (var vIndex = 0; vIndex < pPieces.length; vIndex++) {
      final vPiece = pPieces[vIndex];
      if (vPiece.kind == StockKind.bar &&
          vPiece.widthMm == vWidth &&
          vPiece.thicknessMm == vThickness &&
          vPiece.lengthMm > 0) {
        for (var vCopy = 0; vCopy < vPiece.count; vCopy++) {
          vLengths.add(vPiece.lengthMm);
          vPieceOf.add(vIndex);
        }
      }
    }
    final vPlan = bestBarPlan(vLengths, pKerfMm, pStockMm: pStockMm);
    final vCuts = vPlan.bars.fold(0, (pSum, pBar) => pSum + barCuts(pBar, pKerfMm));
    vBars.add((
      widthMm: vWidth,
      thicknessMm: vThickness,
      plan: vPlan,
      pieceOf: vPieceOf,
      cuts: vCuts,
      kerfLossMm: vCuts * pKerfMm,
    ));
  }

  final vPanels = <PanelStockPlan>[];
  for (final vThickness in vThicknesses) {
    final vParts = <PanelPart>[];
    final vPieceOf = <int>[];
    for (var vIndex = 0; vIndex < pPieces.length; vIndex++) {
      final vPiece = pPieces[vIndex];
      if (vPiece.kind == StockKind.panel &&
          vPiece.thicknessMm == vThickness &&
          vPiece.count > 0 &&
          vPiece.lengthMm > 0 &&
          vPiece.widthMm > 0) {
        vParts.add((lengthMm: vPiece.lengthMm, widthMm: vPiece.widthMm, count: vPiece.count));
        vPieceOf.add(vIndex);
      }
    }
    PanelStockPlan? vBest;
    int vArea(PanelStockPlan pPlan) => pPlan.plan.panels.length * pPlan.lengthMm * pPlan.widthMm;
    for (final (vLength, vWidth) in pPanelSizes) {
      final vPlan = planPanels(vParts, vLength, vWidth, pKerfMm: pKerfMm, pRotate: pRotate);
      final vCuts = vPlan.panels.fold(0, (pSum, pPanel) => pSum + panelCuts(pPanel));
      final vCandidate = (
        thicknessMm: vThickness,
        lengthMm: vLength,
        widthMm: vWidth,
        plan: vPlan,
        pieceOf: vPieceOf,
        cuts: vCuts,
        kerfLossMm: vCuts * pKerfMm,
      );
      // D'abord ce qui rentre en entier, puis la plus petite surface achetée
      final vBetter =
          vBest == null ||
          vPlan.tooBig.length < vBest.plan.tooBig.length ||
          (vPlan.tooBig.length == vBest.plan.tooBig.length && vArea(vCandidate) < vArea(vBest));
      if (vBetter) {
        vBest = vCandidate;
      }
    }
    if (vBest != null) {
      vPanels.add(vBest);
    }
  }
  final rPlan = (bars: vBars, panels: vPanels);

  return rPlan;
}

/// Barres à acheter par longueur, de la plus longue à la plus courte.
List<({int lengthMm, int count})> barsToBuy(BarPlan pPlan) {
  final vCounts = <int, int>{};
  for (final vBar in pPlan.bars) {
    vCounts[vBar.barMm] = (vCounts[vBar.barMm] ?? 0) + 1;
  }
  final vLengths = vCounts.keys.toList()..sort((pA, pB) => pB.compareTo(pA));
  final rBuy = [for (final vLength in vLengths) (lengthMm: vLength, count: vCounts[vLength]!)];

  return rBuy;
}

/// Pièces du châssis fixe : montants, traverses et parcloses (section de la parclose carrée).
List<ProjectPiece> woodWindowPieces(
  WoodWindow pWindow, {
  int pFrameWidthMm = 58,
  int pFrameDepthMm = 70,
}) => [
  (
    name: PieceName.stile,
    kind: StockKind.bar,
    lengthMm: pWindow.stileLengthMm,
    widthMm: pFrameWidthMm,
    thicknessMm: pFrameDepthMm,
    count: 2,
  ),
  (
    name: PieceName.rail,
    kind: StockKind.bar,
    lengthMm: pWindow.railLengthMm,
    widthMm: pFrameWidthMm,
    thicknessMm: pFrameDepthMm,
    count: 2,
  ),
  (
    name: PieceName.bead,
    kind: StockKind.bar,
    lengthMm: pWindow.glassWidthMm,
    widthMm: beadThicknessMm,
    thicknessMm: beadThicknessMm,
    count: 2,
  ),
  (
    name: PieceName.bead,
    kind: StockKind.bar,
    lengthMm: pWindow.glassHeightMm,
    widthMm: beadThicknessMm,
    thicknessMm: beadThicknessMm,
    count: 2,
  ),
];

/// Épaisseur du fond d'étagère : panneau de fibres dur cloué au dos.
const shelfBackMm = 3;

/// Pièces de l'étagère, toutes en panneau : montants, tablettes, fond.
List<ProjectPiece> shelfPieces(ShelfDesign pDesign) => [
  for (final vPart in planShelf(pDesign).parts)
    (
      name: switch (vPart.name) {
        sidePart => PieceName.side,
        shelfPart => PieceName.shelf,
        _ => PieceName.back,
      },
      kind: StockKind.panel,
      lengthMm: vPart.lengthMm,
      widthMm: vPart.widthMm,
      thicknessMm: vPart.name == backPart ? shelfBackMm : pDesign.thicknessMm,
      count: vPart.count,
    ),
];

/// Bois de la mezzanine : solives et lambourdes, poteaux. La poutre en lamellé-collé se
/// commande à la longueur et le plancher se pose en panneaux entiers.
List<ProjectPiece> mezzaninePieces(Mezzanine pMezzanine, MezzaninePlan pPlan) => [
  if (pPlan.joist case final vJoist?) ...[
    (
      name: PieceName.joist,
      kind: StockKind.bar,
      lengthMm: pMezzanine.depthMm,
      widthMm: vJoist.widthMm,
      thicknessMm: vJoist.heightMm,
      count: pPlan.joists,
    ),
    if (pPlan.ledgers > 0)
      (
        name: PieceName.ledger,
        kind: StockKind.bar,
        lengthMm: pMezzanine.lengthMm,
        widthMm: vJoist.widthMm,
        thicknessMm: vJoist.heightMm,
        count: pPlan.ledgers,
      ),
  ],
  if (pPlan.postSideMm case final vSide? when pPlan.postsPerBeam > 0)
    (
      name: PieceName.post,
      kind: StockKind.bar,
      lengthMm: pMezzanine.postHeightMm,
      widthMm: vSide,
      thicknessMm: vSide,
      count: pPlan.postsPerBeam * pPlan.beams,
    ),
];

/// Épaisseur des panneaux du placard sous rampant.
const eavesBoardMm = 18;

/// Panneaux du placard sous rampant : montants (débités dans leur rectangle, la coupe en
/// biais se fait ensuite), fond au sol, portes et tablette.
List<ProjectPiece> eavesPieces(EavesPlan pPlan, {required int pFrontMm, required int pLengthMm}) =>
    [
      (
        name: PieceName.eavesSide,
        kind: StockKind.panel,
        lengthMm: pFrontMm,
        widthMm: pPlan.depthMm,
        thicknessMm: eavesBoardMm,
        count: pPlan.sides,
      ),
      (
        name: PieceName.eavesFloor,
        kind: StockKind.panel,
        lengthMm: pLengthMm,
        widthMm: pPlan.depthMm,
        thicknessMm: eavesBoardMm,
        count: 1,
      ),
      (
        name: PieceName.door,
        kind: StockKind.panel,
        lengthMm: pPlan.doorHeightMm,
        widthMm: pPlan.moduleMm,
        thicknessMm: eavesBoardMm,
        count: pPlan.modules,
      ),
      if (pPlan.shelf case final vShelf?)
        (
          name: PieceName.shelf,
          kind: StockKind.panel,
          lengthMm: pLengthMm,
          widthMm: vShelf.depthMm,
          thicknessMm: eavesBoardMm,
          count: 1,
        ),
    ];
