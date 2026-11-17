/// Plancher et garde-corps d'une mezzanine : panneaux rainurés, vis, colle, barreaudage.
library;

import 'dart:math' as math;

import 'mezzanine.dart';

/// Panneaux de plancher rainurés sur quatre côtés, posés sur solives.
enum FloorPanel {
  /// OSB/3 rainuré 250 × 67,5 cm.
  osb3(lengthMm: 2500, widthMm: 675),

  /// Aggloméré P5 hydrofuge rainuré 205 × 60 cm.
  particleP5(lengthMm: 2050, widthMm: 600);

  const FloorPanel({required this.lengthMm, required this.widthMm});

  final int lengthMm;
  final int widthMm;
}

/// Épaisseur du panneau selon l'entraxe des solives : plus elles sont écartées, plus le
/// panneau est épais pour ne pas plier entre deux.
int floorThicknessMm(FloorPanel pPanel, int pJoistSpacingMm) => switch (pPanel) {
  FloorPanel.osb3 => pJoistSpacingMm <= 400 ? 18 : 22,
  FloorPanel.particleP5 => pJoistSpacingMm <= 400 ? 19 : 22,
};

/// Vis : au moins 2,5 fois l'épaisseur du panneau, arrondi à la dizaine supérieure.
int floorScrewLengthMm(int pThicknessMm) => ((pThicknessMm * 2.5) / 10).ceil() * 10;

typedef FloorPlan = ({
  int thicknessMm,
  int panels,

  /// Vis de 5 mm, une tous les 15 cm sur les solives en bord de panneau, 30 cm ailleurs.
  int screws,
  int screwLengthMm,

  /// Cartouches de colle de 310 ml, dans les rainures et sur les solives.
  int glueCartridges,
});

/// Plancher de [pMezzanine] en [pPanel], 8 % de chutes compris.
FloorPlan planFloor(Mezzanine pMezzanine, FloorPanel pPanel) {
  final vAreaM2 = pMezzanine.lengthMm * pMezzanine.depthMm / 1e6;
  final vPanelM2 = pPanel.lengthMm * pPanel.widthMm / 1e6;
  final vSpacing = pMezzanine.joistSpacingMm <= 0 ? 400 : pMezzanine.joistSpacingMm;
  final vThickness = floorThicknessMm(pPanel, vSpacing);
  // Une ligne de vis par solive, une vis tous les 20 cm en moyenne
  final vScrews = (vAreaM2 * 1000 / vSpacing * 5 - 1e-9).ceil();
  final rPlan = (
    thicknessMm: vThickness,
    panels: (vAreaM2 * 1.08 / vPanelM2 - 1e-9).ceil(),
    screws: vScrews,
    screwLengthMm: floorScrewLengthMm(vThickness),
    glueCartridges: math.max(1, (vAreaM2 / 4 - 1e-9).ceil()),
  );

  return rPlan;
}

/// Hauteur d'un garde-corps de plancher (NF P01-012), en mm.
const guardrailHeightMm = 1000;

/// Plus grand vide admis entre deux éléments : une tête d'enfant ne passe pas.
const guardrailMaxGapMm = 110;

/// Hauteur au-dessus du plancher sans prise horizontale pour grimper.
const guardrailClimbZoneMm = 450;

/// Poteaux de garde-corps : un tous les 1,20 m au plus, boulonnés dans la rive.
const guardrailPostSpacingMm = 1200;

/// Bords dans le vide, accès à l'escalier déduit.
int openEdgeMm(Mezzanine pMezzanine, int pStairOpeningMm) {
  final vEdges = switch (pMezzanine.support) {
    MezzanineSupport.oneWall => pMezzanine.lengthMm + 2 * pMezzanine.depthMm,
    MezzanineSupport.twoWalls => 2 * pMezzanine.lengthMm,
    MezzanineSupport.freestanding => 2 * (pMezzanine.lengthMm + pMezzanine.depthMm),
  };
  final rEdge = math.max(0, vEdges - pStairOpeningMm);

  return rEdge;
}

typedef GuardrailPlan = ({
  int lengthMm,
  int posts,

  /// Barreaux verticaux de [balusterWidthMm], espacés de 11 cm au plus.
  int balusters,
  int balusterWidthMm,

  /// Main courante et lisse basse, chacune de la longueur du garde-corps.
  int railLengthMm,
});

/// Garde-corps à barreaux verticaux le long de [pLengthMm] de bord dans le vide.
GuardrailPlan planGuardrail(int pLengthMm, {int pBalusterWidthMm = 40}) {
  final vLength = math.max(0, pLengthMm);
  final vPitch = guardrailMaxGapMm + pBalusterWidthMm;
  final rPlan = (
    lengthMm: vLength,
    posts: vLength == 0 ? 0 : (vLength / guardrailPostSpacingMm - 1e-9).ceil() + 1,
    balusters: (vLength / vPitch - 1e-9).ceil(),
    balusterWidthMm: pBalusterWidthMm,
    railLengthMm: vLength,
  );

  return rPlan;
}
