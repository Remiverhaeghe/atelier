/// Faïence et crédence : pan de mur moins les ouvertures, découpes de prises, profilés et joint
/// silicone.
library;

import 'tiling.dart';

/// Hauteur courante d'une crédence : du plan de travail au bas des meubles hauts.
const splashbackHeightMm = 600;

/// Diamètre de la scie cloche pour une boîte d'encastrement.
const holeSawMm = 68;

/// Pan de faïence : [design] porte le mur (longueur × hauteur) et les carreaux.
class WallTiling {
  const WallTiling({
    this.design = const TilingDesign(
      lengthMm: 2400,
      widthMm: splashbackHeightMm,
      tileLengthMm: 200,
      tileWidthMm: 100,
      tileThicknessMm: 7,
      jointMm: 2,
      boxM2: 1,
      glueKgPerM2: 4,
      centered: true,
    ),
    this.cutOutWidthMm = 0,
    this.cutOutHeightMm = 0,
    this.sockets = 0,
    this.exposedSides = 0,
    this.onWorktop = true,
    this.topExposed = false,
  });

  final TilingDesign design;

  /// Fenêtre ou niche dans le pan, retirée de la surface.
  final int cutOutWidthMm;
  final int cutOutHeightMm;

  /// Prises et interrupteurs dans la faïence : une découpe et une rehausse chacun.
  final int sockets;

  /// Bords verticaux laissés visibles, à finir par un profilé.
  final int exposedSides;

  /// Crédence posée sur un plan de travail : joint silicone en pied.
  final bool onWorktop;

  /// Haut du pan laissé visible (pas de meuble haut ni de plafond) : profilé en haut aussi.
  final bool topExposed;

  WallTiling copyWith({
    TilingDesign? design,
    int? cutOutWidthMm,
    int? cutOutHeightMm,
    int? sockets,
    int? exposedSides,
    bool? onWorktop,
    bool? topExposed,
  }) => WallTiling(
    design: design ?? this.design,
    cutOutWidthMm: cutOutWidthMm ?? this.cutOutWidthMm,
    cutOutHeightMm: cutOutHeightMm ?? this.cutOutHeightMm,
    sockets: sockets ?? this.sockets,
    exposedSides: exposedSides ?? this.exposedSides,
    onWorktop: onWorktop ?? this.onWorktop,
    topExposed: topExposed ?? this.topExposed,
  );
}

typedef WallTilingNeeds = ({
  TilingNeeds tiling,
  double netAreaM2,
  int tiles,
  int boxes,
  int glueKg,
  double jointKg,
  int holes,
  int profileMm,
  int siliconeMm,
  int bottomFullRows,
});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

/// Quantités d'un pan : le calepinage vient du pan entier, les quantités de la surface nette.
WallTilingNeeds wallTilingNeeds(WallTiling pWall) {
  final vDesign = pWall.design;
  final vGross = vDesign.lengthMm * vDesign.widthMm / 1e6;
  final vCutOut = pWall.cutOutWidthMm * pWall.cutOutHeightMm / 1e6;
  final vNet = (vGross - vCutOut).clamp(0.0, vGross);
  // Les rangées partent du bas, entières : la coupe va en haut, sous les meubles ou au plafond
  final vVertical = layoutAxis(
    vDesign.widthMm,
    vDesign.tileWidthMm,
    vDesign.jointMm,
    pCentered: false,
  );
  final vTiling = tilingNeeds(vDesign);
  final vShare = vGross == 0 ? 0.0 : vNet / vGross;
  final vTileArea = vDesign.tileLengthMm * vDesign.tileWidthMm / 1e6;
  // Chaque découpe de prise gâche un carreau de plus
  final vWithMargin = vNet * (1 + vDesign.marginPercent / 100);
  final vTiles = vTileArea <= 0 ? 0 : _ceil(vWithMargin / vTileArea) + pWall.sockets;
  final rNeeds = (
    tiling: vTiling,
    netAreaM2: vNet,
    tiles: vTiles,
    boxes: vDesign.boxM2 <= 0 ? 0 : _ceil(vTiles * vTileArea / vDesign.boxM2),
    glueKg: _ceil(vNet * vDesign.glueKgPerM2),
    jointKg: (vTiling.jointKg * vShare * 10).ceil() / 10,
    holes: pWall.sockets,
    profileMm: pWall.exposedSides * vDesign.widthMm + (pWall.topExposed ? vDesign.lengthMm : 0),
    siliconeMm: pWall.onWorktop ? vDesign.lengthMm : 0,
    bottomFullRows: vVertical.fullTiles,
  );

  return rNeeds;
}
