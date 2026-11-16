/// Débit de panneaux (contreplaqué, mélaminé, OSB) : pièces rangées en bandes, trait de scie
/// compté, coupes de part en part comme à la scie circulaire sur rail.
library;

/// Pièce à tailler, [count] fois.
typedef PanelPart = ({int lengthMm, int widthMm, int count});

/// Pièce placée sur un panneau : coin haut gauche et taille, tournée ou non.
typedef PlacedPart = ({int partIndex, int xMm, int yMm, int lengthMm, int widthMm});

class CutPanel {
  CutPanel(this.lengthMm, this.widthMm);

  final int lengthMm;
  final int widthMm;
  final parts = <PlacedPart>[];

  double get usedShare => parts.fold(0, (pSum, pPart) => pSum + pPart.lengthMm * pPart.widthMm) /
      (lengthMm * widthMm);
}

typedef PanelPlan = ({List<CutPanel> panels, List<int> tooBig, double wasteShare});

/// Bande en cours sur un panneau : sa hauteur et la longueur déjà prise.
class _Strip {
  _Strip(this.yMm, this.heightMm);

  final int yMm;
  final int heightMm;
  int usedMm = 0;
}

/// Range les pièces, les plus larges d'abord, dans des bandes sur la longueur des panneaux.
/// Avec [pRotate], une pièce peut tourner si le fil du bois ne compte pas.
PanelPlan planPanels(
  List<PanelPart> pParts,
  int pPanelLengthMm,
  int pPanelWidthMm, {
  int pKerfMm = 3,
  bool pRotate = false,
}) {
  final vPieces = <(int, int, int)>[];
  final vTooBig = <int>[];
  for (var vIndex = 0; vIndex < pParts.length; vIndex++) {
    final vPart = pParts[vIndex];
    var vLength = vPart.lengthMm;
    var vWidth = vPart.widthMm;
    final vFits = vLength <= pPanelLengthMm && vWidth <= pPanelWidthMm;
    final vFitsTurned = pRotate && vWidth <= pPanelLengthMm && vLength <= pPanelWidthMm;
    if (vLength <= 0 || vWidth <= 0) {
      continue;
    }
    if (!vFits && !vFitsTurned) {
      vTooBig.add(vIndex);
      continue;
    }
    // Tournée, la pièce présente son plus petit côté en hauteur de bande
    if (pRotate && (!vFits || (vFitsTurned && vWidth > vLength))) {
      (vLength, vWidth) = (vWidth, vLength);
    }
    for (var vCopy = 0; vCopy < vPart.count; vCopy++) {
      vPieces.add((vIndex, vLength, vWidth));
    }
  }
  vPieces.sort((pA, pB) {
    final vByWidth = pB.$3.compareTo(pA.$3);
    return vByWidth != 0 ? vByWidth : pB.$2.compareTo(pA.$2);
  });

  final vPanels = <CutPanel>[];
  final vStrips = <List<_Strip>>[];
  for (final (vIndex, vLength, vWidth) in vPieces) {
    var vPlaced = false;
    for (var vPanel = 0; vPanel < vPanels.length && !vPlaced; vPanel++) {
      for (final vStrip in vStrips[vPanel]) {
        final vStart = vStrip.usedMm == 0 ? 0 : vStrip.usedMm + pKerfMm;
        if (vWidth <= vStrip.heightMm && vStart + vLength <= pPanelLengthMm) {
          vPanels[vPanel].parts.add(
            (partIndex: vIndex, xMm: vStart, yMm: vStrip.yMm, lengthMm: vLength, widthMm: vWidth),
          );
          vStrip.usedMm = vStart + vLength;
          vPlaced = true;
          break;
        }
      }
      if (!vPlaced) {
        // Nouvelle bande sous la dernière, s'il reste la place
        final vLast = vStrips[vPanel].last;
        final vY = vLast.yMm + vLast.heightMm + pKerfMm;
        if (vY + vWidth <= pPanelWidthMm) {
          final vStrip = _Strip(vY, vWidth)..usedMm = vLength;
          vStrips[vPanel].add(vStrip);
          vPanels[vPanel].parts.add(
            (partIndex: vIndex, xMm: 0, yMm: vY, lengthMm: vLength, widthMm: vWidth),
          );
          vPlaced = true;
        }
      }
    }
    if (!vPlaced) {
      final vPanel = CutPanel(pPanelLengthMm, pPanelWidthMm)
        ..parts.add((partIndex: vIndex, xMm: 0, yMm: 0, lengthMm: vLength, widthMm: vWidth));
      vPanels.add(vPanel);
      vStrips.add([_Strip(0, vWidth)..usedMm = vLength]);
    }
  }
  final vUsed = vPanels.fold(0.0, (pSum, pPanel) => pSum + pPanel.usedShare);
  final rPlan = (
    panels: vPanels,
    tooBig: vTooBig,
    wasteShare: vPanels.isEmpty ? 0.0 : 1 - vUsed / vPanels.length,
  );

  return rPlan;
}
